#!/usr/bin/env python3
"""Run the viewer before drawing, because Rasta truncates its file at startup."""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile
import time


def capture(viewer, framebuffer, destination):
    """Save the actual X11 display once it matches the completed raster."""
    from PIL import Image, ImageGrab

    expected = Image.frombytes('1', (1920, 1080),
                               Path(framebuffer).read_bytes()).convert('RGB')
    if not expected.getbbox():
        raise RuntimeError('Cannot capture an empty framebuffer')
    for _ in range(100):
        if viewer.poll() is not None:
            raise RuntimeError('Rasta exited before screenshot capture')
        shot = ImageGrab.grab(xdisplay=os.environ['DISPLAY']).convert('RGB')
        if shot.size == expected.size and shot.tobytes() == expected.tobytes():
            destination.parent.mkdir(parents=True, exist_ok=True)
            shot.save(destination, optimize=True)
            print(f'Saved verified X11 screenshot: {destination}')
            return
        time.sleep(0.1)
    raise RuntimeError('X11 display did not match the completed framebuffer')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--smoke', action='store_true')
    parser.add_argument('--screenshot', type=Path)
    parser.add_argument('--program', default='bin/rasta/demo')
    args = parser.parse_args()
    runtime = Path('build/rasta-runtime')
    runtime.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='session-', dir=runtime) as directory:
        framebuffer = str(Path(directory).resolve() / 'screen.fb')
        env = dict(os.environ, GPX_RASTA_FRAMEBUFFER=framebuffer)
        viewer = subprocess.Popen([
            'bin/rasta/rasta', '--width', '1920', '--height', '1080',
            '--bpp', '1', '--scale', '1', '--port', '5000',
            '--framebuffer', framebuffer,
            '--cursor', 'off' if args.screenshot else 'on'], env=env)
        try:
            for _ in range(100):
                if viewer.poll() is not None:
                    raise RuntimeError('Rasta exited before framebuffer startup')
                if Path(framebuffer).exists() and Path(framebuffer).stat().st_size == 259200:
                    break
                time.sleep(0.05)
            else:
                raise RuntimeError('Timed out waiting for the Rasta framebuffer')
            subprocess.run([args.program], env=env, check=True, timeout=30)
            if args.screenshot:
                capture(viewer, framebuffer, args.screenshot)
            elif args.smoke:
                time.sleep(1)
                if viewer.poll() is not None:
                    raise RuntimeError('Rasta exited during X11 smoke test')
                if not any(Path(framebuffer).read_bytes()):
                    raise RuntimeError('Demo produced an empty framebuffer')
                print('Rasta X11 smoke test passed (1920x1080)')
            else:
                viewer.wait()
        finally:
            if viewer.poll() is None:
                viewer.terminate()
            try:
                viewer.wait(timeout=5)
            except subprocess.TimeoutExpired:
                viewer.kill()
                viewer.wait()


if __name__ == '__main__':
    main()

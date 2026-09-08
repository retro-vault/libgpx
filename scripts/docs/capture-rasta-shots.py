#!/usr/bin/env python3
"""Build and capture the Rasta showcase and portable manual samples on X11.

Run from any directory: python3 scripts/docs/capture-rasta-shots.py
All compilation and capture run in Docker; no host display is required.
"""
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
SAMPLES = {
    'panels': 'samples/demo3/src/panels.c',
    'circles': 'samples/demo4/src/circles.c',
    'polygons': 'samples/demo5/src/polygons.c',
}


def run(*args):
    subprocess.run(list(map(str, args)), cwd=ROOT, check=True)


def capture_samples():
    build = Path('build/demo-shots/rasta')
    build.mkdir(parents=True, exist_ok=True)
    wrapper = build / 'main.c'
    wrapper.write_text('/* Hosted entry for the portable void-main samples. */\n'
                       'void rasta_sample(void);\n'
                       'int main(void) { rasta_sample(); return 0; }\n')
    flags = ['-std=c11', '-O2', '-Wall', '-Wextra', '-Wpedantic', '-Werror',
             '-Iinclude']
    programs = {'showcase': Path('bin/rasta/demo')}
    for name, source in SAMPLES.items():
        obj = build / f'{name}.o'
        program = build / name
        run('gcc', *flags, '-Dmain=rasta_sample', '-c', source, '-o', obj)
        run('gcc', *flags, wrapper, obj, 'bin/rasta/libgpx.a', '-o', program)
        programs[name] = program
    for name, program in programs.items():
        run('python3', 'scripts/run/run-rasta-session.py', '--program', program,
            '--screenshot', f'docs/images/screenshots/{name}-rasta.png')


def main():
    os.chdir(ROOT)
    if '--inside' in sys.argv:
        capture_samples()
        return
    run('make', 'rasta-demo', 'ADVANCED=1')
    run('docker', 'run', '--rm', '--init', '-u', f'{os.getuid()}:{os.getgid()}',
        '-v', f'{ROOT}:/work', '-w', '/work',
        os.environ.get('DOCKER_RASTA', 'libgpx-rasta:local'),
        'env', 'SDL_VIDEODRIVER=x11', 'SDL_RENDER_DRIVER=software',
        'xvfb-run', '-a', '-s', '-screen 0 1920x1080x24',
        'python3', 'scripts/docs/capture-rasta-shots.py', '--inside')


if __name__ == '__main__':
    main()

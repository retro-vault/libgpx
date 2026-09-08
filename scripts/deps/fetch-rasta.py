#!/usr/bin/env python3
"""Cache a pinned Rasta checkout; an existing checkout never needs network."""
import fcntl
from pathlib import Path
import shutil
import subprocess
import sys


def git(*args):
    return subprocess.check_output(['git', *map(str, args)], text=True).strip()


def main():
    dest = Path(sys.argv[1]).resolve()
    revision = sys.argv[2]
    dest.parent.mkdir(parents=True, exist_ok=True)
    with (dest.parent / '.rasta-download.lock').open('w') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if dest.exists():
            actual = git('-C', dest, 'rev-parse', 'HEAD')
            if actual != revision:
                raise SystemExit(f'{dest} is at {actual}, expected {revision}. '
                                 'Move that checkout aside to fetch the pin.')
            print(f'Using cached Rasta {actual[:12]} in {dest}')
            return
        temporary = dest.with_name(dest.name + '.download')
        try:
            temporary.mkdir()
            git('init', '-q', temporary)
            git('-C', temporary, 'remote', 'add', 'origin',
                'https://github.com/tstih/rasta.git')
            git('-C', temporary, 'fetch', '--depth=1', 'origin', revision)
            git('-C', temporary, 'checkout', '--detach', '-q', 'FETCH_HEAD')
            if git('-C', temporary, 'rev-parse', 'HEAD') != revision:
                raise SystemExit('Rasta revision verification failed')
            temporary.rename(dest)
        finally:
            if temporary.exists():
                shutil.rmtree(temporary)


if __name__ == '__main__':
    main()

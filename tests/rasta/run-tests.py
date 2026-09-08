#!/usr/bin/env python3
"""Build native regressions with ASan/UBSan and the existing ZX C oracle."""
import os
from pathlib import Path
import re
import subprocess
import sys


def run(*args, **kwargs):
    subprocess.run(list(map(str, args)), check=True, **kwargs)


def main():
    out = Path('build/tests/rasta')
    out.mkdir(parents=True, exist_ok=True)
    advanced = sys.argv[1].lower() not in ('0', 'n', 'no', 'false', 'off')
    header = Path('include/libgpx.h').read_text()
    names = sorted(set(re.findall(r'\b(gpx_\w+)\s*\(', header)))
    prefix = out / 'reference-prefix.h'
    prefix.write_text('\n'.join(f'#define {n} ref_{n}' for n in names) + '\n')
    clean = re.sub(r'/\*.*?\*/', '', header, flags=re.S)
    clean = clean.replace('extern "C" {', '')
    prototypes = '\n'.join(re.findall(r'extern\s+[^;]+;', clean))
    for name in names:
        prototypes = re.sub(rf'\b{name}\b', f'ref_{name}', prototypes)
    (out / 'reference.h').write_text(
        '#ifdef __cplusplus\nextern "C" {\n#endif\n' + prototypes +
        '\nextern uint8_t *gpx_stub_host_screen(void);\n'
        '#ifdef __cplusplus\n}\n#endif\n')
    flags = ['-g', '-O1', '-Wall', '-Wextra', '-Werror',
             '-fsanitize=address,undefined', '-fno-omit-frame-pointer',
             '-fno-pie', '-no-pie', '-Iinclude', '-Ibuild/rasta-lib', f'-I{out}']
    reference = out / 'reference.o'
    run('gcc', '-std=gnu11', *flags, '-DGPX_STUB_HOST', '-include', prefix,
        '-c', 'tests/zx/stub/gpx_stub.c', '-o', reference)
    sources = sorted(Path('src/rasta').glob('*.c'))
    if not advanced:
        sources = [s for s in sources if s.name != 'advanced.c']
    env = dict(os.environ, GPX_RASTA_FRAMEBUFFER=str(out / 'screen.fb'),
               UBSAN_OPTIONS='halt_on_error=1', ASAN_OPTIONS='detect_leaks=1')
    for compiler, standard in [('g++', 'gnu++17'), ('gcc', 'c11')]:
        program = out / ('test-cpp' if compiler == 'g++' else 'test-c')
        run(compiler, f'-std={standard}', *flags,
            f'-DGPX_ADVANCED={int(advanced)}', *sources,
            'tests/rasta/test_rasta.c', reference, '-o', program)
        run(program, env=env)
    symbols = subprocess.check_output(
        ['nm', '-D', '--defined-only', 'bin/rasta/libgpx.so'], text=True)
    optional = {'gpx_draw_circle', 'gpx_fill_circle',
                'gpx_draw_polygon', 'gpx_fill_polygon'}
    exported = {line.split()[-1] for line in symbols.splitlines()}
    expected = set(names) if advanced else set(names) - optional
    assert expected <= exported, f'Missing API: {expected - exported}'
    if not advanced:
        assert not optional & exported, 'ADVANCED=0 leaked advanced symbols'
    print(f'All {len(expected)} public API symbols are exported')


if __name__ == '__main__':
    main()

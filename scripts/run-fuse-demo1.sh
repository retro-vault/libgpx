#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAPE_PATH="${1:-$ROOT_DIR/bin/demo1/demo1.tap}"

if [ $# -gt 0 ]; then
    shift
fi

# Launch Fuse via the system ELF loader so a poisoned SNAP/VS Code preload
# cannot inject the wrong libpthread into the process. We also scrub the
# Snap Code GTK/GIO variables because they can make a host GTK app load
# Snap-only modules and crash at startup.
LD_PRELOAD=
LD_LIBRARY_PATH=
export LD_PRELOAD LD_LIBRARY_PATH

unset GIO_MODULE_DIR
unset GDK_PIXBUF_MODULEDIR
unset GDK_PIXBUF_MODULE_FILE
unset GTK_PATH
unset GTK_EXE_PREFIX
unset GTK_IM_MODULE_FILE
unset XDG_DATA_DIRS
unset XDG_DATA_HOME

exec /lib64/ld-linux-x86-64.so.2 \
    --library-path /lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu \
    /usr/local/bin/fuse \
    --machine 48 \
    --graphics-filter 2x \
    --kempston-mouse \
    --auto-load \
    --tape "$TAPE_PATH" \
    "$@"

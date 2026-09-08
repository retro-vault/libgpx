#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
: "${DISPLAY:?Set DISPLAY to your X11 or XWayland display}"
args=(--rm --init -u "$(id -u):$(id -g)" -v "$PWD:/work" -w /work
    -e DISPLAY -e SDL_VIDEODRIVER=x11 -e SDL_RENDER_DRIVER=software
    -v /tmp/.X11-unix:/tmp/.X11-unix:ro)
rasta_xauthority=${XAUTHORITY:-${HOME}/.Xauthority}
if [[ -f "$rasta_xauthority" ]]; then
    args+=(-e XAUTHORITY=/tmp/rasta.xauth
        -v "$rasta_xauthority:/tmp/rasta.xauth:ro")
fi
exec docker run "${args[@]}" "${DOCKER_RASTA:-libgpx-rasta:local}" \
    python3 scripts/run/run-rasta-session.py

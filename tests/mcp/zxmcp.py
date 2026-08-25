"""Minimal MCP (JSON-RPC 2.0 over stdio) client for zx-spectrum-mcp.

The server is a cycle-accurate ZX Spectrum 48K emulator with no display.
Tests drive it exactly the way an MCP client would: `load` a binary,
`run` it to HALT, then `read_memory` the display file back.
"""

import json
import os
import subprocess

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

# The zx-spectrum-mcp emulator ships inside the same image as the toolchain,
# so the suite has no dependency on a local build of it. ZX_MCP overrides the
# server command with a local binary when one is being developed alongside.
DOCKER_ZX = os.environ.get("DOCKER_ZX", "wischner/xcc-z80-zx-spectrum")
LOCAL_SERVER = os.environ.get("ZX_MCP")

SCREEN_BASE = 0x4000
SCREEN_BITMAP_BYTES = 0x1800
SCREEN_ATTR_BYTES = 0x300
SCREEN_BYTES = SCREEN_BITMAP_BYTES + SCREEN_ATTR_BYTES


class McpError(RuntimeError):
    pass


class Spectrum:
    """One long-lived emulator process, reset between test cases."""

    def __init__(self, server=None, workdir=None):
        server = server or LOCAL_SERVER
        self.workdir = os.path.abspath(workdir or ROOT)
        if server:
            argv = [server]
            self._path_prefix = ""
        else:
            # The container sees the host workdir at /work, so any path handed
            # to `load` or `screenshot` has to be rewritten into that mount.
            argv = [
                "docker", "run", "--rm", "-i",
                "-u", f"{os.getuid()}:{os.getgid()}",
                "-v", f"{self.workdir}:/work",
                "-w", "/work",
                DOCKER_ZX, "zx-spectrum-mcp",
            ]
            self._path_prefix = "/work"
        self._proc = subprocess.Popen(
            argv,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            bufsize=1)
        self._id = 0
        self._request("initialize", {
            "protocolVersion": "2025-06-18",
            "capabilities": {},
            "clientInfo": {"name": "libgpx-tests", "version": "1"},
        })
        self._notify("notifications/initialized")

    # -- plumbing ---------------------------------------------------------

    def _send(self, payload):
        self._proc.stdin.write(json.dumps(payload) + "\n")
        self._proc.stdin.flush()

    def _notify(self, method, params=None):
        msg = {"jsonrpc": "2.0", "method": method}
        if params is not None:
            msg["params"] = params
        self._send(msg)

    def _request(self, method, params=None):
        self._id += 1
        want = self._id
        msg = {"jsonrpc": "2.0", "id": want, "method": method}
        if params is not None:
            msg["params"] = params
        self._send(msg)
        while True:
            line = self._proc.stdout.readline()
            if not line:
                raise McpError("zx-spectrum-mcp closed the connection")
            reply = json.loads(line)
            if reply.get("id") != want:
                continue  # notification or out-of-band message
            if "error" in reply:
                raise McpError(f"{method}: {reply['error']}")
            return reply["result"]

    def call(self, tool, **arguments):
        result = self._request(
            "tools/call", {"name": tool, "arguments": arguments})
        if result.get("isError"):
            texts = [c.get("text", "") for c in result.get("content", [])]
            raise McpError(f"{tool}: {' '.join(texts)}")
        return result.get("structuredContent", {})

    def close(self):
        if self._proc.poll() is None:
            try:
                self._proc.stdin.close()
            except OSError:
                pass
            self._proc.wait(timeout=10)

    def __enter__(self):
        return self

    def __exit__(self, *_):
        self.close()

    # -- convenience ------------------------------------------------------

    def reset(self, clear_memory=True):
        return self.call("reset", clear_memory=clear_memory)

    def guest_path(self, path):
        """Map a host path into the container mount, if one is in use."""
        if not self._path_prefix:
            return path
        rel = os.path.relpath(os.path.abspath(path), self.workdir)
        if rel.startswith(".."):
            raise McpError(
                f"{path} is outside {self.workdir}, which is the only "
                f"directory the emulator container can see")
        return os.path.join(self._path_prefix, rel)

    def load_binary(self, path, address, start=None, reset=False):
        args = {"path": self.guest_path(path), "format": "binary",
                "address": address}
        if start is not None:
            args["start"] = start
        if reset:
            args["reset"] = True
        return self.call("load", **args)

    def registers(self, **regs):
        return self.call("registers", **regs)

    def run(self, **limits):
        return self.call("run", **limits)

    def status(self):
        return self.call("status")

    def read_memory(self, address, length):
        out = bytearray()
        while length > 0:
            chunk = min(length, 4096)
            res = self.call("read_memory", address=address, length=chunk)
            data = bytes(res["bytes"])
            if len(data) != chunk:
                raise McpError(
                    f"read_memory returned {len(data)} of {chunk} bytes")
            out += data
            address += chunk
            length -= chunk
        return bytes(out)

    def screen(self, attrs=False):
        """Return the 6144-byte display file, or 6912 bytes with attributes."""
        return self.read_memory(
            SCREEN_BASE, SCREEN_BYTES if attrs else SCREEN_BITMAP_BYTES)


def zx_offset(x, y):
    """Byte offset of pixel (x, y) inside the ZX display file."""
    return (((y & 0xC0) << 5) | ((y & 0x07) << 8) | ((y & 0x38) << 2)
            | (x >> 3))

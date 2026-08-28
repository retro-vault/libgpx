"""Minimal MCP (JSON-RPC 2.0 over stdio) client for amstrad-cpc-mcp.

The server is a cycle-stepped Amstrad CPC. Like the ZX and Partner servers
it ships inside the toolchain image and runs in Docker, so paths handed to
it have to be rewritten into the container mount.
"""

import json
import os
import subprocess

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

# amstrad-cpc-mcp and the CPC ROMs ship inside the same image as the
# toolchain, so the suite has no dependency on a local build of it. CPC_MCP
# overrides the server command with a local binary when one is being
# developed alongside; CPC_ROMS then says where that binary's ROMs live.
DOCKER_CPC = os.environ.get("DOCKER_CPC", "wischner/xcc-z80-cpc")
LOCAL_SERVER = os.environ.get("CPC_MCP")
IMAGE_ROMS = "/opt/amstrad-cpc-mcp/share/amstrad-cpc-mcp/roms"

SCREEN_BASE = 0xC000
SCREEN_BYTES = 0x4000
BYTES_PER_ROW = 80


class McpError(RuntimeError):
    pass


class Cpc:
    """One long-lived emulator process, reset between test cases."""

    def __init__(self, server=None, model="cpc6128", workdir=None):
        server = server or LOCAL_SERVER
        self.workdir = os.path.abspath(workdir or ROOT)
        if server:
            argv = [server]
            roms = os.environ.get("CPC_ROMS", IMAGE_ROMS)
            self._path_prefix = ""
        else:
            # The container sees the host workdir at /work, so any path handed
            # to `load` or `screenshot` has to be rewritten into that mount.
            argv = [
                "docker", "run", "--rm", "-i",
                "-u", f"{os.getuid()}:{os.getgid()}",
                "-v", f"{self.workdir}:/work",
                "-w", "/work",
                DOCKER_CPC, "amstrad-cpc-mcp",
            ]
            roms = IMAGE_ROMS
            self._path_prefix = "/work"
        argv += ["--model", model,
                 "--os-rom", f"{roms}/{model}-os.rom",
                 "--basic-rom", f"{roms}/{model}-basic.rom",
                 "--amsdos-rom", f"{roms}/amsdos.rom"]
        self._proc = subprocess.Popen(
            argv, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL, text=True, bufsize=1)
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
                raise McpError("amstrad-cpc-mcp closed the connection")
            reply = json.loads(line)
            if reply.get("id") != want:
                continue
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
            return os.path.abspath(path)
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

    def screen(self):
        """Return the whole 16 KiB CPC screen."""
        return self.read_memory(SCREEN_BASE, SCREEN_BYTES)


def cpc_offset(x_byte, y):
    """Offset of a screen byte inside the 16 KiB CPC framebuffer.

    The CPC interleaves eight scanline banks 0x800 apart, and each bank
    holds every eighth line at 80 bytes per line.
    """
    return ((y & 7) << 11) + ((y >> 3) * BYTES_PER_ROW) + x_byte

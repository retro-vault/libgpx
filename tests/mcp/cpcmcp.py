"""Minimal MCP (JSON-RPC 2.0 over stdio) client for amstrad-cpc-mcp.

The server is a cycle-stepped Amstrad CPC. Unlike the ZX and Partner
servers it runs as a native binary rather than inside Docker, so host paths
reach it unchanged.
"""

import json
import os
import subprocess

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

CPC_MCP = os.environ.get(
    "CPC_MCP", "/home/tstih/data/retro-vault/amstrad-cpc-mcp")
SERVER = os.path.join(CPC_MCP, "bin", "bin", "amstrad-cpc-mcp")
ROMS = os.path.join(CPC_MCP, "data", "roms")

SCREEN_BASE = 0xC000
SCREEN_BYTES = 0x4000
BYTES_PER_ROW = 80


class McpError(RuntimeError):
    pass


class Cpc:
    """One long-lived emulator process, reset between test cases."""

    def __init__(self, server=None, model="cpc6128"):
        argv = [server or SERVER, "--model", model,
                "--os-rom", os.path.join(ROMS, f"{model}-os.rom"),
                "--basic-rom", os.path.join(ROMS, f"{model}-basic.rom"),
                "--amsdos-rom", os.path.join(ROMS, "amsdos.rom")]
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
        """The server is native, so host paths need no rewriting."""
        return os.path.abspath(path)

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

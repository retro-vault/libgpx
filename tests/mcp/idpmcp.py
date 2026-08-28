"""Minimal MCP (JSON-RPC 2.0 over stdio) client for idp-mcp.

idp-mcp is the windowless Iskra Delta Partner emulator that ships inside the
xcc-z80-idp toolchain image. `--model gdp` selects the graphics Partner, so
the EF9367 and the GDP-board PIO at 0x30..0x33 are the real chips rather than
the hand-written C++ model in tests/partner/emulator.cpp.

Tests drive it the way any MCP client would: `load` a binary, point the CPU
at it, `run` to HALT, then read the GDP raster back as ASCII art.
"""

import json
import os
import subprocess

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

DOCKER_IDP = os.environ.get("DOCKER_IDP", "wischner/xcc-z80-idp")
# IDP_MCP runs a local idp-mcp build instead of the one in the toolchain
# image -- needed while a fix is in the emulator tree but not yet packaged.
# See docs/todo/EMULATION.md for known emulator defects and version differences.
LOCAL_SERVER = os.environ.get("IDP_MCP")

# GDP framebuffer geometry. gpx_create(0) selects 1024x256, mode 1 is 1024x512.
GDP_WIDTH = 1024
GDP_HEIGHT_LORES = 256
GDP_HEIGHT_HIRES = 512


class McpError(RuntimeError):
    pass


class Partner:
    """One long-lived emulator process, reset between test cases."""

    def __init__(self, server=None, workdir=None, model="gdp", rom=True):
        server = server or LOCAL_SERVER
        self.workdir = os.path.abspath(workdir or ROOT)
        opts = ["--model", model]
        if not rom:
            opts.append("--no-rom")
        if server:
            argv = [server] + opts
            self._path_prefix = ""
        else:
            # The container sees the host workdir at /work, so any path handed
            # to `load` or `screenshot` has to be rewritten into that mount.
            argv = [
                "docker", "run", "--rm", "-i",
                "-u", f"{os.getuid()}:{os.getgid()}",
                "-v", f"{self.workdir}:/work",
                "-w", "/work",
                DOCKER_IDP, "idp-mcp",
            ] + opts
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
                raise McpError("idp-mcp closed the connection")
            line = line.strip()
            if not line or not line.startswith("{"):
                continue          # stray [info] banner on a shared stream
            reply = json.loads(line)
            if reply.get("id") != want:
                continue          # notification or out-of-band message
            if "error" in reply:
                raise McpError(f"{method}: {reply['error']}")
            return reply["result"]

    def call(self, tool, **arguments):
        result = self._request(
            "tools/call", {"name": tool, "arguments": arguments})
        if result.get("isError"):
            texts = [c.get("text", "") for c in result.get("content", [])]
            raise McpError(f"{tool}: {' '.join(texts)}")
        out = result.get("structuredContent")
        if out is None:
            texts = [c.get("text", "") for c in result.get("content", [])
                     if c.get("type") == "text"]
            joined = "\n".join(texts)
            try:
                return json.loads(joined)
            except ValueError:
                return {"text": joined}
        return out

    def close(self):
        if self._proc.poll() is None:
            try:
                self._proc.stdin.close()
            except OSError:
                pass
            try:
                self._proc.wait(timeout=10)
            except subprocess.TimeoutExpired:
                self._proc.kill()

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

    def registers(self, **kwargs):
        return self.call("registers", **kwargs)

    def status(self):
        return self.call("status")

    def run(self, **kwargs):
        return self.call("run", **kwargs)

    def run_until(self, address, max_tstates=None, stop_on_halt=True):
        args = {"address": address, "stop_on_halt": stop_on_halt}
        if max_tstates is not None:
            args["max_tstates"] = max_tstates
        return self.call("run_until", **args)

    def measure_cycles(self, **kwargs):
        return self.call("measure_cycles", **kwargs)

    def read_memory(self, address, length):
        out = self.call("read_memory", address=address, length=length)
        data = out.get("data", out.get("bytes"))
        if isinstance(data, str):
            return bytes.fromhex(data.replace(" ", ""))
        return bytes(data)

    def write_memory(self, address, data):
        if isinstance(data, (bytes, bytearray)):
            data = data.hex()
        return self.call("write_memory", address=address, data=data)

    def read_port(self, port):
        return self.call("read_port", port=port)

    def set_port(self, port, value):
        return self.call("set_port", port=port, value=value)

    def screenshot(self, path, scale=1, include_border=False):
        return self.call("screenshot", path=self.guest_path(path),
                         scale=scale, include_border=include_border)

    def screen_text(self, mode="pixels", **kwargs):
        out = self.call("screen_text", mode=mode, **kwargs)
        return out


# The emulator renders the GDP raster into a PNG with a border and 2x
# vertical scaling, so a logical pixel (x, y) lands at (X0 + x, Y0 + 2y).
RASTER_X0 = 16
RASTER_Y0 = 56
RASTER_YSCALE = 2


def raster_from_png(path, width=GDP_WIDTH, height=GDP_HEIGHT_LORES):
    """Extract the logical 1bpp GDP framebuffer from a screenshot.

    Two layouts are accepted. The bordered one puts logical pixel (x, y) at
    (RASTER_X0 + x, RASTER_Y0 + 2y); the bare one is the logical raster
    itself, one PNG pixel per GDP pixel. Which one a screenshot comes back
    in depends on the emulator build, so the layout is chosen from the
    image's own size rather than assumed.
    """
    from png import lit_mask
    pw, ph, lit = lit_mask(path)
    need_y = RASTER_Y0 + RASTER_YSCALE * (height - 1)
    if pw >= RASTER_X0 + width and ph > need_y:
        x0, y0, yscale = RASTER_X0, RASTER_Y0, RASTER_YSCALE
    elif pw >= width and ph >= height:
        x0, y0, yscale = 0, 0, 1
    else:
        raise McpError(
            f"{path}: {pw}x{ph} is too small for a {width}x{height} raster")
    rows = []
    for y in range(height):
        src = lit[y0 + yscale * y]
        rows.append(bytes(1 if src[x0 + x] else 0 for x in range(width)))
    return rows


def raster_packed(rows):
    """Pack a raster into 1bpp MSB-first bytes, for hashing and goldens."""
    out = bytearray()
    for row in rows:
        acc = 0
        for x, bit in enumerate(row):
            acc = (acc << 1) | bit
            if (x & 7) == 7:
                out.append(acc)
                acc = 0
        if len(row) & 7:
            out.append(acc << (8 - (len(row) & 7)))
    return bytes(out)


def _raster_method(self, path, width=GDP_WIDTH, height=GDP_HEIGHT_LORES):
    self.screenshot(path)
    return raster_from_png(path, width, height)


Partner.raster = _raster_method

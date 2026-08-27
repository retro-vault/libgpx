#!/usr/bin/env python3
"""Apply the mechanical rules of docs/standards/ASSEMBLY_STYLE_GUIDE.md.

Rewrites end-of-line comments to a single ';' aligned on column 41, and adds
the licence/copyright/date block to any file header missing one. Comment text
itself is never touched. Run check-asm-style.py afterwards to confirm.
"""

import os
import re
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
LICENCE = "GPL2 License (see: LICENSE)"
COPYRIGHT = "Copyright (C) 2026 Tomaz Stih"
INITIALS = "TS"
COL = 40                                  # comment starts at column 41


def last_change(path):
    """Date of the file's most recent commit, or today for a new file."""
    try:
        out = subprocess.run(
            ["git", "log", "-1", "--format=%ad", "--date=short", "--", path],
            cwd=ROOT, capture_output=True, text=True, check=True).stdout.strip()
        if out:
            return out
    except subprocess.CalledProcessError:
        pass
    return subprocess.run(["date", "+%Y-%m-%d"], capture_output=True,
                          text=True).stdout.strip()


def fix_eol(line):
    code, sep, comment = line.partition(";")
    if not sep or not code.strip():
        return line
    text = comment.lstrip(";").lstrip()
    code = code.rstrip()
    pad = " " * (COL - len(code)) if len(code) < COL else " "
    return f"{code}{pad}; {text}" if text else code


SECTION_RENAMES = (("Input:", "Arguments:"),
                   ("Output:", "Return:"),
                   ("Returns:", "Return:"))


def fix_sections(text):
    """Rename routine-comment sections to the names the guide prescribes."""
    for old, new in SECTION_RENAMES:
        text = re.sub(r"(;;\s+)" + re.escape(old) + r"(\s*$)",
                      lambda m: m.group(1) + new + m.group(2), text,
                      flags=re.M)
    return text


def fix_local_labels(text):
    """Dot-prefix local code labels, and every reference to them."""
    exported = set(re.findall(r"^\s*\.globl\s+(\S+)", text, re.M))
    lines = text.split("\n")
    in_data = False
    rename = []
    for i, line in enumerate(lines):
        s = line.strip()
        if s.startswith(".area"):
            in_data = ("_DATA" in s or "_BSS" in s or "INITIALIZ" in s)
        m = re.match(r"^([A-Za-z_][\w]*):(?!:)", line)
        if not m or in_data:
            continue
        nxt = "".join(lines[i + 1:i + 4])
        if re.search(r"^\s*\.(db|dw|ds|ascii|asciz|byte|word)\b", nxt, re.M):
            continue                      # data blob, not a code label
        name = m.group(1)
        if name in exported or name.startswith("__"):
            continue
        rename.append(name)
    for name in sorted(set(rename), key=len, reverse=True):
        text = re.sub(r"(?<![.\w])" + re.escape(name) + r"\b", "." + name, text)
    return text


def fix_header(lines, path):
    head_end = 0
    while head_end < len(lines) and lines[head_end].strip().startswith(";;"):
        head_end += 1
    if head_end == 0:
        return lines
    head = "\n".join(lines[:head_end])
    if "License" in head or "LICENSE" in head:
        return lines
    base = os.path.basename(path)
    if base not in lines[0]:
        lines[0] = f"        ;; {base}"
    block = ["        ;;",
             f"        ;; {LICENCE}",
             f"        ;; {COPYRIGHT}",
             "        ;;",
             f"        ;; {last_change(path)}   {INITIALS}"]
    return lines[:head_end] + block + lines[head_end:]


def main():
    targets = []
    for sub in ("src", "tests", "samples"):
        for dirpath, _, names in os.walk(os.path.join(ROOT, sub)):
            targets += [os.path.join(dirpath, f)
                        for f in names if f.endswith(".s")]
    changed = 0
    for path in sorted(targets):
        original = open(path).read()
        text = fix_local_labels(fix_sections(original))
        lines = text.split("\n")
        lines = [fix_eol(ln) for ln in lines]
        lines = fix_header(lines, path)
        out = "\n".join(lines)
        if out != original:
            open(path, "w").write(out)
            changed += 1
    print(f"{changed} of {len(targets)} assembly files rewritten")
    return 0


if __name__ == "__main__":
    sys.exit(main())

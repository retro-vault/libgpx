#!/usr/bin/env python3
"""Check .s files against docs/standards/ASSEMBLY_STYLE_GUIDE.md.

Mechanical rules only -- the ones a script can judge without reading intent.
Run with --list to see one line per violation, or with no arguments for a
per-rule summary. Exits non-zero when anything fails.
"""

import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DIRECTIVES = (".module", ".globl", ".equ", ".area", ".ds", ".byte", ".db",
              ".dw", ".include", ".optsdcc", ".ascii", ".asciz")


SECTIONS = ("Signature:", "Arguments:", "Return:", "Clobbers:", "References:")
BANNED_SECTIONS = ("Input:", "Output:", "Returns:")


def is_data_symbol(lines, index):
    """True when the label at `index` introduces a data blob, not a routine."""
    for line in lines[index + 1:index + 4]:
        head = line.strip().split(" ")[0]
        if head in (".db", ".dw", ".ds", ".ascii", ".asciz", ".byte", ".word"):
            return True
        if head and not head.startswith(";"):
            return False
    return False


def check(path):
    """Return a list of (rule, line_no, detail) for one file."""
    bad = []
    with open(path) as fh:
        text = fh.read()
    lines = text.split("\n")
    exported = set(re.findall(r"^\s*\.globl\s+(\S+)", text, re.M))
    in_data = False
    # Inside a .macro body, a label may be one of the macro's parameters --
    # a placeholder for the real, dot-prefixed name each expansion passes in.
    # Rule 3 cannot judge those, so they are skipped; any other label in a
    # macro body is still a hard-coded name and still has to carry its dot.
    macro_params = set()

    for n, line in enumerate(lines, 1):
        stripped_area = line.strip()
        m_mac = re.match(r"\.macro\s+\S+\s+(.*)$", stripped_area)
        if m_mac:
            macro_params = {a.strip() for a in m_mac.group(1).split(",")
                            if a.strip()}
        elif stripped_area.startswith(".endm"):
            macro_params = set()
        if stripped_area.startswith(".area"):
            in_data = ("_DATA" in stripped_area or "_BSS" in stripped_area
                       or "INITIALIZ" in stripped_area)

        # Rule 2: every global routine carries a divider comment block that
        # uses the prescribed section names.
        m = re.match(r"^([A-Za-z_][\w]*)::", line)
        if m and not in_data and not is_data_symbol(lines, n - 1):
            back = "\n".join(lines[max(0, n - 44):n - 1])
            if "------" not in back:
                bad.append(("routine-no-block", n, m.group(1)))
            else:
                for banned in BANNED_SECTIONS:
                    if banned in back:
                        bad.append(("routine-section-name", n,
                                    f"{m.group(1)} uses '{banned}'"))
                        break
                else:
                    if "Clobbers:" not in back:
                        bad.append(("routine-no-clobbers", n, m.group(1)))

        # Rule 3: local code labels are dot-prefixed. Exported names and the
        # __utility form of rule 6 are not local labels.
        m = re.match(r"^([A-Za-z_][\w]*):(?!:)", line)
        if (m and not in_data and not is_data_symbol(lines, n - 1)
                and m.group(1) not in exported
                and m.group(1) not in macro_params
                and not m.group(1).startswith("__")):
            bad.append(("local-label-dot", n, m.group(1)))

        if "\t" in line:
            bad.append(("tabs", n, "tab character"))

        stripped = line.strip()
        if not stripped:
            continue

        # Directives must be indented.
        if stripped.split(" ")[0].split("\t")[0] in DIRECTIVES:
            if not line.startswith(" "):
                bad.append(("directive-indent", n, stripped[:40]))

        # Standalone comments use ';;' and are indented; labels are not.
        if stripped.startswith(";"):
            if not stripped.startswith(";;"):
                bad.append(("comment-semis", n, stripped[:40]))
            elif not line.startswith(" "):
                bad.append(("comment-indent", n, stripped[:40]))
            continue

        # A local label must start at column 1 and begin with a dot.
        if re.match(r"^\.\w[\w.]*:", line):
            pass                                   # correct
        elif re.match(r"^\s+\.\w[\w.]*:", line):
            bad.append(("local-label-indent", n, stripped[:40]))

        # End-of-line comments: single ';', aligned to column 41 when the
        # instruction fits before it, otherwise one space after it.
        code, sep, comment = line.partition(";")
        if sep and code.strip():
            if line[len(code):].startswith(";;"):
                bad.append(("eol-double-semi", n, stripped[:46]))
            elif len(code.rstrip()) < 40:
                if len(code) != 40:
                    bad.append(("eol-column", n,
                                f"comment at column {len(code) + 1}, want 41"))
            elif code != code.rstrip() + " ":
                bad.append(("eol-column", n,
                            "long instruction wants exactly one space"))

    # File header: the whole leading comment block, however long.
    end = 0
    while end < len(lines) and lines[end].strip().startswith(";;"):
        end += 1
    head = "\n".join(lines[:end])
    base = os.path.basename(path)
    if not head or base not in lines[0]:
        bad.append(("header-name", 1, "first line is not the file name"))
    if "License" not in head and "LICENSE" not in head:
        bad.append(("header-licence", 1, "no licence line"))
    if "Copyright" not in head:
        bad.append(("header-copyright", 1, "no copyright line"))
    return bad


def main():
    listing = "--list" in sys.argv
    targets = []
    for sub in ("src", "tests", "samples"):
        for dirpath, _, names in os.walk(os.path.join(ROOT, sub)):
            targets += [os.path.join(dirpath, f)
                        for f in names if f.endswith(".s")]
    targets.sort()

    totals, files_bad = {}, 0
    for path in targets:
        bad = check(path)
        if bad:
            files_bad += 1
        for rule, n, detail in bad:
            totals[rule] = totals.get(rule, 0) + 1
            if listing:
                rel = os.path.relpath(path, ROOT)
                print(f"{rel}:{n}: {rule}: {detail}")

    if not listing:
        print(f"{len(targets)} assembly files, {files_bad} with violations")
        for rule in sorted(totals, key=lambda r: -totals[r]):
            print(f"  {rule:22s} {totals[rule]:6d}")
    return 1 if totals else 0


if __name__ == "__main__":
    sys.exit(main())

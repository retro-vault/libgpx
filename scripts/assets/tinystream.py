"""Shared helpers for building Partner "tiny" vector move streams.

The Partner draws a tiny payload by stroking it, and XOR-based callers --
gpx_show_sprite, and gpx_draw_text with BM_XOR -- require that every pixel be
plotted EXACTLY ONCE. A path that retraces itself cancels the retraced pixels
back to the background. Everything here exists to guarantee plot-once
coverage.

Move byte layout:
    bits 6:5  |dx|      bit 1  dx is negative
    bits 4:3  |dy|      bit 2  dy is negative
    bit 7 set + bit 0 clear -> foreground stroke
    bit 0 set            -> mask stroke (drawn in CO_BACK)
    neither              -> pen-up move, plots nothing
"""

MAXD = 3                      # each delta field is two bits
COMMENT_COL = 41              # docs/standards/ASSEMBLY_STYLE_GUIDE.md


def cover(pixels):
    """Cover `pixels` with disjoint straight runs of at most MAXD+1 pixels.

    Runs are horizontal or vertical only: the EF9367 picks its own interior
    pixels for a slanted vector, so a slanted run could not be predicted
    here, and two runs that disagreed by one pixel would either double-plot
    or leave a hole.
    """
    todo = set(pixels)
    runs = []
    while todo:
        x0, y0 = min(todo, key=lambda p: (p[1], p[0]))
        best = (0, 1, 0)
        for dx, dy in ((1, 0), (0, 1)):
            n = 0
            while n <= MAXD and (x0 + dx * n, y0 + dy * n) in todo:
                n += 1
            if n > best[0]:
                best = (n, dx, dy)
        n, dx, dy = best
        pts = [(x0 + dx * i, y0 + dy * i) for i in range(n)]
        todo.difference_update(pts)
        runs.append((pts[0], pts[-1]))
    return runs


def encode(dx, dy, cc):
    """cc: 0 pen-up, 1 foreground, 2 mask."""
    if not (abs(dx) <= MAXD and abs(dy) <= MAXD):
        raise ValueError(f"delta {dx},{dy} does not fit two bits")
    mv = (abs(dx) << 5) | (abs(dy) << 3)
    if dx < 0:
        mv |= 0x02
    if dy < 0:
        mv |= 0x04
    if cc == 1:
        mv |= 0x80
    elif cc == 2:
        mv |= 0x01
    return mv


def stream(runs, start=(0, 0)):
    """Turn (run, colour) pairs into a move list, hopping with pen-up moves."""
    moves, notes = [], []
    cur = start
    for (a, b), cc in runs:
        while cur != a:
            dx = max(-MAXD, min(MAXD, a[0] - cur[0]))
            dy = max(-MAXD, min(MAXD, a[1] - cur[1]))
            moves.append(encode(dx, dy, 0))
            notes.append(f"dx={dx:+d} dy={dy:+d} pen-up")
            cur = (cur[0] + dx, cur[1] + dy)
        dx, dy = b[0] - a[0], b[1] - a[1]
        moves.append(encode(dx, dy, cc))
        notes.append(f"dx={dx:+d} dy={dy:+d} "
                     f"{'fore' if cc == 1 else 'mask'}")
        cur = b
    return moves, notes


def decode(mv):
    dx = (mv & 0x60) >> 5
    dy = (mv & 0x18) >> 3
    if mv & 0x02:
        dx = -dx
    if mv & 0x04:
        dy = -dy
    return dx, dy, (2 if mv & 0x01 else 0) + (1 if mv & 0x80 else 0)


def replay(moves, start=(0, 0)):
    """Return {pixel: times plotted} for a move list."""
    hits, pos = {}, start
    for mv in moves:
        dx, dy, cc = decode(mv)
        nxt = (pos[0] + dx, pos[1] + dy)
        if cc:
            n = max(abs(dx), abs(dy))
            sx = (dx > 0) - (dx < 0)
            sy = (dy > 0) - (dy < 0)
            for i in range(n + 1):
                p = (pos[0] + sx * i, pos[1] + sy * i)
                hits[p] = hits.get(p, 0) + 1
        pos = nxt
    return hits


def row(text, comment):
    """One source line with its comment on COMMENT_COL."""
    pad = max(1, COMMENT_COL - 1 - len(text))
    return f"{text}{' ' * pad}; {comment}\n"

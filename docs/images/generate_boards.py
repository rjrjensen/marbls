"""Generates the illustrative board SVGs used in docs/DESIGN.md.

This is a documentation helper only. It mirrors the layout rules described in
the design doc (one "arm" per seat, arranged around a regular-polygon hub) so the
player-count brainstorm has pictures. Run: python3 docs/images/generate_boards.py
"""
import math
from pathlib import Path

SIDE = 4.0          # hub side length, in hole spacings (matches the physical board)
ARM_LENGTH = 5      # holes from hub edge to the outer end of an arm
HOLE_R = 0.30
SCALE = 28          # px per hole spacing
PAD = 1.2

SEAT_COLORS = ["#d62828", "#1d4ed8", "#f2b705", "#15803d",
               "#7e22ce", "#ea580c", "#0e9aa7", "#db2777"]
TRACK = "#6b4f2a"
BOARD = "#e3c28f"
BOARD_EDGE = "#b08a52"


def board(arm_count: int, seats: list[int], title: str) -> str:
    apothem = SIDE / (2 * math.tan(math.pi / arm_count))
    holes: list[tuple[float, float, str, bool]] = []  # x, y, color, filled

    def direction(k: int) -> tuple[float, float]:
        a = math.radians(180 + k * 360 / arm_count)
        return math.cos(a), math.sin(a)

    for k in range(arm_count):
        nx, ny = direction(k)
        tx, ty = -ny, nx  # tangent: clockwise on screen (y points down)
        color = SEAT_COLORS[seats.index(k)] if k in seats else None

        def at(u: float, v: float) -> tuple[float, float]:
            return ((apothem + v) * nx + (u - SIDE / 2) * tx,
                    (apothem + v) * ny + (u - SIDE / 2) * ty)

        # Main track owned by this arm: left side, outer end, right side.
        for v in range(1, ARM_LENGTH):
            holes.append((*at(0, v), TRACK, False))
            holes.append((*at(SIDE, v), TRACK, False))
        for u in range(int(SIDE) + 1):
            is_start = u == SIDE and color
            holes.append((*at(u, ARM_LENGTH), color if is_start else TRACK, bool(is_start)))
        # Fast Track corner (hub vertex) on the approach side of this arm.
        holes.append((*at(0, 0), color or TRACK, bool(color)))
        if not color:
            continue
        # Finish lane runs down the middle of the arm.
        for v in range(1, ARM_LENGTH):
            holes.append((*at(SIDE / 2, v), color, True))
        # Starting block sits on the wedge bisector past this arm's far corner.
        n2x, n2y = direction(k + 1)
        bx, by = nx + n2x, ny + n2y
        bl = math.hypot(bx, by)
        cx, cy = at(SIDE, 0)
        for step in range(2, 6):
            d = step * math.sqrt(2)
            holes.append((cx + bx / bl * d, cy + by / bl * d, color, False))

    holes.append((0.0, 0.0, "#111111", True))  # Bull's Eye

    xs = [h[0] for h in holes]
    ys = [h[1] for h in holes]
    minx, maxx = min(xs) - PAD, max(xs) + PAD
    miny, maxy = min(ys) - PAD, max(ys) + PAD
    w, h = (maxx - minx) * SCALE, (maxy - miny) * SCALE + 30
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{w:.0f}" height="{h:.0f}" '
           f'viewBox="0 0 {w:.0f} {h:.0f}" font-family="sans-serif">',
           f'<rect x="1" y="1" width="{w-2:.0f}" height="{h-2:.0f}" rx="14" fill="{BOARD}" '
           f'stroke="{BOARD_EDGE}" stroke-width="2"/>',
           f'<text x="{w/2:.0f}" y="22" text-anchor="middle" font-size="15" '
           f'fill="#3b2a12" font-weight="bold">{title}</text>']
    for x, y, color, filled in holes:
        px, py = (x - minx) * SCALE, (y - miny) * SCALE + 30
        fill = color if filled else "#f6e7c8"
        out.append(f'<circle cx="{px:.1f}" cy="{py:.1f}" r="{HOLE_R*SCALE:.1f}" '
                   f'fill="{fill}" stroke="{color}" stroke-width="2.5"/>')
    out.append("</svg>")
    return "\n".join(out)


def main() -> None:
    here = Path(__file__).parent
    layouts = {
        "board-2p.svg": (4, [0, 2], "2 players · classic board, opposite seats"),
        "board-3p.svg": (3, [0, 1, 2], "3 players · 3 arms · 42 track spaces"),
        "board-4p.svg": (4, [0, 1, 2, 3], "4 players · 4 arms · 56 track spaces"),
        "board-5p.svg": (5, [0, 1, 2, 3, 4], "5 players · 5 arms · 70 track spaces"),
        "board-6p.svg": (6, list(range(6)), "6 players · 6 arms · 84 track spaces"),
        "board-8p.svg": (8, list(range(8)), "8 players · 8 arms · 112 track spaces"),
    }
    for name, (arms, seats, title) in layouts.items():
        (here / name).write_text(board(arms, seats, title))


if __name__ == "__main__":
    main()

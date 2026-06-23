#!/usr/bin/env python3
"""Authoring + verification tool for the tracing stroke paths.

The game traces a "follow the road" path for every glyph. Those paths are defined
here in normalized [0,1]x[0,1] space (x -> right, y -> down, screen space) so they
can be verified as ASCII art, then emitted as the GDScript data file the game
loads (`scripts/Glyphs.gd`). Keeping a single source of truth means the drawn
letter and the traceable path can never drift apart.

Usage:
    python3 tools/glyphs.py              # render every glyph as ASCII
    python3 tools/glyphs.py ABC3         # render only these glyphs
    python3 tools/glyphs.py --emit       # (re)generate scripts/Glyphs.gd
"""
import math
import os
import sys

ORDER = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"


def cosd(a):
    return math.cos(math.radians(a))


def sind(a):
    return math.sin(math.radians(a))


def L(*pts):
    """A straight polyline through pts."""
    return [(float(x), float(y)) for (x, y) in pts]


def A(cx, cy, rx, ry, a0, a1, steps=20):
    """Elliptical arc a0->a1 in degrees (y-down): 0=right,90=down,180=left,270=up."""
    out = []
    for i in range(steps + 1):
        a = a0 + (a1 - a0) * i / steps
        out.append((cx + rx * cosd(a), cy + ry * sind(a)))
    return out


def join(*parts):
    """Concatenate point-lists into one stroke, dropping duplicate seams."""
    out = []
    for p in parts:
        if out and p and abs(out[-1][0] - p[0][0]) < 1e-6 and abs(out[-1][1] - p[0][1]) < 1e-6:
            out.extend(p[1:])
        else:
            out.extend(p)
    return out


G = {}

# ---- Letters (uppercase), authored with sensible handwriting stroke order ----
G['A'] = [L((0.18, 0.92), (0.5, 0.08)), L((0.5, 0.08), (0.82, 0.92)), L((0.31, 0.62), (0.69, 0.62))]
G['B'] = [L((0.28, 0.08), (0.28, 0.92)),
          A(0.28, 0.29, 0.30, 0.21, -90, 90, 16),
          A(0.28, 0.71, 0.34, 0.21, -90, 90, 16)]
G['C'] = [A(0.52, 0.5, 0.34, 0.42, -52, -308, 30)]
G['D'] = [L((0.28, 0.08), (0.28, 0.92)),
          A(0.28, 0.5, 0.50, 0.42, -90, 90, 24)]
G['E'] = [L((0.30, 0.08), (0.30, 0.92)), L((0.30, 0.08), (0.72, 0.08)),
          L((0.30, 0.50), (0.66, 0.50)), L((0.30, 0.92), (0.72, 0.92))]
G['F'] = [L((0.30, 0.08), (0.30, 0.92)), L((0.30, 0.08), (0.72, 0.08)),
          L((0.30, 0.50), (0.66, 0.50))]
G['G'] = [A(0.52, 0.5, 0.34, 0.42, -52, -300, 28), L((0.74, 0.55), (0.52, 0.55))]
G['H'] = [L((0.28, 0.08), (0.28, 0.92)), L((0.72, 0.08), (0.72, 0.92)),
          L((0.28, 0.50), (0.72, 0.50))]
G['I'] = [L((0.32, 0.08), (0.68, 0.08)), L((0.50, 0.08), (0.50, 0.92)),
          L((0.32, 0.92), (0.68, 0.92))]
G['J'] = [join(L((0.62, 0.08), (0.62, 0.66)), A(0.46, 0.66, 0.16, 0.20, 0, 180, 14)),
          L((0.46, 0.08), (0.78, 0.08))]
G['K'] = [L((0.30, 0.08), (0.30, 0.92)), L((0.72, 0.08), (0.30, 0.52)),
          L((0.34, 0.48), (0.74, 0.92))]
G['L'] = [L((0.32, 0.08), (0.32, 0.92), (0.72, 0.92))]
G['M'] = [L((0.20, 0.92), (0.20, 0.08), (0.50, 0.62), (0.80, 0.08), (0.80, 0.92))]
G['N'] = [L((0.28, 0.92), (0.28, 0.08), (0.72, 0.92), (0.72, 0.08))]
G['O'] = [A(0.50, 0.5, 0.34, 0.42, -90, -450, 32)]
G['P'] = [L((0.28, 0.08), (0.28, 0.92)), A(0.28, 0.29, 0.32, 0.21, -90, 90, 16)]
G['Q'] = [A(0.50, 0.5, 0.34, 0.42, -90, -450, 32), L((0.58, 0.62), (0.84, 0.94))]
G['R'] = [L((0.28, 0.08), (0.28, 0.92)), A(0.28, 0.29, 0.32, 0.21, -90, 90, 16),
          L((0.28, 0.50), (0.74, 0.92))]
G['S'] = [join(A(0.50, 0.30, 0.22, 0.22, -30, -210, 18), A(0.50, 0.70, 0.22, 0.22, -30, 150, 18))]
G['T'] = [L((0.20, 0.08), (0.80, 0.08)), L((0.50, 0.08), (0.50, 0.92))]
G['U'] = [join(L((0.28, 0.08), (0.28, 0.60)), A(0.50, 0.60, 0.22, 0.32, 180, 0, 18), L((0.72, 0.60), (0.72, 0.08)))]
G['V'] = [L((0.22, 0.08), (0.50, 0.92), (0.78, 0.08))]
G['W'] = [L((0.14, 0.08), (0.32, 0.92), (0.50, 0.32), (0.68, 0.92), (0.86, 0.08))]
G['X'] = [L((0.28, 0.08), (0.72, 0.92)), L((0.72, 0.08), (0.28, 0.92))]
G['Y'] = [L((0.28, 0.08), (0.50, 0.50)), L((0.72, 0.08), (0.50, 0.50)), L((0.50, 0.50), (0.50, 0.92))]
G['Z'] = [L((0.28, 0.08), (0.72, 0.08), (0.28, 0.92), (0.72, 0.92))]

# ---- Numbers ----
G['0'] = [A(0.50, 0.5, 0.28, 0.42, -90, -450, 32)]
G['1'] = [L((0.34, 0.24), (0.50, 0.08), (0.50, 0.92)), L((0.32, 0.92), (0.68, 0.92))]
G['2'] = [join(A(0.50, 0.31, 0.22, 0.21, 196, 392, 18), L((0.69, 0.42), (0.30, 0.85), (0.30, 0.90), (0.74, 0.90)))]
G['3'] = [join(A(0.45, 0.28, 0.21, 0.20, 218, 470, 16), A(0.45, 0.67, 0.25, 0.25, 250, 470, 18))]
G['4'] = [L((0.62, 0.10), (0.24, 0.64), (0.78, 0.64)), L((0.62, 0.10), (0.62, 0.92))]
G['5'] = [L((0.66, 0.10), (0.34, 0.10), (0.34, 0.44)), A(0.42, 0.66, 0.28, 0.26, -110, 120, 18)]
G['6'] = [join(A(0.52, 0.36, 0.26, 0.28, -40, -200, 16), L((0.26, 0.36), (0.26, 0.66)), A(0.50, 0.66, 0.24, 0.26, 180, 540, 26))]
G['7'] = [L((0.26, 0.10), (0.76, 0.10), (0.42, 0.92))]
G['8'] = [join(A(0.50, 0.30, 0.20, 0.22, -90, 270, 18), A(0.50, 0.70, 0.24, 0.24, -90, -450, 22))]
G['9'] = [join(A(0.50, 0.34, 0.22, 0.24, -90, -450, 22), L((0.72, 0.34), (0.50, 0.92)))]


def resample(stroke, n):
    if len(stroke) < 2:
        return stroke
    seglens, total = [], 0.0
    for i in range(len(stroke) - 1):
        d = math.dist(stroke[i], stroke[i + 1])
        seglens.append(d)
        total += d
    if total == 0:
        return stroke
    out = []
    for k in range(n + 1):
        t = total * k / n
        acc = 0.0
        for i in range(len(stroke) - 1):
            if acc + seglens[i] >= t or i == len(stroke) - 2:
                f = 0 if seglens[i] == 0 else (t - acc) / seglens[i]
                x = stroke[i][0] + (stroke[i + 1][0] - stroke[i][0]) * f
                y = stroke[i][1] + (stroke[i + 1][1] - stroke[i][1]) * f
                out.append((x, y))
                break
            acc += seglens[i]
    return out


def render(ch):
    W, H = 24, 30
    grid = [[' '] * W for _ in range(H)]
    for si, stroke in enumerate(G[ch]):
        label = str(si + 1)
        for j, (x, y) in enumerate(resample(stroke, 200)):
            cx = min(W - 1, max(0, int(x * (W - 1))))
            cy = min(H - 1, max(0, int(y * (H - 1))))
            if j == 0:
                grid[cy][cx] = '#'
            elif grid[cy][cx] == ' ':
                grid[cy][cx] = label
    print(f"=== {ch} ({len(G[ch])} stroke(s); # = stroke start) ===")
    for row in grid:
        print('|' + ''.join(row) + '|')
    print()


def emit_gd(path):
    lines = [
        '# AUTO-GENERATED by tools/glyphs.py — do not edit by hand.',
        '# Stroke-path data for traceable glyphs. Coords normalized [0,1]x[0,1]',
        '# (x right, y down). Each glyph = ordered Array of strokes;',
        '# each stroke = PackedVector2Array of waypoints in draw order.',
        '# Registered as the "Glyphs" autoload singleton.',
        'extends Node',
        '',
        'var STROKES: Dictionary = {}',
        '',
        'func _ready() -> void:',
        '\t_build()',
        '',
        '## Returns the ordered list of strokes (PackedVector2Array) for a glyph.',
        'func get_strokes(glyph: String) -> Array:',
        '\treturn STROKES.get(glyph, [])',
        '',
        'func _build() -> void:',
        '\tSTROKES = {',
    ]
    for ch in ORDER:
        lines.append('\t\t"%s": [' % ch)
        for stroke in G[ch]:
            verts = ', '.join('Vector2(%.4f, %.4f)' % (round(x, 4), round(y, 4)) for (x, y) in stroke)
            lines.append('\t\t\tPackedVector2Array([%s]),' % verts)
        lines.append('\t\t],')
    lines.append('\t}')
    lines.append('')
    with open(path, 'w') as f:
        f.write('\n'.join(lines))
    print('Wrote %s (%d glyphs)' % (path, len(ORDER)))


def main():
    args = sys.argv[1:]
    if args and args[0] == '--emit':
        out = os.path.join(os.path.dirname(__file__), '..', 'scripts', 'Glyphs.gd')
        emit_gd(os.path.normpath(out))
        return
    chars = args[0] if args else ORDER
    for ch in chars:
        if ch in G:
            render(ch)


if __name__ == '__main__':
    main()

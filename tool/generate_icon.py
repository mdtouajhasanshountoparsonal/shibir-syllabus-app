#!/usr/bin/env python3
"""Generate the app launcher icon and Android mipmaps with no dependencies.

Renders a rounded-square red tile with a white open-book glyph, supersampled
2x for smooth edges, and writes the Android mipmap PNGs plus a 1024 master.
"""
import math
import os
import struct
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ANDROID_RES = os.path.join(ROOT, "android", "app", "src", "main", "res")
ASSETS = os.path.join(ROOT, "assets", "branding")

BG = (255, 59, 92)        # app seed red
PAGE = (255, 255, 255)
SPINE = (214, 40, 70)
LINE = (255, 186, 198)
SS = 3                    # supersample factor


def new_canvas(w, h, rgba=(0, 0, 0, 0)):
    return [[list(rgba) for _ in range(w)] for _ in range(h)]


def blend(canvas, x, y, color, alpha=1.0):
    if x < 0 or y < 0 or y >= len(canvas) or x >= len(canvas[0]):
        return
    if alpha >= 1.0:
        canvas[y][x] = [color[0], color[1], color[2], 255]
        return
    px = canvas[y][x]
    for i in range(3):
        px[i] = int(px[i] * (1 - alpha) + color[i] * alpha)


def fill_rounded_rect(canvas, x0, y0, x1, y1, r, color):
    for y in range(y0, y1):
        for x in range(x0, x1):
            dx = 0
            dy = 0
            if x < x0 + r:
                dx = x0 + r - x
            elif x > x1 - r - 1:
                dx = x - (x1 - r - 1)
            if y < y0 + r:
                dy = y0 + r - y
            elif y > y1 - r - 1:
                dy = y - (y1 - r - 1)
            if dx * dx + dy * dy <= r * r:
                blend(canvas, x, y, color)


def fill_polygon(canvas, points, color):
    ys = [p[1] for p in points]
    ymin, ymax = int(min(ys)), int(max(ys))
    n = len(points)
    for y in range(ymin, ymax + 1):
        xs = []
        for i in range(n):
            x1, y1 = points[i]
            x2, y2 = points[(i + 1) % n]
            if y1 == y2:
                continue
            if (y >= y1 and y < y2) or (y >= y2 and y < y1):
                t = (y - y1) / (y2 - y1)
                xs.append(x1 + t * (x2 - x1))
        xs.sort()
        for i in range(0, len(xs) - 1, 2):
            for x in range(int(math.ceil(xs[i])), int(math.floor(xs[i + 1])) + 1):
                blend(canvas, x, y, color)


def fill_rect(canvas, x0, y0, x1, y1, color):
    for y in range(y0, y1):
        for x in range(x0, x1):
            blend(canvas, x, y, color)


def render(size):
    s = size * SS
    c = new_canvas(s, s)
    margin = int(s * 0.05)
    fill_rounded_rect(c, margin, margin, s - margin, s - margin,
                      int(s * 0.235), BG)

    cx = s // 2
    top = int(s * 0.30)
    dip = int(s * 0.35)      # center dip height
    bottom = int(s * 0.76)
    left = int(s * 0.16)
    right = int(s * 0.84)
    outer_top = int(s * 0.28)

    # Left and right pages as slightly curved quadrilaterals.
    left_page = [(cx, dip), (left, outer_top), (left + int(s * 0.02), bottom),
                 (cx, bottom + int(s * 0.012))]
    right_page = [(cx, dip), (right, outer_top),
                  (right - int(s * 0.02), bottom),
                  (cx, bottom + int(s * 0.012))]
    fill_polygon(c, left_page, PAGE)
    fill_polygon(c, right_page, PAGE)

    # Spine.
    fill_rect(c, cx - int(s * 0.012), dip, cx + int(s * 0.012),
              bottom + int(s * 0.015), SPINE)

    # Page detail lines.
    for i in range(1, 4):
        ty = dip + int((bottom - dip) * i / 4.0)
        fill_rect(c, left + int(s * 0.04), ty,
                  cx - int(s * 0.05), ty + max(1, int(s * 0.012)), LINE)
        fill_rect(c, cx + int(s * 0.05), ty,
                  right - int(s * 0.04), ty + max(1, int(s * 0.012)), LINE)

    return downsample(c, size)


def downsample(c, size):
    out = new_canvas(size, size)
    for y in range(size):
        for x in range(size):
            r = g = b = a = 0
            for dy in range(SS):
                for dx in range(SS):
                    px = c[y * SS + dy][x * SS + dx]
                    r += px[0]
                    g += px[1]
                    b += px[2]
                    a += px[3]
            n = SS * SS
            out[y][x] = [r // n, g // n, b // n, a // n]
    return out


def write_png(path, canvas):
    h = len(canvas)
    w = len(canvas[0])
    raw = bytearray()
    for row in canvas:
        raw.append(0)
        for px in row:
            raw.extend(px[:4])
    def chunk(tag, data):
        return (struct.pack(">I", len(data)) + tag + data +
                struct.pack(">I", zlib.crc32(tag + data) & 0xffffffff))
    sig = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)
    with open(path, "wb") as f:
        f.write(sig)
        f.write(chunk(b"IHDR", ihdr))
        f.write(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        f.write(chunk(b"IEND", b""))


def main():
    master = render(1024)
    os.makedirs(ASSETS, exist_ok=True)
    write_png(os.path.join(ASSETS, "app_icon.png"), master)

    targets = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, size in targets.items():
        d = os.path.join(ANDROID_RES, folder)
        os.makedirs(d, exist_ok=True)
        write_png(os.path.join(d, "ic_launcher.png"), render(size))
        print("wrote", folder, size)


if __name__ == "__main__":
    main()

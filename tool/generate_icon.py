#!/usr/bin/env python3
"""Genera el icono de la app con el mismo dibujo que `AppLogoPainter`.

Campana de Gauss con la franja central del 95 % en ámbar y las colas en
coral, tres puntos muestrales que caen, un intervalo de confianza con su
estimación y la línea discontinua de μ, sobre el degradado índigo de la app.

Salidas (assets/icon/):
  app_icon.png             1024×1024, cuadrado completo (iOS y Android clásico)
  app_icon_foreground.png  primer plano del icono adaptativo de Android
  app_icon_rounded.png     versión redondeada para documentación
Uso:  python3 tool/generate_icon.py   (requiere Pillow)
"""
import math
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "icon")
SS = 4  # sobremuestreo para bordes suaves

INDIGO_SOFT = (0x3D, 0x4C, 0x8F)
INDIGO = (0x22, 0x30, 0x6B)
INDIGO_DEEP = (0x14, 0x1C, 0x45)
AMBER = (0xF2, 0xA5, 0x41)
CORAL = (0xE5, 0x48, 0x4D)
WHITE = (255, 255, 255)
BAND = 1.6  # mitad del ancho de la franja central, en desviaciones (igual que AppLogoPainter)


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def gradient(size):
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * (size - 1))
            c = lerp(INDIGO_SOFT, INDIGO, t / 0.5) if t < 0.5 else lerp(INDIGO, INDIGO_DEEP, (t - 0.5) / 0.5)
            px[x, y] = c
    return img


def draw_logo(d, s, ox=0.0, oy=0.0, scale=1.0):
    """Dibuja el logo en un cuadrado de lado s (coordenadas del painter)."""
    def P(x, y):
        return (ox + x * scale, oy + y * scale)

    left, right = s * 0.12, s * 0.88
    base, peak = s * 0.66, s * 0.30

    def px(z):
        return left + (z + 3) / 6 * (right - left)

    def py(z):
        return base - (base - peak) * math.exp(-0.5 * z * z)

    def zs(a, b, step=0.02):
        n = int(round((b - a) / step))
        return [a + (b - a) * i / n for i in range(n + 1)]

    # Franja central (región de confianza) y colas (región de rechazo)
    band = [P(px(-BAND), base)] + [P(px(z), py(z)) for z in zs(-BAND, BAND)] + [P(px(BAND), base)]
    d.polygon(band, fill=AMBER)
    for side in (-1, 1):
        pts = [P(px(side * BAND), base)] + [P(px(side * t), py(side * t)) for t in zs(BAND, 3.0)] + [P(px(side * 3.0), base)]
        d.polygon(pts, fill=CORAL)
    # Contorno: trazo redondo continuo (círculos densos, sin dientes)
    w = s * 0.035 * scale
    for z in zs(-3, 3, 0.004):
        cx, cy = P(px(z), py(z))
        d.ellipse([cx - w / 2, cy - w / 2, cx + w / 2, cy + w / 2], fill=WHITE)
    # Línea base
    bw = max(1, round(s * 0.022 * scale))
    d.line([P(left, base), P(right, base)], fill=WHITE + (230,), width=bw)
    # Puntos muestrales
    r = s * 0.032 * scale
    for (x, y) in [(px(-0.9), s * 0.17), (px(0.15), s * 0.12), (px(1.05), s * 0.19)]:
        cx, cy = P(x, y)
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=WHITE)
    # Intervalo de confianza
    y = s * 0.80
    cw = max(1, round(s * 0.04 * scale))
    d.line([P(px(-1.5), y), P(px(1.7), y)], fill=AMBER, width=cw)
    for x in (px(-1.5), px(1.7)):
        d.line([P(x, y - s * 0.05), P(x, y + s * 0.05)], fill=AMBER, width=cw)
    rr = s * 0.045 * scale
    cx, cy = P(px(0.1), y)
    d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=WHITE)
    # μ discontinua
    mw = max(1, round(s * 0.014 * scale))
    yy = peak - s * 0.02
    while yy < y + s * 0.07:
        d.line([P(px(0), yy), P(px(0), min(yy + s * 0.028, y + s * 0.07))], fill=WHITE + (191,), width=mw)
        yy += s * 0.05


def main():
    os.makedirs(OUT, exist_ok=True)
    size = 1024
    S = size * SS

    # 1) Icono completo
    bg = gradient(256).resize((S, S), Image.BICUBIC).convert("RGBA")
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    draw_logo(ImageDraw.Draw(layer), S)
    full = Image.alpha_composite(bg, layer).resize((size, size), Image.LANCZOS)
    full.convert("RGB").save(os.path.join(OUT, "app_icon.png"))

    # 2) Primer plano adaptativo: el logo dentro de la zona segura (≈ 62 %)
    fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    k = 0.62
    draw_logo(ImageDraw.Draw(fg), S, ox=S * (1 - k) / 2, oy=S * (1 - k) / 2, scale=k)
    fg.resize((size, size), Image.LANCZOS).save(os.path.join(OUT, "app_icon_foreground.png"))

    # 3) Versión redondeada
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, S - 1, S - 1], radius=int(S * 0.22), fill=255)
    rounded = Image.alpha_composite(bg, layer)
    rounded.putalpha(mask)
    rounded.resize((512, 512), Image.LANCZOS).save(os.path.join(OUT, "app_icon_rounded.png"))
    print("Iconos generados en", OUT)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
from __future__ import annotations

import hashlib
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
RAW_ROOT = ROOT / "screenshots"
OUT_ROOT = ROOT / "screenshots-promo"
ICON_PATH = ROOT / "TankTime/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
INHERITED_ICON_SHA = "59D21284BBD7CB67ED017022D62A742BBB74A01D9DE0EC67F99C2BAAABAA69D7"

COPY = {
    "en-US": {
        "calculate": ("Know what your tank can do", "Weigh it once. Get a clear runtime estimate in seconds."),
        "plan": ("Leave with enough fuel", "Plan the trip, daily loads and reserve without guesswork."),
        "tanks": ("Your cylinders, ready", "Keep real capacity and tare values one tap away."),
        "history": ("Keep the estimates that matter", "A clean history of the runtime checks you saved."),
        "settings": ("Built around your setup", "Metric or imperial, with privacy controls when required."),
    },
    "fr-FR": {
        "calculate": ("Sachez ce que votre bouteille peut fournir", "Une pesée suffit pour estimer clairement l’autonomie."),
        "plan": ("Partez avec assez de gaz", "Planifiez séjour, usages quotidiens et réserve sans approximation."),
        "tanks": ("Vos bouteilles, toujours prêtes", "Gardez capacité et tare réelles accessibles en un geste."),
        "history": ("Gardez les estimations utiles", "Un historique clair des calculs d’autonomie enregistrés."),
        "settings": ("Adapté à votre installation", "Métrique ou impérial, avec les contrôles de confidentialité requis."),
    },
}

ORDER = ["calculate", "plan", "tanks", "history", "settings"]

ACCENT = (247, 145, 55, 255)
TEXT = (250, 249, 247, 255)
SECONDARY = (176, 179, 185, 255)


def font_candidates(bold: bool) -> list[str]:
    if bold:
        return [
            "/System/Library/Fonts/SFNS.ttf",
            "/System/Library/Fonts/SFNSDisplay.ttf",
            "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
            "/Library/Fonts/Arial Bold.ttf",
        ]
    return [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/SFNSDisplay.ttf",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/Library/Fonts/Arial.ttf",
    ]


def load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for candidate in font_candidates(bold):
        if Path(candidate).exists():
            try:
                return ImageFont.truetype(candidate, size=size)
            except OSError:
                pass
    return ImageFont.load_default()


def vertical_gradient(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    w, h = size
    image = Image.new("RGB", size, top)
    px = image.load()
    for y in range(h):
        t = y / max(h - 1, 1)
        r = round(top[0] * (1 - t) + bottom[0] * t)
        g = round(top[1] * (1 - t) + bottom[1] * t)
        b = round(top[2] * (1 - t) + bottom[2] * t)
        for x in range(w):
            px[x, y] = (r, g, b)
    return image


def add_ambient_glow(canvas: Image.Image, width: int, height: int) -> None:
    glow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(glow)
    r = round(width * 0.44)
    cx = round(width * 0.76)
    cy = round(height * 0.08)
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(247, 120, 38, 80))
    glow = glow.filter(ImageFilter.GaussianBlur(max(45, round(width * 0.09))))
    canvas.alpha_composite(glow)


def wrap(draw: ImageDraw.ImageDraw, text: str, font, max_width: int) -> list[str]:
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        proposal = word if not current else f"{current} {word}"
        if draw.textbbox((0, 0), proposal, font=font)[2] <= max_width:
            current = proposal
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def rounded_screen(screen: Image.Image, radius: int) -> Image.Image:
    screen = screen.convert("RGBA")
    mask = Image.new("L", screen.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, screen.width, screen.height), radius=radius, fill=255)
    screen.putalpha(mask)
    return screen


def icon_is_original() -> bool:
    if not ICON_PATH.exists():
        return False
    digest = hashlib.sha256(ICON_PATH.read_bytes()).hexdigest().upper()
    return digest != INHERITED_ICON_SHA


def render_one(locale: str, device: str, screen_name: str, index: int) -> None:
    source = RAW_ROOT / locale / device / f"{screen_name}.png"
    if not source.exists():
        raise FileNotFoundError(source)

    raw = Image.open(source).convert("RGB")
    width, height = raw.size

    # Output stays at the simulator's native pixel dimensions. The app capture may
    # only be downscaled into the promo composition; it is never enlarged.
    canvas = vertical_gradient((width, height), (24, 27, 33), (6, 7, 10)).convert("RGBA")
    add_ambient_glow(canvas, width, height)
    draw = ImageDraw.Draw(canvas)

    side = round(width * 0.068)
    top = round(height * 0.042)
    eyebrow_font = load_font(max(19, round(width * 0.025)), bold=True)
    headline_font = load_font(max(46, round(width * 0.064)), bold=True)
    subtitle_font = load_font(max(24, round(width * 0.031)), bold=False)

    draw.text((side, top), "TANKTIME", font=eyebrow_font, fill=ACCENT)

    if icon_is_original():
        icon_side = round(width * 0.095)
        icon = Image.open(ICON_PATH).convert("RGB").resize((icon_side, icon_side), Image.Resampling.LANCZOS)
        icon = rounded_screen(icon, round(icon_side * 0.22))
        canvas.alpha_composite(icon, (width - side - icon_side, round(top * 0.72)))

    headline, subtitle = COPY[locale][screen_name]
    headline_y = round(height * 0.086)
    max_text_width = width - side * 2
    headline_lines = wrap(draw, headline, headline_font, max_text_width)
    line_gap = round(headline_font.size * 0.08) if hasattr(headline_font, "size") else 8
    y = headline_y
    for line in headline_lines[:2]:
        draw.text((side, y), line, font=headline_font, fill=TEXT)
        bbox = draw.textbbox((side, y), line, font=headline_font)
        y = bbox[3] + line_gap

    y += round(height * 0.008)
    subtitle_lines = wrap(draw, subtitle, subtitle_font, max_text_width)
    for line in subtitle_lines[:2]:
        draw.text((side, y), line, font=subtitle_font, fill=SECONDARY)
        bbox = draw.textbbox((side, y), line, font=subtitle_font)
        y = bbox[3] + round(subtitle_font.size * 0.16 if hasattr(subtitle_font, "size") else 6)

    card_top = max(round(height * 0.235), y + round(height * 0.022))
    card_bottom_margin = round(height * 0.026)
    available_h = height - card_top - card_bottom_margin
    available_w = width - side * 2

    # Never upscale a screenshot. If the simulator image is already smaller than
    # the available promo area it stays at 1:1 pixels.
    scale = min(1.0, available_w / raw.width, available_h / raw.height)
    target_w = max(1, round(raw.width * scale))
    target_h = max(1, round(raw.height * scale))
    resized = raw if (target_w, target_h) == raw.size else raw.resize((target_w, target_h), Image.Resampling.LANCZOS)

    radius = max(28, round(target_w * 0.038))
    screenshot = rounded_screen(resized, radius)
    x = (width - target_w) // 2
    y_card = card_top + max(0, (available_h - target_h) // 2)

    shadow_pad = max(28, round(width * 0.04))
    shadow = Image.new("RGBA", (target_w + shadow_pad * 2, target_h + shadow_pad * 2), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        (shadow_pad, shadow_pad, shadow_pad + target_w, shadow_pad + target_h),
        radius=radius,
        fill=(0, 0, 0, 182),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(max(16, round(width * 0.026))))
    canvas.alpha_composite(shadow, (x - shadow_pad, y_card - shadow_pad + round(height * 0.008)))

    warm_glow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    warm_draw = ImageDraw.Draw(warm_glow)
    warm_draw.rounded_rectangle(
        (x - 8, y_card - 8, x + target_w + 8, y_card + target_h + 8),
        radius=radius + 8,
        outline=(247, 135, 44, 60),
        width=max(8, width // 120),
    )
    warm_glow = warm_glow.filter(ImageFilter.GaussianBlur(max(12, round(width * 0.016))))
    canvas.alpha_composite(warm_glow)

    canvas.alpha_composite(screenshot, (x, y_card))

    border = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
    border_draw = ImageDraw.Draw(border)
    border_draw.rounded_rectangle(
        (1, 1, target_w - 2, target_h - 2),
        radius=radius,
        outline=(255, 255, 255, 46),
        width=max(2, width // 520),
    )
    canvas.alpha_composite(border, (x, y_card))

    out_dir = OUT_ROOT / locale / device
    out_dir.mkdir(parents=True, exist_ok=True)
    output = out_dir / f"{index:02d}-{screen_name}.png"
    canvas.convert("RGB").save(output, "PNG", optimize=True)
    print(f"rendered {output.relative_to(ROOT)} {width}x{height} source={raw.width}x{raw.height} scale={scale:.4f}")


def main() -> None:
    for locale in COPY:
        for device in ("iphone", "ipad"):
            for index, screen_name in enumerate(ORDER, start=1):
                render_one(locale, device, screen_name, index)


if __name__ == "__main__":
    main()

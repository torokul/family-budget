"""
Генератор иконки для приложения Семейный бюджет.
Создаёт PNG в нескольких размерах для Web и Android.
"""
from PIL import Image, ImageDraw, ImageFilter
import os, math

def make_icon(size: int) -> Image.Image:
    s = size
    img = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # ── 1. Градиентный фон (тёмно-фиолетовый → фиолетовый) ──
    c1 = (0x3B, 0x0F, 0x8C)   # #3B0F8C
    c2 = (0x7C, 0x3A, 0xED)   # #7C3AED
    for y in range(s):
        t  = y / (s - 1)
        dx = 0.25              # небольшой диагональный сдвиг
        tx = 0.0
        blend = min(1.0, t + dx * tx)
        r = int(c1[0] + blend * (c2[0] - c1[0]))
        g = int(c1[1] + blend * (c2[1] - c1[1]))
        b = int(c1[2] + blend * (c2[2] - c1[2]))
        draw.line([(0, y), (s - 1, y)], fill=(r, g, b, 255))

    # ── 2. Скруглённые углы ──
    radius = int(s * 0.22)
    mask = Image.new('L', (s, s), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, s - 1, s - 1], radius=radius, fill=255)
    img.putalpha(mask)

    draw = ImageDraw.Draw(img)

    # ── 3. Корпус кошелька (белый прямоугольник) ──
    pad  = s * 0.12
    wl   = pad
    wt   = s * 0.29
    wr   = s - pad
    wb   = s * 0.74
    wcr  = s * 0.055

    # Тень под кошельком
    shadow_offset = s * 0.018
    draw.rounded_rectangle(
        [wl + shadow_offset, wt + shadow_offset, wr + shadow_offset, wb + shadow_offset],
        radius=wcr, fill=(0, 0, 0, 60)
    )

    # Корпус
    draw.rounded_rectangle([wl, wt, wr, wb], radius=wcr, fill=(255, 255, 255, 255))

    # ── 4. Откидная крышка кошелька ──
    flap_h = s * 0.10
    draw.rounded_rectangle(
        [wl, wt - flap_h + wcr, wr, wt + wcr * 1.2],
        radius=wcr,
        fill=(0xE0, 0xD0, 0xFF, 255)   # светло-фиолетовая
    )

    # ── 5. Карман для монет (правая часть) ──
    pocket_cx = s * 0.695
    pocket_cy = (wt + wb) / 2
    pocket_r  = (wb - wt) * 0.38

    # Фон кармана (углубление)
    draw.ellipse(
        [pocket_cx - pocket_r, pocket_cy - pocket_r,
         pocket_cx + pocket_r, pocket_cy + pocket_r],
        fill=(0xEC, 0xE5, 0xFF, 255)   # ещё светлее
    )

    # ── 6. Золотая монета ──
    coin_r = pocket_r * 0.72
    # Градиент монеты (3 слоя: обод → основной → блик)
    for i, (cr_factor, col) in enumerate([
        (1.00, (0xD4, 0x9B, 0x00, 255)),   # обод
        (0.92, (0xFF, 0xD7, 0x00, 255)),   # тело
        (0.60, (0xFF, 0xEC, 0x5C, 255)),   # блик (верх-лево)
    ]):
        cr2 = coin_r * cr_factor
        draw.ellipse(
            [pocket_cx - cr2, pocket_cy - cr2,
             pocket_cx + cr2, pocket_cy + cr2],
            fill=col
        )
    # Блик: маленький светлый эллипс
    bx, by = pocket_cx - coin_r * 0.22, pocket_cy - coin_r * 0.28
    draw.ellipse(
        [bx - coin_r*0.2, by - coin_r*0.12,
         bx + coin_r*0.2, by + coin_r*0.12],
        fill=(255, 255, 200, 160)
    )

    # Символ "сом" (С с двумя линиями) на монете
    lw   = max(2, int(s * 0.013))
    fc   = (0xA0, 0x72, 0x00, 255)
    cr3  = coin_r * 0.38
    cx0, cy0 = pocket_cx, pocket_cy

    # Дуга буквы "С" (рисуем дугой через chord/arc — PIL не поддерживает
    # незамкнутую дугу с толщиной, поэтому рисуем как отрезки дуги)
    steps = 24
    pts = []
    for i in range(steps + 1):
        angle = math.radians(30 + i * (300 / steps))  # 30° → 330° (открытая справа)
        pts.append((cx0 + cr3 * math.cos(angle), cy0 + cr3 * math.sin(angle)))
    for i in range(len(pts) - 1):
        draw.line([pts[i], pts[i+1]], fill=fc, width=lw)

    # Две горизонтальные черты
    for dy_f in (-0.12, 0.12):
        dy2 = coin_r * dy_f
        draw.line(
            [cx0 - cr3 * 0.55, cy0 + dy2, cx0 + cr3 * 0.55, cy0 + dy2],
            fill=fc, width=lw
        )

    # ── 7. Линии карточек в кошельке (левая часть) ──
    line_x1 = wl + s * 0.07
    line_x2 = pocket_cx - pocket_r - s * 0.035
    lc = (0xCC, 0xBB, 0xEE, 200)
    lw2 = max(2, int(s * 0.012))
    for frac in (0.33, 0.55, 0.72):
        ly = wt + (wb - wt) * frac
        draw.line([(line_x1, ly), (line_x2, ly)], fill=lc, width=lw2)

    # Короткий прямоугольник — "карточка" в кошельке
    card_l = line_x1
    card_t = wt + (wb - wt) * 0.20
    card_r = line_x2
    card_b = wt + (wb - wt) * 0.30
    draw.rounded_rectangle(
        [card_l, card_t, card_r, card_b],
        radius=max(2, int(s * 0.015)),
        fill=(0xD8, 0xC8, 0xFF, 200)
    )

    # ── 8. Лёгкое свечение (добавить мягкий ореол) ──
    glow = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    gd   = ImageDraw.Draw(glow)
    gd.rounded_rectangle([wl - s*0.015, wt - s*0.015, wr + s*0.015, wb + s*0.015],
                         radius=wcr + s*0.015, fill=(255, 255, 255, 30))
    glow_blur = glow.filter(ImageFilter.GaussianBlur(radius=s * 0.025))
    img = Image.alpha_composite(img, glow_blur)

    return img


def save_all():
    out_dir = r'D:\workdata\FamilyBudget\assets\icons'
    os.makedirs(out_dir, exist_ok=True)

    # Мастер-иконка 1024
    master = make_icon(1024)
    master.save(os.path.join(out_dir, 'icon_1024.png'))
    print('  icon_1024.png')

    # Web
    for sz in [192, 512]:
        resized = master.resize((sz, sz), Image.LANCZOS)
        resized.save(os.path.join(out_dir, f'icon_{sz}.png'))
        print(f'  icon_{sz}.png')

    # Android mipmap
    android_sizes = {
        'mdpi':    48,
        'hdpi':    72,
        'xhdpi':   96,
        'xxhdpi':  144,
        'xxxhdpi': 192,
    }
    for name, sz in android_sizes.items():
        resized = master.resize((sz, sz), Image.LANCZOS)
        resized.save(os.path.join(out_dir, f'ic_launcher_{name}.png'))
        print(f'  ic_launcher_{name}.png  ({sz}x{sz})')

    print(f'\nВсе иконки сохранены в: {out_dir}')
    return master


if __name__ == '__main__':
    print('Генерирую иконку...')
    img = save_all()
    print('Готово!')

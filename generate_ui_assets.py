"""
Generate premium Recipely UI assets matching the reference screenshots.
Run: python generate_ui_assets.py
"""
import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

BASE = r"d:\New folder\receipe_flutter\assets\images"

def ensure(path):
    os.makedirs(path, exist_ok=True)
    return path

# ─── COLOURS ──────────────────────────────────────────────────────────────────
CREAM      = (250, 243, 232)   # #FAF3E8  warm background
ORANGE     = (244, 123, 32)    # #F47B20  primary CTA orange
DARK_GREEN = (27, 67, 50)      # #1B4332  AI screen accent
SAGE       = (168, 196, 160)   # #A8C4A0  light sage
LIGHT_SAGE = (235, 244, 230)   # #EBF4E6
RED_WARM   = (214, 56, 56)     # #D63838  save/plan screen accent
GOLD       = (255, 200, 60)    # sparkle gold
WHITE      = (255, 255, 255)
BROWN      = (101, 56, 20)     # text dark brown

SIZE = 1024

def circle(draw, cx, cy, r, fill, outline=None, width=2):
    draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=fill, outline=outline, width=width)

def rounded_rect(img, x1, y1, x2, y2, radius, fill):
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle([x1, y1, x2, y2], radius=radius, fill=fill)

# ══════════════════════════════════════════════════════════════════════════════
# 1. SPLASH LOGO  –  fork & spoon on warm peach circle
# ══════════════════════════════════════════════════════════════════════════════
def gen_splash_logo():
    img = Image.new("RGBA", (SIZE, SIZE), (0,0,0,0))
    draw = ImageDraw.Draw(img)

    # Warm peach gradient background circle
    for r in range(SIZE//2, 0, -1):
        t = 1 - r / (SIZE//2)
        c = (
            int(250 - t*12),
            int(230 - t*20),
            int(200 - t*25),
            255
        )
        circle(draw, SIZE//2, SIZE//2, r, c)

    # Floating herb leaves (decorative)
    leaf_positions = [(160,140),(820,180),(120,700),(860,760),(650,100),(200,820)]
    leaf_colors = [(100,160,80),(80,140,60),(120,180,90)]
    for i,(lx,ly) in enumerate(leaf_positions):
        lc = leaf_colors[i % len(leaf_colors)]
        angle = (i * 60) % 360
        # Simple oval leaf
        w, h = 40, 70
        leaf_img = Image.new("RGBA", (w*2, h*2), (0,0,0,0))
        ld = ImageDraw.Draw(leaf_img)
        ld.ellipse([0, h//2, w*2, h + h//2], fill=lc + (200,))
        leaf_img = leaf_img.rotate(angle, expand=True, resample=Image.BICUBIC)
        img.paste(leaf_img, (lx, ly), leaf_img)

    # Fork (left)
    fx, fy = SIZE//2 - 80, SIZE//2 - 160
    # Handle
    draw.rounded_rectangle([fx-14, fy+80, fx+14, fy+280], radius=14, fill=ORANGE)
    # Tines
    for i in range(3):
        tx = fx - 10 + i * 10
        draw.rounded_rectangle([tx-3, fy, tx+3, fy+90], radius=3, fill=ORANGE)
    # Fork base join
    draw.rounded_rectangle([fx-14, fy+60, fx+14, fy+90], radius=6, fill=ORANGE)

    # Spoon (right)
    sx, sy = SIZE//2 + 50, SIZE//2 - 160
    # Bowl of spoon
    draw.ellipse([sx-30, sy, sx+30, sy+55], fill=ORANGE)
    # Handle
    draw.rounded_rectangle([sx-10, sy+40, sx+10, sy+280], radius=10, fill=ORANGE)

    img.save(ensure(f"{BASE}/splash") + "/splash_logo.png")
    print("✓  splash_logo.png")

# ══════════════════════════════════════════════════════════════════════════════
# 2. ONBOARDING 1  –  Chef cooking (discover recipes)
# ══════════════════════════════════════════════════════════════════════════════
def gen_onboarding_discover():
    img = Image.new("RGBA", (SIZE, SIZE), (0,0,0,0))
    draw = ImageDraw.Draw(img)

    # Warm oval arch background
    draw.ellipse([60, 40, SIZE-60, SIZE-120], fill=(248, 236, 212, 240))

    # Body (white chef coat)
    draw.ellipse([SIZE//2-120, 420, SIZE//2+120, SIZE-80], fill=WHITE)
    # Head
    draw.ellipse([SIZE//2-80, 260, SIZE//2+80, 420], fill=(255, 220, 180))
    # Chef hat
    draw.rounded_rectangle([SIZE//2-85, 180, SIZE//2+85, 275], radius=8, fill=WHITE)
    draw.rounded_rectangle([SIZE//2-65, 140, SIZE//2+65, 200], radius=30, fill=WHITE)
    # Hat band
    draw.rectangle([SIZE//2-85, 255, SIZE//2+85, 280], fill=(230,220,210))

    # Arm left (reaching up with pan)
    draw.rounded_rectangle([SIZE//2-180, 390, SIZE//2-110, 440], radius=20, fill=(255,220,180))
    # Pan
    pan_x, pan_y = SIZE//2-220, 300
    draw.ellipse([pan_x, pan_y+20, pan_x+160, pan_y+70], fill=(60,60,60))
    draw.rounded_rectangle([pan_x, pan_y, pan_x+160, pan_y+50], radius=6, fill=(50,50,50))
    draw.rounded_rectangle([pan_x-80, pan_y+18, pan_x, pan_y+34], radius=10, fill=(40,40,40))

    # Flying vegetables
    vegs = [
        (350, 200, (220, 50, 50), 25),   # tomato
        (600, 150, (160, 80, 200), 20),  # onion
        (680, 250, (255, 140, 0), 18),   # pepper
        (300, 320, (60, 160, 60), 22),   # herb
        (680, 180, (255, 60, 60), 16),   # pepper2
    ]
    for vx, vy, vc, vr in vegs:
        circle(draw, vx, vy, vr, vc)
        # Highlight
        circle(draw, vx-vr//3, vy-vr//3, vr//4, (255,255,255,120))

    # Arm right
    draw.rounded_rectangle([SIZE//2+110, 390, SIZE//2+180, 440], radius=20, fill=(255,220,180))

    # Mustache
    draw.arc([SIZE//2-30, 360, SIZE//2+30, 390], start=0, end=180, fill=(80,50,20), width=5)

    img.save(ensure(f"{BASE}/onboarding") + "/onboarding_discover.png")
    print("✓  onboarding_discover.png")

# ══════════════════════════════════════════════════════════════════════════════
# 3. ONBOARDING 2  –  AI Recipe Card (pasta dish)
# ══════════════════════════════════════════════════════════════════════════════
def gen_onboarding_ai():
    img = Image.new("RGBA", (SIZE, SIZE), (0,0,0,0))
    draw = ImageDraw.Draw(img)

    # Soft sage/cream radial background
    for r in range(SIZE//2, 0, -8):
        t = r / (SIZE//2)
        c = (
            int(235 + t*10),
            int(244 + t*8),
            int(230 + t*10),
            255
        )
        circle(draw, SIZE//2, SIZE//2, r, c)

    # Sparkle stars
    sparkles = [(200,180),(780,200),(150,700),(820,680),(500,120),(700,820)]
    for sx, sy in sparkles:
        for angle in [0, 90]:
            r1, r2 = 25, 8
            draw.line([(sx, sy-r1),(sx, sy+r1)], fill=GOLD+(200,), width=4)
            draw.line([(sx-r1, sy),(sx+r1, sy)], fill=GOLD+(200,), width=4)

    # Recipe card background
    card_x, card_y = 120, 160
    card_w, card_h = 780, 650
    draw.rounded_rectangle([card_x, card_y, card_x+card_w, card_y+card_h],
                           radius=32, fill=WHITE)
    # Card shadow
    shadow = img.filter(ImageFilter.GaussianBlur(radius=8))

    # Food image area (top of card)
    draw.rounded_rectangle([card_x+20, card_y+20, card_x+card_w-20, card_y+360],
                           radius=24, fill=(255, 248, 220))
    # Pasta swirls (circles representing pasta)
    pc = (220, 190, 120)
    for i in range(6):
        px = card_x + 100 + i * 100
        py = card_y + 180
        draw.ellipse([px-60, py-40, px+60, py+40], fill=pc, outline=(200,160,80), width=2)
        draw.ellipse([px-40, py-25, px+40, py+25], fill=(240, 210, 150))
    # Herb garnish
    for i in range(8):
        hx = card_x + 150 + i * 70
        hy = card_y + 120 + (i%3)*20
        circle(draw, hx, hy, 12, (80, 160, 80))

    # "AI Pick" badge
    draw.rounded_rectangle([card_x+40, card_y+40, card_x+180, card_y+90],
                           radius=20, fill=DARK_GREEN)
    draw.text((card_x+65, card_y+52), "✦ AI Pick", fill=WHITE)

    # Heart icon top right
    circle(draw, card_x+card_w-60, card_y+60, 28, (255,240,240))
    draw.text((card_x+card_w-72, card_y+48), "♥", fill=RED_WARM)

    # Card text area
    draw.text((card_x+40, card_y+390), "Creamy Lemon Herb Pasta",
              fill=(30, 30, 30))
    draw.text((card_x+40, card_y+460), "25 min  •  Easy  •  Vegetarian",
              fill=(120, 120, 120))

    # Tag pills
    tag_colors = [(245,250,240),(250,240,240),(240,245,250)]
    tag_texts  = ["High Protein", "Quick & Easy", "Favorite"]
    for i,(tc,tt) in enumerate(zip(tag_colors, tag_texts)):
        tx = card_x + 40 + i * 200
        draw.rounded_rectangle([tx, card_y+510, tx+170, card_y+550], radius=16, fill=tc)
        draw.text((tx+15, card_y+520), f"✓ {tt}", fill=(80,80,80))

    img.save(ensure(f"{BASE}/onboarding") + "/onboarding_ai.png")
    print("✓  onboarding_ai.png")

# ══════════════════════════════════════════════════════════════════════════════
# 4. ONBOARDING 3  –  Meal Planner / Save Favorites
# ══════════════════════════════════════════════════════════════════════════════
def gen_onboarding_plan():
    img = Image.new("RGBA", (SIZE, SIZE), (0,0,0,0))
    draw = ImageDraw.Draw(img)

    # Warm pinkish background
    for r in range(SIZE//2, 0, -8):
        t = r / (SIZE//2)
        c = (int(252+t*2), int(240-t*10), int(230-t*20), 255)
        circle(draw, SIZE//2, SIZE//2, r, c)

    # Calendar body
    cal_x, cal_y = 200, 200
    cal_w, cal_h = 580, 520
    draw.rounded_rectangle([cal_x, cal_y, cal_x+cal_w, cal_y+cal_h],
                           radius=20, fill=WHITE)
    # Calendar rings at top
    ring_y = cal_y - 20
    for i in range(7):
        rx = cal_x + 80 + i * 70
        draw.ellipse([rx-12, ring_y-20, rx+12, ring_y+20], outline=(200,200,200), width=3)
        draw.ellipse([rx-6, ring_y-4, rx+6, ring_y+4], fill=(180,180,180))

    # Day headers
    days = ["MON","TUE","WED","THU","FRI","SAT","SUN"]
    for i, day in enumerate(days):
        dx = cal_x + 40 + i*80
        draw.text((dx, cal_y+20), day, fill=(120,120,120))

    # Food circles for meal slots
    meal_colors = [
        (240,180,100),(200,220,160),(255,160,100),
        (160,200,240),(220,160,180),(200,240,200)
    ]
    for row in range(2):
        for col in range(4):
            mx = cal_x + 70 + col * 130
            my = cal_y + 120 + row * 160
            c = meal_colors[(row*4+col) % len(meal_colors)]
            circle(draw, mx, my, 45, c)
            # Inner food highlight
            circle(draw, mx-10, my-10, 15, (255,255,255,100))

    # Red bookmark/heart tag (left of calendar)
    bm_x, bm_y = 80, 380
    bm_w, bm_h = 100, 140
    draw.rectangle([bm_x, bm_y, bm_x+bm_w, bm_y+bm_h], fill=RED_WARM)
    # Pointed bottom
    draw.polygon([(bm_x, bm_y+bm_h),(bm_x+bm_w//2, bm_y+bm_h+40),(bm_x+bm_w, bm_y+bm_h)],
                 fill=RED_WARM)
    # Heart on bookmark
    heart_x, heart_y = bm_x + bm_w//2, bm_y + bm_h//2
    draw.text((heart_x-16, heart_y-20), "♥", fill=WHITE)

    # Leaf plant (left)
    for i in range(4):
        lx = 120 + i * 12
        ly = 280 - i * 40
        draw.ellipse([lx-20, ly-35, lx+20, ly+5], fill=(80, 160, 80))
    draw.rounded_rectangle([128, 300, 136, 400], radius=4, fill=(60,120,60))

    # Tomato (right)
    circle(draw, 830, 680, 70, (220, 60, 60))
    circle(draw, 820, 668, 20, (200, 40, 40))  # shadow
    draw.rounded_rectangle([824, 610, 836, 648], radius=5, fill=(60,140,60))  # stem

    # Basil leaf (bottom right)
    draw.ellipse([860, 700, 920, 760], fill=(80,160,80))
    draw.ellipse([830, 720, 880, 780], fill=(60,140,60))

    img.save(ensure(f"{BASE}/onboarding") + "/onboarding_plan.png")
    print("✓  onboarding_plan.png")

# ══════════════════════════════════════════════════════════════════════════════
# 5. SIGN IN  –  Ramen bowl top image
# ══════════════════════════════════════════════════════════════════════════════
def gen_login_food():
    img = Image.new("RGBA", (SIZE, SIZE), (0,0,0,0))
    draw = ImageDraw.Draw(img)

    # Warm cream background for the image area
    draw.ellipse([60, 60, SIZE-60, SIZE-60], fill=(252, 244, 228, 255))

    # Bowl shadow
    draw.ellipse([200, 580, SIZE-200, SIZE-80], fill=(200, 180, 150, 80))

    # Bowl body (ceramic brown)
    draw.ellipse([160, 380, SIZE-160, SIZE-120], fill=(180, 120, 60))
    # Bowl interior (soup)
    draw.ellipse([200, 400, SIZE-200, SIZE-160], fill=(200, 140, 60))
    # Broth surface
    draw.ellipse([220, 420, SIZE-220, SIZE-200], fill=(240, 180, 80))

    # Ramen noodles (wavy lines)
    for i in range(8):
        y = 480 + i * 25
        pts = []
        for x in range(220, SIZE-220, 15):
            wave = math.sin((x+i*20) * 0.1) * 10
            pts.append((x, y + wave))
        if len(pts) > 1:
            draw.line(pts, fill=(255,220,140), width=4)

    # Egg halves
    draw.ellipse([280, 440, 380, 540], fill=(255,240,200))   # egg white 1
    draw.ellipse([295, 455, 365, 525], fill=(255,200,60))    # yolk 1
    draw.ellipse([640, 440, 740, 540], fill=(255,240,200))   # egg white 2
    draw.ellipse([655, 455, 725, 525], fill=(255,200,60))    # yolk 2

    # Green onion garnish
    for i in range(6):
        gx = 350 + i * 50
        draw.rounded_rectangle([gx-4, 450, gx+4, 520], radius=4, fill=(80,180,80))
        circle(draw, gx, 450, 8, (100,200,100))

    # Nori seaweed strip
    draw.rectangle([460, 440, 520, 580], fill=(20, 60, 40))
    for i in range(5):
        draw.line([(465, 450+i*25),(515, 450+i*25)], fill=(30,80,50), width=2)

    # Side garnish – small bowl with chili sauce
    draw.ellipse([720, 280, 840, 360], fill=(180, 100, 40))
    draw.ellipse([730, 285, 830, 355], fill=(220, 60, 40))  # red chili

    # Green leaves (herbs) floating
    for i in range(4):
        lx = 180 + i * 180
        ly = 300 + (i%2) * 40
        draw.ellipse([lx-18, ly-30, lx+18, ly+10], fill=(80, 160, 80, 200))

    img.save(ensure(f"{BASE}/auth") + "/login_food.png")
    print("✓  login_food.png")

# ══════════════════════════════════════════════════════════════════════════════
# 6. HERO BANNER  –  Mediterranean bowl
# ══════════════════════════════════════════════════════════════════════════════
def gen_hero_banner():
    img = Image.new("RGBA", (1280, 640), (0,0,0,0))
    draw = ImageDraw.Draw(img)

    # Warm gradient background
    for y in range(640):
        t = y / 640
        c = (int(250-t*30), int(240-t*40), int(220-t*30), 255)
        draw.line([(0,y),(1280,y)], fill=c)

    # Large food bowl
    cx, cy = 960, 320
    draw.ellipse([cx-220, cy-80, cx+220, cy+120], fill=(180,120,50))  # bowl
    draw.ellipse([cx-190, cy-60, cx+190, cy+100], fill=(240, 200, 100))  # broth

    # Food items in bowl
    colors = [(220,80,80),(80,180,80),(240,200,80),(180,120,200)]
    for i, fc in enumerate(colors):
        fx = cx - 120 + i * 60
        fy = cy + (i%2) * 20
        circle(draw, fx, fy, 40, fc)

    # Text side
    draw.text((80, 180), "Cook Like a", fill=(40,30,20))
    draw.text((80, 250), "Chef Today", fill=ORANGE)
    draw.text((80, 340), "Discover thousands of premium", fill=(100,80,60))
    draw.text((80, 380), "recipes from top chefs.", fill=(100,80,60))

    img.save(ensure(f"{BASE}/home") + "/hero_banner.png")
    print("✓  hero_banner.png")

if __name__ == "__main__":
    print("Generating Recipely premium UI assets...")
    gen_splash_logo()
    gen_onboarding_discover()
    gen_onboarding_ai()
    gen_onboarding_plan()
    gen_login_food()
    gen_hero_banner()
    print("\n✅  All assets generated!")

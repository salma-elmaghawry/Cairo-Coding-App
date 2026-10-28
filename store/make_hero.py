#!/usr/bin/env python3
"""Store screenshots 01 + 02: one 2160x1920 scene on the dark brand background, cut in two.

Run from the project root:
  python3 store/make_hero.py            # en + ar
  python3 store/make_hero.py en

Replaces the generic hero from make_store_graphics.py (don't run that with --only hero).
Floating cards are cropped from the real captures in store/screenshots/raw/<lang>/,
so re-run this after re-capturing those screens.

Arabic is mirrored and 01 is the RIGHT half, because Play lays the carousel out
right-to-left for Arabic.
"""
import json, math, pathlib, sys

from PIL import Image

sys.path.insert(0, str(pathlib.Path.home() / ".claude/skills/make-app-ready-to-store/scripts"))
from make_store_graphics import data_uri, render  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent
STORE = ROOT / "store"
FONTS = ROOT / "assets" / "fonts"
W, H, HALF = 2160, 1920, 1080

# Card bounds in the 1344x2992 raw captures: (x, y, w, h, corner radius).
CARDS = {
    "en": {"next": (60, 448, 1224, 1035, 60), "recording": (60, 2404, 1224, 222, 60),
           "moved": (60, 1390, 1224, 222, 48), "cancelled": (60, 1642, 1224, 222, 48)},
    "ar": {"next": (60, 448, 1224, 1041, 60), "recording": (60, 2410, 1224, 222, 60),
           "moved": (60, 1390, 1224, 222, 48), "cancelled": (60, 1642, 1224, 222, 48)},
}

TEXT = {
    "en": {
        "headline_a": "Never miss<br><em>a session.</em>",
        "sub_a": "Your whole course, in one app.",
        "headline_b": "Schedule. Join.<br><em>Rewatch.</em>",
        "sub_b": "Your schedule, meeting link and recordings in one place.",
        "notif_app": "Cairo Coding · now",
        "notif_title": "Session 8 starts at 7:00 PM",
        "notif_body": "CS140 · Open the app to join the meeting.",
    },
    "ar": {
        "headline_a": "متفوّتش<br><em>ولا سيشن.</em>",
        "sub_a": "كورسك كله في تطبيق واحد.",
        "headline_b": "جدول. سيشن.<br><em>تسجيل.</em>",
        "sub_b": "الجدول ورابط الاجتماع والتسجيلات في مكان واحد.",
        "notif_app": "Cairo Coding · الآن",
        "notif_title": "السيشن 8 تبدأ الساعة 7:00 م",
        "notif_body": "افتح التطبيق وانضم للاجتماع · CS140",
    },
}

FACES = [("Nunito", "Nunito-Medium", 500), ("Nunito", "Nunito-SemiBold", 600), ("Nunito", "Nunito-Bold", 700),
         ("Nunito", "Nunito-ExtraBold", 800), ("Cairo", "Cairo-Regular", 400), ("Cairo", "Cairo-SemiBold", 600),
         ("Cairo", "Cairo-Bold", 700), ("Cairo", "Cairo-ExtraBold", 800),
         ("JetBrains Mono", "JetBrainsMono-Medium", 500), ("JetBrains Mono", "JetBrainsMono-Bold", 700)]


def font_faces():
    return "".join(f"@font-face{{font-family:'{fam}';src:url('{(FONTS / f'{file}.ttf').as_uri()}');font-weight:{wt}}}"
                   for fam, file, wt in FACES)


def pattern():
    """Faint code doodles tiled over the background."""
    glyphs = [("{ }", 30, 50, -12), ("&lt;/&gt;", 170, 40, 8), (";", 260, 150, 0), ("( )", 60, 190, 10),
              ("//", 190, 250, -8), ("=&gt;", 110, 120, -4), ("[ ]", 250, 330, 12), ("#", 20, 320, 0)]
    text = "".join(f'<text x="{x}" y="{y}" transform="rotate({r} {x} {y})">{g}</text>' for g, x, y, r in glyphs)
    shapes = ('<path d="M120 300 l22 13 -22 13z"/><circle cx="300" cy="60" r="9"/>'
              '<rect x="300" y="210" width="22" height="22" rx="6"/><path d="M20 110 h20 M30 100 v20"/>')
    return f"""<svg class="pattern" width="{W}" height="{H}"><defs><pattern id="p" width="340" height="360"
patternUnits="userSpaceOnUse" patternTransform="rotate(-14)"><g font-family="JetBrains Mono" font-weight="700"
font-size="34" fill="#C084FC">{text}</g><g fill="none" stroke="#C084FC" stroke-width="3"
stroke-linejoin="round" stroke-linecap="round">{shapes}</g></pattern></defs>
<rect width="{W}" height="{H}" fill="url(#p)"/></svg>"""


def sparkle(x, y, size, color):
    return (f'<svg class="abs" style="{{s}}:{x}px;top:{y}px" width="{size}" height="{size}" viewBox="0 0 24 24">'
            f'<path d="M12 0C13 8 16 11 24 12 16 13 13 16 12 24 11 16 8 13 0 12 8 11 11 8 12 0Z" fill="{color}"/></svg>')


class Hero:
    def __init__(self, lang):
        cfg = json.loads((STORE / "store-config.json").read_text(encoding="utf-8"))
        self.lang, self.L, self.t = lang, cfg["languages"][lang], TEXT[lang]
        self.rtl = self.L["rtl"]
        self.side = "right" if self.rtl else "left"  # every x below is measured from this edge
        self.m = -1 if self.rtl else 1  # flips rotations for the mirrored layout
        self.icon = data_uri(STORE / "graphics" / "play-icon-512.png")
        self.raw = {n: STORE / "screenshots" / "raw" / lang / f"{n}.png" for n in ("01", "02")}

    def card(self, raw, name, x, y, scale, rot, z=5):
        cx, cy, cw, ch, r = CARDS[self.lang][name]
        rw = Image.open(self.raw[raw]).width
        s = scale
        return (f'<div class="card" style="{self.side}:{x}px;top:{y}px;width:{cw * s:.0f}px;height:{ch * s:.0f}px;'
                f'border-radius:{r * s:.0f}px;z-index:{z};transform:rotate({rot * self.m}deg);'
                f'background-image:url({self.raw[raw].as_uri()});background-size:{rw * s:.1f}px auto;'
                f'background-position:{-cx * s:.1f}px {-cy * s:.1f}px"></div>')

    def phone(self, raw, x, y, w, ry, rz):
        return (f'<div class="phone" style="{self.side}:{x}px;top:{y}px;width:{w}px;height:{w * 2.17:.0f}px;'
                f'transform:perspective(3200px) rotateY({ry * self.m}deg) rotateZ({rz * self.m}deg)">'
                f'<i class="btn"></i><div class="screen"><img src="{self.raw[raw].as_uri()}"><b class="cam"></b>'
                f'<span class="gloss"></span></div></div>')

    def html(self):
        t, d, side, rtl = self.t, ("rtl" if self.rtl else "ltr"), self.side, self.rtl
        font = self.L["font"]
        ring_r, ring_c = 420, (HALF, 1180)
        dot_a = math.radians(-105)
        dot = (ring_c[0] + ring_r * math.cos(dot_a) - 17, ring_c[1] + ring_r * math.sin(dot_a) - 17)
        sparkles = "".join(sparkle(*a).replace("{s}", side) for a in [
            (930, 150, 46, "#C084FC"), (1010, 470, 22, "#F2ECFA"), (1975, 1640, 40, "#C084FC"),
            (1160, 1450, 26, "#F2ECFA"), (60, 700, 30, "#C084FC")])
        css = f"""{font_faces()}
*{{margin:0;padding:0;box-sizing:border-box}} html{{overflow:hidden}}
body{{width:{W}px;height:{H}px;overflow:hidden;position:relative;font-family:'{font}','Nunito',sans-serif;
  background:radial-gradient(1200px 900px at 50% 45%,#2c1a40 0%,transparent 70%),linear-gradient(160deg,#241533 0%,#1b0f26 55%,#120a1a 100%)}}
.abs,.pattern,.blob,.ring,.dot,.glow,.phone,.card,.notif,.copy{{position:absolute}}
.pattern{{left:0;top:0;opacity:.07}}
.blob{{border-radius:50%;background:radial-gradient(circle at 35% 30%,#B57BFF 0%,#7C3AED 38%,#5B21B6 75%,#3B1478 100%);
  box-shadow:inset 0 0 120px rgba(18,10,26,.35)}}
.ring{{border-radius:50%;border:3px dashed rgba(192,132,252,.38)}}
.dot{{width:34px;height:34px;border-radius:50%;background:#FACC15;box-shadow:0 0 30px rgba(250,204,21,.55)}}
.glow{{border-radius:50%;background:radial-gradient(circle,rgba(192,132,252,.45) 0%,transparent 65%)}}
.phone{{background:linear-gradient(140deg,#3a3145 0%,#0d0b10 18%,#0d0b10 82%,#2d2636 100%);border-radius:96px;padding:18px;
  box-shadow:0 0 0 3px #4a3f57,0 80px 140px rgba(5,2,10,.65),0 30px 60px rgba(5,2,10,.45);z-index:3}}
.phone .btn{{position:absolute;top:22%;width:8px;height:180px;border-radius:4px;background:#2d2636;{'left' if rtl else 'right'}:-9px}}
.screen{{position:relative;width:100%;height:100%;border-radius:80px;overflow:hidden;background:#FAF7FE}}
.screen img{{width:100%;height:100%;object-fit:cover;object-position:top}}
.cam{{position:absolute;top:22px;left:50%;width:26px;height:26px;margin-left:-13px;border-radius:50%;background:#0d0b10}}
.gloss{{position:absolute;inset:0;background:linear-gradient(115deg,rgba(255,255,255,.18) 0%,rgba(255,255,255,0) 32%)}}
.card{{background-repeat:no-repeat;box-shadow:0 50px 90px rgba(5,2,10,.55),0 14px 30px rgba(5,2,10,.35)}}
.notif{{z-index:6;width:720px;padding:30px 34px;border-radius:44px;background:rgba(250,247,254,.97);color:#1B0F26;
  box-shadow:0 50px 90px rgba(5,2,10,.55),0 14px 30px rgba(5,2,10,.35)}}
.notif .app{{display:flex;align-items:center;gap:16px;font:600 26px 'Nunito',sans-serif;color:#5B4A6E}}
.notif .app img{{width:46px;height:46px;border-radius:12px}}
.notif h4{{margin-top:16px;font-size:35px;font-weight:800;line-height:1.3}}
.notif p{{margin-top:6px;font-size:28px;font-weight:600;color:#5B4A6E;line-height:1.4}}
.copy{{width:900px;color:#F2ECFA;z-index:7;text-align:{'right' if rtl else 'left'}}}
.brand{{display:flex;align-items:center;gap:26px;font-size:{50 if rtl else 52}px;font-weight:800}}
.brand img{{width:112px;height:112px;border-radius:28px;box-shadow:0 20px 40px rgba(5,2,10,.5),0 0 0 2px rgba(192,132,252,.3)}}
h1{{font-size:{112 if rtl else 116}px;line-height:{1.25 if rtl else 1.0};font-weight:800;letter-spacing:{0 if rtl else -3}px}}
h1 em{{font-style:normal;color:#C084FC}}
.sub{{margin-top:{26 if rtl else 34}px;font-size:42px;line-height:1.4;font-weight:600;color:#C9BEDD}}"""

        a_copy = (f'<div class="copy" dir="{d}" style="{side}:110px;top:110px">'
                  f'<div class="brand"><img src="{self.icon}">{self.L["brand"]}</div>'
                  f'<h1 style="margin-top:70px">{t["headline_a"]}</h1><div class="sub">{t["sub_a"]}</div></div>')
        b_copy = (f'<div class="copy" dir="{d}" style="{side}:{HALF + 110}px;top:{1490 if rtl else 1500}px;width:880px">'
                  f'<h1>{t["headline_b"]}</h1><div class="sub">{t["sub_b"]}</div></div>')
        notif = (f'<div class="notif" dir="{d}" style="{side}:{HALF + 70}px;top:330px;transform:rotate({-2 * self.m}deg)">'
                 f'<div class="app"><img src="{self.icon}">{t["notif_app"]}</div>'
                 f'<h4>{t["notif_title"]}</h4><p>{t["notif_body"]}</p></div>')
        body = f"""
{pattern()}
<div class="blob" style="{side}:-430px;top:1020px;width:1300px;height:1300px"></div>
<div class="blob" style="{side}:490px;top:640px;width:560px;height:560px"></div>
<div class="blob" style="{side}:1400px;top:-120px;width:1020px;height:1020px"></div>
<div class="ring" style="{side}:{ring_c[0] - ring_r}px;top:{ring_c[1] - ring_r}px;width:{ring_r * 2}px;height:{ring_r * 2}px"></div>
<div class="dot" style="{side}:{dot[0]:.0f}px;top:{dot[1]:.0f}px"></div>
<div class="glow" style="{side}:-60px;top:760px;width:1000px;height:1000px"></div>
<div class="glow" style="{side}:1340px;top:120px;width:1000px;height:1000px"></div>
{sparkles}
{a_copy}
{self.phone("01", 120, 760, 600, 14, -5)}
{self.card("01", "next", 380, 990, 0.555, 3)}
{self.card("01", "recording", 300, 1640, 0.52, -2)}
{self.phone("02", HALF + 380, 120, 600, -14, 5)}
{notif}
{self.card("02", "moved", HALF + 80, 860, 0.53, -3)}
{self.card("02", "cancelled", HALF + 150, 1030, 0.53, 2)}
{b_copy}"""
        return (f'<!doctype html><html dir="ltr"><head><meta charset="utf-8"><style>{css}</style></head>'
                f'<body>{body}</body></html>')

    def build(self):
        out = STORE / "screenshots" / self.lang
        wide = out / "hero-wide.png"
        render(self.html(), wide, W, H)
        im = Image.open(wide)
        left, right = im.crop((0, 0, HALF, H)), im.crop((HALF, 0, W, H))
        first, second = (right, left) if self.rtl else (left, right)
        first.save(out / "01.png")
        second.save(out / "02.png")
        print("wrote", out / "01.png", "and", out / "02.png")


if __name__ == "__main__":
    for lang in sys.argv[1:] or ["en", "ar"]:
        Hero(lang).build()

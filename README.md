# Tracing Fun 🖍️

A bright, touch-friendly **alphabet & number tracing game for kids (ages 3–6)**,
built with **Godot 4** and GDScript. Children trace letters **A–Z** and numbers
**0–9** by following the stroke path with a finger, get instant green/red
feedback, and are rewarded with a star burst and confetti when they finish.

Designed for **Android**, portrait, **1080 × 1920**.

---

## ✨ Features

| Requirement | How it's done |
|---|---|
| Trace A–Z and 0–9 with touch | `TraceCanvas` follow-the-road tracker driven by screen-touch input |
| Follow the correct stroke path | Per-glyph ordered stroke data (`scripts/Glyphs.gd`), one stroke at a time, with a start dot + direction arrow |
| Visual feedback | **Green glow** while on the path, **red shake** when the finger strays (no progress is lost — it's forgiving for little hands) |
| Audio on completion | Plays a success chime when a glyph is finished; a click on every button & stroke |
| Letter & number displays | Flashcards drawn in code from the same stroke data (`GlyphCard`) — no external image assets |
| Fonts for all UI text | Comic Neue (Bold for titles, Regular for body) |
| Reward animation | One-shot **star burst** on success + falling **confetti** on the result screen |
| Main menu with two modes | **Letters** and **Numbers** |
| Per-session progress | Counts completed glyphs and shows a ⭐ badge on each finished card |
| Child-safe UI | Big buttons, bright colors, and the Android **Back** button never quits the app (it navigates within the game) |
| Export-ready for Android | Portrait, 1080×1920, touch input, `export_presets.cfg` included |

---

## ▶️ Running it

1. Install **Godot 4.3** (or newer 4.x) — the standard build, no C# needed.
2. Open `project.godot` in the Godot editor. On first open it imports all the
   art, fonts and audio (a few seconds).
3. Press **F5** (Play). The mouse emulates touch, so you can trace with the
   mouse on desktop.

## 📱 Exporting for Android

1. In Godot: **Editor → Manage Export Templates → Download** the templates for
   your version.
2. **Project → Export…** — the **Android** preset is already defined in
   `export_presets.cfg`. Set up an Android debug/release keystore as prompted.
3. Export the APK. Orientation is locked to portrait via the project settings.

---

## 🗂️ Project structure

```
tracing/
├── project.godot           # autoloads, portrait 1080x1920, touch, child-safe back
├── icon.svg                # app icon
├── export_presets.cfg      # Android export preset
├── scenes/                 # MainMenu, LetterSelect, TracingGame, ResultScreen
├── scripts/
│   ├── Game.gd             # autoload: state, palette, fonts, audio, UI + particle helpers
│   ├── Glyphs.gd           # autoload: AUTO-GENERATED stroke-path data
│   ├── TraceCanvas.gd      # the core tracing mechanic (drawing + touch + feedback)
│   ├── GlyphCard.gd        # a letter/number flashcard drawn from stroke data
│   ├── Icon.gd             # vector UI icons drawn in code (home/prev/next/redo)
│   ├── MainMenu.gd
│   ├── LetterSelect.gd
│   ├── TracingGame.gd
│   └── ResultScreen.gd
├── tools/
│   ├── glyphs.py           # authoring tool that generates scripts/Glyphs.gd
│   └── make_sounds.py      # synthesizes the click/success sounds
└── assets/
    ├── fonts/              # Comic Neue (OFL) + license
    └── audio/              # click.wav, success.wav (synthesized)
```

### Scene flow

`MainMenu` → pick a mode → `LetterSelect` (grid of cards) → tap a card →
`TracingGame` (trace it) → on success → `ResultScreen` (reward) → *Again /
Next / Menu*.

---

## ✍️ How the tracing paths work

Every glyph is a list of **strokes**, and each stroke is an ordered list of
waypoints in normalized `[0,1] × [0,1]` space. The game draws the letter *from*
this path (as a white "road"), so the shape the child sees and the path they
must follow are guaranteed to be perfectly aligned.

The data lives in `scripts/Glyphs.gd`, which is **generated** from
`tools/glyphs.py` — the single source of truth. The tool can also render each
glyph as ASCII art so the stroke order and direction can be eyeballed:

```bash
python3 tools/glyphs.py          # render all glyphs as ASCII
python3 tools/glyphs.py ABC3     # render only A, B, C, 3
python3 tools/glyphs.py --emit   # regenerate scripts/Glyphs.gd
```

---

## 🎨 Assets & licensing

This project ships **original / freely-licensed assets only** — there are no
borrowed game-art images:

- **Letters, numbers, UI icons and the tracing track** are all drawn in code
  from the stroke-path data (`GlyphCard`, `Icon`, `TraceCanvas`).
- **Font:** [Comic Neue](https://github.com/crozynski/comicneue) by Craig Rozynski,
  under the **SIL Open Font License 1.1** (see `assets/fonts/OFL.txt`).
- **Sound:** `click.wav` and `success.wav` are **synthesized** by
  `tools/make_sounds.py`, so they are original and license-free.
- **Colors / layout / code:** all original.

This makes the game safe to publish or submit as your own work (keep the font's
OFL license file with it, as the license requires).

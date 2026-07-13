-- constants.lua

-- App layout. Size is read from the real window at
-- game start (sync_screen); declared empty here.

APP = { }

-- Upper bound on random-placement attempts (far_point,
-- barrier_place): after this many misses they fall back
-- to the farthest valid spot, so a frame never spins.
-- Kept generous so the fallback rarely shows in play.

SAMPLE_TRIES = 64

-- Menu chrome

COLOR_BG = {
  0.95,
  0.95,
  0.92
}
COLOR_FG = {
  0.15,
  0.15,
  0.15
}
COLOR_DIM = {
  0.55,
  0.55,
  0.55
}

MENU = {
  x = 240,
  y = 170,
  title_y = 110,
  line_h = 44
}

-- Large sans-serif UI font for child-facing text; FONT_BIG
-- is the celebration / help-peek heading size.

FONT_SIZE = 28
FONT_BIG = 56

-- Calm overlay shown when focus or input is lost

RECONNECT = {
  text = "Paused - move the mouse to continue",
  x = 200,
  y = 220,
  dim = 0.7
}

-- Compy LEGO palette (per-button) from COMPY_colors.
-- Each color is its own sub-global so no single chunk
-- runs long once the autoformatter expands the triples.

LEGO_LEFT = {
  0,
  0.129,
  0.863
}
LEGO_RIGHT = {
  0.059,
  0.914,
  0.627
}
LEGO_WHEEL = {
  0.918,
  0.337,
  0.439
}
LEGO_CHEESE = {
  1,
  0.804,
  0
}

LEGO = {
  left = LEGO_LEFT,
  right = LEGO_RIGHT,
  wheel = LEGO_WHEEL,
  cheese = LEGO_CHEESE
}

-- Base logo mark: monochrome gray on the body. Turns
-- colorful (the winking brand mark) on cheese delight.

LOGO_COLOR = {
  0.45,
  0.45,
  0.45
}

-- Offset to place the 200x250 wink phases onto the
-- body-logo origin (MOUSE04_7). Same size, shift only.

WINK_OFF = {
  x = 25,
  y = 163
}

-- LEGO blink cycle for the cheese delight effect.
-- Built from LEGO so the colors live in one place.

LEGO_BLINK = {
  LEGO.left,
  LEGO.right,
  LEGO.wheel,
  LEGO.cheese
}

-- Meet playfield: quiet light-colored field.

MOUSE_BG = {
  0.94,
  0.98,
  0.96
}

-- size: fraction of screen; tilt: max body lean (rad).
-- smooth: follow lerp factor per frame.

MOUSE_TUNE = {
  size_w = 0.2,
  size_h = 0.31,
  tilt_max = 8 * math.pi / 180,
  tilt_rate = 8,
  smooth = 1,
  jitter = 1.5,
  speed_decay = 0.5,
  press_shift = 4
}

-- Wall/barrier bump response. right_flash: how long the
-- right zone lights after a raw-Esc right-click, which
-- has no matching release event.

BUMP = {
  time = 0.12,
  recoil = 6,
  right_flash = 0.3
}

-- Button press glow: rate eases mm.glow toward the
-- pressed state; add is the additive glow strength;
-- eps is the alpha below which the zone is skipped.

GLOW = {
  rate = 12,
  add = 0.5,
  eps = 0.02
}

-- Soft shadow under the mouse. rx/ry are fractions of
-- the sprite half-width; dy drops it toward the base
-- as a fraction of the sprite half-height.

SHADOW = {
  c = {
    0,
    0,
    0
  },
  alpha = 0.04,
  rx = 0.95,
  ry = 0.28,
  dy = 0.8
}

-- Footstep cadence: pixels of travel per step; hit_gap
-- is the min seconds between wall-hit knocks.

MOVE_SND = {
  step_dist = 64,
  hit_gap = 0.4
}

-- Wheel scroll motion (pellets wrap in the window)

WHEEL = {
  pellets = 3,
  scroll_rate = 40,
  decay = 3,
  eps = 2
}

-- Wheel window and pellet geometry (sprite space)

WHEEL_WIN = {
  pel_x = 114.36,
  pel_w = 21.275,
  pel_h = 5.331,
  pel_r = 2.5,
  band_top = 63.15,
  band_h = 62.7,
  pel_c = {
    0.2,
    0.2,
    0.2
  }
}

-- Scroll direction arrow above/below the window

WHEEL_ARR = {
  arr_up = 56,
  arr_dn = 132,
  arr_h = 30,
  arr_w = 26,
  arr_c = {
    0.059,
    0.914,
    0.627
  }
}

-- Cheese: size, pause, respawn distance rule. relax
-- shrinks the min distance on each frame no legal spot
-- is found, so placement always resolves (never blocks).

CHEESE = {
  size = 48,
  pause = 0.5,
  min_diag_frac = 1 / 3,
  relax = 0.9,
  margin_frac = 0.02,
  tries_per_frame = 8,
  twice = true,
  echo_gap = 0.12
}

-- Cheese delight effect timings.
-- wink_p1/p2: progress thresholds between the three
-- wink phases (neutral, half, closed).

DELIGHT = {
  blink_rate = 12,
  wink_time = 0.3,
  wink_p1 = 1 / 3,
  wink_p2 = 2 / 3
}

-- Barrier shape and placement, re-sampled on every
-- appearance. Axis-aligned rounded box fitted to the
-- inner play rectangle (screen minus clearance mouse
-- widths on each side). min_px: smallest side;
-- area_min_frac / area_frac: min and max area as a
-- fraction of the inner rectangle; clearance: side
-- margin in mouse widths (>1 leaves room to pass
-- smoothly); corner: corner radius; fade: fade time.

BARRIER_COLOR = {
  0.5,
  0.5,
  0.52
}

BARRIER = {
  first_cheese = 5,
  swap_every = 3,
  min_px = 50,
  area_min_frac = 0.12,
  area_frac = 0.5,
  clearance = 1.25,
  corner = 12,
  fade = 0.15,
  color = BARRIER_COLOR
}

-- Difficulty-notch bounds shared by skill-based mini-games
-- (find, pop). Meet opts out. The level ranges over min..max;
-- the gauge (win.lua) climbs it on a fill and eases it on a
-- miss streak, and the teacher chord moves it too. The level
-- is the only state that survives a mini-game exit and
-- reenter; it zeroes at program start.

NOTCH = {
  min = -2,
  max = 2
}

-- "Plug in the mouse" screen, shown program-wide when no
-- external mouse is present. The picture carries the
-- message for non-reading children; the caption is a
-- teacher aide. icon_h: mouse height as a screen
-- fraction; plug_gap: sprite-space gap to the plug;
-- text_dy: caption offset below center.

NO_MOUSE = {
  text = "Plug in the mouse.",
  icon_h = 0.3,
  plug_gap = 40,
  text_dy = 170
}

-- Unconnected USB-A plug glyph for the no-mouse screen,
-- drawn in sprite-space units and scaled by the caller.

PLUG_SHELL = {
  0.58,
  0.58,
  0.62
}
PLUG_METAL = {
  0.82,
  0.82,
  0.86
}
PLUG_CABLE = {
  0.2,
  0.2,
  0.2
}

PLUG = {
  w = 70,
  h = 46,
  inner = 9,
  tongue_w = 0.66,
  cable = 60,
  line_w = 7,
  corner = 4,
  shell = PLUG_SHELL,
  metal = PLUG_METAL,
  cable_c = PLUG_CABLE
}

-- Mini-game 2: Find the glowing circle. Dark field so
-- the target stands out.

FIND_BG = {
  0.12,
  0.12,
  0.14
}

-- Cool (idle) and warm (entered) target colors

FIND_COOL = {
  0.42,
  0.46,
  0.95
}
FIND_WARM = {
  1,
  0.7,
  0.16
}

-- Timings (s) and geometry. struggle_t is the ease-down
-- window (a long spawn without an entry); warm_t the
-- cool->warm transition; fade_t the swap cross-fade; pulse
-- the glow period; edge_frac the no-edge-spawn inset (of
-- screen width).

FIND = {
  min_px = 60,
  struggle_t = 12,
  warm_t = 0.3,
  fade_t = 0.3,
  pulse = 1,
  edge_frac = 0.1,
  halo_alpha = 0.25,
  halo_pulse = 0.3,
  halo_grow = 0.22
}

-- Per-notch table. size: circle diameter as a screen-
-- width fraction; reloc: min center move as a width
-- fraction; edge: allow spawns near the screen edges.
-- One sub-global per level (NM = minus, NP = plus) keeps
-- chunks short.

-- Delay after a find before the cross-fade to the next
-- target: animation smoothing only, not a level knob
-- (fixed across notches). Tunable.

FIND_PAUSE = 0.4

FIND_NM2 = {
  size = 0.3,
  reloc = 0.2,
  edge = false
}
FIND_NM1 = {
  size = 0.22,
  reloc = 0.25,
  edge = false
}
FIND_N0 = {
  size = 0.17,
  reloc = 0.3,
  edge = false
}
FIND_NP1 = {
  size = 0.12,
  reloc = 0.4,
  edge = false
}
FIND_NP2 = {
  size = 0.08,
  reloc = 0.5,
  edge = true
}

FIND_NOTCH = {
  [-2] = FIND_NM2,
  [-1] = FIND_NM1,
  [0] = FIND_N0,
  [1] = FIND_NP1,
  [2] = FIND_NP2
}

-- Enlarged high-contrast pointer (shared by find / pop).
-- shape: normalized arrow points (tip at 0,0), scaled by
-- size; convex so polygon fill is correct.

POINTER_FILL = {
  1,
  1,
  1
}
POINTER_EDGE = {
  0.1,
  0.1,
  0.12
}
POINTER_SHAPE = {
  0,
  0,
  0,
  1,
  0.7,
  0.7
}

POINTER = {
  size = 40,
  line = 3,
  fill = POINTER_FILL,
  edge = POINTER_EDGE,
  shape = POINTER_SHAPE
}

-- Mini-game 3: Pop the bubble. Light cheerful field.

POP_BG = {
  0.94,
  0.98,
  1
}

-- Bubble look: translucent fill, brighter rim, white
-- highlight. Alphas and highlight geometry in POP.

POP_FILL = {
  0.5,
  0.75,
  1
}
POP_RIM = {
  0.3,
  0.55,
  0.95
}
POP_HI = {
  1,
  1,
  1
}

-- Timings (s) and tuning. pop_t: shrink-to-zero; grow_t:
-- grow-in; struggle_t: no-pop struggle window;
-- struggle_clicks: off-target clicks that trigger a
-- struggle (ease the gauge).

POP = {
  min_px = 60,
  pop_t = 0.2,
  grow_t = 0.3,
  struggle_t = 15,
  struggle_clicks = 3,
  rim_w = 3,
  fill_a = 0.35,
  hi_a = 0.85,
  hi_off = 0.3,
  hi_r = 0.22
}

-- Delay after a pop before the next bubble grows in:
-- animation smoothing only, not a level knob. Tunable.

POP_RESPAWN = 0.4

-- Per-notch table. size: bubble diameter as a screen-
-- width fraction; reloc: min center move as a width
-- fraction; motion: drift speed (px/s, 0 = stationary).
-- One sub-global per level (NM = minus, NP = plus) keeps
-- chunks short.

POP_NM2 = {
  size = 0.3,
  reloc = 0.2,
  motion = 0
}
POP_NM1 = {
  size = 0.22,
  reloc = 0.25,
  motion = 0
}
POP_N0 = {
  size = 0.17,
  reloc = 0.3,
  motion = 0
}
POP_NP1 = {
  size = 0.12,
  reloc = 0.4,
  motion = 0
}
POP_NP2 = {
  size = 0.08,
  reloc = 0.5,
  motion = 20
}

POP_NOTCH = {
  [-2] = POP_NM2,
  [-1] = POP_NM1,
  [0] = POP_N0,
  [1] = POP_NP1,
  [2] = POP_NP2
}

-- Pop burst: tiny circles scattering from the center.

BURST = {
  count = 8,
  speed = 180,
  life = 0.35,
  r = 5,
  min_speed_frac = 0.5
}

-- Win gauge: a vertical thermometer in the right margin,
-- filling bottom-up with the signed counter g (0..goal). A
-- gold fill on a dim track reads on both the dark find field
-- and the light pop field.

GAUGE_TRACK = {
  0.5,
  0.5,
  0.55
}

-- A reserved strip down the right edge holds the gauge: the
-- pointer is kept out of it and nothing spawns there. All
-- horizontal placement clamps to APP.field_w, set in
-- sync_screen to APP.width - PLAY.reserve_r.

PLAY = {
  reserve_r = 30
}

GAUGE = {
  w = 8,
  right = 11,
  pad = 44,
  radius = 4,
  track_a = 0.2,
  fill_a = 0.85,
  on = LEGO_CHEESE,
  track = GAUGE_TRACK
}

-- First-try successes that fill each mini-game's gauge (its
-- promote threshold). Tunable.

GAUGE_GOAL = {
  meet = 8,
  find = 6,
  pop = 6
}

-- The signed counter floors at GAUGE_DEMOTE; reaching it
-- above the floor notch eases the notch down. After an
-- ease-down the fresh level seeds g at GAUGE_HEAD of its goal
-- (a head start), matching Hunt.

GAUGE_DEMOTE = -3
GAUGE_HEAD = 2 / 3

-- Celebration screen: a dim veil, a warm "Good job!", and a
-- click-to-continue cue that appears only once lock elapses.
-- lock ignores an in-flight click (>= 0.75 s) so a stray
-- click cannot skip the win before the child sees it.

CELEB_VEIL = {
  0,
  0,
  0
}
CELEB_TITLE_C = {
  1,
  0.85,
  0.35
}
CELEB_CUE_C = {
  0.9,
  0.9,
  0.92
}

CELEB = {
  veil = CELEB_VEIL,
  veil_a = 0.5,
  lock = 0.9,
  title = "Good job!",
  title_dy = -46,
  cue = "Click to continue",
  cue_dy = 26,
  title_c = CELEB_TITLE_C,
  cue_c = CELEB_CUE_C
}

-- In-play hint (keyboard parity): a dim Shift+Esc exit chip
-- bottom-left, a dark chip behind light text so it stays
-- legible on both the dark find and light pop fields.

HINT_CHIP = {
  0.1,
  0.1,
  0.12
}
HINT_TEXT_C = {
  0.85,
  0.85,
  0.88
}

HINT = {
  back = "Shift+Esc: menu",
  chip = HINT_CHIP,
  chip_a = 0.5,
  text_c = HINT_TEXT_C,
  pad = 6,
  y_off = 8
}

-- Celebration firework: saturated sparks, no red, for
-- contrast over the light "Good job!" veil. One color per
-- sub-global so no chunk runs long.

FW_BLUE = {
  0.15,
  0.55,
  0.95
}
FW_CYAN = {
  0.1,
  0.72,
  0.78
}
FW_GREEN = {
  0.2,
  0.72,
  0.35
}
FW_VIOLET = {
  0.6,
  0.3,
  0.9
}
FW_GOLD = {
  0.95,
  0.62,
  0.12
}
FW_MAGENTA = {
  0.85,
  0.28,
  0.82
}

FW_COLORS = {
  FW_BLUE,
  FW_CYAN,
  FW_GREEN,
  FW_VIOLET,
  FW_GOLD,
  FW_MAGENTA
}

FW = {
  count = 22,
  speed_lo = 140,
  speed_span = 220,
  life_lo = 1.4,
  life_span = 1,
  rise = 120,
  grav = 180,
  r_halo = 7,
  r_core = 4,
  halo_a = 0.35
}

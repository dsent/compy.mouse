-- mousedraw.lua
-- Draws the on-screen mouse from SVG2LOVE layers.
-- Each require returns a draw function authored in a
-- 250x440 sprite box. The runtime centers, tilts,
-- scales, then stacks layers back -> front. Tintable
-- layers (buttons, wheel, logo, cheese) carry no
-- setColor; the runtime sets the color before each
-- call. The wink phases keep their own brand colors.

mouse_body = require("MOUSE_BODY")
mouse_btn_l = require("MOUSE_BTN_L")
mouse_btn_r = require("MOUSE_BTN_R")
mouse_wheel_hl = require("MOUSE_WHEEL")
mouse_logo = require("MOUSE_LOGO")
mouse_cheese = require("CHEESE")
logo_wink_0 = require("LOGO_WINK_0")
logo_wink_1 = require("LOGO_WINK_1")
logo_wink_2 = require("LOGO_WINK_2")

-- Sprite-space box the layers are authored in

SP = {
  w = 250,
  h = 440
}

-- Cheese is authored in a 254x217 box near the top

CH_BOX = {
  w = 254,
  h = 217,
  cx = 125,
  cy = 125
}

-- Set draw color from an {r, g, b} table, alpha 1

function set_color(c, a)
  gfx.setColor(c[1], c[2], c[3], a or 1)
end

-- Scale so the sprite fills MOUSE_TUNE.size_w/h of the screen

function sprite_scale()
  local sx = APP.width * MOUSE_TUNE.size_w / SP.w
  local sy = APP.height * MOUSE_TUNE.size_h / SP.h
  return math.min(sx, sy)
end

-- Blink color while the cheese delight is active

function delight_color()
  if mm.delight <= 0 then
    return nil
  end
  local t = love.timer.getTime() * DELIGHT.blink_rate
  local i = math.floor(t) % #LEGO_BLINK + 1
  return LEGO_BLINK[i]
end

-- A zone blinks through LEGO colors during the cheese
-- delight; otherwise it shows its press glow.

function draw_zone(layer, zone)
  local blink = delight_color()
  if blink then
    set_color(blink)
    layer()
    return 
  end
  draw_press(layer, zone)
end

-- Pressed look: shift down, fill the zone color, then an
-- additive pass for a soft glow. Both scale with the
-- eased press amount, so button-up fades to neutral.

function draw_press(layer, zone)
  local a = mm.glow[zone]
  if a <= GLOW.eps then
    return 
  end
  gfx.push("all")
  gfx.translate(0, MOUSE_TUNE.press_shift * a)
  set_color(LEGO[zone], a)
  layer()
  gfx.setBlendMode("add")
  set_color(LEGO[zone], a * GLOW.add)
  layer()
  gfx.pop()
end

-- Pick the wink phase layer from delight progress.
-- Called only while delight is active (see draw_logo_layer).

function wink_phase()
  local p = 1 - mm.wink / DELIGHT.wink_time
  if p < DELIGHT.wink_p1 then
    return logo_wink_0
  end
  if p < DELIGHT.wink_p2 then
    return logo_wink_1
  end
  return logo_wink_2
end

-- Draw the winking brand mark, shifted onto the
-- body-logo origin. Phase 0 until the wink starts.

function draw_wink()
  gfx.push("all")
  gfx.translate(WINK_OFF.x, WINK_OFF.y)
  if mm.wink <= 0 then
    logo_wink_0()
  else
    wink_phase()()
  end
  gfx.pop()
end

-- Logo: plain tinted mark, or winking during delight.
-- Wink phases are authored in a 200x250 box; shift
-- them onto the body-logo origin so the wink lands in
-- place. Phases keep their own colors (no tint).

function draw_logo_layer()
  if mm.delight <= 0 then
    set_color(LOGO_COLOR)
    mouse_logo()
  else
    draw_wink()
  end
end

-- The MOUSE04_4/_5 layers are authored mirrored vs
-- screen sides: _4 (mouse_btn_l) covers the right half,
-- _5 (mouse_btn_r) the left. Bind by screen side, not
-- by file name, so button 1 lights the left zone.

function draw_mouse_layers()
  gfx.setColor(1, 1, 1, 1)
  mouse_body()
  draw_zone(mouse_btn_r, "left")
  draw_zone(mouse_btn_l, "right")
  draw_zone(mouse_wheel_hl, "wheel")
  draw_scroll()
  draw_logo_layer()
end

-- Soft shadow under the mouse: a flat ellipse near the
-- base. Not tilted, so a bump lift reads against it.

function draw_shadow()
  local hx, hy = mm_half()
  set_color(SHADOW.c, SHADOW.alpha)
  gfx.ellipse(
    "fill",
    mm.x,
    mm.y + hy * SHADOW.dy,
    hx * SHADOW.rx,
    hx * SHADOW.ry
  )
end

function draw_mouse_sprite()
  local s = sprite_scale()
  local push = (0 < mm.bump) and bump_push() or 0
  draw_shadow()
  gfx.push("all")
  gfx.translate(mm.x, mm.y - push)
  gfx.rotate(mm.tilt)
  gfx.scale(s, s)
  gfx.translate(-SP.w / 2, -SP.h / 2)
  draw_mouse_layers()
  gfx.pop()
end

-- Small recoil offset during a wall/barrier bump

function bump_push()
  local p = mm.bump / BUMP.time
  return math.sin(p * math.pi) * BUMP.recoil
end

-- Wheel scroll: 3 pellets wrapping inside the slot.
-- They travel an inset band so a margin equal to the
-- side gap is kept above and below (never flush).
-- Plus a direction arrow above or below.

function pellet_y(i)
  local n = WHEEL.pellets
  local travel = WHEEL_WIN.band_h - WHEEL_WIN.pel_h
  local phase = (mm.wheel + i / n) % 1
  return WHEEL_WIN.band_top + phase * travel
end

function draw_pellets()
  set_color(WHEEL_WIN.pel_c)
  for i = 0, WHEEL.pellets - 1 do
    local y = pellet_y(i)
    gfx.rectangle(
      "fill",
      WHEEL_WIN.pel_x,
      y,
      WHEEL_WIN.pel_w,
      WHEEL_WIN.pel_h,
      WHEEL_WIN.pel_r,
      WHEEL_WIN.pel_r
    )
  end
end

-- Arrow triangle above (dir<0) or below (dir>0)

function arrow_points(cx, ay, h, hw)
  return {
    cx,
    ay + h,
    cx - hw,
    ay,
    cx + hw,
    ay
  }
end
function scroll_arrow(dir)
  local cx = WHEEL_WIN.pel_x + WHEEL_WIN.pel_w / 2
  local ay = (dir < 0) and WHEEL_ARR.arr_up
       or WHEEL_ARR.arr_dn
  local h = WHEEL_ARR.arr_h * dir
  local hw = WHEEL_ARR.arr_w / 2
  local p = arrow_points(cx, ay, h, hw)
  set_color(WHEEL_ARR.arr_c)
  gfx.polygon("fill", p)
end

function draw_scroll()
  draw_pellets()
  if WHEEL.eps < math.abs(mm.wheel_vel) then
    scroll_arrow(mm.wheel_vel < 0 and -1 or 1)
  end
end

-- Cheese prop: tinted yellow, centered and scaled to
-- CHEESE.size. Called by meet.lua in world space.

function cheese_sprite()
  local s = CHEESE.size / CH_BOX.w
  gfx.push("all")
  gfx.scale(s, s)
  gfx.translate(-CH_BOX.cx, -CH_BOX.cy)
  set_color(LEGO.cheese)
  mouse_cheese()
  gfx.pop()
end

-- Barrier: an axis-aligned rounded box in its local
-- frame (meet.lua sets the position).

function barrier_sprite(alpha)
  local hw, hh = barrier.bw / 2, barrier.bh / 2
  set_color(BARRIER.color, alpha)
  gfx.rectangle(
    "fill",
    -hw,
    -hh,
    barrier.bw,
    barrier.bh,
    BARRIER.corner
  )
end

-- Neutral mouse icon for the no-mouse screen: body and
-- logo only, no pressed zones, no tilt. Drawn around the
-- current transform origin in sprite space.

function mouse_icon()
  gfx.push("all")
  gfx.translate(-SP.w / 2, -SP.h / 2)
  gfx.setColor(1, 1, 1, 1)
  mouse_body()
  set_color(LOGO_COLOR)
  mouse_logo()
  gfx.pop()
end

-- Unconnected USB-A plug: shell, contact tongue, and a
-- trailing cable stub (the trailing cable reads as
-- "not plugged in"). Drawn around the current origin.

function usb_plug()
  local w, h = PLUG.w, PLUG.h
  set_color(PLUG.shell)
  gfx.rectangle("fill", -w / 2, -h / 2, w, h, PLUG.corner)
  set_color(PLUG.metal)
  local ix = -w / 2 + PLUG.inner
  gfx.rectangle(
    "fill",
    ix,
    -h / 2 + PLUG.inner,
    w * PLUG.tongue_w,
    h - PLUG.inner * 2
  )
  set_color(PLUG.cable_c)
  gfx.setLineWidth(PLUG.line_w)
  gfx.line(w / 2, 0, w / 2 + PLUG.cable, 0)
end

-- Mouse centered with the plug floating to its right

function draw_plug_pair(cx, cy, s)
  gfx.push("all")
  gfx.translate(cx, cy)
  gfx.scale(s, s)
  mouse_icon()
  gfx.translate(SP.w / 2 + NO_MOUSE.plug_gap + PLUG.w / 2, 0)
  usb_plug()
  gfx.pop()
end

-- Win gauge: a vertical thermometer in the right margin,
-- filling bottom-up. The signed counter shows 0..goal, so a
-- negative g reads as empty (no punitive drain).

function gauge_frac()
  if WIN.goal <= 0 then
    return 0
  end
  return clamp(WIN.g / WIN.goal, 0, 1)
end

function draw_gauge()
  local f = gauge_frac()
  local x = APP.width - GAUGE.right - GAUGE.w
  local y0 = GAUGE.pad
  local h = APP.height - 2 * GAUGE.pad
  set_color(GAUGE.track, GAUGE.track_a)
  gfx.rectangle("fill", x, y0, GAUGE.w, h, GAUGE.radius)
  set_color(GAUGE.on, GAUGE.fill_a)
  gfx.rectangle("fill", x, y0 + h * (1 - f),
    GAUGE.w, h * f, GAUGE.radius)
end

-- Centered text at (cx, y-top) in the current (UI) font

function draw_center(text, cx, y, color)
  local font = gfx.getFont()
  local tw = font:getWidth(text)
  set_color(color)
  gfx.print(text, cx - tw / 2, y)
end

-- Centered heading in the big font, then restore the UI font

function draw_big(text, cx, cy, color)
  gfx.setFont(BIG_FONT)
  local tw = BIG_FONT:getWidth(text)
  set_color(color)
  gfx.print(text, cx - tw / 2, cy - BIG_FONT:getHeight() / 2)
  gfx.setFont(UI_FONT)
end

-- Firework spark: a soft halo around a bright core

function fw_draw_spark(p)
  local a = p.life / p.max
  set_color(p.col, a * FW.halo_a)
  gfx.circle("fill", p.x, p.y, FW.r_halo)
  set_color(p.col, a)
  gfx.circle("fill", p.x, p.y, FW.r_core)
end

function fw_draw()
  for _, p in ipairs(WIN.fw) do
    fw_draw_spark(p)
  end
end

-- Celebration screen: dim the field, a warm "Good job!", the
-- firework (empty unless a top-notch win started it), and --
-- only once the lock elapses -- the click-to-continue cue, so
-- a stray click cannot skip the win. A click advances (main).

function draw_win_overlay()
  set_color(CELEB.veil, CELEB.veil_a)
  gfx.rectangle("fill", 0, 0, APP.width, APP.height)
  local cx = APP.width / 2
  local cy = APP.height / 2
  draw_big(CELEB.title, cx, cy + CELEB.title_dy, CELEB.title_c)
  if WIN.lock <= 0 then
    draw_center(CELEB.cue, cx, cy + CELEB.cue_dy, CELEB.cue_c)
  end
  fw_draw()
end

-- A dim chip behind light text at the bottom-left edge.

function hint_y()
  return APP.height - gfx.getFont():getHeight() - HINT.y_off
end

function draw_hint_chip(text)
  local font = gfx.getFont()
  local tw = font:getWidth(text)
  local y = hint_y()
  local x = 8
  set_color(HINT.chip, HINT.chip_a)
  gfx.rectangle("fill", x - HINT.pad, y - 3,
    tw + HINT.pad * 2, font:getHeight() + 6, 5)
  set_color(HINT.text_c)
  gfx.print(text, x, y)
end

-- Persistent play-time hint: the Shift+Esc exit chip

function draw_hints()
  draw_hint_chip(HINT.back)
end

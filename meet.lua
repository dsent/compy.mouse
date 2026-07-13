-- meet.lua
-- Mini-game 1: Meet the mouse.
-- Contains the whole mini-game: state, motion, sounds,
-- input, cheese placement, barrier, and the cheese
-- delight effect. 

require("mousedraw")

cheese = {
  x = 0,
  y = 0,
  active = false,
  searching = false,
  min_d = 0
}

-- Play-field diagonal in pixels (minus the reserved strip)

function screen_diag()
  local w, h = APP.field_w, APP.height
  return math.sqrt(w * w + h * h)
end

-- Begin a fresh search; mouse loses its cheese

function cheese_take()
  cheese.active = false
end

function cheese_respawn()
  cheese.searching = true
  cheese.min_d = screen_diag() * CHEESE.min_diag_frac
end

function cheese_radius()
  return CHEESE.size / 2
end

function cheese_clear_margin(x, y, r)
  local m = APP.width * CHEESE.margin_frac
  if x - r < m or APP.field_w - m < x + r then
    return false
  end
  if y - r < m or APP.height - m < y + r then
    return false
  end
  return true
end

function cheese_clear_mouse(x, y, r)
  local hx, hy = mm_half()
  local dx, dy = x - mm.x, y - mm.y
  local clear = math.max(hx, hy) + r
  return clear * clear <= dx * dx + dy * dy
end

-- True if (x, y) clears the spec minimum distance from
-- the mouse center.

function cheese_far_enough(x, y)
  local dx, dy = x - mm.x, y - mm.y
  local d = cheese.min_d
  return d * d <= dx * dx + dy * dy
end

-- A point is legal if far enough from the mouse, off
-- the margin, clear of the mouse body, and clear of the
-- barrier (if present).

function cheese_legal(x, y)
  local r = cheese_radius()
  if not cheese_clear_margin(x, y, r) then
    return false
  end
  if not cheese_far_enough(x, y) then
    return false
  end
  if not cheese_clear_mouse(x, y, r) then
    return false
  end
  return not barrier_hit_disc(x, y, r)
end

-- Sample a point the mouse center can actually reach:
-- inside the same wall-clamped rectangle, so the cheese
-- never lands in the half-sprite dead band at the edges.

function cheese_sample()
  local r = cheese_radius()
  local m = APP.width * CHEESE.margin_frac + r
  local x = rand_range(m, APP.field_w - m)
  local y = rand_range(m, APP.height - m)
  return x, y
end

-- One frame of placement tries; true if a spot was set.

function cheese_try_place()
  for _ = 1, CHEESE.tries_per_frame do
    local x, y = cheese_sample()
    if cheese_legal(x, y) then
      cheese.x, cheese.y = x, y
      cheese.active = true
      cheese.searching = false
      return true
    end
  end
  return false
end

-- Search across frames without blocking. On a frame that
-- finds no legal spot, relax the min-distance rule so a
-- placement is always reached (spec: update the
-- constraints with each iteration).

function cheese_progress()
  if not cheese.searching then
    return 
  end
  if not cheese_try_place() then
    cheese.min_d = cheese.min_d * CHEESE.relax
  end
end

-- Cheese collision works in a normalized frame where the
-- overlap ellipse (mouse half-extents + cheese radius on
-- each axis) is the unit circle. The mouse center inside
-- that unit circle means it overlaps the cheese.

function cheese_norm(x, y)
  local hx, hy = mm_half()
  local r = CHEESE.size / 2
  return (x - cheese.x) / (hx + r),
       (y - cheese.y) / (hy + r)
end

-- Squared distance from the origin to segment a->b, both
-- already in normalized cheese space.

function seg_dist2(ax, ay, bx, by)
  local dx, dy = bx - ax, by - ay
  local len2 = dx * dx + dy * dy
  local t = 0
  if 0 < len2 then
    t = clamp(-(ax * dx + ay * dy) / len2, 0, 1)
  end
  local cx, cy = ax + t * dx, ay + t * dy
  return cx * cx + cy * cy
end

-- True if the mouse center, swept from (ox, oy) to
-- (nx, ny), touched the cheese anywhere on the way. The
-- endpoint test alone tunnels through it on a fast flick.

function cheese_swept(ox, oy, nx, ny)
  local ax, ay = cheese_norm(ox, oy)
  local bx, by = cheese_norm(nx, ny)
  return seg_dist2(ax, ay, bx, by) <= 1
end

function cheese_draw()
  if not cheese.active then
    return 
  end
  gfx.push("all")
  gfx.translate(cheese.x, cheese.y)
  cheese_sprite()
  gfx.pop()
end

barrier = {
  active = false,
  bw = 0,
  bh = 0,
  x = 0,
  y = 0,
  alpha = 0,
  fade_dir = 0,
  cheese_seen = 0,
  swap_x = 0,
  swap_y = 0
}

function barrier_clear()
  barrier.active = false
  barrier.cheese_seen = 0
  barrier.alpha = 0
  barrier.fade_dir = 0
end

-- Inner play rectangle: screen minus a clearance margin
-- (in mouse widths) on each side. A barrier kept inside
-- it always leaves room to pass. Returns width, height.

function barrier_inset()
  local hx, hy = mm_half()
  local c = BARRIER.clearance
  return APP.field_w - 4 * c * hx, APP.height - 4 * c * hy
end

-- One box side: at least min_px and the area-floor share
-- (alo), at most the side cap and the area-cap share
-- (ahi). The area shares couple the two sides together.

function barrier_side(cap, alo, ahi)
  local lo = math.max(BARRIER.min_px, alo)
  return rand_range(lo, math.min(cap, ahi))
end

-- Re-sample a random axis-aligned box. Random aspect,
-- fitted to the inner rectangle, with area between the
-- min and max fractions of it. Called on each appearance.

function barrier_shape()
  local iw, ih = barrier_inset()
  local mn = BARRIER.min_px
  local amin = iw * ih * BARRIER.area_min_frac
  local amax = iw * ih * BARRIER.area_frac
  local w = barrier_side(iw, amin / ih, amax / mn)
  local h = barrier_side(ih, amin / w, amax / w)
  barrier.bw, barrier.bh = w, h
end

-- Bounding-box half-extents of the box

function barrier_bbox()
  return barrier.bw / 2, barrier.bh / 2
end

-- Min center offsets that keep the box inside the inner
-- rectangle (clearance mouse widths off each edge).

function barrier_margins()
  local hx, hy = mm_half()
  local c = BARRIER.clearance
  local mx = 2 * c * hx + barrier.bw / 2
  local my = 2 * c * hy + barrier.bh / 2
  return mx, my
end

-- One random box center within the legal placement band.

function barrier_center()
  local mx, my = barrier_margins()
  return rand_range(mx, APP.field_w - mx),
       rand_range(my, APP.height - my)
end

-- Band corner farthest from the mouse: the least-overlap
-- placement when the legal band has no fully-clear spot.

function barrier_far_center(px, py)
  local mx, my = barrier_margins()
  return pick_far(px, mx, APP.field_w - mx),
       pick_far(py, my, APP.height - my)
end

-- Legal center: bbox inside the inner rect, clear of the
-- mouse. Bounded rejection; if none clear (band collapsed),
-- use the corner farthest from the mouse. Never spins.

function barrier_place(px, py)
  local hx, hy = mm_half()
  local r = math.max(hx, hy)
  for _ = 1, SAMPLE_TRIES do
    local x, y = barrier_center()
    if not barrier_disc_at(px, py, r, x, y) then
      barrier.x, barrier.y = x, y
      return 
    end
  end
  barrier.x, barrier.y = barrier_far_center(px, py)
end

function barrier_disc_at(px, py, r, cx, cy)
  local hw, hh = barrier.bw / 2, barrier.bh / 2
  local qx = clamp(px, cx - hw, cx + hw)
  local qy = clamp(py, cy - hh, cy + hh)
  local ex, ey = px - qx, py - qy
  return ex * ex + ey * ey <= r * r
end

function barrier_hit_disc(px, py, r)
  if not barrier.active then
    return false
  end
  return barrier_disc_at(px, py, r, barrier.x, barrier.y)
end

-- Mouse-vs-barrier as an axis-aligned box overlap. The
-- sprite is far taller than wide, so a single disc of
-- max(hx, hy) bumped too early on the sides. Barrier and
-- mouse boxes are both axis-aligned, so compare extents.

function barrier_hit_mouse(px, py)
  if not barrier.active then
    return false
  end
  local hx, hy = mm_half()
  local bw, bh = barrier_bbox()
  return math.abs(px - barrier.x) <= hx + bw
       and math.abs(py - barrier.y) <= hy + bh
end

-- True on the cheese counts that should (re)place the
-- barrier: the 5th, then every 3rd after (8, 11, 14, …).

function barrier_due(count)
  if count < BARRIER.first_cheese then
    return false
  end
  local after = count - BARRIER.first_cheese
  return after % BARRIER.swap_every == 0
end

-- Appear on the first due count; swap on later ones.

function barrier_emit(px, py)
  if not barrier.active then
    barrier_appear(px, py)
  else
    barrier_start_swap(px, py)
  end
end

-- Called on each cheese: appear or swap on schedule.

function barrier_on_cheese(count, px, py)
  if count <= barrier.cheese_seen then
    return 
  end
  barrier.cheese_seen = count
  if barrier_due(count) then
    barrier_emit(px, py)
  end
end

function barrier_sync_count()
  barrier_on_cheese(mm.cheese_count, mm.x, mm.y)
end

-- Place the first barrier and fade it in

function barrier_appear(px, py)
  barrier_shape()
  barrier_place(px, py)
  barrier.active = true
  barrier.alpha = 1
  barrier.fade_dir = 0
end

-- Begin a swap: remember the spot, fade the old out

function barrier_start_swap(px, py)
  barrier.swap_x = px
  barrier.swap_y = py
  barrier.fade_dir = -1
end

-- Fade alpha during the cheese pause

-- Drive the fade. fade_dir +1 fades in; -1 fades out,
-- and at zero it repositions and flips to fade in.

function barrier_fade(dt)
  if barrier.fade_dir == 0 then
    return 
  end
  local step = (dt / BARRIER.fade) * barrier.fade_dir
  barrier.alpha = clamp(barrier.alpha + step, 0, 1)
  if barrier.fade_dir == 1 and 1 <= barrier.alpha then
    barrier.fade_dir = 0
  elseif barrier.fade_dir == -1 and barrier.alpha <= 0 then
    barrier_shape()
    barrier_place(barrier.swap_x, barrier.swap_y)
    barrier.fade_dir = 1
  end
end

function barrier_draw()
  if not barrier.active then
    return 
  end
  gfx.push("all")
  gfx.translate(barrier.x, barrier.y)
  barrier_sprite(barrier.alpha)
  gfx.pop()
end

meet = { }

-- Mutable state. Reset fully on enter.

mm = { }

-- Sprite half-extents in screen pixels

function mm_half()
  local s = sprite_scale()
  return SP.w * s / 2, SP.h * s / 2
end

-- Lifecycle

-- Zero the per-run sound and motion timers

function reset_mm_timers()
  mm.cheese_count = 0
  mm.delight = 0
  mm.wink = 0
  mm.cheese_echo = 0
  mm.right_flash = 0
  mm.hit_snd = 0
  mm.step_acc = 0
  mm.speed = 0
  mm.move_dir = 0
end

-- Match APP to the real drawable so the playfield fills
-- the actual Compy surface, not a fixed logical size.

function sync_screen()
  APP.width, APP.height = love.graphics.getDimensions()
  APP.field_w = APP.width - PLAY.reserve_r
end

-- Center the mouse and clear its motion / wheel state.

function reset_mm_state()
  mm.x = APP.field_w / 2
  mm.y = APP.height / 2
  mm.tilt = 0
  mm.pause = 0
  mm.bump = 0
  mm.wheel = 0
  mm.wheel_vel = 0
end

-- Clear button-press and glow state.

function reset_glow()
  mm.btn = { }
  mm.glow = {
    left = 0,
    right = 0,
    wheel = 0
  }
end

function meet.enter()
  sync_screen()
  reset_mm_state()
  reset_glow()
  reset_mm_timers()
  barrier_clear()
  cheese_respawn()
  win_reset("meet")
  love.mouse.setVisible(false)
  love.mouse.setRelativeMode(true)
end

-- Meet has no notch: a fresh level (a win-gauge loop) just
-- resets the gauge (win.lua). The cheese hunt is untouched.

function meet.relevel()
end

function meet.leave()
  cursor_release()
end

-- Clamp the mouse center to the playfield walls.
-- Returns true if a wall was touched.

function clamp_walls()
  local hx, hy = mm_half()
  local nx = clamp(mm.x, hx, APP.field_w - hx)
  local ny = clamp(mm.y, hy, APP.height - hy)
  local hit = (nx ~= mm.x) or (ny ~= mm.y)
  mm.x, mm.y = nx, ny
  return hit
end

-- Apply a pointer delta with light smoothing. Speed is
-- measured later from the real post-wall displacement.

function apply_delta(dx, dy)
  mm.x = mm.x + dx * MOUSE_TUNE.smooth
  mm.y = mm.y + dy * MOUSE_TUNE.smooth
end

-- Start a bump (squash) response on contact

function start_bump()
  mm.bump = BUMP.time
end

-- React to wall or barrier contact

function on_contact()
  start_bump()
  mm.hit_snd = play_gated(SND.hit, mm.hit_snd, MOVE_SND.hit_gap)
end

-- Pointer input (only while not paused)

-- After a move resolves against walls/barrier, record the
-- real motion (speed, direction) and emit the footstep.
-- A mouse held against a wall reads as still: no beep.

function meet_after_move(ox, oy)
  local dx, dy = mm.x - ox, mm.y - oy
  local d = math.sqrt(dx * dx + dy * dy)
  mm.speed = d / MOUSE_TUNE.smooth
  if MOUSE_TUNE.jitter < mm.speed then
    mm.move_dir = math.atan2(dy, dx)
    step_accumulate(d)
  end
end

-- Barrier blocks (revert to pre-move spot); else a wall

function meet_collide(ox, oy, wall)
  if barrier_hit_mouse(mm.x, mm.y) then
    mm.x, mm.y = ox, oy
    on_contact()
  elseif wall then
    on_contact()
  end
end

-- Score the cheese if the resolved move swept onto it

function meet_take_cheese(ox, oy)
  if cheese.active and cheese_swept(ox, oy, mm.x, mm.y) then
    on_cheese()
  end
end

function meet_moved(dx, dy)
  if 0 < mm.pause then
    return 
  end
  local ox, oy = mm.x, mm.y
  apply_delta(dx, dy)
  local wall = clamp_walls()
  meet_collide(ox, oy, wall)
  meet_after_move(ox, oy)
  meet_take_cheese(ox, oy)
end

-- Update: tilt toward travel, bump decay, sounds

GLOW_ZONES = {
  "left",
  "right",
  "wheel"
}

-- Target glow for a zone: lit while held, and the right
-- zone also lights briefly on a raw-Esc right-click.

function glow_target(zone)
  if mm.btn[zone] then
    return 1
  end
  if zone == "right" and 0 < mm.right_flash then
    return 1
  end
  return 0
end

-- Ease each zone's glow toward its target so a press
-- lights up and a release fades back to neutral.

function update_glow(dt)
  local k = math.min(1, GLOW.rate * dt)
  for _, z in ipairs(GLOW_ZONES) do
    local t = glow_target(z)
    mm.glow[z] = mm.glow[z] + (t - mm.glow[z]) * k
  end
end

function update_tilt(dt)
  local target = 0
  if MOUSE_TUNE.jitter < mm.speed then
    target = math.cos(mm.move_dir) * MOUSE_TUNE.tilt_max
  end
  local k = math.min(1, MOUSE_TUNE.tilt_rate * dt)
  mm.tilt = mm.tilt + (target - mm.tilt) * k
end

-- Footstep cadence: one step per fixed distance travelled,
-- so the rhythm tracks how fast the mouse actually moves.

function step_accumulate(d)
  mm.step_acc = mm.step_acc + d
  if MOVE_SND.step_dist <= mm.step_acc then
    play(SND.move)
    mm.step_acc = mm.step_acc - MOVE_SND.step_dist
  end
end

-- Wheel scroll spins down over time

function update_wheel(dt)
  mm.wheel = (mm.wheel + mm.wheel_vel * dt) % 1
  local k = math.min(1, WHEEL.decay * dt)
  mm.wheel_vel = mm.wheel_vel - mm.wheel_vel * k
end

-- Decay per-frame timers and bleed off speed

function update_timers(dt)
  mm.bump = decay(mm.bump, dt)
  mm.hit_snd = decay(mm.hit_snd, dt)
  mm.right_flash = decay(mm.right_flash, dt)
  mm.speed = mm.speed * MOUSE_TUNE.speed_decay
end

-- The non-paused per-frame work: cheese, tilt, sounds.

function meet_update_active(dt)
  cheese_progress()
  update_tilt(dt)
  update_wheel(dt)
  update_timers(dt)
end

function meet.update(dt)
  update_glow(dt)
  barrier_sync_count()
  if 0 < mm.pause then
    update_pause(dt)
  else
    meet_update_active(dt)
  end
end

-- Cheese delight: pause, sound, blink, wink, respawn

function on_cheese()
  mm.pause = CHEESE.pause
  mm.delight = CHEESE.pause
  mm.wink = DELIGHT.wink_time
  play_cheese()
  mm.cheese_count = mm.cheese_count + 1
  win_success()
  cheese_take()
  barrier_on_cheese(mm.cheese_count, mm.x, mm.y)
end

-- During the pause, run blink/wink, then respawn once

function update_pause(dt)
  mm.pause = decay(mm.pause, dt)
  mm.delight = decay(mm.delight, dt)
  mm.wink = decay(mm.wink, dt)
  drain_cheese_echo(dt)
  barrier_fade(dt)
  if mm.pause <= 0 then
    cheese_respawn()
  end
end

-- Fire the deferred second cheese sound once its
-- gap elapses (armed by play_cheese).

function drain_cheese_echo(dt)
  if mm.cheese_echo <= 0 then
    return 
  end
  mm.cheese_echo = mm.cheese_echo - dt
  if mm.cheese_echo <= 0 then
    play(SND.cheese)
  end
end

-- Button / wheel-click highlight via dispatch

BTN_OF = {
  [1] = "left",
  [2] = "right",
  [3] = "wheel",
  l = "left",
  r = "right",
  m = "wheel",
  left = "left",
  right = "right",
  middle = "wheel"
}

function meet_pressed(button)
  local zone = BTN_OF[button]
  if zone then
    mm.btn[zone] = true
    if zone == "right" then
      mm.right_flash = BUMP.right_flash
    end
    play(SND.click)
  end
end

function meet_released(button)
  local zone = BTN_OF[button]
  if zone then
    mm.btn[zone] = false
  end
end

-- Right-click arrives as raw Esc 

function meet_right()
  mm.right_flash = BUMP.right_flash
  play(SND.click)
end

function meet_wheel(dy)
  mm.wheel_vel = mm.wheel_vel - dy * WHEEL.scroll_rate
end

-- Input methods for the generic dispatch in main.
-- A mini-game implements only the events it uses;
-- the rest are nil and silently ignored.

meet.moved = meet_moved
meet.pressed = meet_pressed
meet.released = meet_released
meet.wheel = meet_wheel
meet.right = meet_right

function meet.draw()
  gfx.clear(MOUSE_BG)
  barrier_draw()
  cheese_draw()
  draw_mouse_sprite()
end

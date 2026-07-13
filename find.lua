-- find.lua
-- Mini-game 2: Find the glowing circle.
-- A glowing target sits on a dark field; the child moves
-- the visible pointer into it (no clicking). On entry the
-- target warms and a bell plays; after the notch's spawn
-- pause it cross-fades to a new target elsewhere, at least
-- the relocation distance away. Each find fills the shared
-- gauge (win.lua); a struggle eases it. The gauge climbs and
-- eases the notch.

require("pointer")

find = { notched = true }

-- Circle and run state. Reset fully on enter.

fc = { }

function find_row()
  return FIND_NOTCH[notch_level("find")]
end

-- Circle radius for a notch row, clamped to the floor

function find_radius(row)
  return radius_from_row(row, FIND.min_px)
end

-- Edge-rule margin for a center sample: keep the circle
-- on screen, and off the edges unless the notch allows it.

function find_margin(r, edge)
  if edge then
    return r
  end
  return math.max(FIND.edge_frac * APP.width, r)
end

function find_sample(r, edge)
  return random_field_point(find_margin(r, edge))
end

-- Sample a center at least the notch relocation distance
-- from the current one.

function find_far_point(r, row)
  local m = find_margin(r, row.edge)
  local need = row.reloc * APP.width
  return far_point(fc.x, fc.y, need, m)
end

-- Make (x, y) the live target with radius r

function find_spawn(x, y, r)
  fc.x, fc.y, fc.r = x, y, r
  fc.phase = "live"
  fc.age = 0
  fc.warm = 0
  fc.won_t = 0
  fc.swap_t = 0
  fc.alpha = 1
  fc.struggled = false
end

function find.enter()
  sync_screen()
  cursor_custom()
  fc.px, fc.py = love.mouse.getPosition()
  find.relevel()
  win_reset("find")
end

-- Respawn a fresh target at the current notch (a new level).
-- The gauge is set by win.lua; the pointer is untouched.

function find.relevel()
  local row = find_row()
  local r = find_radius(row)
  local x, y = find_sample(r, row.edge)
  find_spawn(x, y, r)
end

function find.leave()
  cursor_show()
end

-- Pointer inside the live target?

function find_inside()
  local dx, dy = fc.px - fc.x, fc.py - fc.y
  return dx * dx + dy * dy <= fc.r * fc.r
end

-- Pointer entered: warm up, fill the gauge, play the bell

function find_enter_circle()
  fc.phase = "won"
  fc.won_t = 0
  play(SND.bell)
  win_success()
end

-- Live: age the target, detect entry, fire one struggle. A
-- struggle eases the gauge (a long spawn without an entry).

function find_live(dt)
  fc.age = fc.age + dt
  if find_inside() then
    find_enter_circle()
  elseif not fc.struggled and FIND.struggle_t <= fc.age then
    fc.struggled = true
    win_miss()
  end
end

-- Won: cool->warm transition, then start the swap once the
-- notch spawn pause (bell-to-next-circle delay) elapses.

function find_won(dt)
  fc.won_t = fc.won_t + dt
  fc.warm = math.min(1, fc.won_t / FIND.warm_t)
  local row = find_row()
  if FIND_PAUSE <= fc.won_t then
    find_start_swap(row)
  end
end

function find_start_swap(row)
  local r = find_radius(row)
  fc.new_x, fc.new_y = find_far_point(r, row)
  fc.new_r = r
  fc.new_alpha = 0
  fc.phase = "swap"
  fc.swap_t = 0
end

-- Swap: old fades out as the new fades in; the new target
-- then becomes the live one.

function find_swap(dt)
  fc.swap_t = fc.swap_t + dt
  local t = math.min(1, fc.swap_t / FIND.fade_t)
  fc.alpha = 1 - t
  fc.new_alpha = t
  if FIND.fade_t <= fc.swap_t then
    find_spawn(fc.new_x, fc.new_y, fc.new_r)
  end
end

PHASE = {
  live = find_live,
  won = find_won,
  swap = find_swap
}

function find.update(dt)
  fc.px, fc.py = love.mouse.getPosition()
  fc.px = clamp(fc.px, 0, APP.field_w)
  PHASE[fc.phase](dt)
end

-- Drawing

function mix_rgb(a, b, t)
  return {
    a[1] + (b[1] - a[1]) * t,
    a[2] + (b[2] - a[2]) * t,
    a[3] + (b[3] - a[3]) * t
  }
end

-- Pulsing glow factor in 0..1, period FIND.pulse

function find_glow()
  local t = love.timer.getTime() / FIND.pulse
  return 0.5 + 0.5 * math.sin(t * 2 * math.pi)
end

-- A target: a soft pulsing halo plus a solid core

function find_circle(x, y, r, color, alpha)
  local g = find_glow()
  local a = alpha * (FIND.halo_alpha + FIND.halo_pulse * g)
  set_color(color, a)
  gfx.circle("fill", x, y, r * (1 + FIND.halo_grow * g))
  set_color(color, alpha)
  gfx.circle("fill", x, y, r)
end

function find_draw_current()
  local color = mix_rgb(FIND_COOL, FIND_WARM, fc.warm)
  find_circle(fc.x, fc.y, fc.r, color, fc.alpha)
end

function find.draw()
  gfx.clear(FIND_BG)
  find_draw_current()
  if fc.phase == "swap" then
    find_circle(
      fc.new_x,
      fc.new_y,
      fc.new_r,
      FIND_COOL,
      fc.new_alpha
    )
  end
  draw_pointer(fc.px, fc.py)
end

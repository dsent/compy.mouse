-- pop.lua
-- Mini-game 3: Pop the bubble.
-- One bubble at a time on a light field; the child moves
-- the pointer onto it and left-clicks. The bubble shrinks
-- to nothing with a small particle burst and a soft pop,
-- then a new one grows in elsewhere (at least the
-- relocation distance away). Adds clicking to find's
-- pointing. Difficulty rides the shared notch mechanism.

require("pointer")

pop = { notched = true }

-- Bubble and run state. Reset fully on enter.
-- phase: "grow" | "live" | "pop". off: off-target clicks
-- this spawn. scale: current visual scale. pop_s0: scale
-- captured when the pop starts. burst: pop particles.

bubble = { }

function pop_row()
  return POP_NOTCH[notch_level("pop")]
end

function pop_radius(row)
  return radius_from_row(row, POP.min_px)
end

function pop_sample(r)
  return random_field_point(r)
end

-- A center at least the notch relocation distance from
-- the current one.

function pop_far_point(r, row)
  local need = row.reloc * APP.width
  return far_point(bubble.x, bubble.y, need, r)
end

-- Drift velocity for the notch (zero unless motion > 0)

function pop_set_drift()
  local m = pop_row().motion
  if m <= 0 then
    bubble.vx, bubble.vy = 0, 0
    return 
  end
  local a = rand_range(0, 2 * math.pi)
  bubble.vx, bubble.vy = math.cos(a) * m, math.sin(a) * m
end

-- Start a new bubble growing in at (x, y)

function pop_begin(x, y, r)
  bubble.x, bubble.y, bubble.r = x, y, r
  bubble.phase = "grow"
  bubble.t = 0
  bubble.age = 0
  bubble.off = 0
  bubble.struggled = false
  bubble.scale = 0
  pop_set_drift()
end

function pop.enter()
  sync_screen()
  cursor_custom()
  bubble.px, bubble.py = love.mouse.getPosition()
  bubble.burst = { }
  pop.relevel()
  win_reset("pop")
end

-- Respawn a fresh bubble at the current notch (a new level).

function pop.relevel()
  local r = pop_radius(pop_row())
  local x, y = pop_sample(r)
  pop_begin(x, y, r)
end

function pop.leave()
  cursor_show()
end

-- Clickable while a bubble exists (growing or live)

function pop_active()
  return bubble.phase == "live" or bubble.phase == "grow"
end

function pop_inside()
  local r = bubble.r * bubble.scale
  local dx, dy = bubble.px - bubble.x, bubble.py - bubble.y
  return dx * dx + dy * dy <= r * r
end

-- Particle burst scattering from the bubble center

function pop_add_particle(i)
  local a = rand_range(0, 2 * math.pi)
  local lo = BURST.speed * BURST.min_speed_frac
  local sp = rand_range(lo, BURST.speed)
  bubble.burst[i] = {
    x = bubble.x,
    y = bubble.y,
    vx = math.cos(a) * sp,
    vy = math.sin(a) * sp,
    life = BURST.life
  }
end

function pop_spawn_burst()
  bubble.burst = { }
  for i = 1, BURST.count do
    pop_add_particle(i)
  end
end

-- On-target left click: score, pop sound, burst, then
-- shrink out and queue the next bubble's position.

function pop_hit()
  win_success()
  play(SND.pop)
  pop_spawn_burst()
  local row = pop_row()
  local nr = pop_radius(row)
  bubble.new_x, bubble.new_y = pop_far_point(nr, row)
  bubble.pop_s0 = bubble.scale
  bubble.phase = "pop"
  bubble.t = 0
end

-- Off-target click: silent, but counted; the 3rd fires a
-- struggle (once per spawn).

function pop_miss()
  bubble.off = bubble.off + 1
  if not bubble.struggled
       and POP.struggle_clicks <= bubble.off
  then
    bubble.struggled = true
    win_miss()
  end
end

function pop_left(button)
  return button == 1 or button == "left"
end

function pop_pressed(button)
  if not pop_left(button) or not pop_active() then
    return 
  end
  if pop_inside() then
    pop_hit()
  else
    pop_miss()
  end
end

-- Move and reflect a drifting bubble within the field

function pop_reflect()
  local r = bubble.r
  if bubble.x < r or APP.field_w - r < bubble.x then
    bubble.vx = -bubble.vx
    bubble.x = clamp(bubble.x, r, APP.field_w - r)
  end
  if bubble.y < r or APP.height - r < bubble.y then
    bubble.vy = -bubble.vy
    bubble.y = clamp(bubble.y, r, APP.height - r)
  end
end

function pop_drift(dt)
  if bubble.vx == 0 and bubble.vy == 0 then
    return 
  end
  bubble.x = bubble.x + bubble.vx * dt
  bubble.y = bubble.y + bubble.vy * dt
  pop_reflect()
end

-- Live: age, drift, and the no-pop struggle at 15 s

function pop_live(dt)
  bubble.age = bubble.age + dt
  pop_drift(dt)
  if not bubble.struggled
       and POP.struggle_t <= bubble.age
  then
    bubble.struggled = true
    win_miss()
  end
end

function pop_grow(dt)
  bubble.t = bubble.t + dt
  bubble.age = bubble.age + dt
  bubble.scale = math.min(1, bubble.t / POP.grow_t)
  if POP.grow_t <= bubble.t then
    bubble.phase = "live"
    bubble.scale = 1
  end
end

-- Pop: shrink to zero, then wait out the respawn delay
-- (measured from the click) before growing the next one.

function pop_anim(dt)
  bubble.t = bubble.t + dt
  local sh = 1 - bubble.t / POP.pop_t
  bubble.scale = bubble.pop_s0 * math.max(0, sh)
  if POP_RESPAWN <= bubble.t then
    pop_begin(bubble.new_x, bubble.new_y, pop_radius(pop_row()))
  end
end

POP_PHASE = {
  grow = pop_grow,
  live = pop_live,
  pop = pop_anim
}

function pop_update_burst(dt)
  for _, p in ipairs(bubble.burst) do
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt
    p.life = p.life - dt
  end
end

function pop.update(dt)
  bubble.px, bubble.py = love.mouse.getPosition()
  bubble.px = clamp(bubble.px, 0, APP.field_w)
  POP_PHASE[bubble.phase](dt)
  pop_update_burst(dt)
end

pop.pressed = pop_pressed

-- Drawing

function pop_draw_bubble()
  local r = bubble.r * bubble.scale
  if r <= 0 then
    return 
  end
  set_color(POP_FILL, POP.fill_a)
  gfx.circle("fill", bubble.x, bubble.y, r)
  set_color(POP_RIM)
  gfx.setLineWidth(POP.rim_w)
  gfx.circle("line", bubble.x, bubble.y, r)
  set_color(POP_HI, POP.hi_a)
  gfx.circle(
    "fill",
    bubble.x - r * POP.hi_off,
    bubble.y - r * POP.hi_off,
    r * POP.hi_r
  )
end

function pop_draw_burst()
  for _, p in ipairs(bubble.burst) do
    if 0 < p.life then
      set_color(POP_RIM, p.life / BURST.life)
      gfx.circle("fill", p.x, p.y, BURST.r)
    end
  end
end

function pop.draw()
  gfx.clear(POP_BG)
  pop_draw_bubble()
  pop_draw_burst()
  draw_pointer(bubble.px, bubble.py)
end

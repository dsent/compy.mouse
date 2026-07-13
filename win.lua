-- win.lua
-- Shared progress gauge for the mouse mini-games, matching
-- the keyboard Hunt model. A signed forgiving counter g
-- rises on a success and eases on a struggle; it is drawn
-- 0..goal, so a negative reads as empty (no punitive drain).
-- At goal it wins: a calm "Good job!" (win sound) below the
-- top notch, or wow + firework at the top. A click advances
-- (win_advance): notch +1 and a fresh level, or -- at the top
-- notch, or in Meet, which has no notch -- a fresh review
-- level. A sustained miss streak (g at GAUGE_DEMOTE, above
-- the floor notch) eases the notch down with a head start.
-- Games opt in: win_reset(name) on enter, then win_success /
-- win_miss on each outcome, and a relevel() that respawns
-- their target at the current notch.

WIN = {
  g = 0,
  goal = 0,
  won = false,
  top = false,
  lock = 0,
  fw = { }
}

-- Per-game facts

function win_goal(name)
  return GAUGE_GOAL[name]
end

function win_notched(name)
  return games[name].notched == true
end

function win_at_top(name)
  return win_notched(name)
       and notch_level(name) >= NOTCH.max
end

-- Set the gauge for a fresh level at the current notch. frac
-- seeds g as a fraction of the goal (0 normally; a head start
-- after an ease-down). No target respawn -- that is relevel.

function win_set_gauge(name, frac)
  WIN.goal = win_goal(name)
  WIN.g = math.floor(WIN.goal * frac)
  WIN.won = false
  WIN.top = win_at_top(name)
  WIN.lock = 0
  WIN.fw = { }
end

-- Enter/reset the gauge for the active game (g = 0)

function win_reset(name)
  win_set_gauge(name, 0)
end

-- A fresh level: respawn the game's target at the current
-- notch, then reset the gauge (frac seeds g).

function win_start_level(name, frac)
  games[name].relevel()
  win_set_gauge(name, frac)
end

-- The gauge filled: freeze into the celebration. wow +
-- firework at the top notch, otherwise the calm win sound.

function win_fill()
  WIN.won = true
  WIN.lock = CELEB.lock
  if WIN.top then
    play(SND.wow)
    fw_start()
  else
    play(SND.win)
  end
end

-- A success: fill by one; the goal-th wins.

function win_success()
  if WIN.won then
    return
  end
  WIN.g = WIN.g + 1
  if WIN.goal <= WIN.g then
    win_fill()
  end
end

-- Ease the notch down one step (above the floor) and start a
-- fresh level with a head start, so a child climbs back fast.

function win_demote(name)
  notch_shift(name, -1)
  win_start_level(name, GAUGE_HEAD)
end

-- After a miss lowers g, either floor it (Meet or the floor
-- notch: no demotion, no failure) or ease the notch down.

function win_check_demote()
  local name = GS.active
  local floored = not win_notched(name)
       or notch_level(name) <= NOTCH.min
  if floored then
    WIN.g = math.max(WIN.g, GAUGE_DEMOTE)
  elseif WIN.g <= GAUGE_DEMOTE then
    win_demote(name)
  end
end

-- A struggle: ease the gauge by one (survivable, forgiving).

function win_miss()
  if WIN.won then
    return
  end
  WIN.g = WIN.g - 1
  win_check_demote()
end

-- Click on the celebration: climb a notch (unless at the top
-- or unnotched) and start a fresh level; the top notch and
-- Meet loop a fresh review level instead.

function win_advance()
  local name = GS.active
  if win_notched(name) and not win_at_top(name) then
    notch_shift(name, 1)
  end
  win_start_level(name, 0)
end

-- Firework: colored sparks from three burst points, arcing
-- out under gravity and fading. Reserved for a top-notch win.

function fw_spark(cx, cy)
  local a = love.math.random() * 2 * math.pi
  local sp = FW.speed_lo + love.math.random() * FW.speed_span
  local life = FW.life_lo + love.math.random() * FW.life_span
  local p = { x = cx, y = cy }
  p.vx = math.cos(a) * sp
  p.vy = math.sin(a) * sp - FW.rise
  p.life = life
  p.max = life
  p.col = FW_COLORS[love.math.random(1, #FW_COLORS)]
  WIN.fw[#WIN.fw + 1] = p
end

function fw_burst(cx, cy)
  for _ = 1, FW.count do
    fw_spark(cx, cy)
  end
end

function fw_start()
  WIN.fw = { }
  fw_burst(APP.width * 0.5, APP.height * 0.36)
  fw_burst(APP.width * 0.3, APP.height * 0.52)
  fw_burst(APP.width * 0.7, APP.height * 0.52)
end

function fw_update(dt)
  local keep = { }
  for _, p in ipairs(WIN.fw) do
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt
    p.vy = p.vy + FW.grav * dt
    p.life = p.life - dt
    if 0 < p.life then
      keep[#keep + 1] = p
    end
  end
  WIN.fw = keep
end

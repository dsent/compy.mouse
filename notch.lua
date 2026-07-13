-- notch.lua
-- Difficulty-notch store for the skill-based mini-games
-- (find, pop). A game opts in with g.notched; Meet does not,
-- so the chords are a no-op there. The notch LEVEL persists
-- across menu exit and reenter and is the only state that
-- survives a mini-game reset; it zeroes at program start.
--
-- The gauge (win.lua) is the sole automatic driver now: it
-- climbs the notch on a fill and eases it on a miss streak.
-- The teacher chord (Ctrl+Alt+Up/Down) also moves the notch
-- and, like the gauge, starts a fresh level at the new notch.

NOTCH_LEVEL = { }

-- Zero every notched game's level at program start

function notch_init()
  for _, entry in ipairs(GAMES) do
    if games[entry.mod].notched then
      NOTCH_LEVEL[entry.mod] = 0
    end
  end
end

function notch_level(name)
  return NOTCH_LEVEL[name]
end

-- Shift the level by dir, clamped to the bounds. Returns
-- true only on a real change.

function notch_shift(name, dir)
  local v = clamp(NOTCH_LEVEL[name] + dir, NOTCH.min, NOTCH.max)
  if v == NOTCH_LEVEL[name] then
    return false
  end
  NOTCH_LEVEL[name] = v
  return true
end

-- Ctrl+Alt+Up / Down: one notch harder / easier on the active
-- game, then a fresh level at the new notch. No-op when the
-- active game does not use notches (e.g. Meet the mouse).

function notch_teacher(dir)
  local g = active_game()
  if not (g and g.notched) then
    return
  end
  if notch_shift(GS.active, dir) then
    win_start_level(GS.active, 0)
  end
end

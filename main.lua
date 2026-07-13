-- main.lua
-- Mouse program: a menu of mouse mini-games.
-- Holds the shared infrastructure (sound palette and
-- the mini-game menu) plus app state and LOVE
-- callbacks. Each mini-game lives in its own file.

require("constants")
require("notch")

gfx = love.graphics

-- Event -> library sound, played as compy.audio[name]().
-- move / cheese / pop use the micro:bit sounds added to
-- the compy.audio library (step / powerup / chirp);
-- hit / click / bell use the retro knock / ping / win.

SND = {
  move = "step",
  hit = "knock",
  cheese = "powerup",
  click = "ping",
  bell = "win",
  pop = "chirp",
  win = "win",
  wow = "wow"
}

function play(name)
  local fn = compy.audio[name]
  if fn then
    fn()
  end
end

-- Rate-limited play, keyed by event. Returns the new
-- timer so callers can store it back.

function play_gated(name, timer, gap)
  if 0 < timer then
    return timer
  end
  play(name)
  return gap
end

-- Cheese sound: play now, optionally arm a second
-- play after a short gap (drained in update_pause).
-- Set CHEESE.twice = false if the echo feels laggy.

function play_cheese()
  play(SND.cheese)
  if CHEESE.twice then
    mm.cheese_echo = CHEESE.echo_gap
  end
end

-- Built mini-games, in display order. Only built games
-- are listed; unbuilt ones are simply absent.

GAMES = {
  {
    key = "1",
    name = "Meet the mouse",
    mod = "meet"
  },
  {
    key = "2",
    name = "Find the glowing circle",
    mod = "find"
  },
  {
    key = "3",
    name = "Pop the bubble",
    mod = "pop"
  }
}

-- Menu lifecycle hooks. The menu is static, so these
-- are intentional no-ops; they mirror the game lifecycle.

function menu_init()
  notch_init()
end

function menu_update(dt)
  
end

-- Draw one numbered line

function draw_menu_line(i, entry)
  local y = MENU.y + (i - 1) * MENU.line_h
  gfx.setColor(COLOR_FG)
  gfx.print(entry.key .. ".  " .. entry.name, MENU.x, y)
end

function menu_draw()
  gfx.clear(COLOR_BG)
  gfx.setColor(COLOR_DIM)
  gfx.print("Mouse Games", MENU.x, MENU.title_y)
  for i, entry in ipairs(GAMES) do
    draw_menu_line(i, entry)
  end
end

-- Digit launches the matching built game

function menu_key(k)
  for _, entry in ipairs(GAMES) do
    if entry.key == k then
      open_game(entry.mod)
      return 
    end
  end
end

require("meet")
require("find")
require("pop")
require("win")

-- App state. mode is "menu" or "game"; active is the
-- module name of the running mini-game.

GS = {
  init = false,
  mode = "menu",
  active = nil,
  focused = true,
  saw_mouse = false,
  saw_touch = false
}

games = {
  meet = meet,
  find = find,
  pop = pop
}

-- Shared helpers

function clamp(value, lo, hi)
  return math.max(lo, math.min(value, hi))
end

function rand_range(lo, hi)
  return lo + love.math.random() * (hi - lo)
end

function decay(v, dt)
  return math.max(0, v - dt)
end

function radius_from_row(row, min_px)
  local d = math.max(row.size * APP.width, min_px)
  return d / 2
end

-- Placement samples inside the play rectangle: the field is
-- APP.width minus the reserved right strip (APP.field_w).

function random_field_point(m)
  local x = rand_range(m, APP.field_w - m)
  local y = rand_range(m, APP.height - m)
  return x, y
end

-- The farther of two coordinates from p, in either order.
-- Used to push a fallback as far from a point as allowed.

function pick_far(p, a, b)
  if math.abs(p - a) < math.abs(p - b) then
    return b
  end
  return a
end

-- Random in-field point at least `need` from (cx, cy).
-- Bounded rejection; if no try clears `need`, fall back
-- to the farthest field corner (>= need when possible).

function far_point(cx, cy, need, m)
  for _ = 1, SAMPLE_TRIES do
    local x, y = random_field_point(m)
    local dx, dy = x - cx, y - cy
    if need * need <= dx * dx + dy * dy then
      return x, y
    end
  end
  return pick_far(cx, m, APP.field_w - m),
       pick_far(cy, m, APP.height - m)
end

-- Cursor: custom (OS cursor hidden, absolute) vs shown

function cursor_custom()
  love.mouse.setRelativeMode(false)
  love.mouse.setVisible(false)
end

function cursor_show()
  love.mouse.setVisible(true)
end

-- Restore the system cursor and leave relative mode, for
-- both a normal game exit and any quit path.

function cursor_release()
  love.mouse.setRelativeMode(false)
  cursor_show()
end

-- Game control

function open_game(name)
  GS.active = name
  GS.mode = "game"
  games[name].enter()
end

function close_game()
  games[GS.active].leave()
  GS.active = nil
  GS.mode = "menu"
  WIN.won = false
  WIN.fw = { }
end

function ensure_init()
  if GS.init then
    return
  end
  UI_FONT = gfx.newFont(FONT_SIZE)
  BIG_FONT = gfx.newFont(FONT_BIG)
  gfx.setFont(UI_FONT)
  menu_init()
  GS.init = true
end

-- Shift state for the reset chord

function shift_down()
  local d = love.keyboard.isDown
  return d("lshift") or d("rshift")
end

function ctrl_down()
  local d = love.keyboard.isDown
  return d("lctrl") or d("rctrl")
end

function alt_down()
  local d = love.keyboard.isDown
  return d("lalt") or d("ralt")
end

-- Main loop

-- Focus loss freezes the game and shows a calm
-- message; regaining focus resumes where it left off.

function love.focus(f)
  GS.focused = f
end

-- Any exit restores the cursor, so quitting mid-game
-- (e.g. Ctrl+Esc) never leaves it hidden or captured.

function love.quit()
  cursor_release()
end

-- Touch on Android arrives as a synthetic mouse event
-- with istouch = true; a real pointer event has it false.
-- We record which we have seen (for the no-mouse screen)
-- but never drop the event -- gameplay input must always
-- reach the active game, so a click is never swallowed.

function note_pointer(istouch)
  if istouch then
    GS.saw_touch = true
  else
    GS.saw_mouse = true
  end
end

function mouse_present()
  return GS.saw_mouse or not GS.saw_touch
end

-- The celebration freezes the game; the firework and the
-- input lock still tick so the sparks animate and an
-- in-flight click cannot skip the win.

function update_active(dt)
  if GS.mode ~= "game" then
    menu_update(dt)
    return
  end
  fw_update(dt)
  WIN.lock = decay(WIN.lock, dt)
  if WIN.won then
    return
  end
  games[GS.active].update(dt)
end

function love.update(dt)
  ensure_init()
  if not mouse_present() then
    return 
  end
  if GS.focused then
    update_active(dt)
  end
end

-- Dim the last frame and show the reconnect message.
-- Reads the window directly so it works before a game
-- has filled APP (e.g. focus lost on the menu).

function draw_reconnect()
  local w, h = love.graphics.getDimensions()
  gfx.setColor(0, 0, 0, RECONNECT.dim)
  gfx.rectangle("fill", 0, 0, w, h)
  gfx.setColor(COLOR_BG)
  gfx.print(RECONNECT.text, RECONNECT.x, RECONNECT.y)
end

-- Centered single-line caption in the foreground color

function draw_caption(text, cx, y)
  local font = gfx.getFont()
  local tw = font:getWidth(text)
  gfx.setColor(COLOR_FG)
  gfx.print(text, cx - tw / 2, y)
end

-- Shown program-wide when no external mouse is present:
-- a centered mouse with an unplugged USB plug beside it
-- and a teacher-facing caption below. Reads the window
-- directly so it works before any game has filled APP.

function draw_no_mouse()
  local w, h = love.graphics.getDimensions()
  gfx.clear(COLOR_BG)
  local s = h * NO_MOUSE.icon_h / SP.h
  draw_plug_pair(w / 2, h / 2, s)
  draw_caption(NO_MOUSE.text, w / 2, h / 2 + NO_MOUSE.text_dy)
end

-- The field, then either the celebration screen (won) or the
-- play-time gauge and exit hint.

function draw_game()
  games[GS.active].draw()
  if WIN.won then
    draw_win_overlay()
  else
    draw_gauge()
    draw_hints()
  end
end

function love.draw()
  if not mouse_present() then
    draw_no_mouse()
    return
  end
  if GS.mode == "game" then
    draw_game()
  else
    menu_draw()
  end
  if not GS.focused then
    draw_reconnect()
  end
end

-- Input is dispatched to the active game. A game
-- implements only the handlers it needs; missing
-- ones mean the event is ignored.

function active_game()
  if GS.mode == "game" then
    return games[GS.active]
  end
  return nil
end

-- Route an input event to the active game's handler,
-- if it has one. No-op in the menu (no active game).

function route_input(name, ...)
  local g = active_game()
  if g and g[name] then
    g[name](...)
  end
end

function love.mousemoved(x, y, dx, dy, istouch)
  note_pointer(istouch)
  if WIN.won then
    return
  end
  route_input("moved", dx, dy)
end

-- A click on the celebration advances (notch bump + fresh
-- level, or a loop at the top); the lock ignores a click
-- that lands in the first moments so the win registers.

function love.mousepressed(x, y, button, istouch)
  note_pointer(istouch)
  if WIN.won then
    if WIN.lock <= 0 then
      win_advance()
    end
    return
  end
  route_input("pressed", button)
end

function love.mousereleased(x, y, button, istouch)
  note_pointer(istouch)
  if WIN.won then
    return
  end
  route_input("released", button)
end

function love.wheelmoved(x, y)
  GS.saw_mouse = true
  if WIN.won then
    return
  end
  route_input("wheel", y)
end

-- Raw Esc is right-click; Shift+Esc is the back-to-menu
-- chord. Ctrl+Esc is compy's reset; it does not fire
-- love.quit, so the keypress is our only hook -- release
-- the cursor here so it survives the reset.

function handle_escape()
  if ctrl_down() then
    cursor_release()
  elseif shift_down() then
    close_game()
  else
    route_input("right")
  end
end

-- Ctrl+Alt+Up / Down adjust the active game's notch.
-- The arrow keys are reserved: plain arrows are ignored
-- (no mini-game uses them) and never reach game input.

function handle_notch_chord(k)
  if not (ctrl_down() and alt_down()) then
    return 
  end
  notch_teacher(k == "up" and 1 or -1)
end

function key_escape()
  if GS.mode == "game" then
    handle_escape()
  end
end

function love.keypressed(k)
  if k == "up" or k == "down" then
    handle_notch_chord(k)
  elseif k == "escape" then
    key_escape()
  elseif GS.mode == "menu" then
    menu_key(k)
  end
end

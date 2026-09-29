# Mouse Games (Compy)

The `mouse` program from `spec/mouse.md`: a digit-launched
menu of mouse mini-games on LÖVE2D. Same house style as maze
and pong3d — global functions, one state table, dispatch
tables, no defensive code, SVG2LÖVE sprites.

This build implements the menu, the shared infrastructure
(difficulty notches + teacher chords, the no-mouse screen,
the `Shift+Esc` / `Ctrl+Esc` key rules), and all
three mini-games — **Meet the mouse**, **Find the glowing
circle**, and **Pop the bubble** — in full. The menu lists
only built games.

## Files

- **constants.lua** — layout, palette, Meet-the-mouse tuning,
  the shared notch convention (`NOTCH`) and no-mouse screen
  (`NO_MOUSE`, `PLUG`).
- **notch.lua** — shared difficulty-notch mechanism: per-game
  level (persists across reenter), auto-match streaks and
  cooldown (run state), and the teacher-chord entry point.
- **main.lua** — entry point, app state, dispatch, callbacks,
  plus the shared infrastructure: the sound palette
  (`play(name)` over the standard `compy.audio` lib and local
  game files) and the digit-launched mini-game menu.
- **meet.lua** — Meet the mouse in full: state, motion, sounds,
  input, cheese placement, barrier, cheese delight.
- **find.lua** — Find the glowing circle: target lifecycle
  (live / won / swap), cool->warm transition, glow pulse, and
  the notch-driven auto-match (clean / struggle / neutral).
- **pointer.lua** — shared enlarged high-contrast pointer for
  the goal-based mini-games (find, pop).
- **pop.lua** — Pop the bubble: bubble lifecycle (grow / live
  / pop), particle burst, optional drift at the top notch, and
  the click-based auto-match (clean / neutral / struggle).
- **mousedraw.lua** — sprite frame, layers, tilt, highlights,
  the wheel scroll, and the procedural barrier; draws the
  transpiled cheese prop.
- **MOUSE_*.lua, CHEESE.lua, LOGO_WINK_*.lua** — mouse sprite
  layers and props in SVG2LÖVE transpile format, one file per
  element. The tintable ones have their baked `gfx.setColor`
  removed (see Tinted layers).

## How it maps to the spec

- Menu: digits launch built games only; `Shift+Esc` returns.
- Playfield: a quiet light field; the light mouse reads
  clearly. The body outline is baked near-black.
- Mouse follows pointer delta with light smoothing; system
  cursor hidden; edges are walls with a stop-and-bump recoil;
  body tilts up to 8° toward travel; a soft shadow sits under
  the mouse (flat, so a bump lift reads against it).
- Buttons: left/right/wheel-click light in per-button LEGO
  colors with a soft additive glow that eases in on press and
  fades back on release. The base logo is a monochrome gray
  mark and turns colorful (the winking brand mark) during the
  cheese delight.
- Wheel scroll: 3 pellets wrapped continuously, speed from
  scroll input, decaying — separate from wheel-click highlight.
- Cheese: one at a time, respawn ≥ 1/3 screen diagonal from the
  mouse, never over the barrier or margin. Placement runs a few
  tries per frame and relaxes the distance each frame, so the
  main loop never blocks and the mouse keeps following smoothly.
- Cheese delight: brief pause, satisfied sound, buttons blink
  LEGO colors, logo winks.
- Barrier: appears at the 5th cheese, swaps position every 3rd
  after (8, 11, …) during the cheese pause with a fade; shape,
  orientation, and length sampled once per session. Placement
  keeps the rotated bounding box inside the playfield with a 2%
  margin (the center is inset by the bbox half-extent).
- The right button lights while it is held; plain `Esc` does
  nothing; `Shift+Esc` is back-to-menu; `Ctrl+Esc` unbound.

## Shared infrastructure

- **Difficulty notches** (`notch.lua`): the level range, streak
  thresholds, and cooldown live in `NOTCH`. A skill-based game
  opts in with `notched = true` and reads its level via
  `notch_level(name)`; it reports each target outcome with
  `notch_report(name, "clean"|"struggle")`. Three clean
  successes bump up, two struggles bump down, with a 15 s
  cooldown between auto-shifts; any change resets the streaks.
  The level is the only state that persists across menu
  exit/reenter — `open_game` resets the run state, `enter`
  resets the rest. Meet the mouse does not opt in, so the
  chord is a no-op there (still reserved).
- **Teacher chords**: `Ctrl+Alt+Up`/`Down` call `notch_teacher`,
  shifting the active game's level by one and bypassing the
  cooldown. The arrow keys are reserved and never reach game
  input; plain arrows are ignored.
- **No-mouse screen** (`draw_no_mouse`): shown once touch input
  has occurred without any real pointer event (a touch-only
  device); a connected mouse is assumed present, so the screen
  does not flash at launch — a centered mouse with an unplugged
  USB plug and the caption `Plug in the mouse.` (see Known
  limitations).

## Find the glowing circle

- One target at a time on a dark field; size, spawn pause,
  relocation distance, and edge-spawn come from the notch
  table (`FIND_NOTCH`), with the circle never below 60 px.
- Movement is the only input (clicks, wheel and Esc ignored).
  The pointer position is read each frame from the OS; entry
  is a point-in-circle test against it.
- On entry the target cross-fades cool->warm over 0.3 s and a
  bell plays; after the notch spawn pause it cross-fades out
  while a new target fades in at least the relocation distance
  away. The glow pulses on a 1 s period.
- Auto-match: entry within 4 s is a clean success; 12 s with no
  entry fires one struggle per spawn; an entry between is
  neutral (breaks the clean streak only). Three cleans bump
  up, two struggles bump down, via the shared notch mechanism.
- The enlarged high-contrast pointer is drawn by the program
  (system cursor hidden).

## Pop the bubble

- One bubble at a time on a light field; size, respawn delay,
  relocation distance, and drift come from the notch table
  (`POP_NOTCH`), never below 60 px. Translucent fill, rim, and
  a bright highlight read it as a bubble.
- Movement positions the pointer; a left click inside pops it
  (shrink to zero over 0.2 s, a particle burst, a soft pop),
  then a new bubble grows in over 0.3 s after the respawn delay
  (timed from the click), at least the relocation distance
  away. Right/wheel clicks and scroll are ignored; clicks
  outside a bubble are silent.
- Drift (notch +2 only): the bubble moves in a straight line at
  20 px/s and reflects off the screen edges.
- Auto-match: a pop with at most one off-target click is clean
  (one fidget click forgiven); a second off-target makes it
  neutral; a third off-target, or 15 s with no pop, fires one
  struggle per spawn. Three cleans bump up, two struggles bump
  down, via the shared notch mechanism.

## Sound

`play(name)` calls `compy.audio[name]` -- all sounds come from
the standard library. Event-to-sound mapping (`SND` in
`main.lua`):

- wall/barrier hit -> `knock`, button click -> `ping`,
  find hover -> `win` -- retro library sounds.
- movement -> `step`, cheese delight -> `powerup` (played
  twice), bubble pop -> `chirp` -- micro:bit library sounds.

The movement/cheese/pop sounds are micro:bit built-in sounds
(MIT, Lancaster University) -- see `SOUND-LICENSE.md`.

## Tinted layers

The button, wheel, logo, and cheese layers take their color
at runtime — buttons light up in per-button LEGO colors on
press, blink during the cheese delight, and the cheese is
tinted yellow. The mouse sprite SVGs carry a marker fill
(`#0065FE`) so the artwork reads in a vector editor, but that
color must NOT reach the output, or the baked `gfx.setColor`
overrides the runtime tint and the layer is stuck blue.

The transpiler bakes each element's SVG fill into a
`gfx.setColor` before the draw. So after transpiling the
tintable layers, the `gfx.setColor(...)` lines are removed by
hand (one pass), leaving the runtime to set the color before
each layer call. Affected files: `MOUSE_BTN_L`, `MOUSE_BTN_R`,
`MOUSE_WHEEL`, `MOUSE_LOGO`, `CHEESE`. The wink phases
(`LOGO_WINK_*`) keep their colors — they are the colored brand
mark, not tinted.

These five files are therefore treated as finished project
assets, not transpiler output: do NOT re-run them through the
transpiler without redoing the strip. If a layer's SHAPE
changes in the SVG, re-transpile it and remove `gfx.setColor`
again (one pass):

    for f in MOUSE_BTN_L MOUSE_BTN_R MOUSE_WHEEL \
             MOUSE_LOGO CHEESE; do
      sed -i '' '/^gfx\.setColor(/d' "$f.lua"   # macOS
    done

TODO (transpiler, future): add a "tintable" mode — a flag or a
marker fill the transpiler recognizes and emits without a
baked `gfx.setColor`, so the manual strip is no longer needed.
Until then the manual pass above is the agreed approach.

## Adding a mini-game

A mini-game is a table registered in `games` with an entry in
`GAMES` (key, name, module). It exposes:

- `enter()` / `leave()` — open / close
- `update(dt)` / `draw()`
- optional input methods, dispatched generically by main and
  called only if present: `moved(dx, dy)`, `pressed(button)`,
  `released(button)`, `wheel(dy)`. A game implements only
  what it needs; other events are ignored.

A new mini-game: write its file with this contract, add a
line to `GAMES` and `games`. No changes to main's callbacks.

## Known limitations

- Tintable layers need a manual `gfx.setColor` strip after
  transpiling (see Tinted layers).
- The wink phases (`LOGO_WINK_*`) are authored in a 200x250
  box while the body logo sits in the lower half of the
  250x440 body, so the runtime places the phases onto the
  body-logo position for the wink to land in place.
- Audio is limited to the standard library (`compy.audio`);
  movement/cheese/pop use micro:bit sounds (`step`, `powerup`,
  `chirp`) added to that library. Layer `.lua` files load via
  `require` from the program directory.
- `mouse_present()` is heuristic. SDL 2.28.5 exposes no
  mouse-presence query and no connect/disconnect event, so the
  program assumes a mouse is present at launch and shows the
  no-mouse screen only on positive evidence of touch-only use:
  a touch event (`istouch = true`) with no prior real pointer.
  A real pointer event (`istouch = false`) is decisive for the
  session. Consequences: a connected mouse never triggers the
  screen (no launch flash), but a truly mouse-less device shows
  the menu until the first touch and the screen after it; a
  built-in trackpad sends `istouch = false` and counts as a
  mouse, so it is not excluded; and there is no disconnect
  event.
  
# AGENTS.md — NEON SIN handoff notes

> Read this before touching the codebase. Update it after finishing work
> that changes state or conventions. This file is the single source of
> truth for agents picking up leftovers — keep it accurate, not complete.

- **Project**: *NEON SIN* — a 2D side-scroller built with **Godot 4.7**
  (Forward+), Windows build target. A learning/portfolio game: gameplay
  programming, combat, UI/HUD, bosses, dialogue.
- **Run**: open `project.godot` in the Godot editor; main scene is
  `res://scenes/menu/MainMenu.tscn`, F5 runs the game. No Godot CLI on
  this machine — see *Verification limits* at the bottom.
- **Project root**: repo root. Code lives in `scripts/`, scenes in
  `scenes/`, art in `art/`, audio in `audio/`.

## Folder map

```
art/
  font/Peaberry Bitmap Fonts/   # itch font pack — DO NOT load directly (see Fonts)
  font/dialogue_font/           # clean, working copy of the dialogue font
  ui/Dialogue/                  # box, nameplate, choice, arrow textures
  ui/PlayerHUD/                 # HP/SP bars + portrait frame (face baked in)
audio/    music/ + sfx/
scenes/   enemies(Crow) / levels(Level1) / menu(Main, Pause, Settings) /
          player(Player) / ui(hud, boss_hud, dialogue_box, dialogue_intro)
scripts/  dialogue / enemies(Crow) / levels / player / ui / systems(empty)
```

## What works / verified as of 2026-10-10- Player movement, jump, run, dash (Shift) with stamina + i-frames +
  dash ghost layer; boss push-out fixed. Dash feel (2026-10-10):
  kept at the original 620/0.55 with the 9-fps dash anim — user tested
780/0.35 and 950/0.208333 and rejected both as too fast.
Attacks can no longer cancel a dash (J mid-dash is swallowed; only
gethit/death interrupt dashes). Camera2D now has position_smoothing
(speed 12; off before) so fast dashes no longer make the camera
hitch — user reported a one-beat stall passing the boss; root cause
was the unsmoothed camera following a 13 px/tick physics jump. F5 to
confirm feel.
- Combat: knockback, control stun, death; HP/SP HUD.
- Boss AI (detection, chase, attack with cooldown) + boss HP bar.
- Main menu with animated background; pause menu (Escape) reusing the
  settings scene (`scenes/menu/SettingsMenu.tscn`); volumes saved to a
  config file.
- Audio: looping music, attack voice, hit SFX; buses in
  `default_bus_layout.tres`.
- Dialogue system v2 (below) — playable, but visual pass not yet
  human-verified (see Known left-overs).

## Dialogue system (recent, active)

- Engine: autoload `DialogueManager`
  (`scripts/dialogue/dialogue_manager.gd`) + UI `DialogueBox`
  (`scripts/dialogue/dialogue_box.gd`). Both have hand-written scene
  wrappers: `scenes/ui/dialogue_box.tscn` and
  `scenes/ui/dialogue_intro.tscn`, instantiated by the `IntroDialogue`
  node in `scenes/levels/Level1.tscn`.
- **The DialogueBox UI is built entirely in code** — do not recreate it
  as a `.tscn` layout; constants at the top of `dialogue_box.gd` are
  the layout.
- Data-driven conversations: `scripts/dialogue/intro_dialogue.gd`
  (speaker "sickyturtlez", English text) exposes `get_intro_lines()`
  and `get_branch(choice_index)`; the trigger lives in
  `scripts/dialogue/dialogue_intro.gd` on the `IntroDialogue` node in
  `scenes/levels/Level1.tscn`.
- Flow: `await DialogueManager.start_conversation(lines)` → returns last
  choice index. Line shapes:
  - `{"speaker": s, "say": text}`
  - `{"speaker": s, "ask": {"text": t, "options": [..]}}` (choice line)
- During a conversation the tree pauses (`get_tree().paused`), but the
  DialogueBox and manager run with `PROCESS_MODE_ALWAYS`, and
  `LevelMusic` keeps playing.
- Input: J (action `attack`) advances/confirms, W/S (actions
  `choice_up` / `choice_down`, added to project.godot as hand-written
  Objects) pick a choice. Keyboard only, no mouse; Escape is swallowed
  so the pause menu can't open mid-dialogue. J's first press while
  typing skips to the full line.
- Visual layout (design-space 1920×1080 on a scale-to-viewport panel):
  box strip 1580×248 at bottom, portrait frame bottom-left (same 248
  height), nameplate overhanging the box top by 42 px, choices stacked
  above the box right-aligned, blinking arrow inside the highlighted
  choice hugging its right edge (z_index 10).
- Text alignment (2026-10-10): choice text and nameplate text are
  **left-aligned**; both nudged upward inside their frames via negative
  `offset_bottom` (−12 choices, −14 nameplate).

## Fonts — important gotchas (cost several rounds)

- Godot only parses BMFont **text/binary v3** `.fnt`. The `(XML)`
  variants inside `art/font/Peaberry Bitmap Fonts/` are NOT text
  variants and render hex-code garbage boxes. Never load those.
- Working font: `res://art/font/dialogue_font/WhitePeaberryOutline.fnt`
  — a copy of the text variant with its page PNG copied next to it
  (originals in the itch pack point to a PNG elsewhere and import as
  `valid=false`).
- Peaberry is a 16 px bitmap font: crisp only at whole multiples — use
  sizes 16/32/48. Body 48, choices 32, nameplate 32.
- Outline is baked into the glyph texture; label fill = `Color.WHITE`.

## House style

- GDScript: tabs, 2 blank lines between top-level funcs, no blank line
  right after `func ...:`, comments in English, short, explain *why*.
- When touching scenes: preserve existing `uid=` attributes and node
  order.
- project.godot: input actions are hand-written Objects — keep that
  format when adding new actions.
- UI layout constants live as `const NAME_*` at the top of the script
  that builds them (dialogue_box.gd is the pattern); derive child
  constants from parent ones (e.g. `NAMEPLATE_POS.y = BOX_POS.y - 42`)
  so a single-size change stays consistent.
- Godot anchor-preset trap: `set_anchors_preset(PRESET_FULL_RECT)`
  resets offsets — set `offset_*` AFTER the preset call (this bug was
  hit and fixed in the dialogue labels).

## Changelog

- 2026-10-10 — Dialogue UI polish: left-aligned choice + nameplate
  text, text nudged upward (offset_bottom −12/−14 set after the anchor
  preset; earlier bug had it set before the preset and got reset),
  nameplate frame kept at 42 px overhang, cleaned leftover
  `.tmp` scenes in scenes/levels, added this AGENTS.md, updated README
  with dialogue feature + controls.
- 2026-10-10 (later) — Dash tuning attempts 620→780→950 with
anim 9→16→24 fps, all reverted per user feedback ("too fast");
final: original 620/0.55 + 9 fps anim. Kept: attack can no longer
cancel a dash (removed _stop_dash() from start_attack, removed the
animation!="dash" early-exit, _physics_process ignores J while
is_dashing). Camera2D got position_smoothing_enabled=true,
speed 12 (user reported camera hitch when dashing past the boss).
- 2026-10-10 (later) — Installed Godot 4.7.2 CLI at
  `~/.local/bin/godot.exe` (winget package + manual shim, user PATH);
  verified `--import`, `--check-only`, `--quit-after 2` headless on this
  repo. Verification-limits section updated from "no CLI" to headless
  workflow.
- 2026-10-10 (earlier) — Dialogue system v2: manager + typewriter box,
  branching choices, pause-while-talking, intro trigger in Level1,
  choice_up/choice_down input actions, font cleanup into
  art/font/dialogue_font.
- Earlier — dash w/ stamina + i-frames, boss AI + push fix, pause +
  settings menus, audio bus layout.

## Known left-overs / next steps

1. **Dialogue visual pass not human-verified yet** (no Godot CLI on
   this machine): layout proportions, arrow position inside choice,
   nameplate overhang, text lift. If the user reports misalignment,
   constants live at the top of `scripts/dialogue/dialogue_box.gd`
   (BOX_*, NAMEPLATE_*, PORTRAIT_*, TEXT_*, CHOICE_*).
2. `dialogue_intro.tscn` / `dialogue_box.tscn` use hand-written uids
   (`uid://cqmenu0intro`, `uid://cqmenu0dialog`) — hand-picked UID strings
   are valid-form but collide-prone; Godot 4.4 swaps them in memory but does
   NOT reliably write the fix to disk on open (verified behavior: engine
   issue #102490). If the editor complains, save the scene once so the
   regenerated uid persists; do not hand-edit uids again.
3. Intro dialogue branch copy is placeholder story text
   (`intro_dialogue.gd` `LINES_1` / `LINES_2`, branched via
   `get_branch(choice_index)`) — copy needs story editing; reuse
   `get_branch` when adding more branches.

## Godot CLI (installed 2026-10-10)

- Godot 4.7.2-stable console binary at `C:\Users\Admin\.local\bin\godot.exe`,
  on user PATH (`~/.local/bin`); copy of the engine + console wrapper from
  the winget package lives in the same folder (wrapper requires the main
  exe named beside it).
- Headless checks an agent can run (all verified working):

  ```sh
  godot --headless --path . --import                # import assets
  godot --headless --path . --check-only --script scripts/path/File.gd   # parse-check one script
  godot --headless --path . --quit-after 2          # smoke-run the main scene
  ```

  A clean run exits 0; `--quit-after` may print benign
  "ObjectDB instances leaked" warnings at exit — normal for early quit.
- ⚠ `--check-only` does NOT see autoloads: scripts referencing
  `DialogueManager` fail on "Identifier not found" even when fine at
  runtime (runtime run of Level1.tscn + full editor scan both pass).
  For a strict autoload-aware check, run the scene headless:
  `godot --headless --path . res://scenes/levels/Level1.tscn --quit-after 60`.
- Headless cannot judge VISUAL layout (alignment, overhang): for anything
  the eye must judge, still ask the human to run F5.

## Verification limits

- Visual/functional confirmation still needs the human running F5 in the
  editor; fold their report back into *What works / verified*. Don't claim
  visual success from headless output.
- The user works in Vietnamese; keep code/comments in English per
  House style, answer the user in Vietnamese.
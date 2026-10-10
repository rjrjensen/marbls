# How Marbls Works

A tour of the code and the technology, written for someone new to Godot. Decisions and plans are in [DESIGN.md](DESIGN.md); the rules themselves are in [RULES.md](RULES.md).

## Contents

- [Godot in one minute](#godot-in-one-minute)
- [The big picture: one turn, start to finish](#the-big-picture-one-turn-start-to-finish)
- [The rules engine (`core/`)](#the-rules-engine-core)
- [How the board is built](#how-the-board-is-built)
- [The tilted camera](#the-tilted-camera)
- [How marbles move (animation)](#how-marbles-move-animation)
- [How card faces are drawn](#how-card-faces-are-drawn)
- [Sound](#sound)
- [Computer opponents](#computer-opponents)
- [Tests, lint and CI](#tests-lint-and-ci)
- [The web build and why the engine file is split](#the-web-build-and-why-the-engine-file-is-split)

## Godot in one minute

- **Godot is a game engine:** an editor app plus a runtime written in C++.
- **Scenes and nodes:** a game is a tree of **nodes** (a mesh, a light, a camera, a button...), saved as **scenes** (`.tscn` text files). Scenes can contain other scenes; a board contains 4 arm scenes, and each arm contains 18 hole scenes.
- **GDScript:** a Python-like language, attached to nodes as scripts. We require **static types** everywhere; untyped code fails to load (see `project.godot`).
- **Resources:** data files such as `.tres`, e.g. the AI personalities in `players/ai/profiles/`.
- **Signals:** how a node tells its parent that something happened (`tapped`, `draw_pressed`). The project-wide **SignalBus** (`autoloads/signal_bus.gd`) carries game-wide events.

## The big picture: one turn, start to finish

1. You tap **Draw**. The HUD (`ui/hud.gd`) emits `draw_pressed` up to the **GameController** (`game/game_controller.gd`).
2. The controller sends an **intent** (`MatchIntent.draw_card`) to the **match host** (`core/match/local_match_host.gd`).
3. The **Match** (`core/match/match.gd`) checks it's allowed, draws your card, and works out every legal move (`MoveGenerator`). It answers with **events**: `CARD_DRAWN`, ...
4. The controller plays the events one at a time: it flips the card, then shows ghost marbles for your choices.
5. You tap a ghost. The controller sends `choose_move`. The Match applies it (`MoveResolver`) and answers with `MARBLE_MOVED`, `MARBLE_KILLED`, `PLAY_AGAIN` or `TURN_STARTED`.
6. The board animates each event, and every event also goes out on the SignalBus.

The key rule: **the screen never changes the game state directly.** It only sends intents and animates events. That's why online play will be straightforward: a server runs the same `Match` and sends the same events over the network.

## The rules engine (`core/`)

Plain code with no scenes or graphics, so it's fast to test and can run on a server.
- **`BoardTopology`:** the board as numbers.
  - The Main Track is a ring of 14 spaces per arm: 56 for 4 players, 84 for 6.
  - Arm `a` exits at `14a`, its Home Base entrance is 2 before that, and the Fast Track corners are at `14k + 5`.
- **`Spot`:** where one marble is: Starting Block, Main Track index, Home Base slot, or Bull's Eye.
- **`MoveGenerator`:** lists every legal move for a card, covering Fast Track hops, Bull's Eye dives, Jack swaps, Seven splits and teams.
- **`Match`:** runs the turn order, cards, play-again, Fast Track chances and winning.
- **Randomness:** all of it comes from **one seeded random number generator**. A game can be saved to JSON and restored, and it continues *exactly* the same. A test checks this.
- **`RuleSet`:** every house-rule option. See [RULES.md → House rules](RULES.md#house-rules).

## How the board is built

The board is made entirely of simple 3D shapes; no 3D modeling tool was used.

| Piece | How it's made |
| --- | --- |
| The board | A flat **cylinder** (a disc) with a wood-colored material (`board/board.tscn`) |
| A hole | A thin dark cylinder slightly above the wood, plus an optional colored **torus** (ring) for the special holes (`board/hole.tscn`) |
| One arm | `board/arm.tscn`: 18 holes at fixed positions. The outer loop section, the Fast Track corner, and the Home Base lane. |
| A Starting Block | `board/starting_block.tscn`: 4 holes in a diagonal line |
| A marble | A **sphere** with a glossy material: low roughness plus a rim light (`board/marble.tscn`) |
| Lighting | One sun-like light that casts shadows, and soft ambient light (`game/game.tscn`) |

- **Placing the arms:** `BoardView` (`board/board_view.gd`) places one arm per player around the center, rotating each by 360° ÷ arms. That's how the same arm makes a triangle, square, hexagon or octagon board.
- **Holes and spots:** each hole knows which Main Track number or Home Base slot it stands for. That's how the code finds "the hole for this `Spot`".
- **Tests:** the board tests check that every track number has a hole exactly one hole-width from the next, for 2–8 players.

## The tilted camera

**The board never tilts; the camera does** (`board/board_camera.gd`).
- **The view:** the camera sits 62° above the table, looking down at the center through a *perspective* lens. Things nearer the camera look bigger, so your side of the board is the largest.
- **The pivot:** the camera is attached to an invisible pivot at the center of the board. Turning the pivot swings the camera around the table, which is how your side (or, in pass-and-play, the current player's side) ends up at the bottom.
- **Fitting the screen:** the distance adjusts so the whole board fits the screen in portrait or landscape.

## How marbles move (animation)

There's no physics; it's all **tweens**. A tween calls a function every frame for a set time with a value going from 0 to 1.
- **The hop** (`_hop()` in `board/board_view.gd`): for each hole along a marble's path, the position is
  - a **straight line** from the old hole to the new one: `start.lerp(target, t)`,
  - **plus a bump**: `sin(π·t) × height`. That's 0 at both ends and highest in the middle, so each step is a little arc.
- **Timing:** each hop takes 0.13 s. The code waits for one to finish before the next (`await`), then plays the click.
- **Longer jumps** (Fast Track hops, swaps) arc higher and take a bit longer.
- **Kills:** the victim "pops" (a quick scale-up) and flies back to its Starting Block on a tall arc, while the camera does a small shake.
- **Other tweens:** the pulsing glow, the Draw button pulse, the camera turn, and the card flip. The card flip squeezes the card's width to 0, swaps the back for the face, and grows it back.

## How card faces are drawn

There are no 54 card pictures. One scene, `ui/cards/card_face.tscn` (class `CardFace`), draws any card when you call `show_card(card)`:
- **The fixed parts live in the scene:** the cream card, the rank and small suit in two corners (the bottom one is the top one turned upside down), the framed crown for J, Q and K, and the Joker's big crown. Open the scene in the editor to see and move them.
- **The pips are placed by code**, because where they go depends on the rank. `ui/cards/card_face_layout.gd` (`CardFaceLayout`) is plain data: for a card it lists each pip's centre, size and whether it is upside down, in "card units" (the card is 50 wide and 70 tall). `CardFace` copies a hidden template pip once per entry.
- **Suit symbols are small SVG files** in `ui/cards/suits/`, drawn in white so the scene can tint them red or black (`self_modulate`). They are imported with mipmaps, which keeps them smooth when the card is drawn small.
- **One size fits all:** the art is laid out at 250x350 pixels and scaled to whatever size the parent gives the `CardFace`, so the same scene works as a big card or a tiny one.

The tests (`tests/presentation/test_card_face_layout.gd`) check that no two pips overlap and that pips stay clear of the corners, with a small gap. To see every face, run `tools/card_sheet.tscn` (F6 in the editor), or save a picture with `godot res://tools/card_sheet.tscn -- --screenshot sheet.png`.

## Sound

The click and the kill thud are **original sounds**, synthesized by `tools/make_sounds.py`:
- **Click:** a few short, fast-fading sine tones (glass) over a lower knock (wood).
- **Thud:** a low tone that drops in pitch, plus a noisy crack.

Each click is played at a slightly random pitch, so a run of hops doesn't sound mechanical.

## Computer opponents

Details are in [DESIGN.md → AI players](DESIGN.md#7-ai-players); the code is in `players/ai/`.
- **Scoring:** for every legal move, each **evaluator** gives a score, e.g. progress toward home, value of kills, safety from opponents' next cards, or the gamble factor.
- **Personality:** an **`AIProfile`** (a `.tres` file of sliders) weights those scores. The best total wins, plus random noise for sloppy personalities like Rookie.
- **Look-ahead:** the Grandmaster also thinks one card ahead using the cards still in its own deck.
- **Balance:** `scripts/simulate.sh` plays hundreds of computer-vs-computer games to check.

## Tests, lint and CI

- **Tests:** `scripts/test.sh` runs Godot headless (no window) with our own small test runner (`tests/test_runner.gd`).
  - Tests extend `TestCase` and name methods `test_*`.
  - The run fails on any failed assertion **or** any script error.
  - Highlights: random full games at 2–8 players, a save-and-restore that must continue identically, and the real game scene driven through hundreds of moves.
- **Lint:** `scripts/lint.sh` runs gdlint for style.
- **CI:** GitHub Actions runs **Lint** and **Headless tests** on every PR, plus **Build and deploy web**. Claude merges its own PRs only when all of them pass.

## The web build and why the engine file is split

**What a browser downloads:**
- `index.html`
- `index.js`: the engine loader
- **`index.wasm`: the whole Godot engine, compiled to WebAssembly, 39.5 MB**
- `index.pck`: our actual game, only about 100 KB

**The problem and today's fix:**
- **The limit:** Cloudflare Pages refuses any single file over 25 MB.
- **The split:** `scripts/build_web.sh` cuts `index.wasm` into two parts (about 20 MB each).
- **The joiner:** a small script in `export_presets.cfg` (`html/head_include`) intercepts the browser's request for `index.wasm`, downloads both parts, joins them in memory, and hands the result to the engine. The engine never knows.
- **Download size:** Cloudflare compresses the transfer to roughly 10 MB.
- **Templates:** `scripts/fetch_export_templates.py` pulls just the web templates (about 20 MB) out of Godot's 1.3 GB templates bundle, using HTTP range requests.

**Ways to get rid of the split** (decision pending):

1. **A slimmed-down engine build.** Compile Godot's web engine ourselves with unused features turned off (VR, navigation, video and so on).
   - The main win is faster loading on phones. It might also get under 25 MB.
   - The cost is a slow engine build in CI, cached and only redone on Godot upgrades.
2. **Cloudflare R2** (file storage) for the engine file, at something like `assets.marbls.co`.
   - Removes the limit, and we stay on Cloudflare.
   - Needs a payment method on file (there's a free tier) and a bit of setup.
3. **Serve the web game from the Fly.io server** (planned for online play), with Cloudflare in front as a cache.
   - The free-plan cache allows files up to 512 MB.
   - One pipeline for the game and the server.

Recommendation: 1 for speed, plus 3 once the server exists (or 2 sooner).

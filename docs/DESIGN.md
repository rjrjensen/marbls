# Marbles — Design & Implementation Plan

This is the starting map for building the digital version of Marbles. The rules themselves live in the [README](../README.md) and in Kelsey's `Marbles Game How to Play.docx`. This doc covers the tech choice, the architecture, how the game scales to different player counts, the rule questions still open, and the order to build things in.

---

## 1. Tech choice: Godot

**Godot is a game engine.** It is not a language or a library. You get:

- **An editor app** (Windows/macOS/Linux) where you build *scenes*: trees of *nodes* such as a board, a hole or a marble. They are saved as `.tscn` files.
- **A runtime** written in C++ that runs those scenes on each target platform.
- **A scripting language, GDScript.** It looks like Python and supports optional static typing. Godot also supports C# and C++ (via GDExtension).

It's free and open source (MIT license), with no royalties and no splash-screen requirement.

### Does it cover web + iOS + Android "natively"?

Yes, from a single codebase:

| Target | What Godot produces | What you need |
| --- | --- | --- |
| Web | WebAssembly + WebGL 2 build (an `index.html` plus `.wasm`/`.pck`) | Any static host (itch.io, GitHub Pages, Netlify). Use the **single-threaded** web export so you don't need special COOP/COEP server headers. |
| iOS | A native Xcode project that compiles to a real `.ipa` | A Mac with Xcode, and an Apple Developer account ($99/yr) |
| Android | A native `.apk`/`.aab` built through Gradle | The Android SDK/JDK (the editor can download them) and a Google Play developer account ($25 one-time) |
| Desktop (bonus) | Native Windows/macOS/Linux executables | Nothing extra |

About "native code for all platforms": the Godot engine itself is compiled to native machine code for iOS and Android, so the result is a real native app, not a web view wrapped in an app shell. Your game logic (GDScript) runs inside that native engine. If "native" meant writing three separate apps (Swift for iOS, Kotlin for Android, JS for web), that works against using Godot and roughly triples the work. The Godot approach is one game codebase, plus small platform plugins only where a store feature needs one (Game Center / Play Games, in-app purchases, haptics).

### GDScript vs C#

**Recommendation: statically typed GDScript.**

- **C# can't export to the web in Godot 4** (as of the 4.x releases to date; re-check before relying on this). Web is a first-class target for us, so C# is ruled out for now.
- **Typed GDScript satisfies "prefer strong typing."** Set the project's `untyped_declaration` warning to *Error* so untyped code fails to load.
- Every exported platform supports it, and its iteration speed in the editor is the best of the three options.

### Renderer

Use the **Compatibility** renderer (OpenGL ES 3 / WebGL 2). Marbles is a 2D board game, and Compatibility has the widest web and low-end mobile support.

---

## 2. Architecture

The key split is a **pure rules core** with no nodes and no rendering, and a **presentation layer** that only displays state and collects input. The rules core is what makes these possible:

- Unit tests for every rule
- AI opponents
- Online multiplayer later (the server runs the same core)
- House rules toggled at runtime ("Rules are subject to change, of course. Sometimes midgame!")

```
res://
├── autoloads/
│   └── signal_bus.gd          # SignalBus: game-wide events (see below)
├── core/                      # Pure rules. RefCounted/Resource only, no Nodes.
│   ├── cards/                 # CardRank (enum), Card, Deck
│   ├── board/                 # BoardTopology, TrackPosition, SeatLayout
│   ├── rules/                 # RuleSet (Resource), MoveGenerator, MoveResolver
│   ├── state/                 # GameState, PlayerState, TeamState
│   └── moves/                 # Move and its MoveStep parts (composition, not subclasses)
├── players/                   # PlayerController + HumanInput / AIInput components
│   └── ai/                    # Strategies: KelseyStrategy, JordanStrategy, ...
├── board/                     # Scenes: Board.tscn, Arm.tscn, Hole.tscn, Marble.tscn
├── ui/                        # Hand/deck view, HUD, menus, lobby / player-count picker
└── tests/                     # gdUnit4 or GUT test suites for core/
```

### How this maps to the CLAUDE.md rules

- **Strong typing.** Every variable, parameter and return is typed. Use enums (`CardRank`, `HoleKind`) and `class_name` types instead of strings and dictionaries.
- **Pass down, signal up.** `Game` passes `GameState` down to `Board` → `Arm` → `Hole` / `Marble`. Children emit signals upward, such as `Marble.selected` and `Hole.clicked`. Nothing reaches up with `get_parent()`.
- **SignalBus for game-wide events.** Examples: `turn_started(seat)`, `card_drawn(seat, card)`, `marble_moved(move)`, `marble_killed(victim, killer)`, `player_finished(seat)`, `game_over(winners)`. Sound, animation, HUD and analytics listen here. UI-local things like `Hole.clicked` stay as instance signals.
- **Composition over inheritance.**
  - A `PlayerController` *has* an input source (`HumanInput` or `AIInput`) and does not use subclasses for player kinds.
  - A `Move` is a list of `MoveStep`s (advance, retreat, enter-home, swap, enter-bullseye, kill) rather than a class per card.
  - Special card behaviour comes from data on `CardRank` plus the `RuleSet`, not from `SevenCard extends Card`.
- **Custom class names.** Use `class_name` on all core types (`Card`, `Deck`, `BoardTopology`, `GameState`, `RuleSet`, ...) for editor autocomplete and type checking.
- **Solidified geometry.** `Hole.tscn` and one `Arm.tscn` (13 track holes, fast-track corner, finish lane, starting block) are hand-built scene files. Only the *placement* of N arms around the hub is computed, because player count genuinely varies. We could also add an editor `@tool` script that bakes `Board3.tscn` … `Board8.tscn` into real scene files so they can be hand-tweaked.

### Board model: topology vs layout

The rules core never works with pixel positions. It sees a graph:

- **Main track:** a ring of `14 × arms` spaces. Each arm contributes 4 side + 5 end + 4 side + 1 corner.
- For seat `s` (with arm index `a`), counting clockwise from 0 at the start of the ring:
  - Starting Exit = `14a`
  - Home Base entrance = `14a − 2`
  - The seat's own Fast Track corner = `14a − 9`
- **Fast Track ring:** the `arms` corner spaces.
- **Bull's Eye:** one center node.
- Per seat: a **Starting Block** (4 slots) and a **Home Base** (4 slots).

The *layout* (`SeatLayout`) maps those nodes to positions on screen. That's the only part that changes when the number of arms changes.

---

## 3. Player counts

Four stays the default. The model separates two numbers:

- **arm count:** the board shape, one arm per possible seat
- **seat count:** how many people are playing

Every seat needs an arm, but an arm can be empty. An empty arm is still main track, it just has no start, home or colors.

Each arm adds 14 track spaces, so every marble travels further on bigger boards (about 14 × arms − 2 spaces for a full lap). Bigger boards mean longer games. That's covered under "Tuning" below.

| Players | Board | Track spaces | Team options | Notes |
| :---: | --- | :---: | --- | --- |
| **2** | Classic 4-arm, seats opposite | 56 | 1v1, or "doubles" (each person plays two colors) | A 2-arm board has no hub, so the Fast Track and Bull's Eye don't work. Reuse the classic board. |
| **3** | 3-arm triangle (alt: classic board with one empty arm) | 42 | Free-for-all | The triangle keeps it tight and fair. The empty-arm version gives the seat after the gap a free lane. |
| **4** | Classic 4-arm (default) | 56 | Free-for-all or 2v2 (partners opposite) | Exactly the physical board. |
| **5** | 5-arm pentagon (alt: 6-arm with one empty) | 70 | Free-for-all | |
| **6** | 6-arm hexagon (same idea as the six-player Aggravation board) | 84 | Free-for-all, 3 teams of 2, or 2 teams of 3 | Partners sit alternating or opposite. |
| **7–8** | 7- or 8-arm board | 98–112 | 8: 4 teams of 2, or 2 teams of 4 | Home blocks get tight in the narrow wedges. Probably needs a zoomable camera on phones. |

Sketches (generated by [`docs/images/generate_boards.py`](images/generate_boards.py) using the layout rules above; filled holes are Starting Exits, Fast Track corners and Home Base rows, and outlined colored holes are Starting Blocks):

| | | |
| :---: | :---: | :---: |
| ![2 players](images/board-2p.svg) | ![3 players](images/board-3p.svg) | ![4 players](images/board-4p.svg) |
| ![5 players](images/board-5p.svg) | ![6 players](images/board-6p.svg) | ![8 players](images/board-8p.svg) |

### Rules that need to scale

- **Fast Track.** It rides the ring of `arms` corners. On big boards it saves far more distance, so it becomes more powerful. That's probably fun, but watch it in playtesting.
- **Bull's Eye.** Unchanged: exit to your own Fast Track corner.
- **Teams.** The `RuleSet` defines teams as lists of seats. "Your partner's cards move your marbles once you finish" generalizes to "any teammate who has finished."
- **Seven split with a teammate.** Allowed by the docx. This also generalizes to any teammate.

### Tuning ideas for long games (not needed for v1)

- Shorter arms on 6+ boards. The catch: the Home Base row is 4 holes because there are 4 marbles, so shortening an arm means fewer marbles too.
- A "speed" `RuleSet` preset: 3 marbles per player, and the 4 card moves back 5.
- Turn timers, auto-play when only one move is legal, and fast-forward animations.

---

## 4. Open rule questions

The README and the docx disagree in places, and some cases aren't covered at all. Each answer becomes a `RuleSet` field with a default, so house-rule variants cost nothing later.

1. **Leaving the Bull's Eye.** README: any face card (J/Q/K). Docx text: K/Q/J. Docx table: only Queen and King. Which is it?
2. **The deck.** Is it 52 cards plus how many Jokers? When cutting for first player, how does a Joker rank, and how are ties broken?
3. **Fast Track use-it-or-lose-it.** Is the window the *next card* (README) or the *next turn* (docx)? These differ when you're chaining play-again cards.
4. **Fast Track movement.** Does each hop between corners cost 1 point of movement? Can one card carry a marble around the Fast Track *and then* along the main track?
5. **Jack swap.** Can you swap with marbles on the Fast Track, in the Bull's Eye, or on someone's Starting Exit? With a teammate's marble? Does a swap count as a kill? (Presumably no.)
6. **Home Base.** Is an exact count required to enter or move within it? Can a marble jump over its own marbles there? (The "never hop your own color" rule suggests no.)
7. **Play-again with no legal move.** If you draw an Ace but no move is possible, do you still draw again? (Presumably yes.)
8. **Kills.** Can you kill a marble sitting on its own Starting Exit? Can you kill in the Bull's Eye?
9. **Four backwards.** Can a 4 move a marble backwards *out of* the Fast Track or Bull's Eye, or only *into* them?
10. **Seven split.** Can the two halves kill? Can one half go into the Home Base?

---

## 5. Roadmap

Each milestone ends with something playable or testable.

0. **Project setup.**
   - Install Godot 4 (latest stable).
   - Create the project with the Compatibility renderer, typed-GDScript warnings set to errors, and the `SignalBus` autoload.
   - Add a test framework (gdUnit4 or GUT) and a CI job running `godot --headless` tests.
1. **Rules core, classic 4-player.**
   - `Card`, `Deck`, `BoardTopology`, `GameState`, `MoveGenerator`, `MoveResolver`: basic movement, starting, kills, Home Base, play-again.
   - Full unit tests. No UI yet.
2. **Hot-seat prototype.**
   - `Board.tscn` built from `Arm.tscn`/`Hole.tscn`, clickable marbles, a card draw button, placeholder art.
   - First human playtest.
3. **Special rules.** Four (backwards), Seven split, Jack swap, Fast Track, Bull's Eye, teams.
4. **AI opponents.** Legal-move scoring with personalities: *Kelsey* (evil and smart) and *Jordan* (kill everything, ignore winning). Useful for solo play and for simulating balance.
5. **Variable player count.** `SeatLayout` for 3–8 arms, a lobby with a seat/team picker, and camera zoom/pan on phones.
6. **Web release.** Single-threaded web export, hosted on itch.io or GitHub Pages, with touch and mouse support.
7. **Mobile release.** Android (`.aab`) then iOS (Xcode). Icons, splash screen, safe-area layout, store listings, privacy policy.
8. **Online multiplayer (optional).** Server-authoritative play on the same rules core, with seeded decks for replay and anti-cheat.

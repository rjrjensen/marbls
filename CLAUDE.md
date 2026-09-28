Guidelines to follow:
- Prefer strong typing
- For component Communication, prefer passing down and signaling up
- Leverage a top level project SignalBus unless it makes more sense to make it an instance level signal
- Prefer Composition over inheritance
- Leverage custom class names where it makes sense for auto-complete
- You may prototype by making geometry in code, but you should "solidify" that geometry in an actual scene file unless there is actually a need for procedural generation

Project context:
- Engine: Godot 4.7, Compatibility renderer, 3D presentation (tilted camera). Targets: Web (single-threaded export), iOS, Android. Online server: headless Godot build of this project.
- Language: statically typed GDScript (not C#: Godot 4 C# can't export to web). Type every variable, parameter, and return value.
- Keep game rules in a pure core (`core/`, RefCounted/Resource classes, no Nodes) so it can be unit-tested and reused by AI and the online server; scenes only render state and collect input. UI and AI send intents to a `MatchHost` and react to the events it emits; never mutate `GameState` directly. All randomness goes through the match's seeded RNG.
- Rules come from README.md (Kelsey's original instructions are merged into it; code uses her terms: Starting Block, Starting Exit, Main Track, Home Base, Fast Track, Bull's Eye); where they're ambiguous, add a `RuleSet` option instead of hard-coding. See docs/DESIGN.md for architecture, player-count layouts, open rule questions, and the roadmap.

Commands:
- Run tests: `scripts/test.sh` (all) or `scripts/test.sh <name filter>`. It imports the project first and fails on any script error, so it doubles as the type/lint check. CI runs the same script.
- Lint: `scripts/lint.sh` (gdlint, config in `gdlintrc`). CI runs lint + tests; PRs may be merged by Claude only when both pass.
- Web build: `scripts/build_web.sh` → `build/web` (splits the >25 MiB engine file for Cloudflare Pages; `.github/workflows/web.yml` deploys it).
- AI balance: `scripts/simulate.sh [games] [players]` plays AI-vs-AI games headless and prints win rates and kills per personality (presets: `players/ai/profiles/*.tres`).
- Godot binary: `godot` on PATH (installed by the session-start hook via `scripts/install_godot.sh`, which uses the official mirror; github.com downloads are blocked in Claude sessions).
- Tests live in `tests/**/test_*.gd`, extend `TestCase`, and name methods `test_*`. Game code under `core/` needs tests.
- GDScript gotchas: `match`, `pass` are keywords; avoid naming things after global functions (`wrap`, `clamp`, ...).

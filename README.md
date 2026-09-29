# Marbls

[![CI](https://github.com/rjrjensen/marbls/actions/workflows/ci.yml/badge.svg)](https://github.com/rjrjensen/marbls/actions/workflows/ci.yml)
[![Web](https://github.com/rjrjensen/marbls/actions/workflows/web.yml/badge.svg)](https://github.com/rjrjensen/marbls/actions/workflows/web.yml)

The digital version of **Marbles**, the Lindaman family's card-driven take on Aggravation. It torments the McGregor family and everyone they know. (The Case family are born cheaters, which is how the rules got changed in the first place.)

**▶ Play it at [marbls.co](https://marbls.co)**

## What works today

- A 3D board for **2–8 players**, on the web (phone or desktop).
- **Every family rule:** Fast Track, Bull's Eye, Jack swap, Seven split, backward Four, and teams.
- **Computer opponents** with personalities: Kelsey, Jordan, The Grandmaster, The Turtle and Rookie. Or pass one device around.
- **Extras:** a starting ceremony, card flips, marble clicks, and a win celebration.

Next up is on the [roadmap](docs/DESIGN.md#12-roadmap). Ideas and work items are in the [issues](https://github.com/rjrjensen/marbls/issues).

## Documentation

| Document | What's in it |
| --- | --- |
| [docs/RULES.md](docs/RULES.md) | The complete rulebook, including every family decision |
| [docs/DESIGN.md](docs/DESIGN.md) | Design, architecture, decisions, and the roadmap |
| [docs/TECH_NOTES.md](docs/TECH_NOTES.md) | How it works: a tour of the code and technology |
| [docs/retros/](docs/retros/) | Retrospectives |
| [CLAUDE.md](CLAUDE.md) | Coding guidelines and working agreements (for people and for Claude) |

## Infrastructure

| What | Where |
| --- | --- |
| Source, issues, CI | [GitHub: rjrjensen/marbls](https://github.com/rjrjensen/marbls) (private). [Actions runs](https://github.com/rjrjensen/marbls/actions) |
| Web hosting | [Cloudflare Pages](https://dash.cloudflare.com/) project `marbls`: [marbls.co](https://marbls.co), [www.marbls.co](https://www.marbls.co), [marbls.pages.dev](https://marbls.pages.dev). Every PR gets a preview URL. |
| DNS | Cloudflare (the `marbls.co` zone) |
| Domain registrar | [Namecheap](https://www.namecheap.com/) (renewals only; DNS lives at Cloudflare) |
| Game server | Fly.io (planned: online play) |
| Accounts and data | Supabase (planned: online play) |
| App stores | Apple App Store Connect and Google Play Console (sign-ups in progress) |

**Deployment:**
- Merging to `master` deploys to marbls.co.
- The GitHub secret `CLOUDFLARE_API_TOKEN` (Cloudflare Pages: Edit) is what makes deploys work.

## Development

You need **[Godot 4.7.2](https://godotengine.org/download)** and Python 3.
- `scripts/install_godot.sh` downloads Godot on Linux.
- In Claude Code cloud sessions, a startup hook installs everything automatically.

| Command | What it does |
| --- | --- |
| `scripts/test.sh [filter]` | Runs the headless test suite. It fails on any script error, and untyped code fails to load. |
| `scripts/lint.sh` | Runs gdlint (config in `gdlintrc`) |
| `scripts/build_web.sh` | Exports the web build to `build/web` |
| `scripts/simulate.sh [games] [players]` | Plays computer-vs-computer games and prints win rates per personality |

Open the project in the Godot editor (`project.godot`) to run it locally. The main scene is `game/game.tscn`.

**Project layout:**

```
core/       Rules engine: cards, board graph, moves, match (pure code, no scenes)
players/ai/ Computer opponents: personalities, move evaluators, simulation
board/      3D board scenes: hole, marble, arm, starting block, camera
game/       Game controller: turns events into animation and taps into moves
ui/         HUD, starting ceremony, win celebration
tests/      Test runner and test suites
scripts/    Build, test, lint, deploy helpers
docs/       Rules, design, tech notes, retrospectives
```

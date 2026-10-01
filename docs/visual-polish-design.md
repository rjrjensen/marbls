# Visual polish: cards, piles, nameplates, orb and menu

Design for the next visual pass on Marbls, settled in a grill-with-ui interview (12 questions, 9 prototype versions). Every seat gets a real-looking draw pile and a messy discard pile on the 3D table; drawing is done by tapping your pile; cards get procedurally drawn faces and seat-colored backs; the top bar, message line, Draw button and bottom card panel go away. Whose turn it is lives on a steady lit nameplate at each seat, and a computer's "thinking" is the marble on its nameplate spinning. Words move to a small info orb (top left, a hints guide that can be turned off); New game moves into a hamburger game menu (top right). Everything visual ships behind live-switchable Variants on a feature flag page so family can compare. Final prototype: [visual-polish-design-visual.html](visual-polish-design-visual.html) (v9; HTML mock, not the real game).

## Terms

- **Draw pile**: a player's face-down stack of undrawn cards (`Deck.draw_pile`). Avoid: "deck" (ambiguous), "stock".
- **Discard pile**: a player's messy face-up pile of already-played cards (`Deck.discard_pile`). Avoid: "drawn cards", "graveyard".
- **Seat marker**: the on-board graphic tied to a seat that shows whose turn it is. Final form: the nameplate alone, steady and lit in the seat color; no ring around the Starting Block, no bouncing. Avoid: "turn label", "top bar", "halo".
- **Variant**: one selectable look or behavior for a feature (e.g. "piles in 3D" vs "piles in HUD"), chosen on the feature flag page. Avoid: "skin", "mode", "theme".
- **Feature flag page**: a screen where you pick a Variant for each flagged feature so family can compare looks. Avoid: "settings", "debug menu".
- **Info orb**: a small marble-shaped guide in the top LEFT. Carries hints, rules help, rejections and notes; stays quiet until the game has something to say, then expands into a squircle message and collapses again. Hints can be turned off. Avoid: "message line", "toast", "notification bar".
- **Game menu**: hamburger-style menu in the top RIGHT that opens New game, the hints toggle and the feature flag page. Separate from the info orb. Avoid: "top bar", "New game button".
- **Thinking marble**: while a computer player thinks, the small marble on its nameplate acts as a loading spinner (a highlight orbits it slowly). Replaces the thinking dots and stops when that turn ends. Avoid: "ellipsis", "dots", "thinking text".
- **Current card**: the card just drawn this turn, which decides which moves are legal until the turn ends. Avoid: "drawn card" (ambiguous with discard pile).
- **Speech chip** (proposed during the grill, not used in the final design): a bubble beside a nameplate carrying words. Hints went to the info orb instead.

## Why

From the request: "The deck of cards should look like a deck of cards", starting as 54 cards face down in a neat stack, lifted onto a less neat pile to its right as cards are drawn, "just like it looks in real life". Click the deck or the pile instead of a Draw button, with a non-verbal "it's your turn" signal. Cards "designed more like a real deck". Card backs simple and colored like each player's marbles. "Show all players' decks on the table while the game is going, and not just all drawn cards on the player's screen. It's hard to follow." The turn indicator in the top-left means "a lot of eye movement" between the corner and the automatic marble movement in the middle, the per-player text is "hard to keep up with", and on your own turn it still says the previous player is thinking.

## Locked decisions

Only the decision that passed all three gates (hard to reverse, surprising, a real trade-off) is marked durable.

### Live-switching Variants via a typed feature flag page (Q4, durable)
- **Decision:** a typed `FeatureFlags` Resource (enum-valued fields, e.g. a piles Variant of WORLD_3D / HUD / HYBRID) held by an autoload, reachable from the game menu, saved with the other settings. Changes apply live in the current game: the affected views tear down and rebuild, and a `flag_changed` signal goes out on the SignalBus.
- **Why:** the point is demoing to family, and flipping a Variant and seeing it change in the same game is the whole point. Typed Resource plus SignalBus matches the project guidelines (strong typing, top-level SignalBus, signal up).
- **Rejected:** (A) apply at next game start: simpler and avoids odd mid-animation states, but a worse demo; it stays the fallback if live switching proves fiddly. (C) query-string/launch-arg only: does not work on iOS/Android where a phone gets handed around.
- **Consequence:** every flagged feature must be able to tear down and rebuild itself mid-game. Piles in particular need one small interface (show count, show top card, animate a draw) so the 3D and HUD versions sit behind the same seam rather than being tangled into `GameController`.

## Routine choices

- **Piles live in the 3D table (Q1, A).** Each seat's draw and discard piles are real objects on the table beside the seat; tapping a pile is 3D picking. They inherit the camera tilt and rotation. Alternatives (all-2D HUD piles; hybrid with big 2D piles for you and small 3D piles for opponents) stay reachable as Variants on the flag page. Rejected as the default: the 2D HUD (has to chase projected positions, never feels on the table) and the hybrid (kept as a fallback if reading the 3D card at a tilt is too fiddly).
- **Card faces are procedural (Q2, B).** One Card scene draws corner indices, suit pips in the standard layouts and simple J/Q/K/Joker art from a template, so there are no 54 image imports and no licensing. Rejected: an existing open/public-domain vector set (fast to look real but locks in someone else's style and licence terms) and a subagent-generated 54-file SVG set (uneven consistency).
- **Active seat marker (Q3).** The active seat's nameplate is a steady lit state in its seat color (optionally larger, with a small static arrow). No halo around the Starting Block and no bouncing or pulsing on nameplates: the user rejected the halo, and the bounce ran at a different frequency than the card. While a computer thinks, the marble on its nameplate becomes a slow spinner (a highlight orbits it, about 2.8 s per turn in the prototype); only the one thinking seat animates. Nameplates are compact pills (marble + name, no reserved dots slot, no card counts) sitting tight to their piles so the board can be as large as possible.
- **"Your turn, tap the pile" cue (Q5, C as answered, reduced by later feedback).** Final cue: only the top card of your draw pile lifts and gently bobs, with a glow in your marble color; the rest of the stack stays put. Keyboard accept (`ui_accept`) still draws. The second half of answer C (a pulse of your color across the table edge or seat halo) was dropped when the halo was rejected; see Open threads. Not shown for computer turns, and the cue stops the moment you tap.
- **No top bar, message line, Draw button or bottom card panel (Q6, C, refined by Q8 and Q10).** The turn label, message line and the green Draw button are removed. New game moves to the game menu.
- **Where words go (Q8).** The info orb (top left) is the helpful guide: hints, rules help, rejections and notes appear there. Hints can be turned off in settings (see Q11). Events are shown by animation rather than text.
- **Orb and menu placement (Q10).** Info orb top left, game menu top right: two separate entities in two separate corners. Both must respect iOS safe-area insets.
- **Current card (Q7, B).** On draw the card lifts, flips, and is held large and readable for at least 1 second, then lands on the discard pile by itself with no click. In the final prototype it takes about 0.75 s of motion plus a 1.1 s hold; the earlier "too fast" and "too slow" versions bracket this. Afterwards the discard pile's top card (drawn slightly larger than the rest of the pile) is where to read the current card. The previously proposed chip beside the nameplate was dropped ("unnecessary"). Rejected: hovering the card until the move finishes (covers the board in the busiest moment).
- **Card backs (Q9).** Three designs, listed and selectable in this order: **C** (classic two-tone diamond lattice in the seat color and a darker shade; the default), **A** (solid seat color, cream border, repeating marble-ring motif) and **B** (A plus a small per-seat symbol in the center). All three are Variants on the flag page. C has no per-seat symbol, so seats rely on color alone by default; B is the fallback if red, orange and pink are hard to tell apart.
- **Hints setting and prompt (Q11).** One typed Settings object, shared with the feature flags, saved to `user://` (which Godot maps to browser storage (IndexedDB) on the Web build, and to a real app-data folder on desktop, iOS and Android). Hints on/off is also a toggle in the game menu. After 10 **wins** (not games) a prompt asks "Do you want to turn off these hints?" with the buttons "Yes" and "Keep them on a little longer"; "Keep them on a little longer" restarts the win counter. Plan: move settings storage to Supabase once accounts exist, and add that as a Supabase story.
- **Process (Q12).** Everything visual is valuable right away, so each piece of work becomes its own "Story: ..." GitHub issue (per CLAUDE.md), and pieces that are isolated and parallelizable can be done by subagents in separate worktrees. See Stories below.

## Verified facts

- Every player already has a personal `Deck` (`draw_pile` plus `discard_pile`) in `core/cards/deck.gd`; the top of the draw pile is the end of the array. The pile-per-seat model exists in the core already. The user describes each deck as 54 cards (52 plus 2 Jokers); the code takes a joker count in `Deck.standard(joker_count)` (the default count was not checked).
- Today's HUD (`ui/hud.tscn`, `ui/hud.gd`): a top bar with `TurnLabel`, `MessageLabel` and a "New game" button; a bottom bar with the drawn card panel and the green Draw button. `GameController._ready_for_input` sets "<name> is thinking..." for computer turns, and `_present` only clears it on `CARD_DRAWN`, which is why it is stale on your turn.
- `GameController` uses `show_message` for several unrelated things: move hints (7-split, Jack swap), kill announcements, "No move with that card", rule rejections (`INTENT_REJECTED`), reshuffles, play again, Bull's Eye and Fast Track notes.
- The camera (`board/board_camera.gd`) only rotates to the current seat in hot-seat games; with one human it stays behind that human.
- The real 4-player board is a "wooden square" of 56 track spaces (4 arms), described in `docs/RULES.md` and drawn in `docs/images/board-4p.svg`; layouts for other seat counts come from the rules in `docs/images/generate_boards.py` (regular-polygon hub of side 4 hole spacings, arm length 5). The first prototype's circular board was a stand-in and was replaced; the final mock re-implements the generator's rules in JS and was checked against `board-4p.svg`, but it did not read `board/board_view.gd`, `board.tscn` or `arm.tscn`.
- Prototype checks actually run (headless Chromium screenshots): 390x844, 820x1180 and 1600x900; nameplate gaps to piles of at least 9 px at 2, 3, 4, 5, 6 and 8 seats; on a 390x844 phone the 4-seat board grew from roughly 148x92 to 275x163 (about +86% wide) after the nameplates were shrunk and moved. The 54-card face sheet was inspected zoomed and at phone size after the club glyph was redrawn.

## Risks

- **The prototype is an HTML mock.** It was never opened on a real device, and some versions (v2, v3, v4, v5, v9) were only syntax-checked, not looked at in a browser. Nothing here has been implemented in Godot.
- **Readability of a card on a tilted 3D table**, especially on phones. The current card flashes large, but afterwards the discard pile top is small and angled. Fallbacks: the hybrid piles Variant, or the dropped current-card chip.
- **Eight seats on a phone is crowded.** The prototype keeps gaps, but this is the biggest test of the camera and nameplate layout.
- **Live-switching Variants** require every flagged feature to rebuild itself cleanly mid-game and mid-animation; this is real engineering cost, not just a settings page.
- **Seat colors:** with back C (no symbol), red, orange and pink are close on a dim table and for color-blind players. Back B is the mitigation.
- **Custom orb animation:** expanding the orb text caused a visible "text keeps refitting" bug in the first prototype. The rule: lay the message out once at its final width, animate only the shell (marble to squircle) with clipping on, then fade the text in; collapse in reverse. In Godot: size the Label up front, tween the Panel size with `clip_contents`, tween Label alpha afterwards.
- **Nameplate sizing bug (found in v6):** anything that changes a nameplate's size (like the old dots) pushes it into its piles. Rule: nameplates are fixed-size (`custom_minimum_size`); the thinking marble animates in place.
- **Hints counter lives in browser storage:** clearing site data resets it, and on a shared family phone it is per device, not per person, until accounts exist.
- **Pip overlap:** in the prototype, the 9 and 10 cards' pips overlap (known, unfixed). Court-card and Joker art is intentionally simple and has not been designed.
- **Draw timing is an estimate.** The "halfway between" timing was computed against a roughly 1 s guess for the first version, which could not be recovered; the timings are constants in the prototype (`DRAW_LIFT_S`, `DRAW_FLIP_S`, `DRAW_FLASH_S`, `DRAW_HOLD_S`, `DRAW_LAND_S`) and should be tuned on the real build.

## Deferred

None. Q9 (card backs) was deferred until the user could see the three designs side by side and was then decided (C default, then A, then B).

## Open threads

- **Q5's second cue.** The answered option C included a pulse of your color across the table edge or seat halo. The later "no halo" and "float only the top card" feedback removed it from the prototype, but Q5 itself was not reopened. Treat the top-card lift plus glow as the cue and confirm the edge pulse is not wanted.
- **Words for events.** Q8 settled that hints go to the info orb and events use animation. Not decided: exactly which messages the orb carries versus which are animation only (rejections, Bull's Eye and Fast Track notes, reshuffle notices, kills, "No move with that card"), and whether the orb auto-expands for important ones (rejected move, game over) or only pulses. The recommendation made during the interview was to reserve auto-expand for things that really need it.
- **Speech chips for your own move hint.** Early options put hints in a chip by your nameplate; the final answer puts the guide in the top-left orb. This reintroduces some eye travel between the orb and the board at the moment you most need the hint. Try it with family and reconsider if it hurts.
- **Pile stack height.** The draw pile visibly shrinks as it is drawn; the numeric count was removed (each player reshuffles once all their cards are in the played pile, so the count is not needed). Whether the stack should stay a constant height is not decided.
- **What counts as a "win" for the hints counter** on a team game, and whether a win by a teammate counts for the human, is not decided.
- **Supabase story.** The request to record "move settings storage to Supabase" in the Supabase stories has not been done yet.

## Stories (one per piece; created after this doc, not yet filed)

Per the Q12 answer and CLAUDE.md, each becomes a `Story: ...` GitHub issue linked from `docs/DESIGN.md`'s backlog. Those touching `GameController` and the HUD overlap, so the isolated pieces below should land first.

Isolated, can run in parallel in separate worktrees:
1. Settings object + feature flags (typed Resources, autoload, `flag_changed` on the SignalBus, `user://` persistence, flag page).
2. Procedural card faces (A to 10, J, Q, K, Joker; fix 9/10 pip overlap).
3. Card backs C, A, B in seat colors.
4. Info orb scene (top left) with the expand/collapse animation rule above.
5. Game menu scene (top right): New game, hints toggle, feature flag page entry.
6. Nameplate scene (compact pill, steady lit state, thinking-marble spinner shader).

Touches shared game code (sequence after the above):
7. Pile interface and 3D piles (neat draw stack, messy discard pile, tap or `ui_accept` to draw, top-card lift cue).
8. Draw animation and current-card flash (about 0.75 s motion plus a 1.1 s hold, auto-land).
9. Remove the top bar, message line, Draw button and bottom card panel; route hints and notes to the orb and the thinking state to the nameplate marble.
10. Hints-off prompt after 10 wins ("Yes" / "Keep them on a little longer"; the latter resets the counter).
11. Supabase story: sync settings and the hints counter per profile.

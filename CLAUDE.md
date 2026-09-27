Guidelines to follow:
- Prefer strong typing
- For component Communication, prefer passing down and signaling up
- Leverage a top level project SignalBus unless it makes more sense to make it an instance level signal
- Prefer Composition over inheritance
- Leverage custom class names where it makes sense for auto-complete
- You may prototype by making geometry in code, but you should "solidify" that geometry in an actual scene file unless there is actually a need for procedural generation

Project context:
- Engine: Godot 4 (latest stable), Compatibility renderer. Targets: Web (single-threaded export), iOS, Android.
- Language: statically typed GDScript (not C#: Godot 4 C# can't export to web). Type every variable, parameter, and return value.
- Keep game rules in a pure core (`core/`, RefCounted/Resource classes, no Nodes) so it can be unit-tested and reused by AI and networking; scenes only render state and collect input.
- Rules come from README.md and "Marbles Game How to Play.docx"; where they're ambiguous, add a `RuleSet` option instead of hard-coding. See docs/DESIGN.md for architecture, player-count layouts, open rule questions, and the roadmap.

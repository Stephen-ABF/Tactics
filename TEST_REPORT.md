# Thornwake Expeditions v0.4.0 — verification

Tested with Godot4.7.2 stable (`ed1daf0bf`), Linux, Compatibility renderer. Test runner completed successfully in an isolated player-data directory.

| Check | Observed result |
| --- | --- |
| Deterministic rules |6,337 assertions,0 failures;1,500 generated encounters;150 distinct6×6 layouts |
| Gear |35 assertions,0 failures;97 destructive outcomes in1,000 seeded corruption samples |
| UI/save/flow |111 assertions,0 failures |
| Expedition integration |2 complete winning expeditions through touch-selection methods, animated commit, all camps/sizes, boss and results |
| Greedy balance probe |18/18 Depth1 wins; baseline18–44 turns, starter14–23, strong11–19 |
| Render review |Actual600×1000 Godot screenshots: title, all five waves, camp, settings, codex |

6,483 counted assertions include repeated generation checks, not independent user studies. Complete expedition tests fast-forward the animation clock; rendered review separately uses software OpenGL. No real Android input/performance or human playtesting has occurred.

Coverage includes route bounds/cardinality/revisits/stride, armor chipping, momentum, stances, poison timing, guard prevention, consumed springs, brute charge/rest, hexer marks, boss telegraphs/enrage-next-turn/death, seeded layouts, save JSON validation, checkpoint roundtrip, camp selection/stance restoration, active gear lock, pause mid-animation, focus loss, safe-area fit math, every cell's perspective pick mapping at each board size, duplicate camp advancement, reward settlement once, depth unlock, malformed checkpoint rejection, backup recovery, crafting/runes/runewords/sets/corruption and placement atomicity.

A generated board always has legal initial movement and can chip armor; the tests do not prove that every possible seed/gear/Depth combination has a winning strategy. Higher Depths have sampled validity checks, not exhaustive balance validation. A greedy solver's wins do not establish fun, fairness or3–6 minute human run lengths.

Run `python3 tools/run_checks.py --godot /path/to/godot`. Render script requires a display: `godot --path . --script res://tests/visual_phase3.gd`. Use isolated user data for render scripts. GitHub Actions independently runs the tests and attempts debug exports; inspect its actual result before claiming an APK or EXE exists.

Known risks: early strong-gear dominance, unmeasured high-Depth difficulty, growing stash needs filters, no device QA, placeholder art, and no store-ready signing/assets/review. Phase3 source work is implemented; platform release acceptance remains outstanding.

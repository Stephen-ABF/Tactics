# PM source of truth — Thornwake v0.6.0

Approved scope: the five follow-ups requested after v0.5.0. All work remains within an offline single-player prototype. Only user/designated PM merges.

| ID | Item | Acceptance |
| --- | --- | --- |
| TW-061 | Local playtest summary | Bounded run records, timing/loot/loss/retry summary, opt-out, copyable JSON; no remote upload |
| TW-062 | Save protection and test signing | Roundtrip backup, rejected malformed imports, explicit replacement confirmation, pre-import recovery, private signing secret support (secret setup pending) |
| TW-063 | Inventory usability | Sort/filter/search, favorites, backend destruction locks, capped/set-aware comparison, quick Sigil recovery |
| TW-064 | Combat clarity | Explain actual hit power, guard, retaliation and recovery before committing; explanations match reducer |
| TW-065 | First balance pass | Compare baseline, safe +3, risky +6 and Binding fixtures across paired seeds/stances/Depths; address repeated offensive boon stacking |

Gameplay and save implementation is complete; stable Android signing awaits repository secrets. Local automated and rendered checks pass:18,832 assertions, two complete expeditions and144 expanded balance simulations. CI export validation is the remaining delivery check. The test report and balance matrix are the evidence, not predictions about retention or fun. See TEST_REPORT.md and tests/balance_matrix.json.

Balance change: camp boons are unique within an expedition and total Edge from gear/boons caps at3. Existing active-wave snapshots stay intact; the cap applies to newly built waves. Legacy camp selections may need reselection if the old option is now already owned. No loot odds were changed in this pass.

Review priorities: import atomicity and recovery; malformed values; locks at every destructive entry point; no double reward/summary settlement; clipping with many modifiers; field/home filtering; same signing certificate across future test builds; safe +3 fixture viability without claiming human win rates.

Open gates: independent audit; real Android/Windows hardware input/performance; human run-length and enjoyment tests; store signing/assets/review. Private test signing secret setup remains external; no key is committed. Earlier disposable v0.5.0 signatures cannot be recovered.

Next decision: collect a small set of real player runs and observe first Binding creation and targeted Sigil hunts before adding more recipes or extending run length.

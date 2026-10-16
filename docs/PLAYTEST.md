# Playtest hypotheses — unvalidated

Local `user://thornwake_events.jsonl` captures tutorial completion, run start/resume/end, active seconds, wave, Depth, seed, run-local ID, immediate retry within15 seconds, rejected routes, move kills/damage/healing/momentum, loot and gear actions. Run IDs are local deduplication identifiers, not accounts. No names, advertising/device IDs or remote upload. Log rolls over at roughly1MiB. Test scripts create synthetic events in isolated data directories.

Use a small consented human test before choosing difficulty or economy targets. Suggested decision thresholds below are **design hypotheses, not industry benchmarks**.

| Hypothesis | Measurement / initial decision rule |
| --- | --- |
| Tutorial teaches planning | Observe 5 people; at least4 complete and correctly explain why a route is dangerous without coaching |
| Action stays readable | Ask after first damage: which enemy caused it? At least4/5 identify the tell |
| Pressure feels fair | Review deaths alongside seed/wave/Depth and route damage; distinguish ignored warnings from unclear rules |
| Runs fit a short break | Human active-time median should land around3–6 minutes; separate camp crafting time and app pause |
| Replay has a reason | Record immediate retries and interview the player about the changed plan; don't infer enjoyment from retries alone |
| Builds change decisions | Compare Duelist/Reaver and edge/defense builds on the same seeds; inspect chosen routes, not just win rate |
| Progression offers options | Observe whether new runes/set pieces change packing, rather than simply filling every available cell |

Current solver outcomes show reachability on a tiny sample only. It searches up to700 candidate routes of length10 with greedy scoring; it knows the rules perfectly and does not model a person.18/18 wins at Depth1 across three seeds, three gear profiles and two stances are a warning about easy optimized play, not validation of retention or all generated boards. No measured D1/D7 retention, market validation or human enjoyment claim.

Dominant-strategy risk: edge/focus reaches enemy thresholds and long kill chains can outperform defense; boon edge stacks above permanent gear caps. Counterweights are armor that stops weak routes, different threat shapes, empty-cell limits, post-retaliation healing and Depth scaling. Do not add more upgrades before observing these interactions. Death does not delete gear; corruption is voluntary and explicitly confirms its destructive odds.

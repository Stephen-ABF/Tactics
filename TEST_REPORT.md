# Thornwake v0.6.0 — verification

Godot4.7.2 stable (`ed1daf0bf`), Linux, Compatibility renderer. Isolated user data. **18,832 assertions**, including repeated seeded sampling rather than independent user studies.

| Suite | Result |
| --- | --- |
| Rules |6,337 assertions; zero failures |
| Gear regression |35 assertions; zero failures |
| Main flow/save |113 assertions; zero failures |
| Economy/effects |12,158 assertions; zero failures |
| Forge/hunt integration |23 assertions; zero failures |
| New save/report/inventory/clarity |166 assertions; zero failures |
| Full expedition integration |Two winning animated five-wave runs, camps and boss results |
| Original balance probe |18 simulated expeditions |
| Expanded balance matrix |144 simulated expeditions, paired seeds/stances across four fixtures and three Depths |
| Render review |Actual600×1000 Godot screens: save/export, restore confirmation, stash tools, comparison, route preview/explanation, local report |

The runner treats Godot script/runtime errors as failures even if the engine exits0. Render/report screenshots use synthetic fixtures, not human data. No physical Android/Windows execution or human playtesting has occurred.

New coverage includes checksum corruption, malformed JSON, future schemas, nested numeric/type errors, duplicate IDs, overlapping packed items, unchanged save on rejected import, pre-import recovery, saved camp export from title, double restore protection, actual desktop file-dialog save/load callbacks, one exclusive picker at a time, protection at all destructive backend entry points, retained flags, complete and repeated unsocketing, field-only access at camp, sorting/filtering/search, nonmutating capped comparisons, bounded/idempotent reports, correct medians, recording opt-out, two unowned camp choices, legacy Edge cap and explained damage summing to actual hit power.

The expanded solver uses350 candidate routes and a maximum route length10, with perfect rule knowledge. It assumes fixed gear, no camp crafting, and first-offered boon selection. The safe/risk fixtures assume gear availability and survival; the simulation does not model human difficulty, real run time, retention or long-term economy. `tests/balance_matrix.json` contains cases and group results.

| Fixture | Depth1 wins | Depth2 wins | Depth3 wins | Depth3 median winning turns |
| --- | ---: | ---: | ---: | ---: |
| Baseline |12/12 |4/12 |0/12 |— |
| Safe +3 |12/12 |12/12 |12/12 |18.5 |
| Risky +6 |12/12 |12/12 |12/12 |17.5 |
| Starter Binding |12/12 |12/12 |12/12 |16.5 |

The low damage suffered by optimized fixtures remains a tuning risk. Higher Depth4–5 are not balance-tested by this matrix. Existing sampled generation checks cover board validity, not a proof that every seed/loadout has a winning strategy.

Existing economy simulation remains unchanged:2,000 full46-kill clears averaged7.8525 gear,3.92 common Sigils and0.306 shards; gear10th/50th/90th percentiles6/8/10. Exclusive drops are additional. See `tests/economy_results.json`.

CI independently repeats the checks and exports Android debug APK and Windows debug EXE/PCK. It verifies the APK signature and checks the expected certificate when private signing secrets are configured. Inspect the successful v0.6.0 run/artifact before claiming its export. No store release/signing or independent audit is claimed. Artifact retention14 days.

Source save migration preserves gear/currencies/flags/checkpoints. Consistent Android signing requires repository secret setup and does not recover earlier disposable keys. No key is committed. Mobile backup uses code/clipboard; mobile document-provider integration and actual clipboard/device behavior remain unverified.

Run: `python3 tools/run_checks.py --godot /path/to/godot`. Display required for `tests/visual_update6.gd`; isolate user data. No remote analytics.

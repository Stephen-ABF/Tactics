# Thornwake v0.5.0 — Sigils & risk verification

Godot 4.7.2 stable (`ed1daf0bf`), Linux, Compatibility renderer. Local suites pass in isolated player-data directories. Test count: **18,666 assertions**, including repeated seeded sampling rather than independent human test cases.

| Suite | Observed result |
| --- | --- |
| Rules |6,337 assertions; zero failures;1,500 generated encounters;150 distinct6×6 layouts |
| Gear regression |35 assertions; zero failures;97 destructions in1,000 corruption samples |
| Main flow/save |113 assertions; zero failures |
| New economy/effects |12,158 assertions; zero failures |
| Forge/hunt integration |23 assertions; zero failures |
| Expedition integration |Two complete winning five-wave expeditions through selected routes, animations, camps, boss and results |
| Balance probe |18/18 simulated Depth1 wins; baseline18–44 turns, new starter14–23, strong11–19 |
| Render inspection |Actual600×1000 Godot renders: scout report, hunting guide, pack, risk quote, Sigil sockets, Binding book, Set collection |

The test runner rejects script/runtime errors even if Godot exits with code0. Integration tests fast-forward animation time; rendered screens are reviewed separately with software OpenGL. Physical Android input, performance, battery and human playtests remain unverified.

## New coverage

- Old Magic→Uncommon migration, retained gear/currencies, initialized exclusive pouch/marks/pity; +6 and exclusive sockets survive JSON roundtrip.
- Every Binding's exact sequence, base and reachable socket count.
- Actual conditional combat: guard spent for power, cover power, wounded-target follow-up, armor Temper, kill-required magic escape and five-kill healing. Reducer includes original killed species for loot, including cleaves.
- +1–+3 safe; risk cannot spend without acceptance; correct cost on success or destruction; inserted Sigils consumed on destruction; stale target-level confirmation cannot advance another tier; maximum +6 preserved.
- Actual UI risk quote/cancel/accept, repeated confirmation, immediate saved result; scrollable Sigil/recipe screens; Set selection and repeated claim spending guard.
- Matching-exclusive source isolation, boss10th-kill guarantee/reset/reload, duplicate source guards, exactly-once boss mark.
- Actual animated Warden kill passes species into the drop channel, triggers saved pity, banks mark and clears checkpoint; repeated completion cannot duplicate rewards.
- Active planning, animation and camp time persisted separately; no background accumulation.

## Seeded economy simulation — not human playtesting

Actual GDScript loot functions,2,000 full clears of46 enemies, seed888:

| Metric | Mean / observed |
| --- | ---: |
| Gear per clear |7.8525 |
| Gear10th /50th /90th percentile |6 /8 /10 |
| Common Sigils per clear |3.92 |
| Corruption shards per clear |0.306 |

Exclusive drops are additional to common quantities.100,000 rarity draws: Normal29,852; Uncommon31,981; Rare25,086; Epic9,062; Unique1,979; Set2,040.2,000 upgrade attempts per tier: +4 destroyed108; +5 destroyed187; +6 destroyed397.2,000 matching regular kills yielded54 exclusives in each controlled test; the same RNG stream was deliberately reused to verify source mapping. The Warden sample yielded369/2,000 due to saved pity, so effective rate exceeds its15% raw roll.

`tests/economy_results.json` contains reproducible summaries. Fresh-profile full-clear simulations do not model failures, chosen enemy targets, repeated campaigns, item usefulness or long-term collection behavior. The6–9-minute run goal is unmeasured with humans. Higher Depth validity is sampled; winning strategies are not proven for every seed/loadout.

## Export status and limitations

Matching Android/Windows debug exports succeeded for v0.4.0. The v0.5.0 workflow independently reruns all checks and exports; use its actual successful artifact for the current build. No device execution or store submission is claimed. CI artifacts expire after14 days.

CI generates a disposable debug signing key per run. Installing over an earlier CI APK may require uninstalling it, which removes app data. Use a consistent local debug keystore for ongoing Android progression testing; preserve test saves before changing signing/installations. Source save migration does not bypass Android signature checks.

Known risks: optimized early builds are easy; higher Depth and new effect interactions need people; optional item destruction does not solve hoarding by itself; regular exclusive drops may take many runs with sparse populations; larger stash needs filters; art remains provisional.

Run `python3 tools/run_checks.py --godot /path/to/godot`. `tests/visual_sigils.gd` requires a display and isolated user data. No remote analytics or personal information collection.

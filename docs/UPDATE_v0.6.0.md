# v0.6.0 — playtest, protection and clarity

The five requested follow-ups are implemented. This is an offline development candidate, not a store release or independently audited build.

## Playtest

Title → Playtest shows the last50 finished recorded runs: win/loss reason, seed, Depth, combat/planning/animation/camp time, gear/common/exclusive drops, damage and rejected inputs. It also shows tutorial completions, immediate retries, forging losses and salvage. Copy summary JSON for analysis. Recording can be switched off; no remote upload exists. Legacy active runs and runs interrupted by switching recording off are excluded from complete-run summaries. Progress counters remain separate from diagnostic records.

## Save protection

Settings → Save export/import. Desktop users can save/load a JSON file or copy/paste a backup code. Android/iOS use the code field and system clipboard; native mobile document pickers are not implemented or device-tested. Keep backups outside the application before uninstalling it.

Restoration first validates the checksum envelope, schema, inventory IDs/placement/modifiers/currencies, progression and active checkpoint. It shows a confirmation and preserves the current profile in `user://thornwake_before_import.json` before replacing it. Load pre-import backup brings that copy back for another reviewed restore. Import replaces rather than merges, and awards no rewards. Old raw v0.5.0 save JSON is also accepted if valid; checksums detect accidental changes, not cheating. Offline saves remain editable.

CI accepts a private test keystore and expected certificate through repository secrets, verifies the APK signature and records signing mode. Secret setup remains external; without it, builds use disposable keys and update compatibility is not guaranteed. Export saves before uninstalling. Store builds require a separate private upload key.

## Inventory

Pack → Tools offers name/base/Sigil search, newest/name/tier/quality sorting, quality/favorite/locked filters and40 rows per page. At camp, home stash remains inaccessible. Favorite and lock flags persist. A lock blocks salvage, corruption and risky upgrades in the gear backend; it permits safe upgrades, movement and Sigil recovery. Sigils → Remove all recovers the whole item’s socket contents without repeated clicks.

Compare selected item shows raw trait differences and, for an unpacked candidate replacing a packed reference, the effective capped pack changes including Set bonuses. Shape placement and expedition boons are explicitly separate. It makes no automatic placement or mutations.

## Combat clarity

Plan a route → Why? shows the actual hit-power components, Counter guard spend, Duelist/Bulwark/Spellstep gains, incoming damage versus guard, remaining poison and healing sources. It reads the same reducer records used by animation. No move is committed when opening explanations.

## Balance pass

Camp boons are unique within an expedition; combined gear/camp Edge caps at3 on newly generated waves. This removes repeated Honed Edge stacking. Existing active-wave snapshots remain intact, while old camp choices already owned may need reselection. Loot and destruction odds did not change.

144 deterministic simulated expeditions compare four fixtures, two stances, six seeds and Depths1–3. Safe +3, risky +6 and the starter Binding fixtures won all sampled cases. The baseline fixture won12/12 at Depth1,4/12 at Depth2 and0/12 at Depth3. At Depth3, median winning turns were18.5 safe +3,17.5 risky +6 and16.5 Binding. These use perfect rule knowledge and a bounded greedy solver, not people. Risk fixtures assume the gear survived forging and do not model acquisition costs. Very low damage in geared cases is an unresolved warning about easy optimized play.

The6–9-minute human run target remains unmeasured. Next: observe actual first Binding creation, route mistakes and targeted hunts before extending content or raising loot supply.

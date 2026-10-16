# v0.5.0 — Sigils, Bindings and risky forging

Scope: replace the demo loot flood with a persistent collection/crafting loop. Implement all current enemy-exclusive Sigils, seven new Bindings, conditional combat bonuses, six rarity categories, +6 forging with risk, saved boss pity and missing-piece collection marks. Keep the existing five-wave 3D expedition loop.

New players get a blade/shield and first Binding ingredients. Existing profiles retain items and currencies. Magic migrates to Uncommon. Upgrade trait contributions are rebalanced; the new per-level table applies when wave bonuses are next calculated. Current active-wave snapshots are preserved.

Review priorities: destructive upgrade confirmation/duplicate clicks; old save/socket migration; killed-enemy identity including Reaver cleaves; pity/mark settlement once; conditional power matching the animation; scrollability of all13 Sigils/11 recipes; hunting report matching the chosen seed; field/home access restrictions.

Acceptance: deterministic model/gear/rules suites, full winning runs in both stances, actual UI callbacks through risky forging and set claiming, reloaded outcomes, economy simulations, rendered screens, successful Android/Windows debug exports. Device performance/touch QA and human fun/run-length tests remain outside available verification.

Tuning targets: approximately8 gear and4 common Sigils per win plus exclusive drops;6–9 minutes including camps is a human pacing hypothesis. Combat planning, animation and camp seconds now log separately; no artificial timer slows players down. No remote analytics.

Risks: small enemy populations make regular exclusive hunting variable; optional destruction does not by itself solve hoarding; optimized gear still makes early Depth easy. Higher Depth and new conditional combinations need human testing. Future boss species require their own Sigil mapping/counter. Larger stash needs filtering. Placeholder art and store requirements remain.

Next improvement: observe first Binding creation and targeted hunts with players, then tune source-specific drop rates against matching kills and actual build changes. Avoid expanding recipes until these loops demonstrate useful decisions.

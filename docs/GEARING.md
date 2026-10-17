# Thornwake v0.5.0 — backpack, Sigils and risk

Every item packed into the 6×5 grid is active. Rotate shapes and fit a build; there are no body equipment slots. The home stash holds spare items. At camp, only packed items and this run's field finds are accessible. Defeat retains collected gear. Destruction comes from deliberate forging, corruption or salvage.

## Fresh profile and migration

New profiles start with a Normal blade (two empty sockets), a Normal shield, one Ash Sigil, one Gale Sigil, 18 scrap and no corruption shards. Select the blade → Sigils → put Ash in socket 1, Gale in socket 2. This forms Briarsteel Binding. Forge Guide explains the sequence. The recipe book is always available from the socket screen.

Existing v0.4.0 inventories, currencies and socket contents are retained; Magic becomes Uncommon. The internal `runes` save key and recipe `runes` arrays remain for backward compatibility, but UI uses Sigils/Bindings. Profile schema is now2; absent new Sigils, marks and boss counters initialize to zero. Active wave bonuses stay snapshotted until the next wave. Upgrade contributions are rebalanced to the per-level table below when bonuses are next calculated.

## Rarity and drops

| Gear quality | Share of gear rolls | Identity |
| --- | ---: | --- |
| Normal |30% | Base trait; eligible for Bindings |
| Uncommon |32% | Base + one random basic-affix roll |
| Rare |25% | Base + two basic-affix rolls |
| Epic |9% | Two basic-affix rolls + one base-specific conditional effect |
| Unique |2% | Curated named stat combination |
| Set |2% | Two basic-affix rolls and distinct-part set bonuses |

Affix rolls may choose the same trait and merge. Rarity is not a universal power ranking. All socketed rarities receive individual Sigil bonuses, but **only Normal bases** form Bindings. Epic blade/shield/coat/staff/charm/relic respectively receive Venom/Counter/Spellstep/Cover strike/Stride/Heartbloom +1.

Per kill: 4% gear, 2% common Sigil, independent matching exclusive roll, one scrap. Each regular wave clear gives one gear; boss clear gives one gear plus one bonus gear. Common Sigils are guaranteed after waves2,4,5. Each of those six clear/boss reward sources gives four scrap. Boss victory gives one Warden mark. Rewards are committed once alongside the turn checkpoint.

The first four waves contain38 enemies total. The boss can end the last wave before all minions die, so a win usually has39–46 kills. Expected gear:6 + kills×0.04 =7.56–7.84. Expected common Sigils:3 + kills×0.02 =3.78–3.92. Exclusive Sigils are **additional** to those common quantities.

Corruption shards:0.1% per regular kill and25% on the Warden kill; no guaranteed shard per victory. A46-kill clear averages0.295 shards before considering run failures. Corruption odds below remain unchanged.

## Sigil hunting

Common pool: Ash (Edge1), Root (Vitality2), Gale (Focus1), Stone (Ward1), Ember (Bulwark1), Echo (Leech1), all equally weighted within a common drop.

| Enemy | Exclusive Sigil | Effect | Chance per matching kill |
| --- | --- | --- | ---: |
| Briar Scout |Trail |Stride1 |3% |
| Shellback |Carapace |Bulwark1 + Counter1 |3% |
| Thorn Archer |Barb |Cover strike2 |3% |
| Fen Viper |Venom |Venom2 |3% |
| Ash Brute |Ruin |Armor break2 |3% |
| Ruin Hexer |Hex |Spellstep1 |3% |
| Heartroot Warden |Heartroot |Leech1 + Heartbloom1 |15% plus protection |

The Warden's Sigil is guaranteed on the10th kill without its exclusive drop. Any exclusive drop resets its counter. This persists across runs and reloads. Common drops do not reset that counter. Duplicate kill settlement cannot roll again or advance it. Protection raises the long-run effective drop rate above15%.

Scout Expedition previews the exact seeded populations before starting. Rescout changes the seed without cost; no loot is awarded for scouting. Hunting Guide lists enemy behavior, exclusive source/effect/chance and current Warden dry streak. The current game contains one boss species; future bosses need their own mapping, counter and recipe.

## Conditional effects and caps

Basic caps: Edge2, Vitality12, Ward3, Focus2, Leech2, Bulwark2. Guard during a wave caps at4. Camp boons are applied separately and can exceed some permanent item caps.

| Effect | Rule | Packed cap |
| --- | --- | ---: |
| Stride | Extra empty cells beyond the normal two per route |2 |
| Counter | Spend one starting guard on the first route hit for +2 power |1 |
| Cover strike | Extra first-hit power if the route starts on cover |3 |
| Venom | Extra route-hit power against an enemy already below max HP |3 |
| Armor break | Extra route-hit power against shellbacks and brutes |4 |
| Spellstep | After a kill, gain guard if starting in old magic marks and landing outside all of them |2 |
| Heartbloom | Extra healing on routes with at least five kills, after retaliation |2 |
| Temper | Extra first-hit power against enemies with max HP≥4 |2 |

Venom is **follow-up damage**, not a new damage-over-time status. The mob's existing poison remains separate. Conditional attack bonuses do not modify Reaver's secondary cleave. Heartbloom and Leech cannot revive lethal damage. Spellstep requires a kill to prevent farming guard by walking in place. The route preview and attack animation use the same reducer hit records.

## Bindings

Exact base type, exact socket count, exact order; retain individual Sigil bonuses in addition to the recipe bonus. Insert/removal is free. Wrong orders still grant individual effects. Adding an extra socket can deactivate a Binding.

| Binding | Sigils in order | Eligible bases | Additional bonus |
| --- | --- | --- | --- |
| Briarsteel |Ash → Gale |blade/staff |Edge1, Focus1 |
| Trailguard |Root → Stone |shield/coat |Bulwark1, Ward1 |
| Cinderwake |Ember → Ash → Gale |blade/staff |Edge1, Focus1 |
| Waking Grove |Root → Echo → Stone |coat/relic |Leech1, Vitality3 |
| Trailweft |Gale → Trail |blade/staff |Stride1, Focus1 |
| Ironbloom |Stone → Carapace → Echo |coat/relic |Counter1, Bulwark1 |
| Thornflight |Gale → Barb → Ash |blade/staff |Cover strike2, Stride1 |
| Venomwake |Ash → Venom |blade/staff |Venom2 |
| Ashbreaker |Stone → Ruin |shield/blade |Armor break2 |
| Hexweave |Gale → Hex → Stone |staff/coat |Spellstep1, Ward1 |
| Heartwake |Root → Heartroot → Echo |coat/relic |Heartbloom1, Vitality2 |

## Upgrades and destruction

Each level costs6×target level scrap:6,12,18,24,30,36. +1–+3 always succeed. +4/+5/+6 have5%/10%/20% destruction respectively. There is no no-change roll. The item and all inserted Sigils are permanently lost on destruction; scrap is spent either way. Safe upgrades show their cost on the button. Risky attempts require a modal quote with odds, next effect and loss warning. Stale/double confirmations cannot trigger another tier.

Each level adds +1 to its listed trait, cumulative:

| Base | +1 | +2 | +3 | +4 | +5 | +6 |
| --- | --- | --- | --- | --- | --- | --- |
| Blade |Edge |Vitality |Focus |Temper |Vitality |Temper |
| Shield |Ward |Vitality |Bulwark |Counter |Vitality |Temper |
| Coat |Vitality |Vitality |Ward |Spellstep |Vitality |Heartbloom |
| Staff |Focus |Vitality |Ward |Cover strike |Vitality |Temper |
| Charm |Vitality |Vitality |Bulwark |Stride |Vitality |Heartbloom |
| Relic |Leech |Vitality |Ward |Heartbloom |Vitality |Temper |

These spread gains across traits so safe upgrades do not merely saturate one capped stat. Current aggregate caps can still reduce a particular upgrade's immediate value.

One corruption shard buys one attempt:90% adds +2 to one random trait from the full trait pool,10% destroys the item and its inserted Sigils. A modifier may be irrelevant to the current build or capped. Successful corruption seals further upgrades and socket additions; Sigil insertion/removal remains possible. The full +4→+5→+6→corruption sequence has61.56% survival, before any usefulness judgment. No passive item decay or gear loss on death.

Adding sockets still costs8 +4×existing socket count, up to the base limit (1–3). Salvage is separately confirmed, gives3 +2×tier scrap and returns inserted Sigils. Removing valuable Sigils before risky forging protects the Sigils, but breaks their Binding until reinserted.

## Sets and duplicate protection

Warden: shield/coat/charm; two distinct parts grant Ward1; three add Bulwark1/Leech1. Wayfarer: blade/staff/relic; two grant Vitality2; three add Focus1/Leech1. Duplicate bases do not count twice.

At home: Forge Guide → Set collection. Six Warden marks buy the chosen base's Set version. A mark is granted once per boss victory. This is a deterministic missing-piece route; it does not change the random2% Set drop rate. Marks cannot be redeemed at camp.

All odds are initial Thornwake design values, not claimed industry benchmarks. Offline saves remain editable; this is not tamper-resistant server storage.

## v0.6.0 follow-up

Pack Tools adds sort/filter/search, favorites, destructive-operation locks and capped comparisons. Remove all safely recovers socketed Sigils. Camp boons no longer repeat and combined Edge caps at3 on new waves. Existing wave snapshots stay intact. Upgrade/drop/corruption odds above are unchanged.

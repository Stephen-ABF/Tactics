# Backpack and forge reference

## Backpack controls

Select a packed item by tapping one of its occupied cells, or select a stash card. The small shape preview shows the current rotation. Choose **Place / Move**, then tap the top-left origin cell where you want that shape. Invalid overlap/out-of-bounds placements leave the item unchanged. **Rotate 90** rotates in place if it fits; stash it first if blocked. **To stash** removes its bonuses. At camp this button becomes **To field**, so the item stays accessible during that camp.

Stash cards are paginated three at a time. The backpack screen shows the aggregate active bonuses and selected-item details. **Done** returns to the title or camp. No inventory management occurs during an attack animation.

## Item catalog and modifiers

Six bases: Briar Blade (3 cells), Root Shield (3-cell L), Moss Coat (2 × 2), Gale Staff (3 cells), Thorn Charm (1 cell), Grove Relic (4-cell T). Rotation is allowed. Base shapes remain fixed after upgrading/corrupting.

Normal items have a base trait. Magic items add one rolled trait; rare and set items add two rolled traits with values 1–2. Unique items have curated identities: Razorwake, Last Bastion, Barkbound, Skythread, Heartseed and Bloodroot, each tied to its base with fixed trait combinations.

| Trait | Combat effect | Aggregate cap |
| --- | --- | --- |
| Edge | Additional power on every route hit | 2 |
| Vitality | Additional maximum health over the baseline 14 | 12 |
| Ward | Starting guard each wave | 3 |
| Focus | Starting momentum each route | 2 |
| Leech | Heal after retaliation on routes with at least 5 kills; cannot revive a lethal hit | 2 |
| Bulwark | Gain guard after a route with 1–3 kills; total guard cap 4 | 2 |

Only items inside the backpack count. Rune bonuses, runewords, upgrades, set bonuses and corruption modifiers combine before these caps. An extra modifier may free packing space without increasing an already capped trait.

## Sockets and runewords

Open **Runes**, select a numbered socket, then choose an available rune. Rune removal is free and returns the rune to your pouch, encouraging experimentation. Rune counts persist. Socket limits are 1–3 depending on the base; they do not change backpack size.

| Rune | Individual effect |
| --- | --- |
| Ash | Edge +1 |
| Root | Vitality +2 |
| Gale | Focus +1 |
| Stone | Ward +1 |
| Ember | Bulwark +1 |
| Echo | Leech +1 |

Runewords require a **normal base**, the exact socket count, the permitted base type, and the exact rune order. Magic/rare/unique/set gear can use ordinary rune bonuses but cannot form runewords. The recipe book is visible in the rune screen; no external lookup is required.

| Runeword | Order | Bases | Additional bonus beyond the runes |
| --- | --- | --- | --- |
| Briarsteel | Ash → Gale | Blade/staff, exactly 2 sockets | Edge +1, Focus +1 |
| Trailguard | Root → Stone | Shield/coat, exactly 2 sockets | Bulwark +1, Ward +1 |
| Cinderwake | Ember → Ash → Gale | Blade/staff, exactly 3 sockets | Edge +1, Focus +1 |
| Waking Grove | Root → Echo → Stone | Coat/relic, exactly 3 sockets | Leech +1, Vitality +3 |

Wrong orders still give ordinary rune effects. Removing a required rune or adding an extra socket deactivates the word. Upgrade tier and corruption do not invalidate an otherwise matching word.

## Sets

**Warden:** shield, coat, charm. Two distinct parts give Ward +1; three also give Bulwark +1 and Leech +1.

**Wayfarer:** blade, staff, relic. Two distinct parts give Vitality +2; three also give Focus +1 and Leech +1.

Duplicate copies of the same base do not count as different set parts. The whole set must be packed to supply its bonuses.

## Forging and corruption

Upgrade costs: 6, 12, 18 scrap for tiers +1, +2, +3. Each tier increases that base's inherent trait by 1. Rolled traits and socketed runes are preserved.

Adding a socket costs 8 + 4 × the current socket count, up to the base limit. Adding a third socket to a completed two-rune word intentionally deactivates it; its exact-count requirement still applies.

One corruption shard buys one attempt:

- **90%:** add +2 to one randomly chosen trait. The upgrade tier and socket count are then sealed.
- **10%:** permanently delete the item and all inserted runes.

You can corrupt an active runeword or set piece. Successfully corrupted items still allow inserting/removing runes, and still contribute their normal set/runeword effects. You cannot corrupt an item again, upgrade it again, or add more sockets after success. The game displays the odds and asks for explicit in-game confirmation before spending the shard.

These are Thornwake's own initial design probabilities, not claimed rates from Diablo, Path of Exile or Project Diablo 2. Outcomes are saved immediately during normal operation. This is offline local storage, not tamper-resistant anti-cheat.

Salvage is a separate confirmation: delete an item for 3 + 2 × upgrade-tier scrap and recover its socketed runes.

## Drops, persistence and run flow

Per defeated enemy, independent rolls: 12% gear, 10% rune, 3% corruption shard, plus 1 scrap. A clear grants a guaranteed gear item and rune, 4 scrap, and an additional 3% shard roll. Multiple drops can occur together. Gear quality odds conditional on a gear drop: 28% normal, 32% magic, 25% rare, 7% unique, 8% set. Base type is chosen uniformly. A dropped item has a 30% chance to start with one empty socket.

The starting profile has six sample items, two of each rune, 18 scrap and two corruption shards so you can test every system without first grinding. Gear is active only if packed. New drops are automatically collected and saved at move completion. Collected gear/runes remain after defeat or app closure; an unfinished combat turn has not awarded its loot yet.

Every loot source uses a run identifier and source key to avoid duplicate awards. Retrying creates a new expedition; farming repeated runs is allowed. Active encounters and camp selections resume after reopening the app. Crafting and backpack changes save immediately. Legacy Phase 1 counters/settings are retained and receive a starter gear profile when absent.

At a new grove, packed bonuses are snapshotted for combat. Camp gear changes preserve missing health, then apply the usual +3 camp recovery; swapping Vitality does not grant a separate free full heal. The tutorial intentionally uses baseline combat without gear modifiers.


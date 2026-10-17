# Thornwake — provisional art handoff

Names and lore below are a working direction for the artist, pending your approval as canon. The world has been overtaken by an unnatural thorn awakening. A lone Wayfarer carries relics through forest, ash, frozen wetlands and abandoned sanctuaries to confront the corrupted Heartroot Warden. Warden equipment protects and sustains; Wayfarer equipment favors movement and chained attacks. Ash, Root, Gale, Stone, Ember and Echo are the Sigil vocabulary. Corruption should look powerful, beautiful and dangerous rather than demonic gore.

## Visual direction

Stylized, readable, low-detail fantasy. Warm parchment highlights, dark teal interface, restrained green/ochre/icy blue/lavender zones. Keep characters readable at roughly 60–80 screen pixels on the 6×6 board. Distinguish enemies by silhouette, weapon and markings as well as color. Keep the ground grid and telegraph symbols visible. The current primitive geometry is replaceable placeholder art.

| Zone ID / filename | Subject | Shapes and palette |
| --- | --- | --- |
| briar | Briarwood | Bent pines, moss, green gold, thorn spirals |
| ash | Ashen Hollow | Broken basalt, ember cracks, rust orange |
| frost | Frostfen | Faceted ice, reeds, mist blue |
| ruins | Moonlit Ruins | Broken arch pillars, rune stone, muted lavender |
| heart | Heartroot Sanctum | Root altar, antler branches, plum and pale amber |

## Drop-in replacements

Actor filenames use the **exact case-sensitive IDs** below in `art_overrides/actors/`. Priority: `.tscn`, then `.glb`, then `.png`. Remove higher-priority files to use PNGs.

| ID | Actor | Recognition |
| --- | --- | --- |
| hero | Wayfarer | Teal hood, short sword, small shield, cape |
| s | Briar Scout | Small pointed ears, dagger |
| h | Shellback | Broad round shell and pale armor ridges |
| a | Thorn Archer | Hood and large curved bow |
| v | Fen Viper | Coiled snake, leaf crest |
| b | Ash Brute | Heavy shoulders, hammer, charge pose |
| w | Ruin Hexer | Tall hood and orb staff |
| B | Heartroot Warden | Larger root creature, antler branches, bright core |

**PNG route:** transparent full-body sprite, suggested 512×512 (boss 768×768), centered horizontally with feet at image bottom. Automatic camera-facing Sprite3D. Ordinary images display 0.95 world units tall; boss 1.55. Whole-image dash/lunge/hit/death animation works; individual limb animation requires a model. A PNG on the 3D board remains a billboard, not a fully modeled character.

**Model route:** glTF binary `.glb` or Godot `.tscn`, Node3D root, Y up, ground at Y=0, local forward -Z, ordinary height about 0.95 and width <0.8. Boss height about1.55. Keep every model within its tile footprint. Optional Node3D pivots named LeftArm, RightArm, LeftLeg, RightLeg receive procedural motion; otherwise the entire model bobs/lunges. No skeleton or AnimationPlayer clips are required or automatically played. Runtime flashes restore materials after hits.

Floor textures: `art_overrides/floors/{zone_id}.png`, suggested 512×512 seamless, subdued contrast, no baked grid/telegraphs. Each board tile receives the texture. Zone scenery: `art_overrides/zones/{zone_id}.tscn`, centered origin, Y up; keep action cells unobstructed. Scene is scenery only, not collision or gameplay. Test every board size before shipping. Restart the game after importing replacements.

UI icons, hero portraits, Sigil icons and animated sprite sheets are not currently auto-import slots; those need a separate integration pass. Do not put text into generated art. Keep the current danger arrows/crosses and tile selection as code-rendered overlays.

## Animation brief

Preserve anticipation → dash → strike → enemy impact → retaliation → player hit → recovery. Distinguish blocked hits with shield response, poison with green impact, magic with purple orb and boss with strong ground marks. Reduced motion removes camera shake; timings and danger information stay intact. Keep enemy tell readable before Strike is tapped. Deliver source assets plus licensing provenance; no third-party franchise copies.

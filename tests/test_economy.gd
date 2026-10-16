extends SceneTree
const G=preload("res://scripts/gear.gd")
const R=preload("res://scripts/rules.gd")
var checks=0
var failures=0
var rng=RandomNumberGenerator.new()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(message)
func profile() -> Dictionary:
	var p=G.fresh();p.items=[];p.scrap=1000;p.shards=100
	return p
func add(p: Dictionary,base: String="blade",rarity: String="normal") -> Dictionary:
	var i=G.make_item(base,rarity,rng);p.items.append(i);return i
func arena(gear: Dictionary={}) -> Dictionary:
	var s=R.new_board(42,0,"Duelist",14,gear)
	for tile in s.tiles:tile.kind=".";tile.hp=1;tile.max_hp=1
	s.player=6;s.tiles[0].kind="s" # Keep a distant enemy so a walk does not end the wave.
	return s
func foe(s: Dictionary,cell: int,kind: String,hp: int,maximum: int=-1) -> void:
	s.tiles[cell].kind=kind;s.tiles[cell].hp=hp;s.tiles[cell].max_hp=hp if maximum<0 else maximum
func _initialize() -> void:
	rng.seed=2001
	var p=G.fresh()
	check(p.items.size()==2 and p.shards==0 and p.runes.Ash==1 and p.runes.Gale==1,"Production starter has two safe bases and first Binding ingredients")
	for i in p.items:check(i.rarity=="normal","Starter has no chase-quality item")
	var old=p.duplicate(true);old.version=1;old.items[1].rarity="magic";old.items[0].tier=3;old.runes={"Ash":4,"Gale":2};old.erase("marks");old.erase("boss_pity")
	var migrated=G.normalize(JSON.parse_string(JSON.stringify(old)))
	check(migrated.items[1].rarity=="uncommon" and migrated.items[0].tier==3 and migrated.runes.Ash==4 and migrated.runes.Heartroot==0,"Legacy rarity, gear tiers and pouch migrate without a reset")
	for recipe in G.BINDINGS:
		var data=G.BINDINGS[recipe]
		for base in data.bases:
			check(data.runes.size()<=G.BASES[base].max_sockets,"Recipe socket count reachable on every listed base")
			var i=G.make_item(base,"normal",rng);i.sockets=data.runes.duplicate()
			check(G.word(i)==recipe,"Every exact recipe activates")
			var roundtrip=profile();roundtrip.items=[i]
			check(G.word(G.normalize(JSON.parse_string(JSON.stringify(roundtrip))).items[0])==recipe,"Binding and exclusive sockets persist")
	for base in G.BASES:
		var i=G.make_item(base,"epic",rng)
		check(i.stats.get(G.EPIC_EFFECTS[base],0)>0,"Epic has actual conditional effect")
	p=profile();var i=add(p);i.sockets=["Ash","Gale"]
	for level in 3:
		G.upgrade(p,i.id)
		check(i.tier==level+1,"Safe upgrades always advance")
	var before=p.duplicate(true);G.upgrade(p,i.id)
	check(p==before,"Risky upgrade requires explicit acceptance and spends nothing otherwise")
	var counts={}
	for tier in [3,4,5]:
		var broken=0
		for sample in 2000:
			p=profile();i=add(p);i.tier=tier;i.sockets=["Ash","Gale"]
			var ash=p.runes.Ash;var scrap=p.scrap
			rng.seed=sample+10000
			G.upgrade(p,i.id,rng,true,tier+1)
			if G.find(p,i.id).is_empty():broken+=1;check(p.runes.Ash==ash,"Broken upgrade consumes inserted Sigils")
			else:check(i.tier==tier+1 and i.sockets==["Ash","Gale"],"Successful risky upgrade preserves sockets")
			check(p.scrap==scrap-(tier+1)*6,"Upgrade charges once on either outcome")
		counts[str(tier+1)]=broken
		check(absf(float(broken)/2000-G.UPGRADE_RISKS[tier])<0.03,"Upgrade sample tracks configured destruction odds")
	p=profile();i=add(p);i.tier=3
	for seed_value in 100:
		var trial=p.duplicate(true);rng.seed=seed_value;G.upgrade(trial,i.id,rng,true,4)
		if not G.find(trial,i.id).is_empty():
			before=trial.duplicate(true);G.upgrade(trial,i.id,rng,true,4)
			check(trial==before,"Stale confirmation cannot attempt the next risk tier");break
	p=profile();i=add(p);i.tier=6
	before=p.duplicate(true);G.upgrade(p,i.id,rng,true)
	check(p==before,"Maximum +6 cannot spend or roll")
	check(G.normalize(JSON.parse_string(JSON.stringify(p))).items[0].tier==6,"High upgrades survive reload")
	var rarity_counts={}
	rng.seed=20261016
	for sample in 100000:
		var rarity=G.draw_rarity(rng);rarity_counts[rarity]=int(rarity_counts.get(rarity,0))+1
	for rarity in G.RARITY_WEIGHTS:check(absf(float(rarity_counts.get(rarity,0))/100000-G.RARITY_WEIGHTS[rarity]/100.0)<0.01,"Rarity distribution: "+rarity)
	var exclusive_counts={}
	for kind in G.EXCLUSIVES:
		p=profile();rng.seed=1234
		for sample in 2000:
			G.roll_loot(p,"mob:%d" % sample,rng,{"type":"mob","kind":kind});p.items.clear()
		for other in G.EXCLUSIVES:
			if other!=kind:check(p.runes[G.EXCLUSIVES[other]]==0,"Enemy cannot drop another species' exclusive Sigil")
		exclusive_counts[kind]=p.runes[G.EXCLUSIVES[kind]]
		if kind!="B":check(p.runes[G.EXCLUSIVES[kind]]>25 and p.runes[G.EXCLUSIVES[kind]]<100,"Regular exclusive rate near 3%")
	p=profile();p.boss_pity.B=9;rng.seed=0
	G.roll_loot(p,"boss-pity",rng,{"type":"mob","kind":"B"})
	check(p.runes.Heartroot==1 and p.boss_pity.B==0,"Tenth dry boss kill guarantees its Sigil and resets streak")
	before=p.duplicate(true);G.roll_loot(p,"boss-pity",rng,{"type":"mob","kind":"B"})
	check(p==before,"Duplicate source cannot reroll drops or advance pity")
	p=profile();p.boss_pity.B=7
	check(G.normalize(JSON.parse_string(JSON.stringify(p))).boss_pity.B==7,"Boss pity survives save reload")
	p=profile();G.roll_loot(p,"boss-reward",rng,{"type":"boss_reward"})
	check(p.items.size()==1 and p.marks==1,"Boss bonus grants gear and exactly one collection mark")
	before=p.duplicate(true);G.roll_loot(p,"boss-reward",rng,{"type":"boss_reward"})
	check(p==before,"Boss collection reward is idempotent")
	p.marks=6;G.redeem_set(p,"coat")
	check(p.marks==0 and p.items.back().rarity=="set" and p.items.back().base=="coat","Six marks select a missing set base")
	before=p.duplicate(true);G.redeem_set(p,"coat")
	check(p==before,"Cannot claim a second piece without marks")
	var s=arena({"counter":1});s.guard=1;foe(s,7,"h",4)
	var out=R.resolve(s,[7]);check(out.attacks[0].power==3 and out.state.guard==0,"Counter spends starting guard for first-hit power")
	s=arena({"cover_power":2});s.tiles[6].kind="c";foe(s,7,"h",4)
	check(R.resolve(s,[7]).attacks[0].power==3,"Barb rewards starting in cover")
	s=arena({"wound":2});foe(s,7,"h",3,4)
	out=R.resolve(s,[7]);check(out.kills==1 and out.defeated[0].kind=="h","Venom follow-up hits wounded armor and preserves killed type")
	s=arena({"temper":1});foe(s,7,"h",4)
	check(R.resolve(s,[7]).attacks[0].power==2,"High upgrade Temper affects armored first hit")
	s=arena({"hexstep":1});foe(s,0,"w",3);s.tiles[0].marks=[6,7];foe(s,3,"s",1);foe(s,7,"s",1)
	out=R.resolve(s,[3]);check(out.state.guard==1,"Hex grants guard when escaping old magic marks")
	check(R.resolve(s,[7]).damage==1,"Remaining in magic marks cannot gain escape guard")
	s=R.new_board(8,1,"Duelist",8,{"bloom":1});s.player=0
	for tile in s.tiles:tile.kind=".";tile.hp=1;tile.max_hp=1
	for cell in [1,2,3,7,6]:foe(s,cell,"s",1)
	out=R.resolve(s,[1,2,3,7,6]);check(out.kills==5 and out.healing==1,"Heartroot heals after a five-kill route")
	var saved=R.normalize_saved(JSON.parse_string(JSON.stringify(s)))
	check(saved==s,"Conditional combat stats survive checkpoint normalization")
	var gear_total=0;var common_total=0;var shard_total=0;var gear_samples=[]
	rng.seed=888
	for run in 2000:
		p=profile()
		for sample in 46:
			G.roll_loot(p,"kill:%d" % sample,rng,{"type":"mob","kind":"B" if sample==45 else "s"})
		for wave in 5:G.roll_loot(p,"clear:%d" % wave,rng,{"type":"clear","wave":wave})
		G.roll_loot(p,"boss",rng,{"type":"boss_reward"})
		gear_samples.append(p.items.size());gear_total+=p.items.size();shard_total+=p.shards-100
		for sigil in G.COMMON_SIGILS:common_total+=p.runes[sigil]-(1 if sigil in ["Ash","Gale"] else 0)
	gear_samples.sort()
	var means={"gear":gear_total/2000.0,"common_sigils":common_total/2000.0,"shards":shard_total/2000.0,"gear_p10":gear_samples[200],"gear_median":gear_samples[1000],"gear_p90":gear_samples[1800]}
	check(absf(means.gear-7.84)<0.2,"Actual reducer loot averages about eight gear per full clear")
	check(absf(means.common_sigils-3.92)<0.2,"Common Sigils average about four per full clear")
	check(absf(means.shards-0.295)<0.08,"Corruption shards average about one per 3–4 full clears")
	var report={"simulated_runs":2000,"kills_per_run":46,"means":means,"upgrade_destroyed_per_2000":counts,"rarity_draws_100000":rarity_counts,"exclusive_drops_per_2000_matching_kills":exclusive_counts,"human_playtesting":false}
	var file=FileAccess.open("res://tests/economy_results.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	print("ECONOMY: %d checks; %d failures; %s" % [checks,failures,JSON.stringify(means)])
	quit(1 if failures else 0)

extends SceneTree
const G=preload("res://scripts/gear.gd")
const R=preload("res://scripts/rules.gd")
const S=preload("res://scripts/save_store.gd")
var checks=0
var failures=0
var rng=RandomNumberGenerator.new()
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(message)
func empty() -> Dictionary:
	var p=G.fresh()
	p.items=[]
	p.scrap=100
	p.shards=100
	return p
func item(p: Dictionary, base: String, rarity: String="normal") -> Dictionary:
	var i=G.make_item(base,rarity,rng)
	p.items.append(i)
	return i
func _initialize() -> void:
	rng.seed=70
	var p=empty()
	var sword=item(p,"blade")
	var shield=item(p,"shield")
	check(G.place(p,sword.id,0,0).begins_with("Packed"),"Place shape")
	check(not G.fits(p,shield,0,0),"Overlap rejected")
	check(not G.fits(p,sword,5,0),"Right edge rejected")
	check(not G.fits(p,sword,-1,0),"Negative edge rejected")
	check(G.fits(p,sword,0,0),"Self excluded during move")
	check(G.rotate(p,sword.id).begins_with("Rotated") and G.cells(sword)==[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2)],"Quarter turn normalized")
	check(not G.fits(p,sword,0,4),"Bottom edge rejected")
	check(G.at(p,0,2)==sword.id and G.at(p,1,0)=="","Occupancy follows rotated footprint")
	sword.sockets=["",""]
	var ash=p.runes.Ash
	G.insert_rune(p,sword.id,0,"Ash")
	check(p.runes.Ash==ash-1,"Insertion consumes one rune")
	G.insert_rune(p,sword.id,0,"Gale")
	check(p.runes.Gale==2,"Occupied socket cannot consume rune")
	G.insert_rune(p,sword.id,1,"Gale")
	check(G.word(sword)=="Briarsteel" and G.quality(sword)=="runeword","Correct base, exact count and order activates word")
	check(G.item_stats(sword).edge==3,"Rune and runeword bonuses combine")
	check(G.bonuses(p).edge==2,"Global edge cap applied")
	G.remove_rune(p,sword.id,0)
	check(G.word(sword)=="" and p.runes.Ash==ash,"Removal recovers rune and disables word")
	G.insert_rune(p,sword.id,0,"Gale")
	G.remove_rune(p,sword.id,1)
	G.insert_rune(p,sword.id,1,"Ash")
	check(G.word(sword)=="","Wrong order stays ordinary sockets")
	var magic=item(p,"blade","magic")
	magic.sockets=["Ash","Gale"]
	check(G.word(magic)=="","Magic bases cannot form words")
	shield.sockets=["Ash","Gale"]
	check(G.word(shield)=="","Wrong base cannot form word")
	sword.sockets=["Ash","Gale"]
	var scrap=p.scrap
	G.upgrade(p,sword.id)
	check(sword.tier==1 and sword.sockets==["Ash","Gale"] and p.scrap==scrap-6,"Upgrade preserves sockets and consumes exact cost")
	G.add_socket(p,sword.id)
	check(sword.sockets.size()==3 and G.word(sword)=="","Extra socket disables exact-count word")
	var before=p.duplicate(true)
	G.add_socket(p,sword.id)
	check(p==before,"Over limit socket operation is atomic")
	p.scrap=0
	before=p.duplicate(true)
	G.upgrade(p,sword.id)
	check(p==before,"Insufficient cost cannot modify item")
	var corrupt_rng=RandomNumberGenerator.new()
	corrupt_rng.seed=10
	var result={}
	for seed_value in 100:
		corrupt_rng.seed=seed_value
		var copy=p.duplicate(true)
		result=G.corrupt(copy,sword.id,corrupt_rng)
		if result.ok and not result.destroyed:
			var found=G.find(copy,sword.id)
			check(not found.corruption.is_empty(),"Successful corruption adds modifier")
			var sealed=copy.duplicate(true)
			G.upgrade(copy,sword.id); G.add_socket(copy,sword.id); G.corrupt(copy,sword.id,corrupt_rng)
			check(copy==sealed,"Corrupted item seals further corruption, upgrading and socket count")
			G.remove_rune(copy,sword.id,0)
			check(G.find(copy,sword.id).sockets[0]=="","Sealed item still permits rune recovery")
			break
	for seed_value in 100:
		corrupt_rng.seed=seed_value
		var copy=p.duplicate(true)
		var rune_count=copy.runes.Ash
		result=G.corrupt(copy,sword.id,corrupt_rng)
		if result.ok and result.destroyed:
			check(G.find(copy,sword.id).is_empty() and copy.runes.Ash==rune_count,"Destruction removes gear without recovering socketed runes")
			break
	p=empty()
	var a=item(p,"shield","set")
	var b=item(p,"charm","set")
	a.stats={}; b.stats={}
	G.place(p,a.id,0,0); G.place(p,b.id,3,0)
	check(G.bonuses(p).ward==1,"Two distinct Warden parts activate set")
	var duplicate=item(p,"shield","set")
	duplicate.stats={}
	G.place(p,duplicate.id,4,0)
	check(G.bonuses(p).leech==0,"Duplicate set part cannot complete three-piece bonus")
	var c=item(p,"coat","set")
	c.stats={}
	G.place(p,c.id,0,3)
	check(G.bonuses(p).leech==1 and G.bonuses(p).bulwark==1,"Three distinct set parts activate bonus")
	var parsed=JSON.parse_string(JSON.stringify(p))
	var normalized=G.normalize(parsed)
	check(G.bonuses(normalized)==G.bonuses(p),"Inventory survives JSON normalization")
	check(normalized.items.size()==p.items.size(),"All valid items persist")
	var invalid=p.duplicate(true)
	invalid.items.append(invalid.items[0].duplicate(true))
	invalid.items[1].x=0; invalid.items[1].y=0
	normalized=G.normalize(invalid)
	check(normalized.items.size()==p.items.size() and normalized.items[1].location=="stash","Duplicate IDs dropped and overlapping placements recovered to stash")
	p=empty()
	rng.seed=707
	var drops=G.roll_loot(p,"unique-roll",rng,true)
	check(p.items.size()==1 and drops.size()>=2,"Grove clear guarantees gear and rune")
	before=p.duplicate(true)
	check(G.roll_loot(p,"unique-roll",rng,true).is_empty() and p==before,"Loot source can be settled only once")
	G.bank_field(p)
	check(p.items[0].location=="stash","Field finds become persistent stash gear")
	var destroyed=0
	for seed_value in 1000:
		var profile=empty()
		var gear=item(profile,"charm")
		corrupt_rng.seed=seed_value
		if G.corrupt(profile,gear.id,corrupt_rng).destroyed: destroyed+=1
	check(destroyed>=65 and destroyed<=135,"1000 seeded corruption samples broadly match 10% destruction")
	print("GEAR TESTS: %d checks; %d failures; simulated corruption destruction %d/1000" % [checks,failures,destroyed])
	quit(1 if failures else 0)

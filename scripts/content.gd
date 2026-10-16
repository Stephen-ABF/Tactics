class_name ThornContent
extends RefCounted
# Provisional lore names and replaceable art direction, not final canon.
const SIDES=[3,4,5,6,6]
const ZONES={
 "briar":{"name":"Briarwood","floor":"4e6847","alternate":"647851","rim":"314c39","sky":"10282c","prop":"pine","accent":"9bce84"},
 "ash":{"name":"Ashen Hollow","floor":"695046","alternate":"805d49","rim":"42373c","sky":"291d29","prop":"basalt","accent":"ef9756"},
 "frost":{"name":"Frostfen","floor":"668489","alternate":"81a0a1","rim":"3d5665","sky":"172a3e","prop":"crystal","accent":"9cdef1"},
 "ruins":{"name":"Moonlit Ruins","floor":"69677e","alternate":"7d7b91","rim":"3c3c55","sky":"1d2037","prop":"pillar","accent":"c0a7ed"},
 "heart":{"name":"Heartroot Sanctum","floor":"534763","alternate":"6e5872","rim":"362d44","sky":"21152f","prop":"root","accent":"e3a47a"}}
const ENEMIES={
 "s":{"name":"Briar Scout","hp":1,"damage":1,"help":"Hits adjacent cells for 1."},
 "h":{"name":"Shellback","hp":4,"damage":2,"help":"Armored. Hits adjacent cells for 2; weak attacks chip its HP."},
 "a":{"name":"Thorn Archer","hp":1,"damage":2,"help":"Fires on its amber row. Cover blocks arrows."},
 "v":{"name":"Fen Viper","hp":2,"damage":1,"help":"Adjacent hit inflicts two future poison ticks if unblocked. Springs cleanse."},
 "b":{"name":"Ash Brute","hp":5,"damage":2,"help":"Strikes adjacent cells on even turns; rests on odd turns."},
 "w":{"name":"Ruin Hexer","hp":3,"damage":1,"help":"Strikes its purple ground marks. Cover cannot block magic."},
 "B":{"name":"Heartroot Warden","hp":18,"damage":2,"help":"Boss: alternating row, column and diagonal/cross strikes. Below half HP it enrages NEXT turn."}}
const BOONS={
 "edge":{"name":"Honed Edge","description":"+1 hit power this expedition.","stats":{"edge":1}},
 "stride":{"name":"Trail Boots","description":"Cross one additional empty cell per route.","stats":{"stride":1}},
 "ward":{"name":"Spirit Guard","description":"+1 starting guard each remaining wave.","stats":{"ward":1}},
 "leech":{"name":"Lifebloom","description":"+1 healing on five-kill routes, after retaliation.","stats":{"leech":1}},
 "vitality":{"name":"Deep Breath","description":"+2 max health; preserve missing health at camp.","stats":{"vitality":2}},
 "pierce":{"name":"Thornbreaker","description":"+2 power against shellbacks and brutes.","stats":{"pierce":2}}}
static func zone(seed_value: int, wave: int) -> String:
	if wave==4: return "heart"
	return ["briar","ash","frost","ruins"][posmod(seed_value/2+wave,4)]
static func choices(seed_value: int,wave: int) -> Array:
	var rng=RandomNumberGenerator.new()
	rng.seed=seed_value*31+wave*103
	var keys=BOONS.keys()
	var first=rng.randi_range(0,keys.size()-1)
	var second=(first+rng.randi_range(1,keys.size()-1))%keys.size()
	return [keys[first],keys[second]]
static func combine(gear: Dictionary,boons: Array) -> Dictionary:
	var result=gear.duplicate(true)
	for id in boons:
		if BOONS.has(id):
			for stat in BOONS[id].stats: result[stat]=int(result.get(stat,0))+int(BOONS[id].stats[stat])
	for stat in result: result[stat]=clampi(int(result[stat]),0,20)
	result.ward=mini(4,int(result.get("ward",0)))
	result.stride=mini(2,int(result.get("stride",0)))
	return result

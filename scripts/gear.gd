class_name ThornGear
extends RefCounted
const WIDTH=6
const HEIGHT=5
const BASES={
 "blade":{"name":"Briar Blade","shape":[[0,0],[1,0],[2,0]],"stat":"edge","max_sockets":3},
 "shield":{"name":"Root Shield","shape":[[0,0],[0,1],[1,1]],"stat":"ward","max_sockets":2},
 "coat":{"name":"Moss Coat","shape":[[0,0],[1,0],[0,1],[1,1]],"stat":"vitality","max_sockets":3},
 "staff":{"name":"Gale Staff","shape":[[0,0],[0,1],[0,2]],"stat":"focus","max_sockets":3},
 "charm":{"name":"Thorn Charm","shape":[[0,0]],"stat":"vitality","max_sockets":1},
 "relic":{"name":"Grove Relic","shape":[[0,0],[1,0],[2,0],[1,1]],"stat":"leech","max_sockets":3}}
const UNIQUES={"blade":{"name":"Razorwake","stats":{"edge":1,"focus":1,"leech":1}},"shield":{"name":"Last Bastion","stats":{"ward":2,"bulwark":1}},"coat":{"name":"Barkbound","stats":{"vitality":4,"leech":1}},"staff":{"name":"Skythread","stats":{"focus":2,"bulwark":1}},"charm":{"name":"Heartseed","stats":{"vitality":3,"ward":1}},"relic":{"name":"Bloodroot","stats":{"leech":2,"edge":1}}}
# Legacy save field `runes` remains readable; player-facing names are Sigils/Bindings.
const COMMON_SIGILS=["Ash","Root","Gale","Stone","Ember","Echo"]
const SIGILS={"Ash":{"edge":1},"Root":{"vitality":2},"Gale":{"focus":1},"Stone":{"ward":1},"Ember":{"bulwark":1},"Echo":{"leech":1},
 "Trail":{"stride":1},"Carapace":{"bulwark":1,"counter":1},"Barb":{"cover_power":2},"Venom":{"wound":2},"Ruin":{"pierce":2},"Hex":{"hexstep":1},"Heartroot":{"leech":1,"bloom":1}}
const EXCLUSIVES={"s":"Trail","h":"Carapace","a":"Barb","v":"Venom","b":"Ruin","w":"Hex","B":"Heartroot"}
const EFFECT_HELP={"stride":"Extra empty cells per route (cap 2).","counter":"Spend 1 starting guard for +2 first-hit power per Counter (cap 1).","cover_power":"Extra first-hit power when starting on cover (cap 3).","wound":"Extra route-hit power against already wounded enemies (cap 3).","pierce":"Extra power against shellbacks/brutes (cap 4).","hexstep":"After a kill, gain guard when escaping a magic-marked start to an unmarked landing (cap 2).","bloom":"Extra healing on 5+ kills, after retaliation (cap 2).","temper":"Extra first-hit power against enemies with at least 4 max HP (cap 2)."}
const BINDINGS={
 "Briarsteel":{"runes":["Ash","Gale"],"bases":["blade","staff"],"stats":{"edge":1,"focus":1}},
 "Trailguard":{"runes":["Root","Stone"],"bases":["shield","coat"],"stats":{"bulwark":1,"ward":1}},
 "Cinderwake":{"runes":["Ember","Ash","Gale"],"bases":["blade","staff"],"stats":{"edge":1,"focus":1}},
 "Waking Grove":{"runes":["Root","Echo","Stone"],"bases":["coat","relic"],"stats":{"leech":1,"vitality":3}},
 "Trailweft":{"runes":["Gale","Trail"],"bases":["blade","staff"],"stats":{"stride":1,"focus":1}},
 "Ironbloom":{"runes":["Stone","Carapace","Echo"],"bases":["coat","relic"],"stats":{"counter":1,"bulwark":1}},
 "Thornflight":{"runes":["Gale","Barb","Ash"],"bases":["blade","staff"],"stats":{"cover_power":2,"stride":1}},
 "Venomwake":{"runes":["Ash","Venom"],"bases":["blade","staff"],"stats":{"wound":2}},
 "Ashbreaker":{"runes":["Stone","Ruin"],"bases":["shield","blade"],"stats":{"pierce":2}},
 "Hexweave":{"runes":["Gale","Hex","Stone"],"bases":["staff","coat"],"stats":{"hexstep":1,"ward":1}},
 "Heartwake":{"runes":["Root","Heartroot","Echo"],"bases":["coat","relic"],"stats":{"bloom":1,"vitality":2}}}
const RUNES=SIGILS # Compatibility for older scripts/saves.
const WORDS=BINDINGS
const COLORS={"normal":"e3e5d9","uncommon":"8cbcf5","rare":"ecd474","epic":"bd97ed","unique":"d9ab69","set":"85d692","binding":"c6a1f0"}
const RARITY_WEIGHTS={"normal":30,"uncommon":32,"rare":25,"epic":9,"unique":2,"set":2}
const STAT_NAMES={"counter":"Counter","cover_power":"Cover strike","wound":"Venom","hexstep":"Spellstep","bloom":"Heartbloom","temper":"Temper","pierce":"Armor break","stride":"Stride"}
const BASIC_STATS=["edge","vitality","ward","focus","leech","bulwark"]
const STATS=["edge","vitality","ward","focus","leech","bulwark","stride","pierce","counter","cover_power","wound","hexstep","bloom","temper"]
const CAPS={"edge":2,"vitality":12,"ward":3,"focus":2,"leech":2,"bulwark":2,"stride":2,"pierce":4,"counter":1,"cover_power":3,"wound":3,"hexstep":2,"bloom":2,"temper":2}
const EPIC_EFFECTS={"blade":"wound","shield":"counter","coat":"hexstep","staff":"cover_power","charm":"stride","relic":"bloom"}
const UPGRADE_TRAITS={"blade":["edge","vitality","focus","temper","vitality","temper"],"shield":["ward","vitality","bulwark","counter","vitality","temper"],"coat":["vitality","vitality","ward","hexstep","vitality","bloom"],"staff":["focus","vitality","ward","cover_power","vitality","temper"],"charm":["vitality","vitality","bulwark","stride","vitality","bloom"],"relic":["leech","vitality","ward","bloom","vitality","temper"]}
const UPGRADE_RISKS=[0.0,0.0,0.0,0.05,0.10,0.20]
const GEAR_CHANCE=0.04
const COMMON_CHANCE=0.02
const EXCLUSIVE_CHANCE=0.03
const BOSS_SIGIL_CHANCE=0.15
const BOSS_PITY=10
const SHARD_CHANCE=0.001
const BOSS_SHARD_CHANCE=0.25
const SET_MARK_COST=6
static func uid() -> String:
	return Crypto.new().generate_random_bytes(8).hex_encode()
static func make_item(base: String, rarity: String, rng: RandomNumberGenerator) -> Dictionary:
	rarity="uncommon" if rarity=="magic" else rarity
	var stats={}
	stats[BASES[base].stat]=1
	if rarity!="normal":
		var rolls=1 if rarity=="uncommon" else 2
		for i in rolls:
			var stat=BASIC_STATS[rng.randi_range(0,BASIC_STATS.size()-1)]
			stats[stat]=int(stats.get(stat,0))+rng.randi_range(1,2)
	if rarity=="epic":stats[EPIC_EFFECTS[base]]=int(stats.get(EPIC_EFFECTS[base],0))+1
	if rarity=="unique": stats=UNIQUES[base].stats.duplicate(true)
	var group=""
	if rarity=="set": group="Warden" if base in ["shield","coat","charm"] else "Wayfarer"
	return {"id":uid(),"base":base,"rarity":rarity,"stats":stats,"tier":0,"sockets":[],"corruption":{},"set":group,"location":"stash","x":0,"y":0,"rotation":0}
static func fresh() -> Dictionary:
	var rng=RandomNumberGenerator.new();rng.seed=801
	var p={"version":2,"items":[],"runes":{},"shards":0,"scrap":18,"rolled":[],"boss_pity":{},"marks":0}
	for sigil in SIGILS:p.runes[sigil]=0
	p.runes.Ash=1;p.runes.Gale=1
	var sword=make_item("blade","normal",rng);sword.sockets=["",""];sword.location="bag"
	var shield=make_item("shield","normal",rng);shield.location="bag";shield.x=4
	p.items=[sword,shield]
	return p
static func normalize(raw: Dictionary, preserve_field: bool = false) -> Dictionary:
	if raw.is_empty(): return fresh()
	var p={"version":2,"items":[],"runes":{},"shards":maxi(0,int(raw.get("shards",0))),"scrap":maxi(0,int(raw.get("scrap",0))),"rolled":[],"marks":maxi(0,int(raw.get("marks",0))),"boss_pity":{}}
	var pity=raw.get("boss_pity",{})
	if pity is Dictionary:
		for kind in EXCLUSIVES:
			if kind=="B":p.boss_pity[kind]=clampi(int(pity.get(kind,0)),0,BOSS_PITY-1)
	var ids=[]
	var saved_runes=raw.get("runes",{})
	if not saved_runes is Dictionary: saved_runes={}
	for rune in RUNES: p.runes[rune]=maxi(0,int(saved_runes.get(rune,0)))
	var saved_items=raw.get("items",[])
	if not saved_items is Array: saved_items=[]
	for item in saved_items:
		if not item is Dictionary or not BASES.has(item.get("base","")) or item.get("rarity","") not in ["normal","magic","uncommon","rare","epic","unique","set"]: continue
		var i=item.duplicate(true)
		if i.rarity=="magic":i.rarity="uncommon"
		if not i.get("id","") is String or i.get("id","").is_empty() or i.id in ids: continue
		ids.append(i.id)
		i.tier=clampi(int(i.get("tier",0)),0,6)
		i.rotation=posmod(int(i.get("rotation",0)),4)
		i.x=int(i.get("x",0)); i.y=int(i.get("y",0))
		i.location="bag" if i.get("location","")=="bag" else ("field" if preserve_field and i.get("location","")=="field" else "stash")
		i.set=str(i.get("set","")) if i.rarity=="set" else ""
		i.stats=clean_stats(i.get("stats",{}))
		i.corruption=clean_stats(i.get("corruption",{}))
		var sockets=[]
		var saved_sockets=i.get("sockets",[])
		if not saved_sockets is Array: saved_sockets=[]
		for rune in saved_sockets:
			if sockets.size()>=BASES[i.base].max_sockets: break
			sockets.append(str(rune) if RUNES.has(rune) else "")
		i.sockets=sockets
		if i.location=="bag" and not fits(p,i,i.x,i.y,i.rotation): i.location="stash"
		p.items.append(i)
	var saved_rolls=raw.get("rolled",[])
	if not saved_rolls is Array: saved_rolls=[]
	for key in saved_rolls:
		if key is String: p.rolled.append(key)
	if p.rolled.size()>1000: p.rolled=p.rolled.slice(-1000)
	return p
static func clean_stats(raw: Variant) -> Dictionary:
	var result={}
	if raw is Dictionary:
		for key in STATS:
			if raw.has(key) and (raw[key] is int or raw[key] is float): result[key]=clampi(int(raw[key]),0,20)
	return result
static func cells(item: Dictionary, rotation: int = -1) -> Array:
	var result=[]
	var r=int(item.rotation) if rotation<0 else rotation
	for raw in BASES[item.base].shape:
		var p=Vector2i(raw[0],raw[1])
		for turn in posmod(r,4): p=Vector2i(-p.y,p.x)
		result.append(p)
	var min_x=99
	var min_y=99
	for p in result:
		min_x=mini(min_x,p.x); min_y=mini(min_y,p.y)
	for n in result.size(): result[n]-=Vector2i(min_x,min_y)
	return result
static func at(profile: Dictionary, x: int, y: int) -> String:
	for i in profile.items:
		if i.location!="bag": continue
		for cell in cells(i):
			if cell+Vector2i(i.x,i.y)==Vector2i(x,y): return i.id
	return ""
static func find(profile: Dictionary, id: String) -> Dictionary:
	for i in profile.items:
		if i.id==id: return i
	return {}
static func fits(profile: Dictionary, item: Dictionary, x: int, y: int, rotation: int = -1) -> bool:
	for cell in cells(item,rotation):
		var p=cell+Vector2i(x,y)
		if p.x<0 or p.y<0 or p.x>=WIDTH or p.y>=HEIGHT: return false
		var occupant=at(profile,p.x,p.y)
		if not occupant.is_empty() and occupant!=item.id: return false
	return true
static func place(profile: Dictionary, id: String, x: int, y: int) -> String:
	var i=find(profile,id)
	if i.is_empty() or not fits(profile,i,x,y): return "Does not fit: check edges and occupied cells."
	i.location="bag"; i.x=x; i.y=y
	return "Packed. Every item in the backpack is active."
static func rotate(profile: Dictionary, id: String) -> String:
	var i=find(profile,id)
	if i.is_empty(): return "Select an item."
	var r=(int(i.rotation)+1)%4
	if i.location=="bag" and not fits(profile,i,i.x,i.y,r): return "Rotation blocked. Move or stash it first."
	i.rotation=r
	return "Rotated 90 degrees."
static func word(item: Dictionary) -> String:
	if item.rarity!="normal": return ""
	for name in WORDS:
		var recipe=WORDS[name]
		if item.base in recipe.bases and item.sockets==recipe.runes: return name
	return ""
static func quality(item: Dictionary) -> String:
	return "binding" if not word(item).is_empty() else item.rarity
static func name_of(item: Dictionary) -> String:
	var name=BASES[item.base].name
	if not word(item).is_empty(): name=word(item)+" Binding"
	elif item.rarity=="set": name=item.set+"'s "+name
	elif item.rarity=="unique": name=UNIQUES[item.base].name
	elif item.rarity=="rare": name="Vengeful "+name
	elif item.rarity=="uncommon": name="Enchanted "+name
	elif item.rarity=="epic":name="Awakened "+name
	return name+" +%d" % item.tier if item.tier>0 else name
static func add_stats(destination: Dictionary, source: Dictionary) -> void:
	for key in source: destination[key]=int(destination.get(key,0))+int(source[key])
static func item_stats(item: Dictionary) -> Dictionary:
	var result=item.stats.duplicate(true)
	for level in int(item.tier):
		var stat=UPGRADE_TRAITS[item.base][level]
		result[stat]=int(result.get(stat,0))+1
	for rune in item.sockets:
		if RUNES.has(rune): add_stats(result,RUNES[rune])
	add_stats(result,item.corruption)
	var active_word=word(item)
	if not active_word.is_empty(): add_stats(result,WORDS[active_word].stats)
	return result
static func bonuses(profile: Dictionary) -> Dictionary:
	var stats={}
	var set_parts={}
	for i in profile.items:
		if i.location!="bag": continue
		add_stats(stats,item_stats(i))
		if not i.set.is_empty():
			if not set_parts.has(i.set): set_parts[i.set]=[]
			if i.base not in set_parts[i.set]: set_parts[i.set].append(i.base)
	for group in set_parts:
		var n=set_parts[group].size()
		if n>=2: add_stats(stats,{"ward":1} if group=="Warden" else {"vitality":2})
		if n>=3: add_stats(stats,{"bulwark":1,"leech":1} if group=="Warden" else {"focus":1,"leech":1})
	for key in CAPS: stats[key]=mini(CAPS[key],int(stats.get(key,0)))
	return stats
static func upgrade_info(profile: Dictionary,id: String) -> Dictionary:
	var i=find(profile,id)
	if i.is_empty():return {"ok":false,"message":"Select an item."}
	if not i.corruption.is_empty():return {"ok":false,"message":"Corrupted: upgrades and socket count are sealed."}
	if i.tier>=6:return {"ok":false,"message":"Already at maximum +6."}
	var cost=(int(i.tier)+1)*6
	if profile.scrap<cost:return {"ok":false,"message":"Need %d scrap." % cost}
	return {"ok":true,"cost":cost,"level":int(i.tier)+1,"risk":UPGRADE_RISKS[int(i.tier)],"trait":UPGRADE_TRAITS[i.base][int(i.tier)]}
static func upgrade(profile: Dictionary,id: String,rng: RandomNumberGenerator=null,accept_risk: bool=false,expected_level: int=-1) -> String:
	var info=upgrade_info(profile,id)
	if not info.ok:return info.message
	if expected_level>=0 and info.level!=expected_level:return "Upgrade changed. Review the new odds first."
	if info.risk>0 and not accept_risk:return "Confirm the destruction risk first. Nothing spent."
	profile.scrap-=info.cost
	var i=find(profile,id)
	if info.risk>0:
		if rng==null:rng=RandomNumberGenerator.new();rng.randomize()
		if rng.randf()<info.risk:
			profile.items.erase(i)
			return "Destroyed at +%d. Item and ALL socketed Sigils lost." % info.level
	i.tier=info.level
	return "Upgraded to +%d: +1 %s. Existing rolls and Sigils preserved." % [info.level,info.trait]
static func add_socket(profile: Dictionary, id: String) -> String:
	var i=find(profile,id)
	if i.is_empty(): return "Select an item."
	if not i.corruption.is_empty(): return "Corrupted: socket count is sealed."
	if i.sockets.size()>=BASES[i.base].max_sockets: return "This base is at its socket limit."
	var cost=8+i.sockets.size()*4
	if profile.scrap<cost: return "Need %d scrap." % cost
	profile.scrap-=cost; i.sockets.append("")
	return "Socket added. Check exact socket counts for Bindings."
static func insert_rune(profile: Dictionary, id: String, slot: int, rune: String) -> String:
	var i=find(profile,id)
	if i.is_empty() or slot<0 or slot>=i.sockets.size(): return "Select an existing socket."
	if not RUNES.has(rune) or int(profile.runes.get(rune,0))<=0: return "No Sigil available."
	if not i.sockets[slot].is_empty(): return "Remove the existing Sigil first."
	i.sockets[slot]=rune; profile.runes[rune]-=1
	return "Sigil inserted." if word(i).is_empty() else "BINDING: "+word(i)
static func remove_rune(profile: Dictionary, id: String, slot: int) -> String:
	var i=find(profile,id)
	if i.is_empty() or slot<0 or slot>=i.sockets.size(): return "Select an existing socket."
	var rune=i.sockets[slot]
	if rune.is_empty(): return "Socket is already empty."
	profile.runes[rune]=int(profile.runes.get(rune,0))+1; i.sockets[slot]=""
	return "Sigil recovered. Any incomplete Binding is inactive."
static func corrupt(profile: Dictionary, id: String, rng: RandomNumberGenerator) -> Dictionary:
	var i=find(profile,id)
	if i.is_empty(): return {"ok":false,"message":"Select an item."}
	if not i.corruption.is_empty(): return {"ok":false,"message":"Each item can be corrupted only once."}
	if profile.shards<=0: return {"ok":false,"message":"You need a corruption shard."}
	profile.shards-=1
	if rng.randf()<0.10:
		profile.items.erase(i)
		return {"ok":true,"destroyed":true,"message":"Destroyed. The item and its socketed Sigils are gone."}
	var stat=STATS[rng.randi_range(0,STATS.size()-1)]
	i.corruption={stat:2}
	return {"ok":true,"destroyed":false,"message":"Corrupted: +2 "+stat+". Upgrade tier and socket count sealed."}
static func salvage(profile: Dictionary, id: String) -> String:
	var i=find(profile,id)
	if i.is_empty(): return "Select an item."
	for rune in i.sockets:
		if not rune.is_empty(): profile.runes[rune]=int(profile.runes.get(rune,0))+1
	profile.scrap+=3+int(i.tier)*2
	profile.items.erase(i)
	return "Salvaged for scrap. Socketed Sigils were recovered."
static func draw_rarity(rng: RandomNumberGenerator) -> String:
	var roll=rng.randf()*100.0
	for rarity in RARITY_WEIGHTS:
		roll-=RARITY_WEIGHTS[rarity]
		if roll<0:return rarity
	return "set"
static func roll_loot(profile: Dictionary,key: String,rng: RandomNumberGenerator,source: Dictionary={}) -> Array:
	if key in profile.rolled:return []
	profile.rolled.append(key)
	if profile.rolled.size()>1000:profile.rolled.pop_front()
	var messages=[]
	var kind=str(source.get("kind",""))
	var category=str(source.get("type","mob"))
	var guaranteed=category in ["clear","boss_reward"]
	if guaranteed or rng.randf()<GEAR_CHANCE:
		var base=BASES.keys()[rng.randi_range(0,BASES.size()-1)]
		var item=make_item(base,draw_rarity(rng),rng);item.location="field"
		if rng.randf()<0.30:item.sockets.append("")
		profile.items.append(item);messages.append(name_of(item))
	var common=(category=="clear" and int(source.get("wave",-1)) in [1,3,4])
	if common or (category=="mob" and rng.randf()<COMMON_CHANCE):
		var sigil=COMMON_SIGILS[rng.randi_range(0,COMMON_SIGILS.size()-1)]
		profile.runes[sigil]+=1;messages.append(sigil+" Sigil")
	if category=="mob" and EXCLUSIVES.has(kind):
		var boss=kind=="B"
		var misses=int(profile.boss_pity.get(kind,0)) if boss else 0
		var hit=rng.randf()<(BOSS_SIGIL_CHANCE if boss else EXCLUSIVE_CHANCE)
		if hit or (boss and misses>=BOSS_PITY-1):
			var sigil=EXCLUSIVES[kind];profile.runes[sigil]+=1;messages.append(sigil+" Sigil")
			if boss:profile.boss_pity[kind]=0
		elif boss:profile.boss_pity[kind]=misses+1
	if category=="mob" and rng.randf()<(BOSS_SHARD_CHANCE if kind=="B" else SHARD_CHANCE):
		profile.shards+=1;messages.append("Corruption shard")
	if category=="boss_reward":profile.marks+=1;messages.append("Warden mark")
	profile.scrap+=4 if guaranteed else 1
	return messages
static func redeem_set(profile: Dictionary,base: String,location: String="stash") -> String:
	if not BASES.has(base):return "Unknown set piece."
	if int(profile.get("marks",0))<SET_MARK_COST:return "Need %d Warden marks." % SET_MARK_COST
	var rng=RandomNumberGenerator.new();rng.randomize()
	var item=make_item(base,"set",rng);item.location=location
	profile.marks-=SET_MARK_COST;profile.items.append(item)
	return "Claimed "+name_of(item)+"."
static func binding_book() -> String:
	var lines=[]
	for name in BINDINGS:
		var recipe=BINDINGS[name]
		lines.append(name+": "+" → ".join(recipe.runes)+"\n"+" / ".join(recipe.bases)+"; exactly %d sockets\n" % recipe.runes.size()+describe_stats(recipe.stats))
	return "\n\n".join(lines)
static func sigil_help(name: String) -> String:
	if not SIGILS.has(name):return ""
	var lines=[name+" Sigil: "+describe_stats(SIGILS[name])]
	for stat in SIGILS[name]:
		if EFFECT_HELP.has(stat):lines.append(EFFECT_HELP[stat])
	return "\n".join(lines)
static func bank_field(profile: Dictionary) -> void:
	for i in profile.items:
		if i.location=="field": i.location="stash"
static func stat_name(key: String) -> String:
	return STAT_NAMES.get(key,key.capitalize())
static func describe_stats(stats: Dictionary) -> String:
	var words=[]
	for key in STATS:
		if int(stats.get(key,0))>0: words.append("%s +%d" % [stat_name(key),stats[key]])
	return ", ".join(words) if not words.is_empty() else "No bonuses"

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
const RUNES={"Ash":{"edge":1},"Root":{"vitality":2},"Gale":{"focus":1},"Stone":{"ward":1},"Ember":{"bulwark":1},"Echo":{"leech":1}}
const WORDS={
 "Briarsteel":{"runes":["Ash","Gale"],"bases":["blade","staff"],"stats":{"edge":1,"focus":1}},
 "Trailguard":{"runes":["Root","Stone"],"bases":["shield","coat"],"stats":{"bulwark":1,"ward":1}},
 "Cinderwake":{"runes":["Ember","Ash","Gale"],"bases":["blade","staff"],"stats":{"edge":1,"focus":1}},
 "Waking Grove":{"runes":["Root","Echo","Stone"],"bases":["coat","relic"],"stats":{"leech":1,"vitality":3}}}
const COLORS={"normal":"e3e5d9","magic":"8cbcf5","rare":"ecd474","unique":"d9ab69","set":"85d692","runeword":"c6a1f0"}
const STATS=["edge","vitality","ward","focus","leech","bulwark"]
const CAPS={"edge":2,"vitality":12,"ward":3,"focus":2,"leech":2,"bulwark":2}
static func uid() -> String:
	return Crypto.new().generate_random_bytes(8).hex_encode()
static func make_item(base: String, rarity: String, rng: RandomNumberGenerator) -> Dictionary:
	var stats={}
	stats[BASES[base].stat]=1
	if rarity!="normal":
		var rolls=1 if rarity=="magic" else 2
		for i in rolls:
			var stat=STATS[rng.randi_range(0,STATS.size()-1)]
			stats[stat]=int(stats.get(stat,0))+rng.randi_range(1,2)
	if rarity=="unique": stats=UNIQUES[base].stats.duplicate(true)
	var group=""
	if rarity=="set": group="Warden" if base in ["shield","coat","charm"] else "Wayfarer"
	return {"id":uid(),"base":base,"rarity":rarity,"stats":stats,"tier":0,"sockets":[],"corruption":{},"set":group,"location":"stash","x":0,"y":0,"rotation":0}
static func fresh() -> Dictionary:
	var rng=RandomNumberGenerator.new()
	rng.seed=801
	var p={"version":1,"items":[],"runes":{},"shards":2,"scrap":18,"rolled":[]}
	for rune in RUNES: p.runes[rune]=2
	var sword=make_item("blade","normal",rng)
	sword.sockets=["",""]
	sword.location="bag"; sword.x=0; sword.y=0
	var coat=make_item("coat","magic",rng)
	coat.location="bag"; coat.x=4; coat.y=0
	p.items=[sword,coat,make_item("shield","set",rng),make_item("staff","rare",rng),make_item("charm","set",rng),make_item("relic","unique",rng)]
	return p
static func normalize(raw: Dictionary, preserve_field: bool = false) -> Dictionary:
	if raw.is_empty(): return fresh()
	var p={"version":1,"items":[],"runes":{},"shards":maxi(0,int(raw.get("shards",0))),"scrap":maxi(0,int(raw.get("scrap",0))),"rolled":[]}
	var ids=[]
	var saved_runes=raw.get("runes",{})
	if not saved_runes is Dictionary: saved_runes={}
	for rune in RUNES: p.runes[rune]=maxi(0,int(saved_runes.get(rune,0)))
	var saved_items=raw.get("items",[])
	if not saved_items is Array: saved_items=[]
	for item in saved_items:
		if not item is Dictionary or not BASES.has(item.get("base","")) or not COLORS.has(item.get("rarity","")): continue
		var i=item.duplicate(true)
		if not i.get("id","") is String or i.get("id","").is_empty() or i.id in ids: continue
		ids.append(i.id)
		i.tier=clampi(int(i.get("tier",0)),0,3)
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
	return "runeword" if not word(item).is_empty() else item.rarity
static func name_of(item: Dictionary) -> String:
	var name=BASES[item.base].name
	if not word(item).is_empty(): name=word(item)
	elif item.rarity=="set": name=item.set+"'s "+name
	elif item.rarity=="unique": name=UNIQUES[item.base].name
	elif item.rarity=="rare": name="Vengeful "+name
	elif item.rarity=="magic": name="Enchanted "+name
	return name+" +%d" % item.tier if item.tier>0 else name
static func add_stats(destination: Dictionary, source: Dictionary) -> void:
	for key in source: destination[key]=int(destination.get(key,0))+int(source[key])
static func item_stats(item: Dictionary) -> Dictionary:
	var result=item.stats.duplicate(true)
	if item.tier>0:
		var stat=BASES[item.base].stat
		result[stat]=int(result.get(stat,0))+int(item.tier)
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
static func upgrade(profile: Dictionary, id: String) -> String:
	var i=find(profile,id)
	if i.is_empty(): return "Select an item."
	if not i.corruption.is_empty(): return "Corrupted: upgrading and new sockets are sealed."
	if i.tier>=3: return "Already at upgrade tier 3."
	var cost=(int(i.tier)+1)*6
	if profile.scrap<cost: return "Need %d scrap." % cost
	profile.scrap-=cost; i.tier+=1
	return "Upgraded. Base trait increased; rolls and runes preserved."
static func add_socket(profile: Dictionary, id: String) -> String:
	var i=find(profile,id)
	if i.is_empty(): return "Select an item."
	if not i.corruption.is_empty(): return "Corrupted: socket count is sealed."
	if i.sockets.size()>=BASES[i.base].max_sockets: return "This base is at its socket limit."
	var cost=8+i.sockets.size()*4
	if profile.scrap<cost: return "Need %d scrap." % cost
	profile.scrap-=cost; i.sockets.append("")
	return "Socket added. Check exact socket counts for runewords."
static func insert_rune(profile: Dictionary, id: String, slot: int, rune: String) -> String:
	var i=find(profile,id)
	if i.is_empty() or slot<0 or slot>=i.sockets.size(): return "Select an existing socket."
	if not RUNES.has(rune) or int(profile.runes.get(rune,0))<=0: return "No rune available."
	if not i.sockets[slot].is_empty(): return "Remove the existing rune first."
	i.sockets[slot]=rune; profile.runes[rune]-=1
	return "Rune inserted." if word(i).is_empty() else "RUNEWORD: "+word(i)
static func remove_rune(profile: Dictionary, id: String, slot: int) -> String:
	var i=find(profile,id)
	if i.is_empty() or slot<0 or slot>=i.sockets.size(): return "Select an existing socket."
	var rune=i.sockets[slot]
	if rune.is_empty(): return "Socket is already empty."
	profile.runes[rune]=int(profile.runes.get(rune,0))+1; i.sockets[slot]=""
	return "Rune recovered. Any incomplete runeword is inactive."
static func corrupt(profile: Dictionary, id: String, rng: RandomNumberGenerator) -> Dictionary:
	var i=find(profile,id)
	if i.is_empty(): return {"ok":false,"message":"Select an item."}
	if not i.corruption.is_empty(): return {"ok":false,"message":"Each item can be corrupted only once."}
	if profile.shards<=0: return {"ok":false,"message":"You need a corruption shard."}
	profile.shards-=1
	if rng.randf()<0.10:
		profile.items.erase(i)
		return {"ok":true,"destroyed":true,"message":"Destroyed. The item and its socketed runes are gone."}
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
	return "Salvaged for scrap. Socketed runes were recovered."
static func roll_loot(profile: Dictionary, key: String, rng: RandomNumberGenerator, guaranteed: bool = false) -> Array:
	if key in profile.rolled: return []
	profile.rolled.append(key)
	if profile.rolled.size()>1000: profile.rolled.pop_front()
	var messages=[]
	if guaranteed or rng.randf()<0.12:
		var base=BASES.keys()[rng.randi_range(0,BASES.size()-1)]
		var roll=rng.randf()
		var rarity="normal" if roll<0.28 else ("magic" if roll<0.60 else ("rare" if roll<0.85 else ("unique" if roll<0.92 else "set")))
		var item=make_item(base,rarity,rng)
		item.location="field"
		if rng.randf()<0.30: item.sockets.append("")
		profile.items.append(item)
		messages.append(name_of(item))
	if guaranteed or rng.randf()<0.10:
		var rune=RUNES.keys()[rng.randi_range(0,RUNES.size()-1)]
		profile.runes[rune]=int(profile.runes.get(rune,0))+1
		messages.append(rune+" rune")
	if rng.randf()<0.03:
		profile.shards+=1
		messages.append("Corruption shard")
	profile.scrap+=1 if not guaranteed else 4
	return messages
static func bank_field(profile: Dictionary) -> void:
	for i in profile.items:
		if i.location=="field": i.location="stash"
static func describe_stats(stats: Dictionary) -> String:
	var words=[]
	for key in STATS:
		if int(stats.get(key,0))>0: words.append("%s +%d" % [key.capitalize(),stats[key]])
	return ", ".join(words) if not words.is_empty() else "No bonuses"

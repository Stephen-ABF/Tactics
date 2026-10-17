class_name ThornSave
extends RefCounted
const Gear=preload("res://scripts/gear.gd")
const Rules=preload("res://scripts/rules.gd")
const Content=preload("res://scripts/content.gd")
const Stats=preload("res://scripts/playtest.gd")
const MAX_BACKUP=2097152
static var events_enabled=true
const PATH="user://thornwake_save.json"
static var recovered_backup=false
static func defaults() -> Dictionary:
	return {"version":3,"sound":true,"motion":true,"quality":"low" if OS.get_name() in ["Android","iOS"] else "balanced","tutorial":false,"runs":0,"wins":0,"best":0,"materials":0,"unlocked_depth":1,"gear":{},"run":{},"playtest_mode":true,"playtest":{}}
static func parse_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):return {}
	var parser=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK or not parser.data is Dictionary:return {}
	return parser.data
static func read_save() -> Dictionary:
	var data=defaults()
	var parsed=parse_file(PATH)
	recovered_backup=false
	if parsed.is_empty() and FileAccess.file_exists(PATH):
		parsed=parse_file(PATH+".bak")
		recovered_backup=not parsed.is_empty()
	for key in data:
		if not parsed.has(key):continue
		if typeof(data[key])==TYPE_INT and (parsed[key] is int or parsed[key] is float):data[key]=maxi(0,int(parsed[key]))
		elif typeof(data[key])==typeof(parsed[key]):data[key]=parsed[key]
	if data.quality not in ["low","balanced"]:data.quality="low"
	data.unlocked_depth=clampi(data.unlocked_depth,1,5)
	return data
static func write_save(data: Dictionary) -> bool:
	var file=FileAccess.open(PATH+".tmp",FileAccess.WRITE)
	if not file:return false
	file.store_string(JSON.stringify(data));file.flush();file.close()
	if not parse_file(PATH).is_empty():
		var backup=FileAccess.open(PATH+".bak",FileAccess.WRITE)
		if backup:backup.store_string(FileAccess.get_file_as_string(PATH));backup.close()
	return DirAccess.rename_absolute(PATH+".tmp",PATH)==OK
static func log_event(event: String,fields: Dictionary={}) -> void:
	if not events_enabled:return
	var path="user://thornwake_events.jsonl"
	if FileAccess.file_exists(path) and FileAccess.get_file_as_string(path).length()>1048576:DirAccess.remove_absolute(path)
	var file=FileAccess.open(path,FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
	if file:
		file.seek_end();file.store_line(JSON.stringify({"event":event,"data":fields,"time":Time.get_unix_time_from_system()}))

static func normalize_checkpoint(raw: Dictionary) -> Dictionary:
	if raw.is_empty() or not valid_number(raw.get("version",0),1) or int(raw.get("version",0))!=1 or raw.get("phase","") not in ["game","camp"]:return {}
	if not raw.get("state") is Dictionary:return {}
	for key in ["schema","side","player","hp","max_hp","guard","poison","turn","kills","seed","encounter","materials","depth","layout"]:
		if not valid_number(raw.state.get(key)):return {}
	if not raw.state.get("tiles") is Array:return {}
	for tile in raw.state.tiles:
		if not tile is Dictionary:return {}
		for key in ["hp","max_hp","phase"]:
			if not valid_number(tile.get(key)):return {}
		var aim=tile.get("aim")
		if not (aim is int or aim is float) or not is_finite(float(aim)) or float(int(aim))!=float(aim):return {}
	if not raw.state.get("gear") is Dictionary:return {}
	for value in raw.state.gear.values():
		if not valid_number(value):return {}
	var checked=Rules.normalize_saved(raw.state)
	if checked.is_empty() or checked.status=="lost":return {}
	if (raw.phase=="camp" and (checked.status!="won" or checked.encounter>=4)) or (raw.phase=="game" and checked.status!="playing"):return {}
	if not raw.get("id") is String or raw.id.is_empty() or not raw.get("boons") is Array:return {}
	var copy=raw.duplicate(true);copy.state=checked
	var clean=[]
	for id in copy.boons:
		if not Content.BOONS.has(id):return {}
		clean.append(id)
	if clean.size()!=checked.encounter:return {}
	copy.boons=clean
	for key in ["bank","total_kills","run_loot","seconds"]:
		if not (copy.get(key) is int or copy.get(key) is float) or copy[key]<0:return {}
	copy.bank=int(copy.bank);copy.total_kills=int(copy.total_kills);copy.run_loot=int(copy.run_loot);copy.seconds=float(copy.seconds)
	for key in ["camp_seconds","planning_seconds","animation_seconds"]:
		var value=copy.get(key,0.0)
		if not (value is int or value is float) or value<0:return {}
		copy[key]=float(value)
	copy.stance=copy.get("stance",checked.stance)
	if copy.stance not in ["Duelist","Reaver"]:return {}
	copy.choice=str(copy.get("choice",""))
	if not copy.choice.is_empty() and copy.choice not in Content.choices(checked.seed,checked.encounter,copy.boons):copy.choice=""
	var clean_metrics=preload("res://scripts/playtest.gd").metrics()
	for key in clean_metrics:
		var value=copy.get("metrics",{}).get(key,0) if copy.get("metrics",{}) is Dictionary else 0
		if not (value is int or value is float) or not is_finite(float(value)) or value<0:return {}
		clean_metrics[key]=clampi(int(value),0,100000000)
	copy.metrics=clean_metrics
	copy.report_eligible=copy.get("report_eligible",false)==true
	return copy

static func encode_backup(data: Dictionary) -> String:
	var payload=JSON.stringify(data)
	return JSON.stringify({"format":"thornwake-backup","version":1,"game_version":"0.6.0","data":payload,"sha256":payload.sha256_text()},"  ")
static func valid_number(value: Variant,maximum: float=100000000.0) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value>=0 and value<=maximum and float(int(value))==float(value)
static func decode_backup(value: String) -> Dictionary:
	if value.to_utf8_buffer().size()>MAX_BACKUP:return {"ok":false,"error":"Backup is too large (2 MiB limit)."}
	var parser=JSON.new()
	if parser.parse(value)!=OK:return {"ok":false,"error":"This is not valid JSON."}
	var parsed=parser.data
	if not parsed is Dictionary:return {"ok":false,"error":"This is not a JSON save or backup."}
	if parsed.has("format"):
		if parsed.format!="thornwake-backup" or parsed.get("version")!=1 or not parsed.get("data") is String:return {"ok":false,"error":"Unknown backup format/version."}
		if parsed.get("sha256","")!=parsed.data.sha256_text():return {"ok":false,"error":"Backup checksum failed. Nothing changed."}
		if parser.parse(parsed.data)!=OK:return {"ok":false,"error":"Invalid backup payload JSON."}
		parsed=parser.data
	return validate_payload(parsed)
static func validate_payload(raw: Variant) -> Dictionary:
	if not raw is Dictionary or raw.get("version")!=3 or not raw.get("gear") is Dictionary or not raw.get("run") is Dictionary:return {"ok":false,"error":"Unsupported or incomplete save."}
	var g=raw.gear
	if not valid_number(g.get("version",1),2) or int(g.get("version",1)) not in [1,2]:return {"ok":false,"error":"Unsupported inventory version."}
	if raw.has("playtest") and not raw.playtest is Dictionary:return {"ok":false,"error":"Invalid playtest summary."}
	if not g.get("items") is Array or g.items.size()>5000 or not g.get("runes") is Dictionary:return {"ok":false,"error":"Invalid inventory."}
	for key in ["scrap","shards","marks"]:
		if not valid_number(g.get(key,0)):return {"ok":false,"error":"Invalid currency."}
	for sigil in g.runes:
		if not Gear.SIGILS.has(sigil) or not valid_number(g.runes[sigil]):return {"ok":false,"error":"Invalid Sigil pouch."}
	if g.has("boss_pity") and not g.boss_pity is Dictionary:return {"ok":false,"error":"Invalid boss protection counters."}
	if g.has("boss_pity"):
		for count in g.boss_pity.values():
			if not valid_number(count,9):return {"ok":false,"error":"Invalid boss protection count."}
	for item in g.items:
		if not item is Dictionary or not Gear.BASES.has(item.get("base","")) or item.get("rarity","") not in ["normal","magic","uncommon","rare","epic","unique","set"]:return {"ok":false,"error":"Invalid gear entry."}
		if item.get("location","") not in ["bag","stash","field"] or item.get("set","") not in ["","Warden","Wayfarer"]:return {"ok":false,"error":"Invalid item location or set."}
		for coordinate in ["x","y","rotation"]:
			if not valid_number(item.get(coordinate,0),10000):return {"ok":false,"error":"Invalid item position."}
		for flag in ["favorite","locked"]:
			if item.has(flag) and not item[flag] is bool:return {"ok":false,"error":"Invalid item protection flags."}
		if not valid_number(item.get("tier",0),6) or not item.get("sockets") is Array or item.sockets.size()>Gear.BASES[item.base].max_sockets:return {"ok":false,"error":"Invalid gear tier/sockets."}
		for sigil in item.sockets:
			if sigil!="" and not Gear.SIGILS.has(sigil):return {"ok":false,"error":"Unknown socketed Sigil."}
		for field in ["stats","corruption"]:
			if not item.get(field) is Dictionary:return {"ok":false,"error":"Invalid item modifiers."}
			for stat in item[field]:
				if not Gear.STATS.has(stat) or not valid_number(item[field][stat],20):return {"ok":false,"error":"Invalid item modifier."}
	var gear=Gear.normalize(g,true)
	if gear.items.size()!=g.items.size():return {"ok":false,"error":"Invalid or duplicate gear IDs."}
	for index in g.items.size():
		if g.items[index].get("location")=="bag" and gear.items[index].location!="bag":return {"ok":false,"error":"Packed items overlap or exceed the backpack."}
	var run=normalize_checkpoint(raw.run)
	if not raw.run.is_empty() and run.is_empty():return {"ok":false,"error":"Invalid active expedition. Nothing changed."}
	var result=defaults()
	for key in ["runs","wins","best","materials","unlocked_depth"]:
		if not valid_number(raw.get(key,0)):return {"ok":false,"error":"Invalid progression."}
		result[key]=int(raw.get(key,0))
	if result.unlocked_depth<1 or result.unlocked_depth>5 or result.wins>result.runs:return {"ok":false,"error":"Invalid progression totals."}
	for key in ["sound","motion","tutorial","playtest_mode"]:
		if raw.has(key) and not raw[key] is bool:return {"ok":false,"error":"Invalid settings."}
		result[key]=raw.get(key,result[key])
	result.quality=raw.get("quality","low")
	if result.quality not in ["low","balanced"]:return {"ok":false,"error":"Unknown graphics setting."}
	result.gear=gear;result.run=run;result.playtest=Stats.normalize(raw.get("playtest",{}))
	return {"ok":true,"payload":result}
static func write_text(path: String,value: String) -> bool:
	var file=FileAccess.open(path,FileAccess.WRITE)
	if not file:return false
	file.store_string(value);file.flush();file.close();return true
static func apply_backup(value: String,current: Dictionary) -> Dictionary:
	var decoded=decode_backup(value)
	if not decoded.ok:return decoded
	if not write_text("user://thornwake_before_import.json",encode_backup(current)):return {"ok":false,"error":"Cannot preserve the current save. Import cancelled."}
	if not write_save(decoded.payload):return {"ok":false,"error":"Cannot write imported save. Current progress remains in the pre-import backup."}
	return decoded
static func read_backup_file(path: String) -> String:
	var file=FileAccess.open(path,FileAccess.READ)
	if not file or file.get_length()>MAX_BACKUP:return ""
	return file.get_as_text()

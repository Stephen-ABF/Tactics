class_name ThornSave
extends RefCounted
const PATH="user://thornwake_save.json"
static var recovered_backup=false
static func defaults() -> Dictionary:
	return {"version":3,"sound":true,"motion":true,"quality":"low" if OS.get_name() in ["Android","iOS"] else "balanced","tutorial":false,"runs":0,"wins":0,"best":0,"materials":0,"unlocked_depth":1,"gear":{},"run":{}}
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
	var path="user://thornwake_events.jsonl"
	if FileAccess.file_exists(path) and FileAccess.get_file_as_string(path).length()>1048576:DirAccess.remove_absolute(path)
	var file=FileAccess.open(path,FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
	if file:
		file.seek_end();file.store_line(JSON.stringify({"event":event,"data":fields,"time":Time.get_unix_time_from_system()}))

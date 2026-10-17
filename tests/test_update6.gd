extends SceneTree
const G=preload("res://scripts/gear.gd")
const S=preload("res://scripts/save_store.gd")
const P=preload("res://scripts/playtest.gd")
const R=preload("res://scripts/rules.gd")
const C=preload("res://scripts/content.gd")
const E=preload("res://scripts/combat_explain.gd")
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var original={}
	for suffix in ["",".bak"]:
		if FileAccess.file_exists(S.PATH+suffix):original[suffix]=FileAccess.get_file_as_string(S.PATH+suffix)
	var data=S.defaults();data.gear=G.fresh();data.playtest=P.fresh()
	var code=S.encode_backup(data);var decoded=S.decode_backup(code)
	check(decoded.ok and decoded.payload.gear.items.size()==2,"Portable backup roundtrip retains gear")
	var wrapper=JSON.parse_string(code);wrapper.data+=" "
	check(not S.decode_backup(JSON.stringify(wrapper)).ok,"Checksum detects altered inner payload")
	for malformed in ["{broken","[]",JSON.stringify({"format":"other","version":1}),JSON.stringify({"version":999,"gear":{},"run":{}})]:check(not S.decode_backup(malformed).ok,"Malformed/unsupported imports rejected")
	for path in ["tier","x","rotation"]:
		var bad=data.duplicate(true);bad.gear.items[0][path]={"bad":true}
		check(not S.decode_backup(JSON.stringify(bad)).ok,"Malformed inventory numeric field rejected safely")
	var bad=data.duplicate(true);bad.gear.items.append(bad.gear.items[0].duplicate(true))
	check(not S.decode_backup(JSON.stringify(bad)).ok,"Duplicate IDs rejected without silently losing items")
	bad=data.duplicate(true);bad.gear.items[1].x=0
	check(not S.decode_backup(JSON.stringify(bad)).ok,"Overlapping packed backup rejected")
	S.write_save(data);var current=FileAccess.get_file_as_string(S.PATH)
	check(not S.apply_backup("bad",data).ok and FileAccess.get_file_as_string(S.PATH)==current,"Invalid import cannot alter current save")
	var replacement=data.duplicate(true);replacement.gear.scrap=222
	check(S.apply_backup(S.encode_backup(replacement),data).ok and S.read_save().gear.scrap==222,"Valid import replaces progress")
	check(S.decode_backup(S.read_backup_file("user://thornwake_before_import.json")).payload.gear.scrap==data.gear.scrap,"Pre-import recovery preserves previous progress")
	var profile=G.fresh();var id=profile.items[0].id;profile.items[0].tier=3;profile.scrap=1000;profile.shards=3
	G.flag(profile,id,"favorite");G.flag(profile,id,"locked")
	var before=profile.duplicate(true);var rng=RandomNumberGenerator.new();rng.seed=1
	G.salvage(profile,id);G.corrupt(profile,id,rng);G.upgrade(profile,id,rng,true)
	check(profile==before,"Lock blocks every destructive backend operation")
	profile.items[0].sockets=["Ash","Gale"]
	var ash=profile.runes.Ash;var gale=profile.runes.Gale
	check(G.unsocket_all(profile,id).count==2 and profile.runes.Ash==ash+1 and profile.runes.Gale==gale+1,"Quick recovery returns every inserted Sigil even when locked")
	check(G.unsocket_all(profile,id).count==0,"Repeated unsocket cannot duplicate Sigils")
	var roundtrip=G.normalize(JSON.parse_string(JSON.stringify(profile)))
	check(roundtrip.items[0].favorite and roundtrip.items[0].locked,"Protection flags survive reload")
	var extra=G.make_item("blade","rare",rng);extra.location="stash";profile.items.append(extra)
	var field=G.make_item("coat","epic",rng);field.location="field";profile.items.append(field)
	check(G.query(profile,true).size()==1 and G.query(profile,true)[0].id==field.id,"Camp tools cannot expose home stash")
	check(G.query(profile,false,"Favorites","Name","",true).size()==1,"Favorite filter includes protected packed item")
	check(G.query(profile,false,"Epic").size()==1,"Quality filter works")
	check(G.query(profile,false,"All","Name","  blade  ").size()==1,"Search trims input and matches base")
	before=profile.duplicate(true);var comparison=G.compare(profile,extra.id,id)
	check(comparison.ok and not comparison.effective.is_empty() and profile==before,"Comparison includes capped hypothetical loadout without mutating it")
	var report=P.fresh()
	var row={"id":"same","won":true,"seconds":300,"camp_seconds":60,"gear":8,"stance":"Duelist"}
	check(P.record_run(report,row) and not P.record_run(report,row),"Run summary settlement is idempotent")
	check(P.median([60,300])==180 and P.summary(report).contains("6.0 min"),"Summary duration includes camp and uses correct median")
	for index in 70:P.record_run(report,{"id":str(index),"won":false,"reason":"health"})
	check(report.runs.size()==50 and P.normalize(JSON.parse_string(JSON.stringify(report))).runs.size()==50,"Summary retains bounded recent history")
	P.craft(report,"gear_upgrade",{"destroyed":true});P.craft(report,"gear_corrupt",{"ok":false});P.craft(report,"gear_corrupt",{"ok":true,"destroyed":true})
	check(report.upgrade_attempts==1 and report.upgrade_losses==1 and report.corruption_attempts==1 and report.corruption_losses==1,"Craft report excludes rejected attempts")
	for seed_value in 30:
		var owned=[]
		for wave in 4:
			var options=C.choices(seed_value,wave,owned)
			check(options.size()==2 and options[0]!=options[1] and options[0] not in owned and options[1] not in owned,"Camp always offers two unowned boons")
			owned.append(options[0])
	check(C.combine({"edge":2},["edge","edge","edge"]).edge==3,"Legacy duplicate Edge cannot exceed new cap")
	var state=R.new_board(9,0,"Duelist",14,{"edge":1,"counter":1,"temper":1});state.guard=1
	for tile in state.tiles:tile.kind=".";tile.hp=1;tile.max_hp=1
	state.player=6;state.tiles[7].kind="h";state.tiles[7].hp=4;state.tiles[7].max_hp=4;state.tiles[0].kind="s"
	var outcome=R.resolve(state,[7]);var sum=0
	for part in outcome.attacks[0].parts:sum+=part.amount
	check(sum==outcome.attacks[0].power and E.describe(state,[7],outcome).contains("Counter"),"Explained bonuses sum to actual animated hit power")
	S.write_save(data)
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.audio.enabled=false
	game.show_save_tools();check(game.modal_kind=="save_tools" and S.decode_backup(game.backup_editor.text).ok,"Save manager exports current profile")
	var export_path=OS.get_user_data_dir().path_join("test_export.json")
	game.backup_file_dialog(true)
	var picker=game.overlay.get_child(game.overlay.get_child_count()-1)
	game.backup_file_dialog(true);check(game.file_picker==picker,"Repeated clicks cannot open multiple exclusive file dialogs")
	picker.file_selected.emit(export_path)
	check(S.decode_backup(S.read_backup_file(export_path)).ok,"Desktop file picker callback writes a valid backup")
	game.backup_editor.text="";game.backup_file_dialog(false)
	picker=game.overlay.get_child(game.overlay.get_child_count()-1);picker.file_selected.emit(export_path)
	check(S.decode_backup(game.backup_editor.text).ok,"Desktop file picker callback reloads backup bytes")
	DirAccess.remove_absolute(export_path)
	game.stage_import(S.encode_backup(replacement));check(game.modal_kind=="import_confirm" and game.prefs.gear.scrap!=222,"Restore stages confirmation without mutation")
	game.confirm_import();game.confirm_import();game.audio.enabled=false;check(game.screen=="title" and game.prefs.gear.scrap==222,"UI restoration applies once and returns to title")
	game.show_playtest();check(game.modal_kind=="playtest","Local summary opens")
	game.close_modal();game.open_pack(false);var pack=game.pack_ui;pack.selected=game.prefs.gear.items[0].id;pack.tools_dialog();check(pack.dialog!=null,"Stash tools open")
	pack.compare_dialog();check(pack.dialog!=null,"Comparison panel opens")
	pack.closed.emit();game.start_run(false,7);game.select_cell(R.legal_actions(game.state)[0][0]);game.show_route_explanation();check(game.modal_kind=="explain","Route explanation opens without committing move")
	for invalid_key in ["version","state"]:
		var broken=game.prefs.duplicate(true);broken.run[invalid_key]=[]
		check(not S.decode_backup(S.encode_backup(broken)).ok,"Malformed checkpoint envelope rejected")
	for invalid_key in ["schema","side","player"]:
		var broken=game.prefs.duplicate(true);broken.run.state[invalid_key]={"bad":true}
		check(not S.decode_backup(S.encode_backup(broken)).ok,"Malformed checkpoint numeric field rejected")
	game.close_modal()
	game.state.status="won";game.encounter=0;game.checkpoint("camp");game.show_title()
	check(S.decode_backup(game.export_code()).ok,"Exporting from title preserves a saved camp checkpoint")
	game.prefs.playtest_mode=false;S.events_enabled=false;var count=game.prefs.playtest.runs.size();game.finish_run(false,"abandon")
	check(game.prefs.playtest.runs.size()==count,"Recording toggle prevents new summary rows")
	game.queue_free();await process_frame;S.events_enabled=true
	for suffix in ["",".bak"]:
		if original.has(suffix):S.write_text(S.PATH+suffix,original[suffix])
		else:DirAccess.remove_absolute(S.PATH+suffix)
	print("UPDATE 6: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)

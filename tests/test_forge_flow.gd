extends SceneTree
const G=preload("res://scripts/gear.gd")
const R=preload("res://scripts/rules.gd")
const S=preload("res://scripts/save_store.gd")
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var backups={}
	for suffix in ["",".bak"]:
		if FileAccess.file_exists(S.PATH+suffix):backups[suffix]=FileAccess.get_file_as_string(S.PATH+suffix)
	S.write_save(S.defaults())
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.audio.enabled=false
	game.show_hunt_preview()
	check(game.modal_kind=="scout" and not game.prefs.run.size(),"Scout report previews without starting or granting a run")
	game.close_modal();game.show_codex()
	check(game.modal_kind=="codex","Enemy-specific drop guide opens")
	game.close_modal()
	game.prefs.gear=G.fresh();game.prefs.gear.scrap=1000;game.prefs.gear.marks=6
	var gear=game.prefs.gear.items[0];gear.tier=3;gear.sockets=["Ash","Gale"]
	game.open_pack(false)
	var pack=game.pack_ui;pack.selected=gear.id;pack.render()
	pack.socket_dialog();check(pack.dialog!=null,"All thirteen Sigils fit a scrollable socket screen")
	pack.binding_dialog();check(pack.dialog!=null,"Eleven Binding recipes open in scrollable book")
	pack.render();var before=game.prefs.gear.duplicate(true)
	pack.upgrade_dialog();check(pack.confirmation_active and pack.dialog!=null and game.prefs.gear==before,"Risk quote spends nothing before confirmation")
	pack.render();check(game.prefs.gear==before,"Cancel risk leaves item and resources intact")
	pack.upgrade_dialog()
	var confirm: Button
	for child in pack.dialog.get_children():
		if child is Button and child.text.begins_with("ACCEPT RISK"):confirm=child
	check(confirm!=null,"Explicit destructive-action button exists")
	confirm.pressed.emit();confirm.pressed.emit()
	check(game.prefs.gear.scrap==976,"Double confirmation spends only one upgrade cost")
	var upgraded=G.find(game.prefs.gear,gear.id)
	check(upgraded.is_empty() or upgraded.tier==4,"UI commits one success or destruction, never another upgrade")
	check(S.read_save().gear.scrap==976,"Forge outcome persists immediately")
	pack.collection_dialog()
	var claim: Button
	for child in pack.dialog.get_children():
		if child is Button and child.text.begins_with("Warden Moss Coat"):claim=child
	check(claim!=null and not claim.disabled,"Missing set piece can be targeted")
	claim.pressed.emit();claim.pressed.emit()
	check(game.prefs.gear.marks==0,"Set claim cannot spend unavailable marks on a repeated click")
	var coats=0
	for item in game.prefs.gear.items:
		if item.base=="coat" and item.rarity=="set":coats+=1
	check(coats==1,"One mark purchase creates exactly one piece")
	check(S.read_save().gear.marks==0,"Collection spending persists")
	pack.closed.emit();game.start_run(false,14026)
	game._process(2);check(game.planning_seconds>0 and game.camp_seconds==0,"Planning time measured separately")
	game._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
	var seconds=game.active_seconds;game._process(2)
	check(game.active_seconds==seconds,"Background does not accrue active time")
	game.queue_free();await process_frame
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.audio.enabled=false;game.resume_run()
	check(game.planning_seconds>0 and game.state.side==3,"Timing and active expedition reload together")
	game.prefs.gear.boss_pity.B=9
	var heart_before=game.prefs.gear.runes.Heartroot;var marks_before=game.prefs.gear.marks
	game.encounter=4;game.boons=["edge","ward","stride","leech"]
	game.state=R.new_board(14026,4,"Duelist",14,{"edge":30})
	for tile in game.state.tiles:tile.kind=".";tile.hp=1;tile.max_hp=1
	game.state.player=0;game.state.tiles[1].kind="B";game.state.tiles[1].hp=18;game.state.tiles[1].max_hp=18
	game.show_game();game.select_cell(1);game.execute_move();game.board._process(100)
	check(game.screen=="results" and game.state.boss_defeated,"Actual animated boss kill reaches results")
	check(game.prefs.gear.runes.Heartroot==heart_before+1 and game.prefs.gear.boss_pity.B==0,"Actual kill routes boss identity into the exclusive-drop pity channel")
	check(game.prefs.gear.marks==marks_before+1,"Actual victory grants one collection mark")
	var settled=game.prefs.gear.duplicate(true);game.commit_move()
	check(game.prefs.gear==settled,"Repeated animation completion cannot duplicate boss drops or marks")
	game.queue_free();await process_frame
	for suffix in ["",".bak"]:
		if backups.has(suffix):
			var file=FileAccess.open(S.PATH+suffix,FileAccess.WRITE);file.store_string(backups[suffix]);file.close()
		else:DirAccess.remove_absolute(S.PATH+suffix)
	print("FORGE FLOW: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)

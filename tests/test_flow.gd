extends SceneTree
const R=preload("res://scripts/rules.gd")
const S=preload("res://scripts/save_store.gd")
const G=preload("res://scripts/gear.gd")
const C=preload("res://scripts/content.gd")
var game
var checks=0
var failures=0
var backup={}
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(message)
func instantiate_game():
	var instance=load("res://scenes/main.tscn").instantiate()
	root.add_child(instance);instance.audio.enabled=false
	return instance
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	for suffix in ["",".bak"]:
		if FileAccess.file_exists(S.PATH+suffix):backup[suffix]=FileAccess.get_file_as_string(S.PATH+suffix)
	S.write_save(S.defaults())
	game=instantiate_game()
	check(game.screen=="title" and game.prefs.gear.items.size()==6,"First launch migrates starter gear")
	game.open_pack(false)
	check(is_instance_valid(game.pack_ui),"Home backpack available")
	game.pack_ui.closed.emit()
	game.start_run(false,14026)
	check(game.state.side==3 and not game.prefs.run.is_empty(),"New expedition starts 3x3 and checkpoints")
	var before=game.state.duplicate(true)
	game.pause_game();game.execute_move()
	check(game.state==before and game.paused,"Pause blocks gameplay")
	game.show_settings();game.if_board_quality();game.close_modal()
	check(not game.paused,"Closing settings resumes")
	var cell=R.legal_actions(game.state)[0][0]
	var global=game.board.position+game.board.center(cell)
	var touch=InputEventScreenTouch.new();touch.pressed=true;touch.position=game.board.center(cell)
	game.board._gui_input(touch)
	check(game.route==[cell],"Touch input selects a projected 3D cell")
	game.execute_move()
	game.pause_game()
	var old_turn=game.state.turn
	game.board._process(1.0)
	check(game.state.turn==old_turn and game.busy,"Pause freezes an attack in flight")
	game.close_modal();game.board._process(100)
	check(game.state.turn==old_turn+1,"Resume commits once")
	var committed=game.state.duplicate(true)
	var id=game.run_id
	game.checkpoint()
	var saved_profile=game.prefs.gear.duplicate(true)
	game.queue_free();await process_frame
	game=instantiate_game();game.resume_run()
	check(game.state==committed and game.run_id==id,"App reload resumes the exact committed encounter")
	check(game.prefs.gear.items.size()==saved_profile.items.size(),"Loot profile roundtrips without duplication")
	game.pause_game();game.show_title();game.open_pack(false)
	check(not is_instance_valid(game.pack_ui) and game.modal_kind=="pack_locked","Active expedition prevents out-of-camp loadout changes")
	game.close_modal();game.resume_run()
	# Exercise cleared-wave/camp checkpoint and boon flow with a reducer-produced terminal state.
	var terminal=R.new_board(14026,0,"Duelist",14,{})
	for tile in terminal.tiles:tile.kind=".";tile.hp=1
	var target=R.neighbors(terminal.player,3)[0]
	terminal.tiles[target].kind="s"
	game.state=terminal;game.encounter=0;game.boons=[];game.show_game()
	game.select_cell(target);game.execute_move();game.board._process(100)
	check(game.screen=="camp" and game.prefs.run.phase=="camp","Wave clear saves camp and guaranteed loot")
	var camp_profile=game.prefs.gear.duplicate(true)
	var choices=C.choices(game.seed_value,0)
	game.selected_boon=choices[0];game.stance="Reaver";game.checkpoint("camp")
	game.queue_free();await process_frame
	game=instantiate_game();game.resume_run()
	check(game.screen=="camp" and game.selected_boon==choices[0] and game.stance=="Reaver","Camp choice and stance survive reload")
	game.open_pack(true)
	check(game.pack_ui.camp,"Camp field inventory opens")
	game.pack_ui.closed.emit()
	game.next_wave_from_camp()
	check(game.state.side==4 and game.encounter==1 and game.boons.size()==1,"Boon choice advances to 4x4")
	game.next_wave_from_camp()
	check(game.encounter==1 and game.boons.size()==1,"Double continue cannot skip waves or duplicate boons")
	var checkpoint=game.prefs.run.duplicate(true)
	game._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.paused and not game.prefs.run.is_empty(),"Focus loss pauses and saves")
	game.close_modal()
	var count=game.prefs.runs
	var materials=game.prefs.materials
	game.finish_run(false,"test")
	game.finish_run(false,"test")
	check(game.prefs.runs==count+1 and game.prefs.run.is_empty() and game.prefs.materials>=materials,"Results settle exactly once and clear active run")
	game.start_run(false,14)
	game.encounter=4;game.boons=["edge","ward","stride","leech"]
	game.state=R.new_board(14,4,"Reaver",14,{})
	game.finish_run(true,"test")
	check(game.prefs.unlocked_depth==2 and game.screen=="results","Victory unlocks next depth")
	var good=game.prefs.duplicate(true)
	S.write_save(good);S.write_save(good)
	var bad=FileAccess.open(S.PATH,FileAccess.WRITE);bad.store_string("{broken");bad.close()
	var recovered=S.read_save()
	check(S.recovered_backup and recovered.wins==good.wins,"Corrupt primary save recovers valid backup")
	var malformed=checkpoint.duplicate(true);malformed.state.player=999
	check(game.normalize_snapshot(malformed).is_empty(),"Malformed active-run data rejected")
	for rect in [Rect2(0,0,360,800),Rect2(0,0,1200,720),Rect2(12,40,576,900),Rect2(0,0,600,1000)]:
		var fit=game.fit_canvas(rect)
		check(rect.encloses(Rect2(fit.position,Vector2(600,1000)*fit.scale)),"Canvas fits simulated safe bounds")
	for n in [3,4,5,6]:
		game.state=R.new_board(8,n-3 if n<6 else 3,"Duelist")
		game.encounter=game.state.encounter;game.show_game();game.board._process(0)
		for i in n*n:check(game.board.pick_cell(game.board.center(i))==i,"Perspective pick roundtrip for every board size")
	game.queue_free();await process_frame
	for suffix in ["",".bak"]:
		if backup.has(suffix):
			var file=FileAccess.open(S.PATH+suffix,FileAccess.WRITE);file.store_string(backup[suffix]);file.close()
		else:DirAccess.remove_absolute(S.PATH+suffix)
	print("PHASE 3 FLOW: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)

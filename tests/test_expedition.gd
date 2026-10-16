extends SceneTree
const G=preload("res://scripts/gear.gd")
const C=preload("res://scripts/content.gd")
const R=preload("res://scripts/rules.gd")
const S=preload("res://scripts/save_store.gd")
var game
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var backups={}
	for suffix in ["",".bak"]:
		if FileAccess.file_exists(S.PATH+suffix):backups[suffix]=FileAccess.get_file_as_string(S.PATH+suffix)
	var traces=JSON.parse_string(FileAccess.get_file_as_string("res://tests/solution_traces.json"))
	var completed=0
	for stance in ["Duelist","Reaver"]:
		var solution={}
		for candidate in traces:
			if candidate.profile=="starter" and candidate.stance==stance:solution=candidate;break
		if solution.is_empty():push_error("No starter solution for "+stance);quit(1);return
		S.write_save(S.defaults())
		game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.audio.enabled=false
		game.prefs.run={};game.settled=true;game.prefs.gear=G.fresh();game.stance=stance;game.depth=1
		game.start_run(false,int(solution.seed))
		for wave in 5:
			if game.state.side!=C.SIDES[wave]:push_error("Incorrect wave size");quit(1);return
			for path in solution.trace[wave]:
				var input=[]
				for cell in path:input.append(int(cell))
				var expected=R.resolve(game.state,input)
				if not expected.valid:push_error("Solution became invalid");quit(1);return
				for cell in input:game.select_cell(cell)
				game.execute_move();game.board._process(100)
				if game.state!=expected.state:push_error("Animated commit differs from reducer");quit(1);return
				await process_frame
			if wave<4:
				if game.screen!="camp":push_error("Expected camp");quit(1);return
				game.selected_boon=solution.boons[wave];game.next_wave_from_camp()
		if game.screen!="results" or not game.state.boss_defeated or not game.prefs.run.is_empty():push_error("Boss result not settled");quit(1);return
		completed+=1;game.queue_free();await process_frame
	for suffix in ["",".bak"]:
		if backups.has(suffix):
			var file=FileAccess.open(S.PATH+suffix,FileAccess.WRITE);file.store_string(backups[suffix]);file.close()
		else:DirAccess.remove_absolute(S.PATH+suffix)
	print("FULL EXPEDITIONS: ",completed," wins through all sizes, camps, 3D animation, boss and results")
	quit()

extends SceneTree
const R=preload("res://scripts/rules.gd")
const S=preload("res://scripts/save_store.gd")
var game
func _initialize() -> void:
	call_deferred("run")
func snap(name: String) -> void:
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview/"+name+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://preview")
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.audio.enabled=false
	game.prefs.run={};game.settled=true
	await snap("title")
	for wave in 5:
		game.state=R.new_board(14026,wave,"Duelist",20,{"vitality":6},1)
		game.encounter=wave;game.seed_value=14026;game.show_game()
		await snap("wave_%d" % (wave+1))
	game.encounter=0;game.state=R.new_board(14026,0,"Duelist");game.state.status="won";game.show_camp()
	await snap("camp")
	game.show_title();game.show_settings();await snap("settings");game.close_modal()
	game.show_codex();await snap("codex")
	print("PHASE 3 RENDER COMPLETE")
	quit()

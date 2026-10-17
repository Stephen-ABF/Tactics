extends SceneTree
const G=preload("res://scripts/gear.gd")
const P=preload("res://scripts/playtest.gd")
const R=preload("res://scripts/rules.gd")
var game
func _initialize() -> void:call_deferred("run")
func snap(name: String) -> void:
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview/"+name+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://preview")
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.audio.enabled=false
	game.show_title();await snap("v6_title")
	P.record_run(game.prefs.playtest,{"id":"render-sample","won":true,"reason":"boss","seconds":320,"camp_seconds":75,"planning_seconds":250,"animation_seconds":70,"gear":8,"common":4,"exclusive":1,"damage":11,"depth":1,"seed":14026,"decisions":23})
	game.show_playtest();await snap("v6_report");game.close_modal()
	game.show_save_tools();await snap("v6_save")
	game.stage_import(game.backup_editor.text);await snap("v6_restore");game.close_modal()
	var rng=RandomNumberGenerator.new();rng.seed=777
	for n in 15:
		var item=G.make_item(G.BASES.keys()[n%6],["normal","uncommon","rare","epic","unique","set"][n%6],rng)
		item.favorite=n%4==0;item.locked=n%5==0;game.prefs.gear.items.append(item)
	game.open_pack(false);var pack=game.pack_ui;pack.selected=game.prefs.gear.items[3].id;pack.tools_dialog();await snap("v6_stash")
	pack.compare_dialog();await snap("v6_compare");pack.closed.emit()
	game.start_run(false,9)
	game.state=R.new_board(9,0,"Duelist",14,{"edge":1,"counter":1,"temper":1});game.state.guard=1
	for tile in game.state.tiles:tile.kind=".";tile.hp=1;tile.max_hp=1
	game.state.player=6;game.state.tiles[7].kind="h";game.state.tiles[7].hp=4;game.state.tiles[7].max_hp=4;game.state.tiles[0].kind="s"
	game.show_game();game.select_cell(7);await snap("v6_preview")
	game.show_route_explanation();await snap("v6_why")
	print("UPDATE 6 SCREENS RENDERED");quit()

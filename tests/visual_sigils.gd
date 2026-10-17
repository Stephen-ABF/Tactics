extends SceneTree
const G=preload("res://scripts/gear.gd")
var game
func _initialize() -> void:call_deferred("run")
func snap(name: String) -> void:
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview/"+name+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://preview")
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.audio.enabled=false
	game.prefs.run={};game.settled=true;game.show_title();await snap("sigil_title")
	game.show_hunt_preview();await snap("scout_report");game.close_modal()
	game.show_codex();await snap("hunting_guide");game.close_modal()
	game.prefs.gear=G.fresh();game.prefs.gear.scrap=300;game.prefs.gear.marks=6
	for sigil in G.SIGILS:game.prefs.gear.runes[sigil]=2
	game.prefs.gear.items[0].tier=3
	game.open_pack(false);var pack=game.pack_ui;pack.selected=game.prefs.gear.items[0].id;pack.render()
	await snap("new_pack");pack.upgrade_dialog();await snap("risky_upgrade")
	pack.render();pack.socket_dialog();await snap("sigil_sockets")
	pack.binding_dialog();await snap("binding_book")
	pack.collection_dialog();await snap("set_collection")
	print("SIGIL SCREENS RENDERED");quit()

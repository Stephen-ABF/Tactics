extends Control
signal changed(event: String, data: Dictionary)
signal closed
const Gear=preload("res://scripts/gear.gd")
const ShapePreview=preload("res://scripts/shape_preview.gd")
const Grid=preload("res://scripts/pack_grid.gd")
var profile: Dictionary
var camp=false
var selected=""
var page=0
var placing=false
var socket_index=0
var message="Select an item, then Place / Move and tap its top-left cell."
var dialog: Control
var grid: Control
func _ready() -> void:
	size=Vector2(600,1000)
	render()
func label(value: String, rect: Rect2, font_size: int=18, color: Color=Color("e4e9d9"), parent: Node=null) -> Label:
	var node=Label.new()
	node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size",font_size)
	node.add_theme_color_override("font_color",color)
	node.text=value
	node.position=rect.position; node.size=rect.size
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	(parent if parent else self).add_child(node)
	return node
func button(value: String, rect: Rect2, callback: Callable, parent: Node=null) -> Button:
	var node=Button.new()
	node.text=value
	node.position=rect.position; node.size=rect.size
	node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size",17)
	var box=StyleBoxFlat.new()
	box.bg_color=Color("2d5149")
	box.set_corner_radius_all(8)
	node.add_theme_stylebox_override("normal",box)
	node.pressed.connect(callback)
	(parent if parent else self).add_child(node)
	return node
func clear() -> void:
	for child in get_children():
		remove_child(child); child.queue_free()
	dialog=null
func selected_item() -> Dictionary:
	return Gear.find(profile,selected)
func change(event: String, data: Dictionary={}) -> void:
	changed.emit(event,data)
	render()
func render() -> void:
	clear()
	var bg=ColorRect.new()
	bg.color=Color("101f24"); bg.size=size
	add_child(bg)
	label("PACK & FORGE",Rect2(36,22,285,48),28)
	button("Help",Rect2(340,20,104,52),help_dialog)
	button("Done",Rect2(460,20,104,52),func(): closed.emit())
	grid=Grid.new()
	grid.profile=profile; grid.selected=selected
	grid.position=Vector2(63,95); grid.size=Vector2(474,395)
	grid.cell_clicked.connect(cell_click)
	add_child(grid)
	label("Scrap %d   Shards %d   •   6 x 5 backpack" % [profile.scrap,profile.shards],Rect2(36,500,528,28),19)
	label(Gear.describe_stats(Gear.bonuses(profile))+" (caps apply)",Rect2(36,531,528,48),16,Color("b4d5b7"))
	var available=[]
	for item in profile.items:
		if item.location=="bag": continue
		if camp and item.location!="field": continue
		available.append(item)
	var max_page=maxi(0,(available.size()-1)/3)
	page=clampi(page,0,max_page)
	button("<",Rect2(36,590,42,62),func(): page=maxi(0,page-1); render())
	for n in 3:
		var index=page*3+n
		if index>=available.size(): break
		var item: Dictionary=available[index]
		var id: String=item.id
		var b=button(Gear.name_of(item),Rect2(84+n*146,590,140,62),func(): selected=id; placing=false; render())
		b.add_theme_color_override("font_color",Color(Gear.COLORS[Gear.quality(item)]))
	button(">",Rect2(522,590,42,62),func(): page=mini(max_page,page+1); render())
	label(("FIELD FINDS" if camp else "STASH")+"  %d items • page %d/%d" % [available.size(),page+1,max_page+1],Rect2(36,561,528,25),16)
	var item=selected_item()
	if not item.is_empty():
		var details=Gear.name_of(item)+"  ["+Gear.quality(item).to_upper()+"]\n"+Gear.describe_stats(Gear.item_stats(item))+"\nSockets: "+socket_summary(item)+("\nCORRUPTED: upgrades/socket count sealed" if not item.corruption.is_empty() else "")
		label(details,Rect2(36,669,422,103),16,Color(Gear.COLORS[Gear.quality(item)]))
		var shape=ShapePreview.new()
		shape.item=item; shape.position=Vector2(474,677); shape.size=Vector2(90,90)
		shape.mouse_filter=Control.MOUSE_FILTER_IGNORE
		add_child(shape)
	else: label("Select a packed item or a stash find. Every packed item contributes; there are no worn equipment slots.",Rect2(36,669,528,90),19)
	button("Place / Move",Rect2(36,780,168,50),func(): placing=true; message="Tap the top-left cell for the selected shape."; render())
	button("To stash" if not camp else "To field",Rect2(216,780,168,50),unpack)
	button("Rotate 90",Rect2(396,780,168,50),func(): message=Gear.rotate(profile,selected); change("gear_rotate"))
	button("Upgrade",Rect2(36,838,168,50),func(): message=Gear.upgrade(profile,selected); change("gear_upgrade"))
	button("Add socket",Rect2(216,838,168,50),func(): message=Gear.add_socket(profile,selected); change("gear_socket"))
	button("Runes",Rect2(396,838,168,50),socket_dialog)
	button("CORRUPT",Rect2(36,896,254,50),corruption_dialog)
	button("Salvage",Rect2(310,896,254,50),salvage_dialog)
	label(message,Rect2(36,953,528,42),16,Color("b9d0b4"))
func cell_click(x: int,y: int) -> void:
	var occupant=Gear.at(profile,x,y)
	if placing or (occupant.is_empty() and not selected.is_empty()):
		message=Gear.place(profile,selected,x,y)
		if message.begins_with("Packed"): placing=false
		change("gear_place",{"id":selected,"x":x,"y":y})
	elif not occupant.is_empty():
		selected=occupant
		placing=false
		render()
func unpack() -> void:
	var item=selected_item()
	if item.is_empty(): message="Select an item."
	else:
		item.location="field" if camp else "stash"
		message="Removed from active backpack."
	change("gear_unpack")
func panel(title: String) -> void:
	if dialog:
		remove_child(dialog); dialog.queue_free()
	dialog=Control.new(); dialog.size=size
	add_child(dialog)
	var shade=ColorRect.new()
	shade.size=size; shade.color=Color("0b1b21")
	dialog.add_child(shade)
	label(title,Rect2(36,45,528,70),30,Color("e4e9d9"),dialog)
func help_dialog() -> void:
	panel("YOUR BACKPACK IS YOUR BUILD")
	label("All packed items are active. Rotate and arrange shapes; there are no armor or weapon slots.\n\nEdge: + hit power (cap 2).\nVitality: + max HP (cap 12).\nWard: starting guard per grove (cap 3).\nFocus: starting momentum per route (cap 2).\nLeech: heal on 5+ kills, after retaliation (cap 2).\nBulwark: guard on 1–3-kill routes (cap 2).\n\nWarden set: 2 distinct pieces +1 Ward; 3 adds +1 Bulwark and Leech.\nWayfarer set: 2 pieces +2 Vitality; 3 adds +1 Focus and Leech.\n\nAt camp, only packed gear and this run's new field finds are accessible. Return home for the full stash.",Rect2(36,138,528,660),19,Color("d8e2d2"),dialog)
	button("Back",Rect2(36,880,528,60),render,dialog)
func socket_dialog() -> void:
	var item=selected_item()
	if item.is_empty(): message="Select an item first."; render(); return
	panel("SOCKETS & RUNEWORDS")
	label(Gear.name_of(item)+"\nOnly normal bases form runewords. Exact socket count, order and base type matter.",Rect2(36,125,528,100),21,Color("e4e9d9"),dialog)
	for n in item.sockets.size():
		var index=n
		button("%d: %s%s" % [n+1,"Empty" if item.sockets[n].is_empty() else item.sockets[n]," <" if n==socket_index else ""],Rect2(36+n*180,245,168,58),func(): socket_index=index; socket_dialog(),dialog)
	label("Select a socket, then a rune. Removal returns it safely.",Rect2(36,320,528,55),19,Color("b4d5b7"),dialog)
	var n=0
	for rune in Gear.RUNES:
		var name: String=rune
		button(name+" x%d" % profile.runes[name],Rect2(36+(n%3)*180,390+(n/3)*66,168,58),func(): message=Gear.insert_rune(profile,selected,socket_index,name); changed.emit("rune_insert",{"rune":name}); socket_dialog(),dialog)
		n+=1
	button("Remove selected rune",Rect2(36,535,528,55),func(): message=Gear.remove_rune(profile,selected,socket_index); changed.emit("rune_remove",{}); socket_dialog(),dialog)
	label("Briarsteel: Ash → Gale (blade/staff, 2)\nTrailguard: Root → Stone (shield/coat, 2)\nCinderwake: Ember → Ash → Gale (blade/staff, 3)\nWaking Grove: Root → Echo → Stone (coat/relic, 3)\n\n"+message,Rect2(36,620,528,220),20,Color("dfd6b7"),dialog)
	button("Back to pack",Rect2(36,880,528,60),render,dialog)
func corruption_dialog() -> void:
	var item=selected_item()
	if item.is_empty(): message="Select an item first."; render(); return
	panel("CORRUPTION — ONE ATTEMPT")
	label(Gear.name_of(item)+"\n\nCosts 1 corruption shard.\n\n90%: add +2 to one randomly chosen trait.\n10%: destroy this item and ALL socketed runes.\n\nSuccess seals the upgrade tier and socket count. You may still insert or remove runes. Trait caps may limit the immediate benefit to your current build.\n\nThis choice is irreversible during normal play.",Rect2(36,145,528,600),24,Color("edcfb6"),dialog)
	button("USE SHARD — ACCEPT RISK",Rect2(36,786,528,62),func():
		var rng=RandomNumberGenerator.new(); rng.randomize()
		var result=Gear.corrupt(profile,selected,rng)
		message=result.message
		changed.emit("gear_corrupt",result)
		render(),dialog)
	button("Cancel",Rect2(36,875,528,60),render,dialog)
func salvage_dialog() -> void:
	var item=selected_item()
	if item.is_empty(): message="Select an item first."; render(); return
	panel("SALVAGE ITEM")
	label("Permanently dismantle "+Gear.name_of(item)+"?\n\nGain %d scrap. All socketed runes return to your rune pouch." % (3+int(item.tier)*2),Rect2(36,160,528,320),24,Color("e4e9d9"),dialog)
	button("Salvage",Rect2(36,745,528,60),func(): message=Gear.salvage(profile,selected); selected=""; change("gear_salvage"),dialog)
	button("Cancel",Rect2(36,835,528,60),render,dialog)

func socket_summary(item: Dictionary) -> String:
	if item.sockets.is_empty(): return "None"
	var names=[]
	for rune in item.sockets: names.append("Empty" if rune.is_empty() else rune)
	return " | ".join(names)

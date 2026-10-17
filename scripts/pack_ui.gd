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
var confirmation_active=false
var sort_order="Newest"
var quality_filter="All"
var search_text=""
var compare_id=""
var tools_page=0
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
	dialog=null;confirmation_active=false
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
	label("PACK",Rect2(36,22,180,48),28)
	button("Tools",Rect2(230,20,104,52),tools_dialog)
	button("Guide",Rect2(340,20,104,52),help_dialog)
	button("Done",Rect2(460,20,104,52),func(): closed.emit())
	grid=Grid.new()
	grid.profile=profile; grid.selected=selected
	grid.position=Vector2(63,95); grid.size=Vector2(474,395)
	grid.cell_clicked.connect(cell_click)
	add_child(grid)
	label("Scrap %d • Shards %d • Marks %d" % [profile.scrap,profile.shards,profile.marks],Rect2(36,500,528,28),19)
	var total=Gear.bonuses(profile)
	var specials=0
	for stat in Gear.STATS:
		if stat not in Gear.BASIC_STATS and int(total.get(stat,0))>0:specials+=1
	label("Edge %d • HP +%d • Ward %d • Focus %d\nLeech %d • Bulwark %d • %d special traits • caps apply" % [total.edge,total.vitality,total.ward,total.focus,total.leech,total.bulwark,specials],Rect2(36,531,528,40),16,Color("b4d5b7"))
	var available=Gear.query(profile,camp,quality_filter,sort_order,search_text)
	var max_page=maxi(0,(available.size()-1)/3)
	page=clampi(page,0,max_page)
	button("<",Rect2(36,604,42,62),func(): page=maxi(0,page-1); render())
	for n in 3:
		var index=page*3+n
		if index>=available.size(): break
		var item: Dictionary=available[index]
		var id: String=item.id
		var b=button(("★ " if item.get("favorite",false) else "")+("[L] " if item.get("locked",false) else "")+Gear.name_of(item),Rect2(84+n*146,604,140,62),func(): selected=id; placing=false; render())
		b.add_theme_color_override("font_color",Color(Gear.COLORS[Gear.quality(item)]))
	button(">",Rect2(522,604,42,62),func(): page=mini(max_page,page+1); render())
	label(("FIELD FINDS" if camp else "STASH")+"  %d items • page %d/%d" % [available.size(),page+1,max_page+1],Rect2(36,574,528,25),16)
	var item=selected_item()
	if not item.is_empty():
		var details=("LOCKED • " if item.get("locked",false) else "")+("FAVORITE • " if item.get("favorite",false) else "")+Gear.name_of(item)+"  ["+Gear.quality(item).to_upper()+"]\n"+Gear.describe_stats(Gear.item_stats(item))+"\nSockets: "+socket_summary(item)+("\nCORRUPTED: upgrades/socket count sealed" if not item.corruption.is_empty() else "")
		var detail_scroll=ScrollContainer.new();detail_scroll.name="ItemDetails";detail_scroll.position=Vector2(36,681);detail_scroll.size=Vector2(422,88);add_child(detail_scroll)
		var detail_copy=Label.new();detail_copy.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail_copy.custom_minimum_size=Vector2(398,0)
		detail_copy.add_theme_font_size_override("font_size",16);detail_copy.add_theme_color_override("font_color",Color(Gear.COLORS[Gear.quality(item)]));detail_copy.text=details;detail_scroll.add_child(detail_copy)
		var shape=ShapePreview.new()
		shape.item=item; shape.position=Vector2(474,685); shape.size=Vector2(90,90)
		shape.mouse_filter=Control.MOUSE_FILTER_IGNORE
		add_child(shape)
	else: label("Select a packed item or a stash find. Every packed item contributes; there are no worn equipment slots.",Rect2(36,681,528,88),19)
	button("Place / Move",Rect2(36,780,168,50),func(): placing=true; message="Tap the top-left cell for the selected shape."; render())
	button("To stash" if not camp else "To field",Rect2(216,780,168,50),unpack)
	button("Rotate 90",Rect2(396,780,168,50),func(): message=Gear.rotate(profile,selected); change("gear_rotate"))
	button("Upgrade"+(" +%d (%d)" % [item.tier+1,(item.tier+1)*6] if not item.is_empty() and item.tier<6 else ""),Rect2(36,838,168,50),upgrade_dialog)
	button("Add socket",Rect2(216,838,168,50),func(): message=Gear.add_socket(profile,selected); change("gear_socket"))
	button("Sigils",Rect2(396,838,168,50),socket_dialog)
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
func scroll_copy(value: String,rect: Rect2,font_size: int=19) -> void:
	var scroll=ScrollContainer.new();scroll.position=rect.position;scroll.size=rect.size;dialog.add_child(scroll)
	var copy=Label.new();copy.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;copy.custom_minimum_size=Vector2(rect.size.x-24,0)
	copy.add_theme_font_size_override("font_size",font_size);copy.text=value;scroll.add_child(copy)
func help_dialog() -> void:
	panel("PACK & FORGE GUIDE")
	var body="All packed items are active. Rotate shapes; no body equipment slots. Caps apply across your entire backpack.\n\nFIRST BINDING: select your starting blade, open Sigils, insert Ash in socket 1 and Gale in socket 2. Briarsteel activates.\n\nUpgrades +1 to +3 are safe. +4: 5% destruction; +5: 10%; +6: 20%. Costs 6 × target level scrap. Each level adds the trait shown before upgrading; caps can limit current benefit.\n\nCorruption: 90% random +2 modifier, 10% destroys gear and inserted Sigils. One attempt; success seals upgrades/socket count. Sigil removal remains free.\n\nEdge: hit power (cap 2). Vitality: max HP (12). Ward: starting guard (3). Focus: starting momentum (2). Leech: heal on 5+ kills, after damage (2). Bulwark: guard on 1–3 kills (2).\n\n"
	for stat in Gear.EFFECT_HELP:body+=Gear.stat_name(stat)+": "+Gear.EFFECT_HELP[stat]+"\n\n"
	body+="Warden set: 2 distinct pieces +1 Ward; 3 adds Bulwark/Leech. Wayfarer: 2 pieces +2 Vitality; 3 adds Focus/Leech.\n\nHome stash is unavailable at camp. New field finds can be packed there. Warden victories grant a mark; 6 marks buy a chosen set piece at home."
	scroll_copy(body,Rect2(36,135,528,610))
	button("Set collection • %d marks" % profile.marks,Rect2(36,790,528,60),collection_dialog,dialog)
	button("Back",Rect2(36,880,528,60),render,dialog)
func upgrade_dialog() -> void:
	var info=Gear.upgrade_info(profile,selected)
	if not info.ok:message=info.message;render();return
	if info.risk<=0:
		message=Gear.upgrade(profile,selected);change("gear_upgrade",{"tier":info.level,"cost":info.cost,"destroyed":false});return
	var id=selected
	panel("PUSH THIS ITEM FURTHER?")
	label(Gear.name_of(selected_item())+"\n\nUpgrade to +%d: +1 %s\nCost: %d scrap\n\n%d%%: succeeds\n%d%%: DESTROYS item and ALL inserted Sigils.\n\nThe scrap is spent on either outcome. Caps can limit the benefit. Remove valuable Sigils first if you want to protect them." % [info.level,Gear.stat_name(info.trait),info.cost,100-int(info.risk*100),int(info.risk*100)]+("\n\n"+Gear.EFFECT_HELP[info.trait] if Gear.EFFECT_HELP.has(info.trait) else ""),Rect2(36,150,528,550),23,Color("edcfb6"),dialog)
	confirmation_active=true
	button("ACCEPT RISK • UPGRADE +%d" % info.level,Rect2(36,785,528,62),func():
		if not confirmation_active:return
		confirmation_active=false
		var rng=RandomNumberGenerator.new();rng.randomize()
		message=Gear.upgrade(profile,id,rng,true,info.level)
		changed.emit("gear_upgrade",{"tier":info.level,"cost":info.cost,"risk":info.risk,"destroyed":Gear.find(profile,id).is_empty()})
		render(),dialog)
	button("Cancel",Rect2(36,875,528,60),render,dialog)
func socket_dialog() -> void:
	var item=selected_item()
	if item.is_empty():message="Select an item first.";render();return
	panel("SOCKETS & SIGILS")
	label(Gear.name_of(item)+"\nBindings require a Normal base, exact socket count and correct Sigil order.",Rect2(36,125,528,90),19,Color("e4e9d9"),dialog)
	socket_index=clampi(socket_index,0,maxi(0,item.sockets.size()-1))
	for n in item.sockets.size():
		var index=n
		button("%d: %s%s" % [n+1,"Empty" if item.sockets[n].is_empty() else item.sockets[n]," <" if n==socket_index else ""],Rect2(36+n*180,230,168,58),func():socket_index=index;socket_dialog(),dialog)
	var scroll=ScrollContainer.new();scroll.position=Vector2(36,310);scroll.size=Vector2(528,310);dialog.add_child(scroll)
	var choices=GridContainer.new();choices.columns=2;choices.add_theme_constant_override("h_separation",12);choices.add_theme_constant_override("v_separation",8);scroll.add_child(choices)
	for sigil in Gear.SIGILS:
		var name: String=sigil
		var badge="" if name in Gear.COMMON_SIGILS else (" [Boss]" if name=="Heartroot" else " [Hunt]")
		var choice=button(name+badge+" ×%d\n" % profile.runes[name]+Gear.describe_stats(Gear.SIGILS[name]),Rect2(0,0,246,74),func():message=Gear.insert_rune(profile,selected,socket_index,name);changed.emit("sigil_insert",{"sigil":name});socket_dialog(),choices)
		choice.custom_minimum_size=Vector2(246,74);choice.add_theme_font_size_override("font_size",17)
		choice.disabled=profile.runes[name]<=0 or item.sockets.is_empty()
	label("Select socket, then Sigil. Scroll for enemy Sigils.\n"+message,Rect2(36,636,528,65),17,Color("b4d5b7"),dialog)
	button("Remove selected",Rect2(36,712,254,55),func():message=Gear.remove_rune(profile,selected,socket_index);changed.emit("sigil_remove",{});socket_dialog(),dialog)
	button("Remove all",Rect2(310,712,254,55),func():var result=Gear.unsocket_all(profile,selected);message=result.message;changed.emit("sigil_remove_all",{"count":result.count});socket_dialog(),dialog)
	button("Binding recipes & effects",Rect2(36,785,528,60),binding_dialog,dialog)
	button("Back to pack",Rect2(36,880,528,60),render,dialog)
func binding_dialog() -> void:
	panel("BINDING RECIPE BOOK")
	var body="Normal bases only. Exact number of sockets; exact order. Wrong combinations retain individual Sigil bonuses.\n\n"+Gear.binding_book()+"\n\nCONDITIONAL EFFECTS\n"
	for stat in Gear.EFFECT_HELP:body+="\n"+Gear.stat_name(stat)+": "+Gear.EFFECT_HELP[stat]
	scroll_copy(body,Rect2(36,140,528,680),18)
	button("Back to Sigils",Rect2(36,880,528,60),socket_dialog,dialog)
func collection_dialog() -> void:
	panel("CHOOSE A SET PIECE")
	label("%d Warden marks • Each chosen piece costs %d.\nOne mark per boss victory. Distinct set parts activate bonuses.\n" % [profile.marks,Gear.SET_MARK_COST]+("Return home to redeem marks." if camp else "Choose a base below to claim its set version."),Rect2(36,145,528,150),21,Color("e4e9d9"),dialog)
	var n=0
	for base in Gear.BASES:
		var name: String=base
		var group="Warden" if base in ["shield","coat","charm"] else "Wayfarer"
		var claim=button(group+" "+Gear.BASES[base].name+" • 6 marks",Rect2(36,325+n*77,528,64),func():message=Gear.redeem_set(profile,name);changed.emit("set_redeem",{"base":name});collection_dialog(),dialog)
		claim.disabled=camp or profile.marks<Gear.SET_MARK_COST;n+=1
	label(message,Rect2(36,800,528,65),17,Color("b4d5b7"),dialog)
	button("Back",Rect2(36,880,528,60),render,dialog)
func corruption_dialog() -> void:
	var item=selected_item()
	if item.get("locked",false):message="Locked: unlock in Tools before corruption.";render();return
	if item.is_empty(): message="Select an item first."; render(); return
	panel("CORRUPTION — ONE ATTEMPT")
	label(Gear.name_of(item)+"\n\nCosts 1 corruption shard.\n\n90%: add +2 to one randomly chosen trait.\n10%: destroy this item and ALL socketed Sigils.\n\nSuccess seals the upgrade tier and socket count. You may still insert or remove Sigils. Trait caps may limit the immediate benefit to your current build.\n\nThis choice is irreversible during normal play.",Rect2(36,145,528,600),24,Color("edcfb6"),dialog)
	button("USE SHARD — ACCEPT RISK",Rect2(36,786,528,62),func():
		var rng=RandomNumberGenerator.new(); rng.randomize()
		var result=Gear.corrupt(profile,selected,rng)
		message=result.message
		changed.emit("gear_corrupt",result)
		render(),dialog)
	button("Cancel",Rect2(36,875,528,60),render,dialog)
func salvage_dialog() -> void:
	var item=selected_item()
	if item.get("locked",false):message="Locked: unlock in Tools before salvage.";render();return
	if item.is_empty(): message="Select an item first."; render(); return
	panel("SALVAGE ITEM")
	label("Permanently dismantle "+Gear.name_of(item)+"?\n\nGain %d scrap. All socketed Sigils return to your Sigil pouch." % (3+int(item.tier)*2),Rect2(36,160,528,320),24,Color("e4e9d9"),dialog)
	button("Salvage",Rect2(36,745,528,60),func(): message=Gear.salvage(profile,selected); selected=""; change("gear_salvage",{"salvaged":message.begins_with("Salvaged")}),dialog)
	button("Cancel",Rect2(36,835,528,60),render,dialog)

func socket_summary(item: Dictionary) -> String:
	if item.sockets.is_empty(): return "None"
	var names=[]
	for rune in item.sockets: names.append("Empty" if rune.is_empty() else rune)
	return " | ".join(names)

func tools_dialog() -> void:
	panel("STASH TOOLS")
	var order=OptionButton.new();order.position=Vector2(36,130);order.size=Vector2(254,50);order.add_theme_font_size_override("font_size",18)
	var orders=["Newest","Name","Tier","Quality"]
	for value in orders:order.add_item(value)
	order.select(orders.find(sort_order));order.item_selected.connect(func(index):sort_order=orders[index];page=0;tools_page=0;tools_dialog());dialog.add_child(order)
	var filter=OptionButton.new();filter.position=Vector2(310,130);filter.size=Vector2(254,50);filter.add_theme_font_size_override("font_size",18)
	var filters=["All","Favorites","Locked","Normal","Uncommon","Rare","Epic","Unique","Set","Binding"]
	for value in filters:filter.add_item(value)
	filter.select(filters.find(quality_filter));filter.item_selected.connect(func(index):quality_filter=filters[index];page=0;tools_page=0;tools_dialog());dialog.add_child(filter)
	var search=LineEdit.new();search.position=Vector2(36,195);search.size=Vector2(528,50);search.placeholder_text="Search name, base or Sigil; Enter to apply";search.text=search_text;search.add_theme_font_size_override("font_size",17)
	search.text_changed.connect(func(value):search_text=value)
	search.text_submitted.connect(func(value):search_text=value;page=0;tools_page=0;tools_dialog());dialog.add_child(search)
	var scroll=ScrollContainer.new();scroll.position=Vector2(36,275);scroll.size=Vector2(528,300);dialog.add_child(scroll)
	var list=VBoxContainer.new();list.add_theme_constant_override("separation",8);scroll.add_child(list)
	var entries=Gear.query(profile,camp,quality_filter,sort_order,search_text,true)
	var pages=maxi(1,ceili(entries.size()/40.0));tools_page=clampi(tools_page,0,pages-1)
	label("%d matches • page %d / %d" % [entries.size(),tools_page+1,pages],Rect2(36,247,528,26),16,Color("b4d5b7"),dialog)
	for item in entries.slice(tools_page*40,tools_page*40+40):
		var id: String=item.id
		var caption=("★ " if item.get("favorite",false) else "")+("[LOCK] " if item.get("locked",false) else "")+Gear.name_of(item)+" • "+Gear.quality(item)+(" • packed" if item.location=="bag" else "")
		var row=button(caption,Rect2(0,0,500,56),func():selected=id;tools_dialog(),list);row.custom_minimum_size=Vector2(500,56)
	if entries.is_empty():label("No matches. Change filters or clear search.",Rect2(36,275,490,70),19,Color("b4d5b7"),dialog)
	var item=selected_item()
	button("Previous",Rect2(36,590,254,50),func():tools_page=maxi(0,tools_page-1);tools_dialog(),dialog)
	button("Next",Rect2(310,590,254,50),func():tools_page=mini(pages-1,tools_page+1);tools_dialog(),dialog)
	label(Gear.name_of(item) if not item.is_empty() else "Select any row or packed item.",Rect2(36,650,528,28),17,Color("b4d5b7"),dialog)
	button(("Unfavorite" if item.get("favorite",false) else "Favorite"),Rect2(36,685,254,55),func():Gear.flag(profile,selected,"favorite");changed.emit("gear_flag",{});tools_dialog(),dialog)
	button(("Unlock" if item.get("locked",false) else "Lock destruction"),Rect2(310,685,254,55),func():Gear.flag(profile,selected,"locked");changed.emit("gear_flag",{});tools_dialog(),dialog)
	button("Compare selected item",Rect2(36,760,528,55),compare_dialog,dialog)
	label("Lock blocks salvage, corruption and risky upgrades. Safe upgrades and Sigil recovery remain available.",Rect2(36,830,528,45),16,Color("b4d5b7"),dialog)
	button("Back to pack",Rect2(36,900,528,60),render,dialog)
func compare_dialog() -> void:
	var item=selected_item()
	if item.is_empty():message="Select a candidate first.";render();return
	panel("COMPARE GEAR")
	var refs=[]
	for entry in profile.items:
		if entry.id!=selected and entry.location=="bag":refs.append(entry)
	if refs.is_empty():
		label("Pack a reference item first.",Rect2(36,160,528,100),22,Color("b4d5b7"),dialog)
	else:
		if not compare_id in refs.map(func(entry):return entry.id):compare_id=refs[0].id
		var selector=OptionButton.new();selector.position=Vector2(36,140);selector.size=Vector2(528,55);selector.add_theme_font_size_override("font_size",18)
		for entry in refs:selector.add_item(Gear.name_of(entry))
		for index in refs.size():
			if refs[index].id==compare_id:selector.select(index)
		selector.item_selected.connect(func(index):compare_id=refs[index].id;compare_dialog());dialog.add_child(selector)
		var result=Gear.compare(profile,selected,compare_id)
		var lines=["CANDIDATE: "+Gear.name_of(item),"Footprint: %d cells; rotate/rearrange manually." % Gear.cells(item).size(),"ITEM TRAIT DIFFERENCES\n"+Gear.delta_text(result.get("raw",{}))]
		if not result.get("effective",{}).is_empty():lines.append("EFFECTIVE PACK CHANGE\n"+Gear.delta_text(result.effective))
		lines.append(result.message)
		scroll_copy("\n\n".join(lines),Rect2(36,230,528,570),20)
	button("Back to Tools",Rect2(36,880,528,60),tools_dialog,dialog)

extends Control
const Rules=preload("res://scripts/rules.gd")
const Content=preload("res://scripts/content.gd")
const Save=preload("res://scripts/save_store.gd")
const Gear=preload("res://scripts/gear.gd")
const PackUI=preload("res://scripts/pack_ui.gd")
const BoardScene=preload("res://scenes/board.tscn")
const Sound=preload("res://scripts/audio.gd")
var canvas: Control
var board: ThornBoard
var audio: ThornAudio
var prefs: Dictionary
var state: Dictionary={}
var route: Array=[]
var preview: Dictionary={}
var pending: Dictionary={}
var status_label: Label
var info_label: Label
var strike_button: Button
var overlay: Control
var pack_ui: Control
var screen="title"
var modal_kind=""
var stance="Duelist"
var seed_value=14026
var encounter=0
var depth=1
var bank=0
var total_kills=0
var active_seconds=0.0
var camp_seconds=0.0
var planning_seconds=0.0
var animation_seconds=0.0
var app_active=true
var settled=true
var paused=false
var busy=false
var training=false
var run_id=""
var run_loot=0
var boons: Array=[]
var selected_boon=""
var last_finished=0
var save_failed=false
var title_notice=""
func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("101f24"))
	get_tree().auto_accept_quit=false
	prefs=Save.read_save()
	prefs.version=3
	var valid_snapshot=normalize_snapshot(prefs.run)
	prefs.run=valid_snapshot
	prefs.gear=Gear.normalize(prefs.gear,not valid_snapshot.is_empty())
	if valid_snapshot.is_empty():Gear.bank_field(prefs.gear)
	if Save.recovered_backup:title_notice="Recovered your previous save checkpoint."
	audio=Sound.new();add_child(audio);audio.enabled=prefs.sound
	canvas=Control.new();canvas.size=Vector2(600,1000);add_child(canvas)
	get_viewport().size_changed.connect(layout)
	layout();persist();show_title()
func _process(delta: float) -> void:
	if not app_active:return
	var seconds=minf(delta,1.0)
	if screen=="game" and not paused:
		active_seconds+=seconds
		if busy:animation_seconds+=seconds
		else:planning_seconds+=seconds
	elif screen=="camp":camp_seconds+=seconds
static func fit_canvas(available: Rect2) -> Dictionary:
	var factor=maxf(0.01,minf(available.size.x/600.0,available.size.y/1000.0))
	return {"scale":factor,"position":available.position+(available.size-Vector2(600,1000)*factor)*0.5}
func layout() -> void:
	if not canvas:return
	var rect=get_viewport_rect()
	if OS.get_name() in ["Android","iOS"]:
		var window=get_window()
		var safe=DisplayServer.get_display_safe_area()
		if safe.size.x>0 and safe.size.y>0 and window.size.x>0 and window.size.y>0:
			var physical=Rect2i(window.position,window.size).intersection(safe)
			if physical.size.x>0 and physical.size.y>0:
				var ratio=rect.size/Vector2(window.size)
				rect=Rect2(Vector2(physical.position-window.position)*ratio,Vector2(physical.size)*ratio)
	var result=fit_canvas(rect)
	canvas.scale=Vector2.ONE*result.scale;canvas.position=result.position
func text(value: String,x: float,y: float,width: float,height: float,font_size: int=20,color: Color=Color("dfebdb"),parent: Node=null) -> Label:
	var node=Label.new();node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size",font_size);node.add_theme_color_override("font_color",color)
	node.text=value;node.position=Vector2(x,y);node.size=Vector2(width,height)
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	(parent if parent else canvas).add_child(node)
	return node
func button(value: String,rect: Rect2,callback: Callable,accent: bool=false,parent: Node=null) -> Button:
	var node=Button.new();node.text=value;node.position=rect.position;node.size=rect.size
	node.add_theme_font_size_override("font_size",19)
	var style=StyleBoxFlat.new();style.bg_color=Color("3d795f") if accent else Color("29413f");style.set_corner_radius_all(10)
	node.add_theme_stylebox_override("normal",style)
	var hover=style.duplicate();hover.bg_color=style.bg_color.lightened(0.12)
	node.add_theme_stylebox_override("hover",hover);node.add_theme_stylebox_override("pressed",hover)
	node.pressed.connect(callback);(parent if parent else canvas).add_child(node)
	return node
func clear_screen() -> void:
	for child in canvas.get_children():canvas.remove_child(child);child.queue_free()
	board=null;overlay=null;pack_ui=null;modal_kind="";paused=false;busy=false
func persist() -> void:
	save_failed=not Save.write_save(prefs)
func normalize_snapshot(raw: Dictionary) -> Dictionary:
	if raw.is_empty() or int(raw.get("version",0))!=1 or raw.get("phase","") not in ["game","camp"]:return {}
	if not raw.get("state") is Dictionary:return {}
	var checked=Rules.normalize_saved(raw.state)
	if checked.is_empty() or checked.status=="lost":return {}
	if (raw.phase=="camp" and (checked.status!="won" or checked.encounter>=4)) or (raw.phase=="game" and checked.status!="playing"):return {}
	if not raw.get("id") is String or raw.id.is_empty() or not raw.get("boons") is Array:return {}
	var copy=raw.duplicate(true);copy.state=checked
	var clean=[]
	for id in copy.boons:
		if not Content.BOONS.has(id):return {}
		clean.append(id)
	if clean.size()!=checked.encounter:return {}
	copy.boons=clean
	for key in ["bank","total_kills","run_loot","seconds"]:
		if not (copy.get(key) is int or copy.get(key) is float) or copy[key]<0:return {}
	copy.bank=int(copy.bank);copy.total_kills=int(copy.total_kills);copy.run_loot=int(copy.run_loot);copy.seconds=float(copy.seconds)
	for key in ["camp_seconds","planning_seconds","animation_seconds"]:
		var value=copy.get(key,0.0)
		if not (value is int or value is float) or value<0:return {}
		copy[key]=float(value)
	copy.stance=copy.get("stance",checked.stance)
	if copy.stance not in ["Duelist","Reaver"]:return {}
	copy.choice=str(copy.get("choice",""))
	if not copy.choice.is_empty() and copy.choice not in Content.choices(checked.seed,checked.encounter):copy.choice=""
	return copy
func checkpoint(phase: String="game") -> void:
	if training or settled:return
	prefs.run={"version":1,"phase":phase,"state":state.duplicate(true),"id":run_id,"stance":stance,"boons":boons.duplicate(),"choice":selected_boon,"bank":bank,"total_kills":total_kills,"run_loot":run_loot,"seconds":active_seconds,"camp_seconds":camp_seconds,"planning_seconds":planning_seconds,"animation_seconds":animation_seconds}
	persist()
func show_title() -> void:
	clear_screen();screen="title"
	text("T H O R N W A K E",36,64,528,65,42)
	text("SIGILS OF THE WILD",39,133,522,35,17,Color("a5c4a7"))
	text("3 x 3 → 4 x 4 → 5 x 5\n6 x 6 → HEARTROOT WARDEN",39,205,522,100,27)
	text("Pack. Hunt Sigils. Forge Bindings.\nReclaim five changing battlegrounds.",39,320,522,65,21)
	button("Depth %d / %d" % [depth,prefs.unlocked_depth],Rect2(36,415,254,56),func():depth=depth%prefs.unlocked_depth+1;show_title())
	button("Stance: "+stance,Rect2(310,415,254,56),func():stance="Reaver" if stance=="Duelist" else "Duelist";show_title())
	if not prefs.run.is_empty():
		button("RESUME WAVE %d" % (prefs.run.state.encounter+1),Rect2(36,501,528,64),resume_run,true)
		button("New expedition…",Rect2(36,579,528,58),confirm_new)
	else:button("SCOUT EXPEDITION",Rect2(36,527,528,68),show_hunt_preview,true)
	button("Backpack & forge",Rect2(36,665,528,60),func():open_pack(false))
	button("Learn to play",Rect2(36,740,254,56),func():show_help(true))
	button("Hunting guide",Rect2(310,740,254,56),show_codex)
	button("Settings",Rect2(36,812,528,54),show_settings)
	text("v0.5.0 • SIGILS & RISK TEST BUILD\n%d wins / %d runs • %d supplies" % [prefs.wins,prefs.runs,prefs.materials],39,890,522,62,16,Color("9ab3a4"))
	text("Save failed; check writable storage." if save_failed else title_notice,39,955,522,35,16,Color("e7b098"))
func confirm_new() -> void:
	modal("START A NEW EXPEDITION?","Your saved encounter will end. Packed gear and collected loot stay safe.","new")
	modal_button("End saved run & start",750,func():resume_run();finish_run(false,"abandon");start_run(false),true)
	modal_button("Cancel",835,close_modal)
func expedition_seed() -> int:
	return int(Time.get_unix_time_from_system())%1000000
func show_hunt_preview(requested_seed: int=-1) -> void:
	var proposed_seed=expedition_seed() if requested_seed<0 else requested_seed
	var lines=["Seed %d • Depth %d\nCommon Sigils: 2%% from every enemy.\n" % [proposed_seed,depth]]
	for wave in 5:
		var sample=Rules.new_board(proposed_seed,wave,stance,14,{},depth)
		var counts={}
		for tile in sample.tiles:
			if Rules.enemy(tile):counts[tile.kind]=int(counts.get(tile.kind,0))+1
		var foes=[]
		for kind in counts:foes.append("%s ×%d" % [Content.ENEMIES[kind].name,counts[kind]])
		lines.append("Wave %d • %s\n%s" % [wave+1,Content.ZONES[sample.zone].name,", ".join(foes)])
	modal("EXPEDITION SCOUT REPORT","","scout")
	modal_scroll("\n\n".join(lines),Rect2(36,190,528,560))
	modal_button("Begin this expedition",800,func():close_modal();start_run(false,proposed_seed),true)
	button("Rescout",Rect2(36,882,254,60),func():show_hunt_preview((proposed_seed+7919)%1000000),false,overlay)
	button("Back",Rect2(310,882,254,60),close_modal,false,overlay)
func start_run(tutorial: bool=false,requested_seed: int=-1) -> void:
	if not prefs.run.is_empty() and not settled and not tutorial:return
	training=tutorial;run_id=Gear.uid();run_loot=0;boons=[];selected_boon=""
	seed_value=14026 if tutorial else (requested_seed if requested_seed>=0 else int(Time.get_unix_time_from_system())%1000000)
	encounter=0;bank=0;total_kills=0;active_seconds=0;camp_seconds=0;planning_seconds=0;animation_seconds=0;settled=false
	if not tutorial:Gear.bank_field(prefs.gear)
	var bonus={} if tutorial else Content.combine(Gear.bonuses(prefs.gear),boons)
	state=Rules.new_board(seed_value,0,stance,Rules.MAX_HP+int(bonus.get("vitality",0)),bonus,1 if tutorial else depth)
	Save.log_event("run_start",{"id":run_id,"seed":seed_value,"depth":depth,"gear":bonus,"training":training,"immediate_retry":last_finished>0 and Time.get_ticks_msec()-last_finished<15000})
	checkpoint();show_game()
func resume_run() -> void:
	var saved=normalize_snapshot(prefs.run)
	if saved.is_empty():prefs.run={};Gear.bank_field(prefs.gear);persist();show_title();return
	state=saved.state;seed_value=state.seed;encounter=state.encounter;depth=state.depth;stance=saved.stance
	run_id=saved.id;boons=saved.boons;bank=saved.bank;total_kills=saved.total_kills;run_loot=saved.run_loot;active_seconds=saved.seconds;camp_seconds=saved.camp_seconds;planning_seconds=saved.planning_seconds;animation_seconds=saved.animation_seconds;selected_boon=saved.choice
	training=false;settled=false
	Save.log_event("run_resume",{"id":run_id,"wave":encounter})
	if saved.phase=="camp":show_camp()
	else:show_game()
func show_game() -> void:
	clear_screen();screen="game";route=[];preview={}
	text("THORNWAKE",30,20,400,38,28)
	button("II",Rect2(510,20,60,54),pause_game)
	var zone=Content.ZONES[state.zone].name
	text(("PRACTICE" if training else "WAVE %d / 5" % (encounter+1))+" • "+zone+" • %d x %d" % [state.side,state.side],30,75,540,34,17,Color("a6c8b2"))
	status_label=text("",30,113,540,34,22)
	info_label=text("",30,151,540,66,17)
	board=BoardScene.instantiate();board.position=Vector2(6,220);board.size=Vector2(588,588)
	board.state=state;board.reduced_motion=not prefs.motion;board.quality=prefs.quality
	board.cell_selected.connect(select_cell);board.animation_done.connect(commit_move)
	board.health_changed.connect(func(value):status_label.text="HEALTH %d / %d" % [value,state.max_hp])
	board.combat_event.connect(func(kind):audio.tone(115 if kind=="hurt" else (740 if kind=="guard" else (950 if kind=="bow" else 390)),0.10))
	canvas.add_child(board)
	strike_button=button("STRIKE",Rect2(30,818,260,60),execute_move,true)
	button("Undo",Rect2(306,818,120,60),undo);button("Clear",Rect2(442,818,128,60),clear_route)
	text("Tap adjoining cells • empty-cell stride: %d" % (2+int(state.gear.get("stride",0))),30,890,540,30,17,Color("a5c4a7"))
	button("Rules",Rect2(30,934,110,50),func():show_help(false))
	text("Seed %d • %s • Depth %d" % [seed_value,stance,depth],155,936,415,44,15,Color("a0b7a8"))
	update_preview()
func select_cell(i: int) -> void:
	if screen!="game" or paused or busy:return
	if i==state.player:route.clear()
	elif i in route:route=route.slice(0,route.find(i)+1)
	else:
		var candidate=route+[i]
		var check=Rules.resolve(state,candidate)
		if not check.valid:info_label.text=check.reason;audio.tone(130);Save.log_event("route_rejected",{"reason":check.reason});return
		route=candidate
	audio.tone(380+route.size()*25,0.04);update_preview()
func update_preview() -> void:
	status_label.text="HP %d / %d    GUARD %d    FOES %d%s" % [state.hp,state.max_hp,state.guard,Rules.enemies_left(state),"   POISON %d" % state.poison if state.poison>0 else ""]
	preview=Rules.resolve(state,route);strike_button.disabled=not preview.valid or busy
	if route.is_empty():
		info_label.text="Plan a route, inspect danger, then Strike.\n"+("Practice: defeat a scout." if training else "Amber = arrows • purple crosses = spells • coral = boss")
	elif preview.valid:
		info_label.text="%d kills • %d momentum • %d damage • +%d healing\n" % [preview.kills,preview.momentum,preview.damage,preview.healing]
		info_label.text+="Enemy survives: lunge, chip, return." if preview.state.player!=route.back() else ("Safe landing." if preview.damage==0 else "Survivors strike after your move. Try another landing.")
	board.state=state;board.route=route;board.preview=preview
func undo() -> void:
	if paused or busy:return
	if not route.is_empty():route.pop_back()
	update_preview()
func clear_route() -> void:
	if paused or busy:return
	route.clear();update_preview()
func execute_move() -> void:
	if paused or busy or screen!="game":return
	pending=Rules.resolve(state,route)
	pending.route_cells=route.size()
	if not pending.valid:return
	busy=true;strike_button.disabled=true;board.start_animation(route);audio.tone(240,0.16)
func loot(source: String,options: Dictionary={}) -> Array:
	var key=run_id+":"+source
	var rng=RandomNumberGenerator.new();rng.seed=hash(key)
	var finds=Gear.roll_loot(prefs.gear,key,rng,options)
	run_loot+=finds.size()
	if not finds.is_empty():Save.log_event("loot_drop",{"id":run_id,"source":key,"channel":options,"finds":finds})
	return finds
func commit_move() -> void:
	if not busy:return
	var previous=int(state.kills)
	state=pending.state;route=[];busy=false;update_preview()
	Save.log_event("move",{"id":run_id,"wave":encounter,"turn":state.turn,"kills":pending.kills,"damage":pending.damage,"healing":pending.healing,"momentum":pending.momentum,"route_cells":pending.get("route_cells",0)})
	if training:
		if pending.kills>0:
			prefs.tutorial=true;persist();Save.log_event("tutorial_complete")
			modal("YOU HAVE YOUR FIRST ROUTE","You planned, previewed and struck.\n\nThe full expedition grows from 3 x 3 to a 6 x 6 boss arena. Read marks and try different landings.","training")
			modal_button("Resume saved expedition" if not prefs.run.is_empty() else "Begin expedition",760,func():
				if not prefs.run.is_empty():resume_run()
				else:settled=true;start_run(false),true)
			modal_button("Title",845,show_title)
		return
	var finds=[]
	for i in pending.defeated.size():
		finds.append_array(loot("kill:%d:%d" % [encounter,previous+i+1],{"type":"mob","kind":pending.defeated[i].kind}))
	if state.status=="won":
		finds.append_array(loot("clear:%d" % encounter,{"type":"clear","wave":encounter}))
		bank+=state.materials;total_kills+=state.kills
		if encounter==4:
			finds.append_array(loot("boss",{"type":"boss_reward"}))
			finish_run(true,"boss");return
		selected_boon="";show_camp();checkpoint("camp");return
	if state.status=="lost":finish_run(false,"health");return
	if not finds.is_empty():
		info_label.text="FOUND: "+str(finds[0])+(" +%d more" % (finds.size()-1) if finds.size()>1 else "")+"\nSaved with your turn. Fit gear at camp."
		board.loot_notice="LOOT +%d" % finds.size()
	checkpoint()
func show_camp() -> void:
	clear_screen();screen="camp";paused=true
	text("WAVE %d CLEARED" % (encounter+1),36,58,528,65,34)
	var next_wave=encounter+1
	var n=int(Content.SIDES[next_wave])
	text("NEXT: "+Content.ZONES[Content.zone(seed_value,next_wave)].name+"\n%d x %d %s" % [n,n,"BOSS ARENA" if next_wave==4 else "BATTLEFIELD"],36,145,528,85,25)
	text("Choose one expedition boon:",36,260,528,35,20)
	var options=Content.choices(seed_value,encounter)
	for i in options.size():
		var id: String=options[i]
		var boon=Content.BOONS[id]
		button(("✓ " if id==selected_boon else "")+boon.name+"\n"+boon.description,Rect2(36,310+i*104,528,88),func():selected_boon=id;checkpoint("camp");show_camp(),id==selected_boon)
	button("Duelist",Rect2(36,548,254,58),func():stance="Duelist";checkpoint("camp");show_camp(),stance=="Duelist")
	button("Reaver",Rect2(310,548,254,58),func():stance="Reaver";checkpoint("camp");show_camp(),stance=="Reaver")
	button("Backpack & field finds",Rect2(36,642,528,62),func():open_pack(true))
	text("%d supplies secured • all collected gear retained\nCamp restores 3 health and cleanses poison.\nNew gear and boons apply to the next wave." % bank,36,725,528,94,19,Color("b4cbb5"))
	var advance=button("ENTER NEXT WAVE",Rect2(36,845,528,66),next_wave_from_camp,true)
	advance.disabled=selected_boon.is_empty()
	button("Save & title",Rect2(36,928,528,48),func():checkpoint("camp");show_title())
func next_wave_from_camp() -> void:
	if screen!="camp" or selected_boon not in Content.choices(seed_value,encounter):return
	boons.append(selected_boon);selected_boon="";encounter+=1
	var bonus=Content.combine(Gear.bonuses(prefs.gear),boons)
	var maximum=Rules.MAX_HP+int(bonus.get("vitality",0))
	var health=clampi(maximum-(int(state.max_hp)-int(state.hp))+3,1,maximum)
	state=Rules.new_board(seed_value,encounter,stance,health,bonus,depth)
	Save.log_event("wave_start",{"id":run_id,"wave":encounter,"side":state.side,"zone":state.zone,"boons":boons})
	checkpoint();show_game()
func finish_run(won: bool,reason: String="health") -> void:
	if settled:return
	settled=true
	if not training:
		Gear.bank_field(prefs.gear);prefs.runs+=1
		if won:prefs.wins+=1;prefs.unlocked_depth=mini(5,maxi(prefs.unlocked_depth,depth+1))
		prefs.materials+=bank;prefs.best=maxi(prefs.best,total_kills+(int(state.kills) if state.status!="won" else 0));prefs.run={};persist()
	Save.log_event("run_end",{"id":run_id,"won":won,"reason":reason,"seconds":active_seconds,"camp_seconds":camp_seconds,"planning_seconds":planning_seconds,"animation_seconds":animation_seconds,"wave":encounter,"loot":run_loot,"depth":depth})
	last_finished=Time.get_ticks_msec();clear_screen();screen="results"
	text("THE HEARTROOT FALLS" if won else "ROOTS HOLD FAST",36,110,528,80,34)
	text("Expedition won" if won else "Your gear and collected loot are safe.",36,230,528,70,24)
	text("%d / 5 waves cleared\n%d supplies banked • %d loot finds\n%d active seconds • seed %d\n\n%s" % [5 if won else encounter,bank,run_loot,int(active_seconds),seed_value,"Depth %d unlocked. Try another build." % prefs.unlocked_depth if won else "Inspect the next attack marks and choose a safer landing."],36,340,528,235,22)
	button("RETRY EXPEDITION",Rect2(36,660,528,66),func():start_run(false),true)
	button("Replay same seed",Rect2(36,743,528,58),func():start_run(false,seed_value))
	button("Backpack & forge",Rect2(36,817,528,58),func():open_pack(false))
	button("Title",Rect2(36,891,528,58),show_title)
func modal(title: String,body: String,kind: String) -> void:
	if overlay:canvas.remove_child(overlay);overlay.queue_free()
	paused=true;modal_kind=kind
	if board:board.anim_paused=true
	overlay=Control.new();overlay.size=Vector2(600,1000);canvas.add_child(overlay)
	var shade=ColorRect.new();shade.color=Color(0.02,0.06,0.08,0.98);shade.size=Vector2(600,1000);overlay.add_child(shade)
	text(title,36,70,528,100,30,Color("dfebdb"),overlay)
	text(body,36,190,528,520,21,Color("d8e3d2"),overlay)
func modal_button(value: String,y: float,callback: Callable,accent: bool=false) -> void:
	button(value,Rect2(36,y,528,60),callback,accent,overlay)
func close_modal() -> void:
	if modal_kind=="training":settled=true;show_title();return
	if overlay:canvas.remove_child(overlay);overlay.queue_free();overlay=null
	modal_kind="";paused=screen=="camp"
	if board:board.anim_paused=false
func pause_game() -> void:
	if screen!="game" or paused:return
	checkpoint()
	modal("REST A MOMENT","The expedition is paused and checkpointed.\n\nClosing during an attack resumes before that uncommitted move. Gear and completed loot are preserved.","pause")
	modal_button("Resume",650,close_modal,true)
	modal_button("Settings",727,show_settings)
	modal_button("Save & title",804,func():checkpoint();show_title())
	modal_button("End expedition",881,func():finish_run(false,"abandon"))
func show_settings() -> void:
	modal("SETTINGS","Sound: "+("on" if prefs.sound else "off")+"\nMotion: "+("normal" if prefs.motion else "reduced")+"\nGraphics: "+prefs.quality+"\n\nLow: smaller render target, no shadows or MSAA.\nBalanced: 720-pixel target and soft shadows.\n\nNo screen shake. Offline saves. No accounts, ads or remote analytics.","settings")
	modal_button("Toggle sound",650,func():prefs.sound=not prefs.sound;audio.enabled=prefs.sound;persist();show_settings())
	modal_button("Toggle reduced motion",727,func():prefs.motion=not prefs.motion;if_board_motion();persist();show_settings())
	modal_button("Toggle graphics",804,func():prefs.quality="low" if prefs.quality=="balanced" else "balanced";if_board_quality();persist();show_settings())
	modal_button("Back",881,close_modal,true)
func if_board_motion() -> void:
	if board:board.reduced_motion=not prefs.motion
func if_board_quality() -> void:
	if board:
		board.quality=prefs.quality;board.viewport.size=Vector2i(480,480) if prefs.quality=="low" else Vector2i(720,720)
		board.viewport.msaa_3d=Viewport.MSAA_DISABLED if prefs.quality=="low" else Viewport.MSAA_2X
		for child in board.world.get_children():
			if child is DirectionalLight3D and child.light_energy>=0.9:child.shadow_enabled=prefs.quality!="low"
func show_help(begin_training: bool) -> void:
	modal("PLAN. PREVIEW. STRIKE.","Tap adjoining cells, then Strike. No diagonals or revisits.\n\nKills build momentum. A surviving enemy takes chip damage and stops the route.\n\nYou may cross two empty cells per route. Trail Boots adds more stride.\n\nCheck damage and healing before committing. Cover blocks arrows; springs heal and cleanse poison. Thorns hurt on landing.\n\nAmber marks: arrows. Purple crosses: magic. Coral crosses: boss. Enemy codex explains every behavior.","help")
	modal_button("Practice a strike" if begin_training else "Back",850,func():
		if begin_training:training=true;start_run(true)
		else:close_modal(),true)
func modal_scroll(value: String,rect: Rect2) -> void:
	var body=overlay.get_child(2);overlay.remove_child(body);body.queue_free()
	var scroll=ScrollContainer.new();scroll.position=rect.position;scroll.size=rect.size;overlay.add_child(scroll)
	var label=Label.new();label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.custom_minimum_size=Vector2(rect.size.x-28,0);label.add_theme_font_size_override("font_size",19);label.text=value;scroll.add_child(label)
func show_codex() -> void:
	var lines=["Common Sigils: 2%% from any enemy. Exclusive Sigils roll separately: 3%% from their matching regular enemy; 15%% from the Warden. Warden Sigil guaranteed by the 10th kill without one.\nWarden dry streak: %d / 9.\n" % int(prefs.gear.boss_pity.get("B",0))]
	for kind in Content.ENEMIES:
		lines.append(Content.ENEMIES[kind].name+": "+Content.ENEMIES[kind].help+"\n"+Gear.sigil_help(Gear.EXCLUSIVES[kind]))
	modal("HUNTING GUIDE","","codex")
	modal_scroll("\n\n".join(lines),Rect2(36,190,528,600))
	modal_button("Back",850,close_modal,true)
func open_pack(at_camp: bool) -> void:
	if busy or is_instance_valid(pack_ui):return
	if not at_camp and not prefs.run.is_empty():
		modal("EXPEDITION LOADOUT IS CHECKPOINTED","Resume your expedition to manage its backpack at camp, or end it before preparing another loadout.","pack_locked")
		modal_button("Back",835,close_modal);return
	paused=true
	if board:board.anim_paused=true
	pack_ui=PackUI.new();pack_ui.profile=prefs.gear;pack_ui.camp=at_camp
	pack_ui.changed.connect(func(event,data):
		if at_camp:checkpoint("camp")
		else:persist()
		Save.log_event(event,data))
	pack_ui.closed.connect(func():
		canvas.remove_child(pack_ui);pack_ui.queue_free();pack_ui=null
		if at_camp:checkpoint("camp");show_camp()
		else:persist();show_title())
	canvas.add_child(pack_ui)
func back_action() -> void:
	if is_instance_valid(pack_ui):
		if pack_ui.dialog:pack_ui.render()
		else:pack_ui.closed.emit()
	elif overlay:close_modal()
	elif screen=="game":pause_game()
	elif screen=="camp":checkpoint("camp");show_title()
	elif screen=="results":show_title()
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):back_action();get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") and not overlay and not is_instance_valid(pack_ui):execute_move()
func _notification(what: int) -> void:
	if not is_instance_valid(canvas):return
	if what in [NOTIFICATION_APPLICATION_FOCUS_IN,NOTIFICATION_APPLICATION_RESUMED]:app_active=true
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:
		app_active=false
		if screen=="game" and not paused:pause_game()
		elif screen=="camp":checkpoint("camp")
	elif what==NOTIFICATION_WM_GO_BACK_REQUEST:back_action()
	elif what==NOTIFICATION_WM_CLOSE_REQUEST:
		if not settled and not training:checkpoint("camp" if screen=="camp" else "game")
		get_tree().quit()

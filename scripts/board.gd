class_name ThornBoard
extends Control
signal cell_selected(index: int)
signal animation_done
signal health_changed(value: int)
signal combat_event(kind: String)
const Art = preload("res://scripts/art.gd")
const Actor = preload("res://scripts/actor.gd")
const Content=preload("res://scripts/content.gd")
const Rules = preload("res://scripts/rules.gd")
const CELL = 88.0
var state: Dictionary = {}:
	set(value):
		if state != value:
			state=value
			rebuild_requested=true
var route: Array = []:
	set(value):
		route=value.duplicate()
		markers_requested=true
var preview: Dictionary = {}:
	set(value):
		preview=value
		markers_requested=true
var animation: Array = []
var elapsed = 0.0
var anim_paused = false
var reduced_motion = false
var viewport: SubViewport
var camera: Camera3D
var world: Node3D
var actor_root: Node3D
var marker_root: Node3D
var floor_tiles: Array = []
var actors: Dictionary = {}
var hero: ThornActor
var rebuild_requested = true
var markers_requested = true
var timeline: Array = []
var event_index = 0
var event_time = 0.0
var event_started = false
var impact_done = false
var clock = 0.0
var effects: Array = []
var shown_health = 14
var loot_notice=""
var quality="balanced"
var texture: TextureRect

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	viewport=SubViewport.new()
	viewport.size=Vector2i(480,480) if quality=="low" else Vector2i(720,720)
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d=Viewport.MSAA_DISABLED if quality=="low" else Viewport.MSAA_2X
	add_child(viewport)
	texture=TextureRect.new()
	texture.texture=viewport.get_texture()
	texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode=TextureRect.STRETCH_SCALE
	texture.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(texture)
	world=Node3D.new()
	viewport.add_child(world)
	build_environment()
	actor_root=Node3D.new()
	world.add_child(actor_root)
	marker_root=Node3D.new()
	world.add_child(marker_root)
	rebuild()
func point(i: int) -> Vector3:
	var n=Rules.side(state)
	return Vector3(i%n-(n-1)*0.5,0,i/n-(n-1)*0.5)
func center(i: int) -> Vector2:
	if not camera: return Vector2.ZERO
	return camera.unproject_position(point(i)+Vector3(0,0.15,0))/Vector2(viewport.size)*size
func pick_cell(at: Vector2) -> int:
	if not camera or not Rect2(Vector2.ZERO,size).has_point(at): return -1
	var pixel=at/size*Vector2(viewport.size)
	var hit=Plane(Vector3.UP,0).intersects_ray(camera.project_ray_origin(pixel),camera.project_ray_normal(pixel))
	if hit==null: return -1
	var n=Rules.side(state)
	var x=int(floor(hit.x+n*0.5))
	var y=int(floor(hit.z+n*0.5))
	return y*n+x if x>=0 and x<n and y>=0 and y<n else -1
func _gui_input(event: InputEvent) -> void:
	if not animation.is_empty() or anim_paused: return
	var at=Vector2.ZERO
	var activate=false
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		at=event.position
		activate=true
	elif event is InputEventScreenTouch and event.pressed:
		at=event.position
		activate=true
	if activate:
		var i=pick_cell(at)
		if i>=0: cell_selected.emit(i)
		accept_event()
func zone_color(i: int) -> String:
	var z=Content.ZONES[state.zone]
	var n=Rules.side(state)
	return z.floor if (i%n+i/n)%2==0 else z.alternate
func floor_material(i: int) -> StandardMaterial3D:
	var material=Art.mat(zone_color(i))
	var path="res://art_overrides/floors/"+str(state.zone)+".png"
	if ResourceLoader.exists(path):
		material=material.duplicate()
		material.albedo_texture=load(path)
	return material
func prop(parent: Node3D, at: Vector3, type: String, height: float) -> void:
	if type=="pine":Art.pine(parent,at,height)
	elif type=="basalt":
		Art.cone(parent,0.25,height,at+Vector3(0,height*0.5,0),"484952",0.16)
		Art.orb(parent,0.08,at+Vector3(0,height+0.05,0),"d78a55")
	elif type=="crystal":
		var crystal=Art.cone(parent,0.22,height,at+Vector3(0,height*0.5,0),"97ccd4")
		crystal.rotation.z=0.16
		Art.cone(parent,0.13,height*0.6,at+Vector3(0.22,height*0.3,0.12),"b9dee4")
	elif type=="pillar":
		Art.box(parent,Vector3(0.32,height,0.32),at+Vector3(0,height*0.5,0),"9392a5")
		Art.box(parent,Vector3(0.47,0.13,0.47),at+Vector3(0,height,0),"bbb3b9")
	else:
		Art.cone(parent,0.15,height,at+Vector3(0,height*0.5,0),"665063",0.075)
		for x in [-1,1]:Art.rod(parent,at+Vector3(0,height*0.6,0),at+Vector3(x*0.35,height,0.12),0.055,"917265")
		Art.orb(parent,0.11,at+Vector3(0,height+0.05,0),"d8a0c6")
func build_environment() -> void:
	var n=Rules.side(state)
	var zone=Content.ZONES[state.zone]
	var environment=WorldEnvironment.new()
	var env=Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color(zone.sky)
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("aac3c1")
	env.ambient_light_energy=0.34
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	environment.environment=env
	world.add_child(environment)
	var sun=DirectionalLight3D.new()
	sun.light_color=Color("ffe3b1")
	sun.light_energy=1.0
	sun.rotation_degrees=Vector3(-53,-30,0)
	sun.shadow_enabled=quality!="low"
	sun.directional_shadow_max_distance=25
	world.add_child(sun)
	var rim=DirectionalLight3D.new()
	rim.light_color=Color(zone.accent)
	rim.light_energy=0.32
	rim.rotation_degrees=Vector3(-28,155,0)
	world.add_child(rim)
	camera=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=n+1.1
	camera.position=Vector3(0,12,5.4)
	world.add_child(camera)
	camera.look_at(Vector3(0,0.10,0))
	camera.current=true
	Art.box(world,Vector3(n+0.65,0.65,n+0.65),Vector3(0,-0.46,0),zone.rim)
	Art.box(world,Vector3(n+0.60,0.18,n+0.60),Vector3(0,-0.08,0),zone.floor)
	for i in n*n:
		var p=point(i)
		var tile=Art.box(world,Vector3(0.94,0.14,0.94),p+Vector3(0,-0.045,0),zone.floor)
		tile.material_override=floor_material(i)
		floor_tiles.append(tile)
		if state.zone=="briar":
			for k in 2:Art.cone(world,0.04,0.12,p+Vector3(-0.34+k*0.66,0.10,0.33),"81935b")
	var half=n*0.5
	var custom="res://art_overrides/zones/"+str(state.zone)+".tscn"
	if ResourceLoader.exists(custom):
		var scenery=load(custom).instantiate()
		world.add_child(scenery)
	else:
		for x in [-1,1]:
			for z in [-0.75,0.70]:prop(world,Vector3(x*(half+0.35),0,z*half),zone.prop,0.65)
			prop(world,Vector3(x*(half-0.25),0,-half-0.30),zone.prop,0.85)
		for x in [-1,1]:
			Art.cone(world,0.13,0.48,Vector3(x*(half+0.15),0.24,half+0.20),zone.rim,0.11)
			Art.orb(world,0.085,Vector3(x*(half+0.15),0.53,half+0.20),zone.accent)
func empty_node(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
func rebuild() -> void:
	if not actor_root or state.is_empty(): return
	empty_node(actor_root)
	actors.clear()
	for effect in effects:
		if is_instance_valid(effect.node): effect.node.queue_free()
	effects.clear()
	for i in state.tiles.size():
		var tile: Dictionary=state.tiles[i]
		if Rules.enemy(tile):
			var actor=Actor.new()
			actor_root.add_child(actor)
			actor.position=point(i)
			actor.build(tile.kind,tile.hp)
			actor.rotation.y=PI if tile.kind!="a" else PI-0.25
			if actor.hp_label and tile.kind=="b":actor.hp_label.text=str(tile.hp)+("\nCHARGE" if int(state.turn)%2==0 else "\nREST")
			if actor.hp_label and tile.kind=="B":actor.hp_label.text=str(tile.hp)+"\nPHASE %d" % int(tile.phase)
			actors[i]=actor
		elif tile.kind=="c":
			prop(actor_root,point(i)+Vector3(0.18,0,0.12),Content.ZONES[state.zone].prop,0.48)
			Art.label(actor_root,"COVER",point(i)+Vector3(0,0.10,-0.30),"a6d7c0",22)
		elif tile.kind=="t":
			for x in [-0.18,0.18]:
				var thorn=Art.cone(actor_root,0.08,0.25,point(i)+Vector3(x,0.15,0),"c57d6c")
				thorn.rotation.z=x*1.5
			Art.label(actor_root,"THORNS",point(i)+Vector3(0,0.15,0.30),"f1b492",20)
		elif tile.kind=="f":
			Art.cone(actor_root,0.33,0.035,point(i)+Vector3(0,0.055,0),"75b7c3",0.33)
			Art.ring(actor_root,point(i)+Vector3(0,0.08,0),0.32,"a4d6cc",0.018)
			Art.label(actor_root,"SPRING",point(i)+Vector3(0,0.15,0.30),"bce8da",20)
	hero=Actor.new()
	actor_root.add_child(hero)
	hero.position=point(state.player)
	hero.build("hero")
	hero.rotation.y=PI-0.25
	shown_health=state.hp
	rebuild_requested=false
	markers_requested=true
func rebuild_markers() -> void:
	if not marker_root or state.is_empty(): return
	empty_node(marker_root)
	for i in state.tiles.size():
		floor_tiles[i].material_override=floor_material(i)
	var drawn=[]
	for mark in Rules.telegraphs(state):
		if mark.type not in ["a","w","B"]:continue
		var color="e9a548" if mark.type=="a" else ("d2a4ef" if mark.type=="w" else "e59b77")
		for cell in mark.cells:
			var key=str(cell)+str(mark.type)
			if key in drawn:continue
			drawn.append(key)
			var p=point(int(cell))+Vector3(0,0.08,-0.32)
			if mark.type=="a":Art.rod(marker_root,p+Vector3(-0.35,0,0),p+Vector3(0.35,0,0),0.022,color,0.15)
			else:
				Art.rod(marker_root,p+Vector3(-0.10,0,-0.10),p+Vector3(0.10,0,0.10),0.025,color,0.35)
				Art.rod(marker_root,p+Vector3(-0.10,0,0.10),p+Vector3(0.10,0,-0.10),0.025,color,0.35)
	var points=[state.player]+route
	for n in range(1,points.size()):
		var p=point(points[n])+Vector3(0,0.09,0)
		Art.rod(marker_root,point(points[n-1])+Vector3(0,0.09,0),p,0.035,"8de5c1",0.8)
		Art.label(marker_root,str(n),p+Vector3(0.31,0.34,0.17),"d9f7d8",27)
		floor_tiles[points[n]].material_override=Art.mat("608c68")
	if preview.get("valid",false):
		Art.ring(marker_root,point(preview.state.player)+Vector3(0,0.075,0),0.43,"f29a75" if preview.damage>0 else "9ae4bd")
		for threat in preview.threats:
			if threat.source>=0:Art.label(marker_root,"!",point(threat.source)+Vector3(-0.29,0.85,0),"ffb483",42)
	markers_requested=false
func start_animation(path: Array) -> void:
	if rebuild_requested: rebuild()
	animation=[state.player]+path.duplicate()
	timeline=[]
	var cursor=int(state.player)
	var result=Rules.resolve(state,path)
	for i in path:
		var tile: Dictionary=state.tiles[i]
		var is_foe=Rules.enemy(tile)
		var attack={"power":0,"lethal":false}
		for data in result.attacks:
			if data.to==i and not data.cleave: attack=data; break
		timeline.append({"type":"strike" if is_foe else "walk","from":cursor,"to":int(i),"power":int(attack.power),"lethal":attack.lethal,"duration":0.43 if is_foe else 0.23})
		if not is_foe or attack.lethal: cursor=int(i)
	for attack in result.attacks:
		if attack.cleave:
			timeline.append({"type":"cleave","from":cursor,"to":int(attack.to),"power":int(attack.power),"lethal":attack.lethal,"duration":0.43})
	var guard=int(result.guard_used)
	for threat in result.threats:
		var blocked=int(threat.get("blocked",mini(guard,threat.damage)))
		guard-=blocked
		timeline.append({"type":"retaliate","from":int(threat.source),"to":cursor,"power":int(threat.damage)-blocked,"blocked":blocked,"ranged":threat.type in ["a","w","B"],"element":threat.type,"duration":0.62})
	if result.healing>0: timeline.append({"type":"heal","power":result.healing,"duration":0.40})
	timeline.append({"type":"settle","duration":0.65 if result.state.hp<=0 else 0.28})
	event_index=0
	event_time=0.0
	elapsed=0.0
	event_started=false
	impact_done=false
	empty_node(marker_root)
func spawn_text(value: String, at: Vector3, color: String) -> void:
	var node=Art.label(world,value,at,color,52)
	effects.append({"node":node,"age":0.0,"life":0.85,"origin":at,"velocity":Vector3(0,0.8,0),"kind":"text"})
func burst(at: Vector3, color: String) -> void:
	for i in (5 if reduced_motion else 10):
		var angle=TAU*i/10.0
		var node=Art.orb(world,0.045,at,color)
		effects.append({"node":node,"age":0.0,"life":0.40,"origin":at,"velocity":Vector3(cos(angle),0.5+float(i%3)*0.4,sin(angle))*1.4,"kind":"spark"})
func slash(at: Vector3) -> void:
	var root=Node3D.new()
	world.add_child(root)
	root.position=at
	for i in 9:
		var a=-1.2+i*0.30
		var b=a+0.30
		Art.rod(root,Vector3(cos(a)*0.47,sin(a)*0.36,0),Vector3(cos(b)*0.47,sin(b)*0.36,0),0.025,"ffdc9d",1)
	effects.append({"node":root,"age":0.0,"life":0.23,"origin":at,"velocity":Vector3.ZERO,"kind":"slash"})
func update_effects(delta: float) -> void:
	for i in range(effects.size()-1,-1,-1):
		var e: Dictionary=effects[i]
		if not is_instance_valid(e.node):
			effects.remove_at(i)
			continue
		e.age+=delta
		if e.age>=e.life:
			e.node.queue_free()
			effects.remove_at(i)
			continue
		e.node.position=e.origin+e.velocity*e.age
		if e.kind!="text": e.node.scale=Vector3.ONE*maxf(0.01,1-e.age/e.life)
		else: e.node.modulate.a=clampf((e.life-e.age)*3,0,1)
func apply_impact(e: Dictionary) -> void:
	impact_done=true
	if e.type in ["strike","cleave"]:
		var target: ThornActor=actors.get(e.to)
		if not target: return
		target.flash(true)
		burst(point(e.to)+Vector3(0,0.4,0),"efce80")
		slash(point(e.to)+Vector3(0,0.55,0))
		spawn_text("-%d" % e.power,point(e.to)+Vector3(0,0.95,0),"fff0b8")
		combat_event.emit("strike")
		if target.hp_label and not e.lethal:
			var hp=int(state.tiles[e.to].hp)
			for prior in timeline:
				if prior.type in ["strike","cleave"] and prior.to==e.to:hp-=prior.power
				if prior==e:break
			target.hp_label.text=str(maxi(0,hp))
	elif e.type=="retaliate":
		if e.power>0:
			var damage_color="9acb8d" if e.get("element","") in ["poison","v"] else ("c4a0ed" if e.get("element","")=="w" else "ff8374")
			hero.flash(true,damage_color)
			shown_health=maxi(0,shown_health-e.power)
			health_changed.emit(shown_health)
			spawn_text("-%d HP" % e.power,hero.position+Vector3(0,1.15,0),damage_color)
			burst(hero.position+Vector3(0,0.5,0),"f18b79")
			combat_event.emit("hurt")
		if e.blocked>0:
			spawn_text("GUARD",hero.position+Vector3(0,1.45,0),"a9ebee")
			var shield=Art.ring(world,hero.position+Vector3(0,0.12,0),0.38,"a9ebee")
			effects.append({"node":shield,"age":0.0,"life":0.40,"origin":shield.position,"velocity":Vector3.ZERO,"kind":"guard"})
			combat_event.emit("guard")
	elif e.type=="heal":
		shown_health+=e.power
		health_changed.emit(shown_health)
		spawn_text("+%d HP" % e.power,hero.position+Vector3(0,1.2,0),"9fe7ad")
		burst(hero.position+Vector3(0,0.4,0),"9fe7ad")
func begin_event(e: Dictionary) -> void:
	impact_done=false
	event_started=true
	if e.type in ["strike","walk","cleave"]:
		hero.look_at(point(e.to)+Vector3(0,0.001,0))
	elif e.type=="retaliate":
		var target: ThornActor=actors.get(e.from)
		if target:
			target.look_at(hero.position+Vector3(0,0.001,0))
			combat_event.emit("bow" if e.ranged else "swing")
func animate_event(e: Dictionary, t: float) -> void:
	if e.type in ["strike","walk","cleave"]:
		var old_position=hero.position
		var from=point(e.from)
		var to=point(e.to)
		var stops=e.type=="cleave" or (e.type=="strike" and not e.lethal)
		if e.type=="walk":
			hero.position=from.lerp(to,smoothstep(0,1,t))
			hero.pose("run",t,clock)
		else:
			var target=from.lerp(to,0.48) if stops else to
			hero.position=from.lerp(target,smoothstep(0,0.42,t))
			if stops and t>0.72: hero.position=target.lerp(from,smoothstep(0.72,1,t))
			hero.pose("run" if t<0.40 else "attack",t/0.40 if t<0.40 else (t-0.40)/0.60,clock)
			if t>=0.55 and not impact_done: apply_impact(e)
			var victim: ThornActor=actors.get(e.to)
			if victim and impact_done:
				if e.lethal: victim.die(clampf((t-0.55)/0.42,0,1))
				else:
					victim.pose("hit",(t-0.55)/0.45,clock)
					victim.flash(t<0.78)
		if not reduced_motion and hero.position.distance_to(old_position)>0.06:
			var trail=Art.rod(world,old_position+Vector3(0,0.3,0),hero.position+Vector3(0,0.3,0),0.035,"91d8cd",0.35)
			effects.append({"node":trail,"age":0.0,"life":0.16,"origin":trail.position,"velocity":Vector3.ZERO,"kind":"trail"})
	elif e.type=="retaliate":
		var attacker: ThornActor=actors.get(e.from)
		if attacker:
			var from=point(e.from)
			if e.ranged:
				attacker.pose("attack",t,clock)
				# The visible arrow travels from the bow to the ranger before impact.
				if t>=0.22 and t<0.65:
					var a=from+Vector3(0,0.55,0)
					var b=hero.position+Vector3(0,0.50,0)
					var tip=a.lerp(b,(t-0.22)/0.43)
					var tail=tip-(b-a).normalized()*0.30
					var arrow=Art.rod(world,tail,tip,0.025,"f9d68e",0.6) if e.element=="a" else Art.orb(world,0.09,tip,"c4a0ed" if e.element=="w" else "e5a87e")
					effects.append({"node":arrow,"age":0.0,"life":0.045,"origin":arrow.position,"velocity":Vector3.ZERO,"kind":"arrow"})
			else:
				attacker.position=from.lerp(hero.position,0.45*sin(t*PI))
				attacker.pose("attack",t,clock)
		if t>=0.65 and not impact_done: apply_impact(e)
		if impact_done:
			hero.pose("hit" if e.power>0 else "guard",(t-0.65)/0.35,clock)
			hero.flash(e.power>0 and t<0.85,"ff8374")
	elif e.type=="heal" and t>=0.4 and not impact_done:
		apply_impact(e)
	elif e.type=="settle" and shown_health<=0:
		hero.die(t*0.95)
func end_event(e: Dictionary) -> void:
	if e.type in ["strike","cleave","heal"]:
		if not impact_done: apply_impact(e)
		var victim: ThornActor=actors.get(e.get("to",-1))
		if victim:
			victim.flash(false)
			if e.lethal: victim.visible=false
	elif e.type=="retaliate":
		if not impact_done: apply_impact(e)
		var attacker: ThornActor=actors.get(e.from)
		if attacker:
			attacker.position=point(e.from)
			attacker.pose("idle",0,clock)
	hero.flash(false)
func _process(delta: float) -> void:
	if anim_paused: return
	clock+=delta
	if rebuild_requested and animation.is_empty(): rebuild()
	if markers_requested and animation.is_empty(): rebuild_markers()
	if not loot_notice.is_empty() and animation.is_empty():
		spawn_text(loot_notice,hero.position+Vector3(0,1.4,0),"dab9f3")
		loot_notice=""
	update_effects(delta)
	for actor in actors.values():
		if not actor.dead: actor.pose("idle",0,clock)
	if animation.is_empty():
		if hero: hero.pose("idle",0,clock)
		return
	elapsed+=delta
	var budget=delta*(1.25 if reduced_motion else 1.0)
	while budget>0 and event_index<timeline.size():
		var e: Dictionary=timeline[event_index]
		if not event_started: begin_event(e)
		var step=minf(budget,e.duration-event_time)
		event_time+=step
		budget-=step
		animate_event(e,clampf(event_time/e.duration,0,1))
		if event_time>=e.duration-0.00001:
			end_event(e)
			event_index+=1
			event_time=0.0
			event_started=false
	if event_index>=timeline.size():
		hero.pose("idle",0,clock)
		animation.clear()
		animation_done.emit()

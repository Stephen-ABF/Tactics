class_name ThornActor
extends Node3D
const Art = preload("res://scripts/art.gd")
var kind = "hero"
var rig: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var cape: MeshInstance3D
var pieces: Array = []
var originals: Array = []
var hp_label: Label3D
var dead = false
var sprites: Array=[]
var sprite_colors: Array=[]
func build(actor_kind: String, health: int = 1) -> void:
	kind = actor_kind
	rig=Node3D.new()
	add_child(rig)
	var override_path="res://art_overrides/actors/"+kind+".tscn"
	if not ResourceLoader.exists(override_path):override_path="res://art_overrides/actors/"+kind+".glb"
	if not ResourceLoader.exists(override_path) and ResourceLoader.exists("res://art_overrides/actors/"+kind+".png"):
		override_path="res://art_overrides/actors/"+kind+".png"
	if override_path.ends_with(".png") and ResourceLoader.exists(override_path):
		var sprite=Sprite3D.new();sprite.texture=load(override_path)
		var height=1.55 if kind=="B" else 0.95
		sprite.pixel_size=height/maxf(1,sprite.texture.get_height())
		sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		sprite.position.y=height*0.5;rig.add_child(sprite)
	elif ResourceLoader.exists(override_path):
		var resource=load(override_path)
		if resource is PackedScene:
			var model=resource.instantiate()
			rig.add_child(model)
			left_arm=model.find_child("LeftArm",true,false)
			right_arm=model.find_child("RightArm",true,false)
			left_leg=model.find_child("LeftLeg",true,false)
			right_leg=model.find_child("RightLeg",true,false)
		else: build_biped()
	elif kind=="h":build_shell()
	elif kind=="v":build_viper()
	elif kind=="B":build_boss()
	else:build_biped()
	gather_meshes(rig)
	if health>1: hp_label=Art.label(self,str(health),Vector3(0,1.70 if kind=="B" else 0.90,0),"ecd7b2",32)
func pivot(at: Vector3) -> Node3D:
	var node=Node3D.new()
	node.position=at
	rig.add_child(node)
	return node
func build_biped() -> void:
	var hero=kind=="hero"
	var skin="e6bb89" if hero else ("b5a5cf" if kind=="w" else ("ba8864" if kind=="b" else "9abb65"))
	var cloth="397b75" if hero else ("713e57" if kind=="a" else ("524477" if kind=="w" else ("6c5148" if kind=="b" else "797b49")))
	left_leg=pivot(Vector3(-0.105,0.29,0))
	right_leg=pivot(Vector3(0.105,0.29,0))
	for leg in [left_leg,right_leg]:
		Art.box(leg,Vector3(0.13,0.23,0.14),Vector3(0,-0.10,0),"3a3434")
		Art.box(leg,Vector3(0.15,0.11,0.23),Vector3(0,-0.23,-0.04),"594433")
	Art.cone(rig,0.21,0.35,Vector3(0,0.42,0),cloth,0.17)
	Art.box(rig,Vector3(0.34,0.06,0.24),Vector3(0,0.33,0),"5b3c2e")
	Art.box(rig,Vector3(0.07,0.07,0.03),Vector3(0,0.33,-0.14),"d5ac58")
	Art.orb(rig,0.19,Vector3(0,0.72,0),cloth,Vector3(1.13,1.13,1.1))
	Art.orb(rig,0.14,Vector3(0,0.72,-0.10),skin,Vector3(0.95,1,0.57))
	for x in [-0.052,0.052]: Art.orb(rig,0.022,Vector3(x,0.75,-0.179),"172e30")
	Art.cone(rig,0.23,0.16,Vector3(0,0.88,0.025),cloth,0.045)
	left_arm=pivot(Vector3(-0.23,0.56,0))
	right_arm=pivot(Vector3(0.23,0.56,0))
	for arm in [left_arm,right_arm]:
		Art.box(arm,Vector3(0.13,0.22,0.15),Vector3(0,-0.08,0),cloth)
		Art.orb(arm,0.075,Vector3(0,-0.22,-0.015),skin)
	if hero:
		cape=Art.box(rig,Vector3(0.36,0.43,0.045),Vector3(0,0.42,0.155),"203d56")
		cape.rotation.x=-0.18
		Art.box(rig,Vector3(0.40,0.07,0.12),Vector3(0,0.59,-0.13),"d8af62")
		Art.orb(left_arm,0.14,Vector3(-0.04,-0.12,-0.02),"627f88",Vector3(0.45,1,1))
		Art.box(right_arm,Vector3(0.065,0.49,0.065),Vector3(0,-0.04,-0.19),"dce9e6")
		Art.box(right_arm,Vector3(0.23,0.045,0.09),Vector3(0,-0.22,-0.19),"d3a956")
		Art.cone(right_arm,0.05,0.17,Vector3(0,0.285,-0.19),"dce9e6")
		Art.orb(right_arm,0.035,Vector3(0,-0.30,-0.19),"85d6c6")
	elif kind=="a":
		var points=[Vector3(0,-0.40,-0.14),Vector3(0,-0.30,-0.32),Vector3(0,-0.12,-0.40),Vector3(0,0.09,-0.32),Vector3(0,0.18,-0.14)]
		for i in range(1,points.size()): Art.rod(left_arm,points[i-1],points[i],0.025,"cea36a")
		Art.rod(left_arm,points[0],points[-1],0.009,"e1dbc0")
	elif kind=="w":
		Art.rod(left_arm,Vector3(0,-0.5,-0.1),Vector3(0,0.3,-0.1),0.035,"8c786f")
		Art.orb(left_arm,0.11,Vector3(0,0.35,-0.1),"ad94e7")
	elif kind=="b":
		rig.scale=Vector3(1.22,1.12,1.1)
		Art.box(rig,Vector3(0.45,0.14,0.20),Vector3(0,0.56,0),"8d8a82")
		Art.box(right_arm,Vector3(0.20,0.33,0.16),Vector3(0,0.1,-0.14),"63675d")
	else:
		for x in [-1,1]:
			var ear=Art.cone(rig,0.09,0.23,Vector3(x*0.23,0.76,0),skin)
			ear.rotation.z=x*-1.0
		Art.box(right_arm,Vector3(0.04,0.25,0.055),Vector3(0,0.02,-0.16),"b9c6be")
func build_shell() -> void:
	Art.orb(rig,0.36,Vector3(0,0.29,0),"6c6656",Vector3(1,0.78,1.13))
	for x in [-1,1]:
		for z in [-0.2,0.03,0.23]:
			Art.rod(rig,Vector3(x*0.23,0.19,z),Vector3(x*0.40,0.07,z+0.12),0.035,"3d4941")
		Art.cone(rig,0.11,0.29,Vector3(x*0.17,0.53,0),"c4b49a",0.025)
	Art.box(rig,Vector3(0.035,0.14,0.54),Vector3(0,0.49,0),"c4b49a")
	for x in [-0.11,0.11]: Art.orb(rig,0.035,Vector3(x,0.26,-0.34),"edb35d")
func gather_meshes(node: Node) -> void:
	if node is Sprite3D:
		sprites.append(node);sprite_colors.append(node.modulate)
	if node is MeshInstance3D:
		pieces.append(node)
		originals.append(node.material_override)
	for child in node.get_children(): gather_meshes(child)
func flash(enabled: bool, color: String = "ffdba0") -> void:
	for i in pieces.size(): pieces[i].material_override=Art.mat(color,0.5) if enabled else originals[i]
	for i in sprites.size():sprites[i].modulate=Color(color) if enabled else sprite_colors[i]
func pose(mode: String, phase: float, clock: float) -> void:
	if dead: return
	var wave=sin(phase*PI)
	rig.position=Vector3.ZERO
	rig.rotation=Vector3.ZERO
	for limb in [left_arm,right_arm,left_leg,right_leg]:
		if limb:limb.rotation=Vector3.ZERO
	if mode=="run":
		rig.position.y=absf(sin(phase*TAU))*0.09
		rig.rotation.x=-0.18
		if left_arm and right_arm and left_leg and right_leg:
			left_leg.rotation.x=sin(phase*TAU)*0.85
			right_leg.rotation.x=-sin(phase*TAU)*0.85
			left_arm.rotation.x=-sin(phase*TAU)*0.5
			right_arm.rotation.x=0.6
	elif mode=="attack":
		rig.rotation.y=sin(phase*TAU)*0.45
		if right_arm and left_arm:
			right_arm.rotation.x=-1.8+phase*3.3
			right_arm.rotation.z=-0.7+phase*1.6
			left_arm.rotation.x=-wave*0.65
	elif mode=="guard":
		if left_arm:
			left_arm.rotation.x=-1.2*wave
			left_arm.rotation.z=-0.5*wave
	elif mode=="hit":
		rig.position.z=wave*0.14
		rig.rotation.z=sin(phase*PI*3)*0.12
	else:
		rig.position.y=sin(clock*2.8)*0.016
		if left_arm: left_arm.rotation.z=sin(clock*2.3)*0.04
	if cape: cape.rotation.x=-0.18-(wave*0.5 if mode=="run" else sin(clock*2)*0.04)
func die(phase: float) -> void:
	dead=true
	if hp_label: hp_label.visible=false
	rig.rotation.z=phase*1.3
	rig.position.y=-phase*0.22
	rig.scale=Vector3.ONE*maxf(0.001,1-phase)

func build_viper() -> void:
	for i in 5:
		Art.orb(rig,0.13,Vector3(sin(i*0.9)*0.15,0.11+i*0.025,0.30-i*0.10),"65886a",Vector3(1,0.8,1.15))
	Art.orb(rig,0.20,Vector3(0.02,0.30,-0.23),"8fa86c",Vector3(1,0.72,1.2))
	for x in [-0.09,0.09]:Art.orb(rig,0.026,Vector3(x,0.35,-0.39),"efd077")
	Art.rod(rig,Vector3(0,0.24,-0.4),Vector3(0,0.22,-0.57),0.015,"c3757c")
func build_boss() -> void:
	Art.cone(rig,0.37,0.85,Vector3(0,0.48,0),"665445",0.25)
	Art.orb(rig,0.37,Vector3(0,0.92,0),"687c56",Vector3(1.2,1.15,0.9))
	for x in [-1,1]:
		Art.rod(rig,Vector3(x*0.20,0.35,0),Vector3(x*0.43,0.04,0.26),0.11,"55483d")
		Art.rod(rig,Vector3(x*0.24,1.08,0),Vector3(x*0.55,1.47,0.12),0.06,"a89774")
		Art.rod(rig,Vector3(x*0.40,1.28,0.08),Vector3(x*0.68,1.29,0.04),0.04,"a89774")
		Art.orb(rig,0.052,Vector3(x*0.12,0.96,-0.32),"efb372")
	left_arm=pivot(Vector3(-0.40,0.81,0))
	right_arm=pivot(Vector3(0.40,0.81,0))
	for arm in [left_arm,right_arm]:
		Art.cone(arm,0.12,0.55,Vector3(0,-0.18,0),"6f644e",0.19)
		Art.orb(arm,0.16,Vector3(0,-0.44,-0.07),"74835a")
	Art.orb(rig,0.13,Vector3(0,0.62,-0.30),"b484d7")

extends Control
signal cell_clicked(x: int,y: int)
const Gear=preload("res://scripts/gear.gd")
var profile: Dictionary
var selected=""
const CELL=79.0
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		var x=int(event.position.x/CELL)
		var y=int(event.position.y/CELL)
		if x>=0 and y>=0 and x<6 and y<5: cell_clicked.emit(x,y)
		accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		var x=int(event.position.x/CELL)
		var y=int(event.position.y/CELL)
		if x>=0 and y>=0 and x<6 and y<5: cell_clicked.emit(x,y)
		accept_event()
func _draw() -> void:
	if profile.is_empty(): return
	var font=ThemeDB.fallback_font
	for y in 5:
		for x in 6:
			draw_rect(Rect2(x*CELL+2,y*CELL+2,CELL-4,CELL-4),Color("233b39"))
	for item in profile.items:
		if item.location!="bag": continue
		var color=Color(Gear.COLORS[Gear.quality(item)])
		for cell in Gear.cells(item):
			var p=Vector2(cell+Vector2i(item.x,item.y))*CELL
			draw_rect(Rect2(p+Vector2(3,3),Vector2(CELL-6,CELL-6)),color.darkened(0.72))
			draw_rect(Rect2(p+Vector2(3,3),Vector2(CELL-6,CELL-6)),color,false,3 if item.id==selected else 1)
		var p=Vector2(item.x,item.y)*CELL+Vector2(39,36)
		match item.base:
			"blade":
				draw_line(p+Vector2(-14,17),p+Vector2(16,-18),color,7,true)
				draw_line(p+Vector2(-18,1),p+Vector2(-1,16),Color("d8b974"),5,true)
			"staff":
				draw_line(p+Vector2(-7,19),p+Vector2(8,-17),Color("bc9a66"),6,true)
				draw_circle(p+Vector2(8,-17),9,color)
			"shield":
				draw_colored_polygon(PackedVector2Array([p+Vector2(-18,-15),p+Vector2(18,-15),p+Vector2(14,7),p+Vector2(0,22),p+Vector2(-14,7)]),color)
			"coat":
				draw_colored_polygon(PackedVector2Array([p+Vector2(-11,-17),p+Vector2(-24,-6),p+Vector2(-16,4),p+Vector2(-11,-1),p+Vector2(-14,20),p+Vector2(14,20),p+Vector2(11,-1),p+Vector2(16,4),p+Vector2(24,-6),p+Vector2(11,-17)]),color)
			_:
				draw_colored_polygon(PackedVector2Array([p+Vector2(0,-20),p+Vector2(17,0),p+Vector2(0,20),p+Vector2(-17,0)]),color)
		var suffix=("+"+str(item.tier)) if item.tier>0 else ""
		if not item.corruption.is_empty(): suffix+=" !"
		draw_string(font,p+Vector2(-23,34),suffix,HORIZONTAL_ALIGNMENT_LEFT,-1,15,color)
		for n in item.sockets.size():
			var s=p+Vector2(25,n*13-20)
			draw_circle(s,4,Color("b6e5df") if not item.sockets[n].is_empty() else Color("172724"))

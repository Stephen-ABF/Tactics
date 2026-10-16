extends Control
const Gear=preload("res://scripts/gear.gd")
var item: Dictionary
func _draw() -> void:
	if item.is_empty(): return
	var color=Color(Gear.COLORS[Gear.quality(item)])
	for p in Gear.cells(item): draw_rect(Rect2(Vector2(p)*24+Vector2(8,8),Vector2(21,21)),color)

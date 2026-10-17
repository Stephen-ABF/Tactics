class_name ThornSolver
extends RefCounted
const R=preload("res://scripts/rules.gd")
var visits={}
var route_limit=10
var candidate_limit=700
var routes=[]
var damage_weight=5.0
func enumerate(state: Dictionary,path: Array,cursor: int,momentum: int,strides: int) -> void:
	if path.size()>=route_limit or routes.size()>=candidate_limit:return
	var n=R.side(state)
	for i in R.neighbors(cursor,n):
		if i==state.player or i in path:continue
		var tile: Dictionary=state.tiles[i]
		var next_strides=strides+(0 if R.enemy(tile) else 1)
		if next_strides>2+int(state.gear.get("stride",0)):continue
		var next=path+[i]
		var result=R.resolve(state,next)
		if not result.valid:continue
		routes.append({"path":next,"result":result})
		if result.state.player==i:
			var gained=(2 if tile.kind in ["h","b","B"] else 1) if R.enemy(tile) else 0
			enumerate(state,next,i,momentum+gained,next_strides)
func choose(state: Dictionary) -> Dictionary:
	routes=[]
	enumerate(state,[],state.player,int(state.gear.get("focus",0)),0)
	var best={}
	var best_score=-INF
	for candidate in routes:
		var p: Dictionary=candidate.result
		var chip=0
		var nearest=99
		for i in state.tiles.size():
			if R.enemy(p.state.tiles[i]):
				chip+=maxi(0,int(state.tiles[i].hp)-int(p.state.tiles[i].hp))
				var diff=R.pos(p.state.player,state.side)-R.pos(i,state.side)
				nearest=mini(nearest,absi(diff.x)+absi(diff.y))
		var score=p.kills*13.0+chip*8.0-p.damage*damage_weight+p.healing*3.0-nearest*1.6-float(visits.get(p.state.player,0))*0.9
		if p.state.status=="won":score+=1000
		if p.state.status=="lost":score-=10000
		if score>best_score:best_score=score;best=candidate
	return best

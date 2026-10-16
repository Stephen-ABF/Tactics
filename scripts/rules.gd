class_name ThornRules
extends RefCounted
const Content=preload("res://scripts/content.gd")
const MAX_HP=14
const SHELL_HP=4
const ARCHER_DAMAGE=2
const TILE_KINDS=[".","c","t","f","s","h","a","v","b","w","B"]
static func side(state: Dictionary) -> int:
	return int(state.get("side",6))
static func pos(i: int,n: int=6) -> Vector2i:
	return Vector2i(i%n,i/n)
static func adjacent(a: int,b: int,n: int=6) -> bool:
	var d=pos(a,n)-pos(b,n)
	return absi(d.x)+absi(d.y)==1
static func enemy(tile: Dictionary) -> bool:
	return Content.ENEMIES.has(tile.kind)
static func neighbors(i: int,n: int) -> Array:
	var result=[]
	for j in [i-1,i+1,i-n,i+n]:
		if j>=0 and j<n*n and adjacent(i,j,n): result.append(j)
	return result
static func new_board(seed_value: int,wave: int,stance: String,health: int=MAX_HP,gear: Dictionary={},depth: int=1) -> Dictionary:
	wave=clampi(wave,0,4)
	depth=clampi(depth,1,5)
	var n=int(Content.SIDES[wave])
	var rng=RandomNumberGenerator.new()
	rng.seed=seed_value*97+wave*1709+depth*307
	var tiles=[]
	for i in n*n: tiles.append({"kind":".","hp":1,"max_hp":1,"aim":-1,"marks":[],"phase":1})
	var path=[]
	var family=rng.randi_range(0,2)
	if family==0:
		for row in n:
			for column in n:
				path.append((n-1-row)*n+(column if row%2==0 else n-1-column))
	elif family==1:
		var left=0
		var right=n-1
		var top=0
		var bottom=n-1
		while left<=right and top<=bottom:
			for x in range(left,right+1): path.append(bottom*n+x)
			for y in range(bottom-1,top-1,-1): path.append(y*n+right)
			if top<bottom:
				for x in range(right-1,left-1,-1): path.append(top*n+x)
			if left<right:
				for y in range(top+1,bottom): path.append(y*n+left)
			left+=1;right-=1;top+=1;bottom-=1
	else:
		var stack=[n*(n-1)]
		var visited=[]
		while not stack.is_empty():
			var current=int(stack.back())
			if current not in visited: visited.append(current);path.append(current)
			var options=[]
			for j in neighbors(current,n):
				if j not in visited: options.append(j)
			if options.is_empty(): stack.pop_back()
			else: stack.append(options[rng.randi_range(0,options.size()-1)])
	var symmetry=rng.randi_range(0,7)
	for i in path.size():
		var p=pos(path[i],n)
		if symmetry>=4:p.x=n-1-p.x
		for turn in symmetry%4:p=Vector2i(n-1-p.y,p.x)
		path[i]=p.y*n+p.x
	var player=int(path[0])
	var sites=path.slice(1)
	# Keep two connected scouts at the opening; seeded rest makes varied situations.
	var first=sites.pop_front()
	var second=sites.pop_front()
	var shuffled=[]
	while not sites.is_empty(): shuffled.append(sites.pop_at(rng.randi_range(0,sites.size()-1)))
	sites=[first,second]+shuffled
	var count=8 if wave==4 else n+wave*2+2
	var zone_id=Content.zone(seed_value,wave)
	for k in count:
		var kind="s"
		if k>=2:
			var pool=["s","s","h"]
			if wave>=1: pool.append_array(["a","v"])
			if wave>=2: pool.append_array(["b","w"])
			if zone_id=="ash" and wave>=2:pool.append("b")
			if zone_id=="ruins" and wave>=2:pool.append("w")
			kind=pool[rng.randi_range(0,pool.size()-1)]
		if wave==4 and k==count-1:kind="B"
		var hp=int(Content.ENEMIES[kind].hp)+(depth-1 if kind!="B" else (depth-1)*5)
		tiles[sites[k]].kind=kind;tiles[sites[k]].hp=hp;tiles[sites[k]].max_hp=hp
	for k in range(count,sites.size()):
		var roll=rng.randf()
		if roll<0.20:tiles[sites[k]].kind="c"
		elif roll<0.30:tiles[sites[k]].kind="t"
		elif roll<0.40:tiles[sites[k]].kind="f"
	var active_gear={}
	for key in gear:
		if int(gear[key])>0:active_gear[key]=int(gear[key])
	var maximum=MAX_HP+int(gear.get("vitality",0))
	var state={"schema":3,"side":n,"tiles":tiles,"player":player,"hp":clampi(health,1,maximum),"max_hp":maximum,"guard":mini(4,int(gear.get("ward",0))),"poison":0,"turn":0,"kills":0,"stance":stance,"status":"playing","seed":seed_value,"encounter":wave,"materials":0,"gear":active_gear,"zone":zone_id,"depth":depth,"layout":family,"boss_defeated":false}
	update_marks(state)
	return state
static func update_marks(state: Dictionary) -> void:
	var n=side(state)
	var p=pos(state.player,n)
	for tile in state.tiles:
		if tile.kind=="a":tile.aim=p.y
		elif tile.kind=="w":
			tile.marks=[state.player]
			for x in [p.x-1,p.x+1]:
				if x>=0 and x<n:tile.marks.append(p.y*n+x)
		elif tile.kind=="B":
			tile.phase=2 if tile.hp<=tile.max_hp/2 else 1
			tile.marks=[]
			var pattern=int(state.turn)%3
			for j in n*n:
				var q=pos(j,n)
				if (pattern==0 and q.y==p.y) or (pattern==1 and q.x==p.x) or (pattern==2 and ((q.x+q.y==p.x+p.y) if tile.phase==1 else (q.x==p.x or q.y==p.y))):tile.marks.append(j)
static func telegraphs(state: Dictionary) -> Array:
	var result=[]
	var n=side(state)
	for i in state.tiles.size():
		var tile: Dictionary=state.tiles[i]
		if not enemy(tile):continue
		var cells=[]
		var damage=int(Content.ENEMIES[tile.kind].damage)+int((int(state.get("depth",1))-1)/2)
		if tile.kind=="a":
			for x in n:cells.append(int(tile.aim)*n+x)
		elif tile.kind in ["w","B"]:
			cells=tile.marks.duplicate()
			if tile.kind=="B" and tile.phase==2:damage+=1
		elif tile.kind!="b" or int(state.turn)%2==0:cells=neighbors(i,n)
		result.append({"source":i,"cells":cells,"damage":damage,"type":tile.kind})
	return result
static func threats(state: Dictionary,destination: int) -> Array:
	var result=[]
	for mark in telegraphs(state):
		if destination not in mark.cells:continue
		if mark.type=="a" and state.tiles[destination].kind=="c":continue
		result.append({"source":mark.source,"damage":mark.damage,"type":mark.type})
	if state.tiles[destination].kind=="t":result.append({"source":-1,"damage":1,"type":"thorns"})
	if int(state.get("poison",0))>0:result.append({"source":-1,"damage":1,"type":"poison"})
	return result
static func enemies_left(state: Dictionary) -> int:
	var count=0
	for tile in state.tiles:
		if enemy(tile):count+=1
	return count
static func resolve(state: Dictionary,route: Array) -> Dictionary:
	var result={"valid":false,"reason":"Choose an adjoining cell.","damage":0,"kills":0,"momentum":0,"guard_used":0,"hits":[],"attacks":[],"defeated":[],"healing":0,"threats":[],"state":state.duplicate(true)}
	var n=side(state)
	if state.status!="playing" or route.is_empty() or route.size()>n*n:return result
	var next: Dictionary=result.state
	var cursor=int(state.player)
	var seen=[cursor]
	var gear: Dictionary=state.get("gear",{})
	var momentum=int(gear.get("focus",0))
	var strides=0
	var first_attack=true
	for step in route.size():
		if not (route[step] is int or route[step] is float):return result
		var i=int(route[step])
		if i<0 or i>=n*n or i in seen or not adjacent(cursor,i,n):
			result.reason="Use adjoining cells once; no diagonals."
			return result
		seen.append(i)
		var tile: Dictionary=next.tiles[i]
		if enemy(tile):
			var power=1+momentum+int(gear.get("edge",0))+(int(gear.get("pierce",0)) if tile.kind in ["h","b"] else 0)
			if tile.hp<tile.max_hp:power+=int(gear.get("wound",0))
			if first_attack:
				if state.tiles[state.player].kind=="c":power+=int(gear.get("cover_power",0))
				if tile.max_hp>=4:power+=int(gear.get("temper",0))
				if next.guard>0 and int(gear.get("counter",0))>0:
					next.guard-=1;power+=2*int(gear.counter)
				first_attack=false
			var lethal=tile.hp<=power
			result.attacks.append({"to":i,"power":power,"lethal":lethal,"cleave":false})
			result.hits.append(i)
			if not lethal:
				if step!=route.size()-1:
					result.reason="That enemy survives and stops the route. End there to chip it."
					return result
				tile.hp-=power
			else:
				result.defeated.append({"cell":i,"kind":tile.kind})
				if tile.kind=="B":next.boss_defeated=true
				momentum+=2 if tile.kind in ["h","b","B"] else 1
				tile.kind=".";tile.hp=1
				result.kills+=1
				cursor=i
		else:
			strides+=1
			if strides>2+int(gear.get("stride",0)):
				result.reason="Route uses too many empty cells (stride budget %d)." % (2+int(gear.get("stride",0)))
				return result
			cursor=i
	next.player=cursor
	if next.stance=="Duelist" and result.kills==3:next.guard=maxi(next.guard,1)
	if result.kills>=1 and result.kills<=3:next.guard=mini(4,next.guard+int(gear.get("bulwark",0)))
	if next.stance=="Reaver" and result.kills>=6:
		for i in neighbors(cursor,n):
			if enemy(next.tiles[i]):
				result.attacks.append({"to":i,"power":2,"lethal":next.tiles[i].hp<=2,"cleave":true})
				result.hits.append(i)
				next.tiles[i].hp-=2
				if next.tiles[i].hp<=0:
					result.defeated.append({"cell":i,"kind":next.tiles[i].kind})
					if next.tiles[i].kind=="B":next.boss_defeated=true
					next.tiles[i].kind=".";next.tiles[i].hp=1
					result.kills+=1
				break
	if int(gear.get("hexstep",0))>0 and result.kills>0:
		var marked_start=false
		var marked_landing=false
		for mark in telegraphs(state):
			if mark.type in ["w","B"]:
				if state.player in mark.cells:marked_start=true
				if cursor in mark.cells:marked_landing=true
		if marked_start and not marked_landing:next.guard=mini(4,next.guard+int(gear.hexstep))
	var spring=next.tiles[cursor].kind=="f"
	if spring:next.poison=0;next.tiles[cursor].kind="."
	# Boss defeat ends the encounter immediately; surviving minions do not retaliate.
	if not next.boss_defeated:result.threats=threats(next,cursor)
	var guard=int(next.guard)
	var poison=maxi(0,int(next.get("poison",0))-1)
	for threat in result.threats:
		var blocked=mini(guard,int(threat.damage))
		guard-=blocked
		threat.blocked=blocked
		threat.actual=int(threat.damage)-blocked
		result.guard_used+=blocked
		result.damage+=threat.actual
		if threat.type=="v" and threat.actual>0:poison=2
	next.guard=guard
	next.poison=poison
	next.hp=maxi(0,int(next.hp)-result.damage)
	if next.hp>0:
		var recovery=(int(gear.get("leech",0))+int(gear.get("bloom",0)) if result.kills>=5 else 0)+(2 if spring else 0)
		result.healing=mini(recovery,int(next.max_hp)-int(next.hp))
		next.hp+=result.healing
	next.kills+=result.kills;next.materials+=result.kills;next.turn+=1
	update_marks(next)
	if next.hp<=0:next.status="lost"
	elif next.boss_defeated or enemies_left(next)==0:next.status="won"
	result.valid=true;result.momentum=momentum;result.reason="Ready"
	return result
static func legal_actions(state: Dictionary) -> Array:
	var result=[]
	if state.status!="playing":return result
	for i in neighbors(state.player,side(state)):
		if resolve(state,[i]).valid:result.append([i])
	return result
static func normalize_saved(raw: Dictionary) -> Dictionary:
	if int(raw.get("schema",0))!=3:return {}
	var n=int(raw.get("side",0))
	if n<3 or n>6 or not raw.get("tiles") is Array or raw.tiles.size()!=n*n:return {}
	if not Content.ZONES.has(raw.get("zone","")) or raw.get("status","") not in ["playing","won","lost"]:return {}
	var s=raw.duplicate(true)
	s.schema=3
	for key in ["side","player","hp","max_hp","guard","poison","turn","kills","seed","encounter","materials","depth","layout"]:
		if not (s.get(key) is int or s.get(key) is float):return {}
		s[key]=int(s[key])
	if s.player<0 or s.player>=n*n or s.encounter<0 or s.encounter>4 or s.side!=Content.SIDES[s.encounter] or s.max_hp<1 or s.max_hp>200 or s.hp<0 or s.hp>s.max_hp or s.depth<1 or s.depth>5 or s.guard<0 or s.guard>4 or s.turn<0 or s.poison<0 or s.poison>2:return {}
	if s.get("stance","") not in ["Duelist","Reaver"] or not s.get("gear") is Dictionary:return {}
	s.boss_defeated=bool(s.get("boss_defeated",false))
	var cleaned={}
	for key in ["edge","vitality","ward","focus","leech","bulwark","stride","pierce","counter","cover_power","wound","hexstep","bloom","temper"]:
		if s.gear.has(key):cleaned[key]=clampi(int(s.gear[key]),0,20)
	s.gear=cleaned
	for tile in s.tiles:
		if not tile is Dictionary or tile.get("kind","") not in TILE_KINDS:return {}
		for key in ["hp","max_hp","aim","phase"]:
			if not (tile.get(key) is int or tile.get(key) is float):return {}
			tile[key]=int(tile[key])
		if tile.hp<1 or tile.hp>200 or tile.max_hp<1 or tile.max_hp>200 or tile.aim < -1 or tile.aim>=n:return {}
		if not tile.get("marks") is Array:return {}
		var cells=[]
		for value in tile.marks:
			if not (value is int or value is float) or int(value)<0 or int(value)>=n*n:return {}
			cells.append(int(value))
		tile.marks=cells
	if enemy(s.tiles[s.player]):return {}
	if s.status=="playing" and (s.hp<=0 or enemies_left(s)==0):return {}
	return s

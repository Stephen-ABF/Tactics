extends SceneTree
const R=preload("res://scripts/rules.gd")
const C=preload("res://scripts/content.gd")
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(message)
func fixture(n: int=3) -> Dictionary:
	var s=R.new_board(1,n-3 if n<6 else 3,"Duelist")
	for tile in s.tiles:tile.kind=".";tile.hp=1;tile.max_hp=1;tile.aim=-1;tile.marks=[];tile.phase=1
	s.player=n*(n-1);s.gear={};s.guard=0;s.poison=0
	return s
func foe(s: Dictionary,i: int,kind: String,hp: int=-1) -> void:
	var value=int(C.ENEMIES[kind].hp) if hp<0 else hp
	s.tiles[i]={"kind":kind,"hp":value,"max_hp":value,"aim":int(s.side)-1,"marks":[] ,"phase":1}
func _initialize() -> void:
	var s=fixture()
	for i in [7,8,5]:foe(s,i,"s")
	foe(s,2,"h")
	var original=s.duplicate(true)
	var p=R.resolve(s,[7,8,5,2])
	check(p.valid and p.kills==4 and p.state.player==2 and p.state.status=="won","Momentum kills armor and clears wave")
	check(s==original,"Preview does not mutate input")
	check(p==R.resolve(s,[7,8,5,2]),"Reducer deterministic")
	for path in [[],[-1],[9],[4],[7,6],[7,8,7]]:check(not R.resolve(s,path).valid,"Input boundaries / revisits")
	check(not R.adjacent(2,3,3),"Rows never wrap")
	check(not R.resolve(p.state,[1]).valid,"Won state rejects input")
	s=fixture();check(R.resolve(s,[7,8]).valid,"Two empty strides legal")
	check(not R.resolve(s,[7,8,5]).valid,"Third empty stride blocked")
	s.gear={"stride":1};check(R.resolve(s,[7,8,5]).valid,"Trail Boots extends stride")
	s=fixture();foe(s,7,"h")
	p=R.resolve(s,[7]);check(p.valid and p.state.player==6 and p.state.tiles[7].hp==3,"Nonlethal lunge chips and returns")
	check(not R.resolve(s,[7,8]).valid,"Cannot pass surviving enemy")
	for i in 4:s=R.resolve(s,[7]).state
	check(s.status=="won","Isolated armor is defeatable")
	s=fixture();foe(s,4,"v")
	p=R.resolve(s,[7]);check(p.damage==1 and p.state.poison==2,"Unblocked viper inflicts poison")
	s=p.state;s.tiles[4].kind="."
	p=R.resolve(s,[8]);check(p.damage==1 and p.state.poison==1,"First future poison tick")
	s=p.state;s.status="playing";foe(s,0,"s")
	p=R.resolve(s,[5]);check(p.damage==1 and p.state.poison==0,"Second poison tick expires")
	s=fixture();foe(s,4,"v");s.guard=1
	p=R.resolve(s,[7]);check(p.damage==0 and p.state.poison==0,"Guard prevents poison application")
	s=fixture();s.poison=2;s.hp=10;s.tiles[7].kind="f"
	p=R.resolve(s,[7]);check(p.damage==0 and p.healing==2 and p.state.poison==0 and p.state.tiles[7].kind==".","Spring cleanses, heals once and consumes")
	s=fixture();s.tiles[7].kind="t"
	check(R.resolve(s,[7]).damage==1,"Thorn landing deals damage")
	s=fixture();foe(s,4,"b")
	check(R.resolve(s,[7]).damage==2,"Charged brute hits")
	s.turn=1;check(R.resolve(s,[7]).damage==0,"Brute rests on alternate turn")
	s=fixture();foe(s,0,"a")
	check(R.resolve(s,[7]).damage==2,"Archer row hits")
	s.tiles[7].kind="c";check(R.resolve(s,[7]).damage==0,"Cover blocks arrows")
	s=fixture();foe(s,0,"w");s.tiles[0].marks=[7];s.tiles[7].kind="c"
	check(R.resolve(s,[7]).damage==1,"Hexer marks ignore cover")
	s=fixture();s.player=7;foe(s,4,"B",10);s.tiles[4].max_hp=18;s.tiles[4].marks=[6,7,8]
	p=R.resolve(s,[4]);check(p.damage==2 and p.state.tiles[4].phase==2,"Boss phase change does not surprise with immediate extra damage")
	check(p.state.tiles[4].marks==[1,4,7],"Boss next pattern is a visible column")
	s=fixture();s.player=7;foe(s,4,"B",1);foe(s,1,"h");s.tiles[4].marks=[6,7,8]
	p=R.resolve(s,[4]);check(p.state.status=="won" and p.state.boss_defeated and p.damage==0 and R.enemies_left(p.state)==1,"Boss defeat wins and cancels retaliation")
	s=fixture();foe(s,7,"h");s.gear={"edge":2,"focus":1}
	check(R.resolve(s,[7]).attacks[0].power==4,"Gear contributes exact hit power")
	s=fixture();foe(s,7,"h");s.gear={"pierce":2}
	check(R.resolve(s,[7]).attacks[0].power==3,"Thornbreaker targets armor")
	s=fixture();s.gear={"leech":2};s.hp=10
	for i in [7,8,5,2,1]:foe(s,i,"s")
	p=R.resolve(s,[7,8,5,2,1]);check(p.healing==2 and p.state.hp==12,"Leech after long route")
	s.hp=1;s.poison=1
	p=R.resolve(s,[7,8,5,2,1]);check(p.state.status=="lost" and p.healing==0,"Healing does not revive lethal poison")
	var seen={}
	for seed_value in 150:
		for wave in 5:
			for depth in [1,3]:
				s=R.new_board(seed_value,wave,"Duelist",14,{},depth)
				check(s.side==C.SIDES[wave] and s.tiles.size()==s.side*s.side,"Expanding board size")
				check(not R.enemy(s.tiles[s.player]) and not R.legal_actions(s).is_empty(),"Safe spawn with legal actions")
				check(s==R.new_board(seed_value,wave,"Duelist",14,{},depth),"Seed reproduces full layout")
				var loaded=R.normalize_saved(JSON.parse_string(JSON.stringify(s)))
				check(not loaded.is_empty() and loaded.player==s.player and loaded.tiles.size()==s.tiles.size(),"Checkpoint board roundtrip")
				if wave==4:
					var bosses=0
					for tile in s.tiles:
						if tile.kind=="B":bosses+=1
					check(bosses==1,"Boss arena has exactly one boss")
				if wave==3 and depth==1:
					var key=str(s.player)
					for tile in s.tiles:key+=str(tile.kind)
					seen[key]=true
	check(seen.size()>100,"Generated layouts vary beyond mirrored templates")
	var malformed=fixture();malformed.side=7;check(R.normalize_saved(malformed).is_empty(),"Malformed checkpoint rejected")
	print("EXPEDITION RULES: %d checks; %d failures; %d distinct 6x6 layouts" % [checks,failures,seen.size()])
	quit(1 if failures else 0)

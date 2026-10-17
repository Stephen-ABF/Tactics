extends SceneTree
const G=preload("res://scripts/gear.gd")
const R=preload("res://scripts/rules.gd")
const C=preload("res://scripts/content.gd")
const Solver=preload("res://tests/solver.gd")
func _initialize() -> void:
	var report=[];var summary={}
	for style in ["baseline","safe3","risk6","binding"]:
		var profile=G.fresh()
		for item in profile.items:item.tier=6 if style=="risk6" else 3
		if style=="binding":profile.items[0].sockets=["Ash","Gale"]
		var gear={} if style=="baseline" else G.bonuses(profile)
		for depth in [1,2,3]:
			var key=style+"_depth"+str(depth);summary[key]={"wins":0,"runs":0,"turns":[],"damage":[]}
			for stance in ["Duelist","Reaver"]:
				for seed_value in [14026,14027,102,77,301,999]:
					var hp=14+int(gear.get("vitality",0));var boons=[];var turns=0;var damage=0;var cleared=0
					for wave in 5:
						var state=R.new_board(seed_value,wave,stance,hp,C.combine(gear,boons),depth)
						var solver=Solver.new();solver.candidate_limit=350
						for turn in 75:
							if state.status!="playing":break
							solver.visits[state.player]=int(solver.visits.get(state.player,0))+1
							var choice=solver.choose(state)
							if choice.is_empty():break
							state=choice.result.state;turns+=1;damage+=choice.result.damage
						if state.status!="won":break
						cleared+=1
						if wave<4:
							boons.append(C.choices(seed_value,wave,boons)[0])
							var max_hp=14+int(C.combine(gear,boons).get("vitality",0))
							hp=clampi(max_hp-(state.max_hp-state.hp)+3,1,max_hp)
					var row={"profile":style,"depth":depth,"stance":stance,"seed":seed_value,"won":cleared==5,"waves":cleared,"turns":turns,"damage":damage}
					report.append(row);summary[key].runs+=1
					if row.won:summary[key].wins+=1;summary[key].turns.append(turns)
					summary[key].damage.append(damage)
			print(key,": ",summary[key].wins,"/",summary[key].runs)
	var file=FileAccess.open("res://tests/balance_matrix.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"simulation_only":true,"solver_candidate_budget":350,"runs":report,"groups":summary,"policy":"unique camp boons; expedition Edge cap 3"},"\t"));file.close()
	print("BALANCE MATRIX: ",report.size()," simulated expeditions; no human win-rate or duration claim")
	quit()

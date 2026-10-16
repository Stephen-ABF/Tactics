extends SceneTree
const R=preload("res://scripts/rules.gd")
const C=preload("res://scripts/content.gd")
const G=preload("res://scripts/gear.gd")
const Solver=preload("res://tests/solver.gd")
func _initialize() -> void:
	var report=[]
	var solutions=[]
	for profile in ["baseline","starter","strong"]:
		for stance in ["Duelist","Reaver"]:
			for seed_value in [14026,14027,102]:
				var gear={} if profile=="baseline" else G.bonuses(G.fresh())
				if profile=="strong":gear={"edge":2,"vitality":6,"ward":2,"focus":1,"leech":1,"bulwark":1}
				var hp=14+int(gear.get("vitality",0))
				var boon_ids=[]
				var turns=0
				var cleared=0
				var trace=[]
				var failure=""
				for wave in 5:
					var bonus=C.combine(gear,boon_ids)
					var s=R.new_board(seed_value,wave,stance,hp,bonus)
					var solver=Solver.new()
					var paths=[]
					for turn in 75:
						if s.status!="playing":break
						solver.visits[s.player]=int(solver.visits.get(s.player,0))+1
						var choice=solver.choose(s)
						if choice.is_empty():failure="no_action";break
						paths.append(choice.path)
						s=choice.result.state;turns+=1
					trace.append(paths)
					if s.status!="won":failure="health" if s.status=="lost" else "cutoff";break
					cleared+=1
					if wave<4:
						boon_ids.append(C.choices(seed_value,wave)[0])
						var next_bonus=C.combine(gear,boon_ids)
						hp=clampi(14+int(next_bonus.get("vitality",0))-(int(s.max_hp)-int(s.hp))+3,1,14+int(next_bonus.get("vitality",0)))
				var row={"profile":profile,"stance":stance,"seed":seed_value,"waves":cleared,"turns":turns,"failure":failure}
				report.append(row);print(JSON.stringify(row))
				if cleared==5:solutions.append({"profile":profile,"stance":stance,"seed":seed_value,"gear":gear,"trace":trace,"boons":boon_ids})
	var f=FileAccess.open("res://tests/balance_results.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close()
	f=FileAccess.open("res://tests/solution_traces.json",FileAccess.WRITE);f.store_string(JSON.stringify(solutions,"\t"));f.close()
	print("SIMULATED EXPEDITIONS: ",solutions.size()," wins / ",report.size(),"; not human playtesting")
	quit()

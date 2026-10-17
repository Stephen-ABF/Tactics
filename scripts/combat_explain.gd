class_name ThornExplain
extends RefCounted
const R=preload("res://scripts/rules.gd")
const C=preload("res://scripts/content.gd")
static func cell_name(cell: int,n: int) -> String:
	return "row %d, column %d" % [cell/n+1,cell%n+1]
static func describe(state: Dictionary,path: Array,result: Dictionary) -> String:
	if not result.get("valid",false):return result.get("reason","Plan an adjoining route first.")
	var lines=["Landing: "+cell_name(result.state.player,R.side(state)),"%d kills • %d damage • %d healing\nGuard %d → %d • poison after: %d" % [result.kills,result.damage,result.healing,state.guard,result.state.guard,result.state.poison]]
	for hit in result.attacks:
		var parts=[]
		for part in hit.get("parts",[]):parts.append("%d %s" % [part.amount,part.source])
		var kind=state.tiles[hit.to].kind
		var name=C.ENEMIES.get(kind,{"name":"Enemy"}).name
		lines.append("%s at %s\n%s = %d power\n%s" % [name,cell_name(hit.to,R.side(state))," + ".join(parts) if not parts.is_empty() else "Reaver cleave",hit.power,"Defeated." if hit.lethal else "Survives; route stops before this enemy."])
	if not result.get("guard_notes",[]).is_empty():lines.append("GUARD\n"+"\n".join(result.guard_notes))
	if result.threats.is_empty():lines.append("RETALIATION\nNo damage sources reach this landing.")
	for threat in result.threats:
		var name=C.ENEMIES[threat.type].name if C.ENEMIES.has(threat.type) else str(threat.type).capitalize()
		lines.append("%s: %d incoming − %d guard = %d damage" % [name,threat.damage,threat.get("blocked",0),threat.get("actual",threat.damage)])
	if result.get("spring",false):lines.append("Spring consumed: poison cleansed; up to 2 healing after retaliation.")
	if result.get("healing_sources",[]).size()>0:lines.append("RECOVERY\n"+"\n".join(result.healing_sources)+"\nActual healing is limited by missing HP; it cannot revive lethal damage.")
	if result.state.status=="lost":lines.append("LETHAL: damage resolves before healing. Choose a different landing or route.")
	return "\n\n".join(lines)

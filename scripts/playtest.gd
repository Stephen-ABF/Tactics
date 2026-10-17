class_name ThornPlaytest
extends RefCounted
const LIMIT=50
static func fresh() -> Dictionary:
	return {"runs":[],"tutorials":0,"retries":0,"upgrade_attempts":0,"upgrade_losses":0,"corruption_attempts":0,"corruption_losses":0,"salvaged":0}
static func metrics() -> Dictionary:
	return {"gear":0,"common":0,"exclusive":0,"damage":0,"decisions":0,"mistakes":0}
static func normalize(raw: Variant) -> Dictionary:
	var result=fresh()
	if not raw is Dictionary:return result
	for key in result:
		if key!="runs" and (raw.get(key) is int or raw.get(key) is float):result[key]=clampi(int(raw[key]),0,100000000)
	if raw.get("runs") is Array:
		var ids=[]
		for row in raw.runs:
			if not row is Dictionary or not row.get("id") is String or row.id in ids:continue
			var clean={"id":row.id.substr(0,128),"won":bool(row.get("won",false)),"reason":str(row.get("reason","unknown")).substr(0,30),"stance":str(row.get("stance","Duelist"))}
			for key in ["seconds","camp_seconds","planning_seconds","animation_seconds","gear","common","exclusive","damage","decisions","mistakes","wave","depth","seed"]:
				var value=row.get(key,0)
				clean[key]=clampf(float(value),0,100000000) if (value is int or value is float) and is_finite(float(value)) else 0.0
			ids.append(row.id);result.runs.append(clean)
		if result.runs.size()>LIMIT:result.runs=result.runs.slice(-LIMIT)
	return result
static func record_run(report: Dictionary,row: Dictionary) -> bool:
	for prior in report.runs:
		if prior.id==row.id:return false
	var clean=normalize({"runs":[row]}).runs
	if clean.is_empty():return false
	report.runs.append(clean[0])
	if report.runs.size()>LIMIT:report.runs.pop_front()
	return true
static func craft(report: Dictionary,event: String,data: Dictionary) -> void:
	if event=="gear_upgrade":
		report.upgrade_attempts+=1
		if data.get("destroyed",false):report.upgrade_losses+=1
	elif event=="gear_corrupt" and data.get("ok",false):
		report.corruption_attempts+=1
		if data.get("destroyed",false):report.corruption_losses+=1
	elif event=="gear_salvage" and data.get("salvaged",false):report.salvaged+=1
static func median(values: Array) -> float:
	if values.is_empty():return 0.0
	var sorted=values.duplicate();sorted.sort()
	var middle=sorted.size()/2
	return float(sorted[middle]) if sorted.size()%2 else (float(sorted[middle-1])+float(sorted[middle]))/2
static func summary(report: Dictionary) -> String:
	var wins=0;var durations=[];var completed=[];var gear=0;var damage=0
	for row in report.runs:
		var total=row.seconds+row.camp_seconds;durations.append(total);gear+=row.gear;damage+=row.damage
		if row.won:wins+=1;completed.append(total)
	var lines=["Local test records only. Last %d finished runs retained; no remote upload.\n" % LIMIT]
	if report.runs.is_empty():lines.append("No finished runs recorded yet. Play an expedition with logging enabled.")
	else:
		lines.append("%d wins / %d finished runs\nMedian all attempts: %.1f min\nMedian wins: %s\nMean gear per attempt: %.1f\nTotal damage taken: %d" % [wins,report.runs.size(),median(durations)/60.0,"%.1f min" % (median(completed)/60.0) if not completed.is_empty() else "no wins yet",float(gear)/report.runs.size(),damage])
	lines.append("Tutorial completions: %d\nImmediate retries (<15 seconds): %d\nUpgrade losses: %d / %d attempts\nCorruption losses: %d / %d attempts\nItems salvaged: %d" % [report.tutorials,report.retries,report.upgrade_losses,report.upgrade_attempts,report.corruption_losses,report.corruption_attempts,report.salvaged])
	for index in range(report.runs.size()-1,maxi(-1,report.runs.size()-11),-1):
		var row=report.runs[index]
		lines.append("%s • Depth %d • seed %d\n%s • wave %d • %.1f min\nPlan %.0fs / animation %.0fs / camp %.0fs\nGear %d • common Sigils %d • exclusive %d\nDamage %d • moves %d • rejected taps %d" % ["WIN" if row.won else "END",row.depth,row.seed,row.reason,row.wave+1,(row.seconds+row.camp_seconds)/60.0,row.planning_seconds,row.animation_seconds,row.camp_seconds,row.gear,row.common,row.exclusive,row.damage,row.decisions,row.mistakes])
	return "\n\n".join(lines)

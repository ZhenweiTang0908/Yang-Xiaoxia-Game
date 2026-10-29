extends SceneTree
# Motion smoothness audit on the authored timing only: for every move, look at
# consecutive key poses and report cuts that skip several drawings at once.
const MOVES=preload("res://scripts/actors/lion_moves.gd")
const POSES=preload("res://scripts/animation/lion_pose_timelines.gd")
const BALANCE=preload("res://scripts/core/balance.gd")
func _initialize():
	var tuning=BALANCE.new()
	var rough=0
	for id in MOVES.MOVES:
		var move=MOVES.MOVES[id]
		if not POSES.TIMES.has(id):print("NO_TIMELINE ",id);rough+=1;continue
		var beats=[]
		for index in move.beats.size():
			var prefix="lion_"+id+"_"+str(index)+"_"
			beats.append({"time":tuning.get_value(prefix+"time"),"window":tuning.get_value(prefix+"window")})
		var recovery=tuning.get_value("lion_"+id+"_recovery")
		var keys=POSES.sequence(id,beats,move,recovery)
		var last_contact=beats[-1].time+beats[-1].window
		for i in range(1,keys.size()):
			var dt=keys[i].time-keys[i-1].time
			var step=absi(int(keys[i].index)-int(keys[i-1].index))
			if step>=3 and dt<=.14:
				rough+=1
				print("HARD_CUT %s t=%.2f dt=%.2f frames=%d->%d" % [id,keys[i].time,dt,keys[i-1].index,keys[i].index])
			elif step>=1 and dt>=.46:
				# Settling on the last drawn pose before returning to idle is intended;
				# a long hold in the middle of the action is what reads as a freeze.
				# A held recovery or a deliberate anticipation pause is fine; a
				# freeze while the strike is still being delivered is not.
				var before_strike=keys[i].time<last_contact-.01
				if i<keys.size()-1 and before_strike:rough+=1
				print("LONG_HOLD %s t=%.2f dt=%.2f frames=%d->%d %s" % [id,keys[i].time,dt,keys[i-1].index,keys[i].index,"PRE_STRIKE" if before_strike else "recovery"])
	print("LION_TIMELINE_AUDIT rough=",rough)
	quit(0 if rough==0 else 1)

extends SceneTree
# The mesh bridge warps one authored pose into the next. If the gap between keys
# is shorter than that warp, the drawing never settles and fast flurries read as
# a smear. Count how often that happens with the shipped durations.
const MOVES=preload("res://scripts/actors/lion_moves.gd")
const POSES=preload("res://scripts/animation/lion_pose_timelines.gd")
const BALANCE=preload("res://scripts/core/balance.gd")
func base_duration(index):
	match index%6:
		2:return .11
		3:return .055
		4:return .07
		_:return .085
func _initialize():
	var tuning=BALANCE.new()
	var total=0;var collisions=0
	for id in MOVES.MOVES:
		var move=MOVES.MOVES[id]
		if not POSES.TIMES.has(id):continue
		var beats=[]
		for index in move.beats.size():
			var prefix="lion_"+id+"_"+str(index)+"_"
			beats.append({"time":tuning.get_value(prefix+"time"),"window":tuning.get_value(prefix+"window")})
		var keys=POSES.sequence(id,beats,move,tuning.get_value("lion_"+id+"_recovery"))
		var over=0
		for i in range(0,keys.size()-1):
			var gap=keys[i+1].time-keys[i].time
			var need=base_duration(int(keys[i].index))
			total+=1
			if gap<need*1.1:over+=1;collisions+=1
		if over>0:print("BRIDGE_OVERRUN %s %d/%d" % [id,over,keys.size()-1])
	print("LION_BRIDGE_AUDIT transitions=",total," overruns=",collisions)
	quit(0)

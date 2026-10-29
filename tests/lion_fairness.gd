extends SceneTree
# Independent contract tests. No main scene, SaveStore, tuning.load/save or real saves.
# Run ONLY via .agents/skills/godot-headless-test/run_test.sh tests/lion_fairness.gd 120
const ELDER=preload("res://scripts/actors/lion_elder.gd")
const CONTACTS={"M01":[6],"M02":[6],"M03":[10],"M04":[6],"M05":[5],"M06":[5],"M07":[7],"M08":[2,6,10],"M09":[5],"M10":[7],"M11":[7],"M12":[6,11],"M13":[8],"M14":[8],"M15":[7],"M16":[5],"M17":[3,7],"M18":[5,10],"M19":[4,10],"M20":[3,9,15]}
const LONG=["M04","M08","M12","M18","M19","M20"]
class Target extends Node2D:
	var health=10000.0
	var invincible=0.0
	var roll_guard=0.0
	var hits=[]
	func take_damage(amount,_direction=0,_source="",_owner=0):
		health-=amount;hits.append(amount);return true
	func hurt_rect():return Rect2(position-Vector2(8,38),Vector2(16,38))
class Silent extends RefCounted:
	func setup(_game):pass
	func clear():pass
	func tick(_dt):pass
	func cue(_a,_b,_c):return false
	func speak(_a,_b=false):return false
class Services extends RefCounted:
	func remove_owner(_id):pass
	func reset(_actor):pass
	func hit_mark(_a,_b,_c,_d):pass
	func number(_a,_b,_c):pass
	func burst(_a,_b,_c,_d):pass
class MemoryTuning extends RefCounted:
	const SCHEMA=preload("res://scripts/core/balance.gd").SCHEMA
	var values={}
	func _init():reset()
	func reset():
		values.clear()
		for key in SCHEMA:values[key]=float(SCHEMA[key][1])
	func get_value(key):return values.get(key,0.0)
class World extends Node:
	var qa_mode=true
	var state="playing"
	var hitstop=0.0
	var tuning=MemoryTuning.new()
	var player=Target.new()
	var summon={"phase":"active","brother":Target.new()}
	var combat=Services.new()
	var scene_motion=Services.new()
	var fx=Services.new()
	var GOLD=Color.GOLD
	var TEAL=Color.TEAL
	var kills=0
	func active():return state=="playing"
	func ally_target(_pos):return player
	func boss_defeated():state="win"
var game
var boss
var checks=0
var failures=[]
func _initialize():call_deferred("run")
func verify(ok,label):
	checks+=1
	if not ok:failures.append(label);print("FAIL ",label)
func reset(id,face=1.0):
	game.state="playing";game.hitstop=0
	game.player.hits.clear();game.player.health=10000
	game.summon.brother.hits.clear();game.summon.brother.health=10000
	game.player.position=Vector2(900,450);game.summon.brother.position=Vector2(900,450)
	boss.position=Vector2(480,450);boss.facing=face;boss.phase=1 if id in ["M01","M02","M03","M04","M05","M06","M07","M08","M19"] else 2
	boss.phase_moves=12;boss.hp=boss.max_hp*.2;boss.phase_shift=0;boss.turn_left=0;boss.stagger_left=0;boss.dead=false;boss.active_battle=true
	boss.history.clear();boss.damage_log.clear();boss.far_time=0;boss.ranged_ready=999;boss.pending_rush=false;boss.pending_spit=false;boss.begin(id)
func advance_to(at):
	while boss.t<at-.0000001 and boss.action!="":
		boss._physics_process(minf(1.0/240,at-boss.t))
func park(index):
	var b=boss.beats[index]
	# Aim at the narrow interior, including elevated high attacks and negative back kicks.
	var x=boss.position.x+boss.lock_dir*(b.near+b.far)*.5
	var y=minf(450,450-(b.low+b.high)*.5+19)
	# Independently find a visible contact point in the authored cap. Do not call
	# the production silhouette predicate as the oracle for that same predicate.
	var bank=boss.move.bank
	if boss.visual.banks.has(bank):
		var data=boss.visual.banks[bank]
		var frame=0
		for pose in boss.move.poses:
			if pose.time<=b.time+.001:frame=pose.index
		if frame>=0 and frame<data.pictures.size():
			var image=data.pictures[frame].get_image()
			var scale_unit=float(data.info.reference_height)/maxf(1,data.bounds[int(data.info.get("reference_frame",0))].size.y)
			var mirror=-boss.move.source_dir
			var found=false
			for height in range(maxi(19,int(b.low)+1),int(b.high),2):
				for offset in range(int(b.near)+1,int(b.far),2):
					var local_x=boss.lock_dir*offset
					var pixel=Vector2i(int(local_x/mirror/scale_unit+data.anchors[frame]),int(-height/scale_unit+data.bounds[frame].end.y))
					if pixel.x>=0 and pixel.y>=0 and pixel.x<image.get_width() and pixel.y<image.get_height() and image.get_pixelv(pixel).a>.35:
						x=boss.position.x+local_x;y=450-height+19;found=true;break
				if found:break
	game.player.position=Vector2(x,y);game.summon.brother.position=Vector2(x,y)
func selection():
	var seen={}
	for phase in [1,2]:
		for distance in [-35,20,35,80,130,200,250]:
			reset("M01" if phase==1 else "M09")
			boss.phase=phase;boss.phase_moves=20;boss.history.clear();boss.since_rest=0;boss.rest_ready=999
			for n in 120:
				boss.position=Vector2(480,450)
				game.player.position=Vector2(480+distance,450)
				# This harness measures selection legality; a whiff stumble or a rest
				# would pause the actor and hide the next legal choice.
				boss.stagger_left=0;boss.stagger_kind="";boss.rest_ready=999
				if boss.facing!=1 and distance>=0:
					boss.choose();boss._physics_process(boss.turn_left+.001)
				var pool=boss.candidates()
				if pool.is_empty():
					var old=boss.position.x
					boss.clear_attacks()
					boss.choose()
					verify(boss.action=="" and (boss.position.x!=old or boss.turn_left>0 or boss.idle>0),"out of reach repositions phase=%s distance=%s n=%s action=%s" % [phase,distance,n,boss.action])
					break
				var previous=boss.history.back() if not boss.history.is_empty() else ""
				boss.choose()
				var chosen=boss.action
				verify(chosen in pool,"normal choose uses legal pool "+chosen)
				verify(chosen!=previous and not (chosen in LONG and previous in LONG),"normal chain no repeat/adjacent long "+previous+" -> "+chosen)
				if boss.beats.is_empty():break
				seen[chosen]=true
				advance_to(boss.beats[-1].time+boss.beats[-1].window+boss.recovery+.001)
	for id in CONTACTS:verify(seen.has(id),"normal selection reaches "+id)
func damage():
	for id in CONTACTS:
		for face in [-1.0,1.0]:
			for index in ELDER.CATALOG.MOVES[id].beats.size():
				reset(id,face)
				var b=boss.beats[index].duplicate()
				advance_to(b.time-.002);park(index)
				boss._physics_process(.001)
				verify(game.player.hits.is_empty() and game.summon.brother.hits.is_empty(),"no early contact %s/%d face=%s" % [id,index,face])
				boss._physics_process(.002)
				var dealt=b.damage*boss.cfg("damage_scale")
				verify(game.player.hits==[dealt] and game.summon.brother.hits==[dealt],"actual damage both targets %s/%d face=%s got=%s/%s" % [id,index,face,game.player.hits,game.summon.brother.hits])
				for n in 8:
					park(index);boss._physics_process(b.window/10)
				verify(game.player.hits.size()==1 and game.summon.brother.hits.size()==1,"unique per target beat %s/%d face=%s" % [id,index,face])
				if id=="M01":print("EVIDENCE M01 face=",face," beat_at=",b.time," damage_log=",boss.damage_log)
				reset(id,face)
				advance_to(b.time+b.window+.002);park(index)
				boss._physics_process(.001)
				verify(game.player.hits.is_empty() and game.summon.brother.hits.is_empty(),"no contact after window %s/%d face=%s" % [id,index,face])
func interruptions():
	for id in CONTACTS:
		for fraction in [.05,.55,1.01]:
			for mode in ["paused","hitstop","dead","defeat","phase"]:
				reset(id);advance_to(boss.beats[0].time*fraction)
				var old=boss.t;var pos=boss.position;var frame=boss.visual.frame
				var hits=game.player.hits.size();var events=boss.event_log.size()
				if mode=="paused":game.state="paused"
				elif mode=="hitstop":game.hitstop=1
				elif mode=="dead":game.state="dead"
				elif mode=="defeat":boss.take_hit(999999,"brother",1,false,false,false)
				else:boss.begin_phase_shift()
				for n in 4:boss._physics_process(.2)
				if mode in ["paused","hitstop"]:
					verify(boss.t==old and boss.position==pos and boss.visual.frame==frame and boss.event_log.size()==events,"freeze clocks/pose/events %s %s t=%s" % [id,mode,old])
				else:
					verify(boss.action=="" and boss.beats.is_empty() and boss.victims.is_empty() and boss.fired.is_empty(),"clear pending contacts %s %s t=%s" % [id,mode,old])
				verify(game.player.hits.size()==hits,"no delayed damage %s %s" % [id,mode])
func sprite_reach():
	# Exhaust a spatial grid at five instants, keeping failed onset tests above.
	# Each probe is a new target encounter; per-victim uniqueness is tested separately.
	for id in CONTACTS:
		for face in [-1.0,1.0]:
			for index in ELDER.CATALOG.MOVES[id].beats.size():
				reset(id,face)
				var b=boss.beats[index].duplicate()
				var reached=false
				var evidence={}
				for fraction in [.001,.20,.45,.70,.95]:
					advance_to(b.time+b.window*fraction)
					for height in range(maxi(19,int(b.low)+1),int(b.high),4):
						for offset in range(int(b.near)+1,int(b.far),4):
							boss.victims.clear();game.player.hits.clear();game.summon.brother.hits.clear()
							game.player.position=Vector2(boss.position.x+boss.lock_dir*offset,450-height+19)
							game.summon.brother.position=game.player.position
							boss.contact(index,boss.beat_rect(index,boss.position.x,boss.position.x))
							if game.player.hits==[b.damage*boss.cfg("damage_scale")] and game.summon.brother.hits==[b.damage*boss.cfg("damage_scale")]:
								reached=true;evidence={"time":boss.t,"target":game.player.position};break
						if reached:break
					if reached:break
				print("REACH ",id,"/",index," face=",face," reachable=",reached," evidence=",evidence)
				verify(reached,"sprite beat reachable across active window %s/%d face=%s (4px grid, five times)" % [id,index,face])
	# Fixed world positions supplied by the parent: do not search/move these targets.
	for face in [-1.0,1.0]:
		# The revised low-pounce pose visibly reaches 226px from the starting root.
		# Keep a fixed target safely beyond its maximum 150+80+8 cap as the miss.
		for offset in [200,250]:
			reset("M01",face);boss.position.x=400;boss.origin=boss.position
			game.player.position=Vector2(400+face*offset,450)
			game.summon.brother.position=game.player.position
			advance_to(1.1)
			verify(game.player.hits.size()==(1 if offset==200 else 0) and game.summon.brother.hits.size()==(1 if offset==200 else 0),"M01 fixed painted reach offset=%d face=%s got=%s/%s" % [offset,face,game.player.hits,game.summon.brother.hits])
func authored():
	for id in CONTACTS:
		for face in [-1.0,1.0]:
			reset(id,face)
			verify(boss.visual.banks.has(id),"authored draft bank available "+id)
			# Edit in-memory F2 values only; deliberately nonuniform beat changes.
			var saved=game.tuning.values.duplicate()
			game.tuning.values["lion_"+id+"_windup"]+=.19
			for index in boss.beats.size():game.tuning.values["lion_%s_%d_time" % [id,index]]+=.13*index
			boss.begin(id)
			for index in boss.beats.size():
				advance_to(boss.beats[index].time+.00001)
				verify(boss.visual.active_bank==id and boss.visual.frame==CONTACTS[id][index],"F2 contact frame %s/%d face=%s expected=%d actual=%s/%d t=%.3f" % [id,index,face,CONTACTS[id][index],boss.visual.active_bank,boss.visual.frame,boss.t])
				verify(boss.move.source_dir==face and boss.visual.facing==-face,"authored mirror retains source_dir "+id+"/"+str(index))
			game.tuning.values=saved
	for face in [-1.0,1.0]:
		reset("M14",face);advance_to(.8)
		verify((boss.position.x-480)*face<0 and boss.lock_dir==face,"M14 retreats away with initial-facing kick "+str(face))
		reset("M20",face)
		var turn=boss.beats[-1].time-.35
		advance_to(turn-.001);verify(boss.lock_dir==face,"M20 no early reversal "+str(face))
		advance_to(turn+.001);verify(boss.lock_dir==-face and boss.facing==-face and boss.move.source_dir==face and boss.visual.facing==-face,"M20 .35 telegraph reversal preserves artwork mirror "+str(face))
func run():
	seed(20261026)
	game=World.new();root.add_child(game)
	game.tuning.reset()
	boss=ELDER.new();boss.game=game;boss.audio=Silent.new()
	# Avoid _ready/audio and scene initialization: only the actor's real visual helper is attached.
	boss.visual=ELDER.VISUAL.new();boss.add_child(boss.visual);boss.visual.setup(boss)
	selection();damage();interruptions();sprite_reach();authored()
	print("LION_FAIRNESS_RESULT checks=",checks," failures=",failures.size())
	print("LIMIT: target spies measure actual actor contact/damage calls without player i-frames; audio is silent spy. 258 drafted / 0 visually approved; no fluency claim.")
	boss.free();game.player.free();game.summon.brother.free();game.free()
	quit(0 if failures.is_empty() else 1)

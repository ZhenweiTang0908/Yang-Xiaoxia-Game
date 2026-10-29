extends CharacterBody2D
# Every contact belongs to a committed, timed beat. Decorative cloth/lamp never hit.
const CATALOG=preload("res://scripts/actors/lion_moves.gd")
const POSES=preload("res://scripts/animation/lion_pose_timelines.gd")
const AUDIO=preload("res://scripts/core/lion_audio.gd")
const VISUAL=preload("res://scripts/animation/lion_elder_visual.gd")
const LONG_MOVES=["M04","M08","M12","M18","M19","M20"]
var game
var spec
var kind="boss"
var spawn_id="boss"
var section=0
var dead=false
var active_battle=false
var hp=4600.0
var max_hp=4600.0
var body_height=120.0
var radius=30.0
var facing=-1.0
var phase=1
var phase_shift=0.0
var phase_total=0.0
var phase_walk_duration=0.0
var phase_walk_from=Vector2.ZERO
var phase_drop_position=Vector2.ZERO
var phase_drop_facing=-1.0
var head_prop
var hurt_front=true
var time=0.0
var t=0.0
var windup=0.0
var hurt=0.0
var strike=0.0
var idle=.8
var action=""
var move={}
var arena=Rect2(0,80,960,370)
var audio=AUDIO.new()
var visual
var beats=[]
var fired={}
var victims={}
var history=[]
var shown_moves={}
var damage_log=[]
var event_log=[]
var lock_dir=-1.0
var origin=Vector2.ZERO
var travel=0.0
var recovery=1.0
var stagger_left=0.0
var stagger_kind=""
var phase_moves=0
var since_rest=0
var rest_ready=0.0
# Harmless comic breathers between the sip. Each is [reactions frames, seconds];
# frames swap at the halfway mark. Only the sip can be knocked out of his hands.
const RESTS={"sip":[[12,13],0.0],"rub_waist":[[6,6],.9],"hug_gourd":[[4,5],.95],"pat_knee":[[8,9],.85],"bow":[[10,10],1.0]}
var rest_kind="sip"
var rest_history=[]
var turn_left=0.0
var turn_total=.35
var turn_pending=-1.0
var dead_time=0.0
var low_spoken=false
var ally_seen=false
var opening_bow=false
var step_distance=0.0
var step_side=0
var cancelled=false
var projectile_contact=false
var whiff_ready=0.0
# Range answers. Phase one the lion head catches frontal shots and spits them
# back; phase two the drunk sways out of frontal shots and staggers into your face.
var caught=0
var pending_spit=false
var pending_rush=false
var ranged_ready=0.0
var far_time=0.0
var sway_left=0.0
var sway_ready=0.0
const CALL_MOVE=Color("ffd27a")
const CALL_CATCH=Color("ffb347")
const CALL_SWAY=Color("9fe3ff")
func cfg(key):return game.tuning.get_value("lion_"+key)
func setup(world,id,x):
	game=world;spec=load("res://data/bosses/"+id+".tres")
	position=Vector2(x,450);arena=game.level.arena
	hp=cfg("health");max_hp=hp
func _ready():
	collision_layer=0;collision_mask=0;process_physics_priority=10;z_index=1
	audio.setup(game)
	visual=VISUAL.new();add_child(visual);visual.setup(self)
func _exit_tree():
	audio.clear()
	if is_instance_valid(head_prop):head_prop.queue_free()
func cue(beat,stage):
	audio.cue(action,beat+1,stage)
	event_log.append({"move":action,"beat":beat,"stage":stage,"time":t})
	if event_log.size()>256:event_log.pop_front()
func speak_event(event,priority=false):return audio.speak(event,priority)
func phase_title(_value=0):return "狮先逗人" if phase==1 else "人来逗狮"
func target_node():return game.ally_target(position)
func _physics_process(dt):
	audio.tick(0.0 if game.hitstop>0 else dt)
	if not game.active():
		if game.state in ["dead","title","stage_select"] and not cancelled:
			clear_attacks();cancelled=true
			if game.state=="dead":speak_event("player_death",true)
		return
	if game.hitstop>0:return
	visual.facing=1.0 if facing<0 else -1.0
	time+=dt;hurt=maxf(0,hurt-dt);strike=maxf(0,strike-dt);rest_ready=maxf(0,rest_ready-dt);whiff_ready=maxf(0,whiff_ready-dt);ranged_ready=maxf(0,ranged_ready-dt);sway_left=maxf(0,sway_left-dt);sway_ready=maxf(0,sway_ready-dt)
	visual.tint=preload("res://scripts/combat/hit_feedback.gd").tint(hurt,.12)
	if dead:
		dead_time+=dt
		visual.pose("reactions" if visual.banks.has("reactions") else "backfall",11,true);return
	if not active_battle:
		idle-=dt
		if idle<=0:active_battle=true;idle=.8;game.audio.change_music(game.level.number,true);speak_event("intro",true)
		return
	game.player.position.x=clampf(game.player.position.x,arena.position.x+10,arena.end.x-10)
	if not opening_bow and time>4:opening_bow=speak_event("bow",true)
	if not ally_seen and game.summon.phase=="active":ally_seen=true;speak_event("ally_enter")
	if phase_shift>0:
		phase_shift=maxf(0,phase_shift-dt)
		var elapsed=phase_total-phase_shift
		if elapsed<phase_walk_duration:
			position=phase_walk_from.lerp(phase_drop_position,elapsed/maxf(.001,phase_walk_duration))
			visual.pose("common_lion" if visual.banks.has("common_lion") else "lion",2+int(time*8)%4,true)
		else:
			position=phase_drop_position
			var u=clampf((elapsed-phase_walk_duration)/cfg("phase_safe"),0,1)
			if visual.banks.has("transition"):
				visual.pose("transition",mini(7,int(u*8)),true)
			else:visual.pose("lion",10,true)
		if phase_shift==0:
			place_head()
			visual.pose("common_elder" if visual.banks.has("common_elder") else "backfall",0,true)
		return
	if stagger_left>0:
		stagger_left=maxf(0,stagger_left-dt)
		if visual.banks.has("reactions"):
			var base={"counter_head":0,"counter_gourd":3,"counter_support":7}.get(stagger_kind,7)
			visual.pose("reactions",base+mini(2,int((1-stagger_left/maxf(.001,move.get("stagger_duration",1.25)))*3)),true)
		else:visual.pose("lion" if phase==1 else "backfall",11 if phase==1 else 5,true)
		return
	if turn_left>0:
		turn_left=maxf(0,turn_left-dt)
		var bank="common_lion" if phase==1 else "common_elder"
		if visual.banks.has(bank):visual.pose(bank,mini(9,6+int((1-turn_left/turn_total)*4)),true)
		if turn_left==0:
			facing=turn_pending;visual.facing=1.0 if facing<0 else -1.0
			if visual.banks.has(bank):visual.pose(bank,0,true)
		return
	if action!="":advance_action(dt)
	else:
		idle=maxf(0,idle-dt)
		var bank="common_lion" if phase==1 else "common_elder"
		visual.pose(bank if visual.banks.has(bank) else ("lion" if phase==1 else "backfall"),(10 if hurt_front else 11) if hurt>0 and visual.banks.has(bank) else int(time*2)%2,true)
		if sway_left>0 and phase==2 and visual.banks.has("common_elder"):visual.pose("common_elder",11,true)
		if idle<=0:choose(dt)
	visual.sync_pose(dt)
func clear_attacks(stop_audio=true,remove_projectiles=true):
	if remove_projectiles:game.combat.remove_owner(get_instance_id())
	beats.clear();victims.clear();fired.clear();action="";move={};windup=0;strike=0;travel=0
	if stop_audio:audio.clear()
func begin_phase_shift():
	clear_attacks();caught=0;pending_spit=false;pending_rush=false;far_time=0;sway_left=0;sway_ready=0;phase=2;body_height=86;phase_moves=0;since_rest=0
	phase_walk_from=position
	phase_drop_position=Vector2(arena.position.x+130 if position.x<arena.get_center().x else arena.end.x-130,450)
	phase_walk_duration=absf(phase_drop_position.x-position.x)/cfg("walk_speed")
	if phase_walk_duration>.01:facing=signf(phase_drop_position.x-position.x)
	phase_drop_facing=facing
	phase_total=phase_walk_duration+cfg("phase_safe")+cfg("phase_gap");phase_shift=phase_total
	idle=.2;stagger_left=0;turn_left=0
	game.scene_motion.reset(self);audio.cue("phase_2",1,"material");speak_event("phase_2",true)
func place_head():
	if is_instance_valid(head_prop) or not visual.banks.has("transition"):return
	var data=visual.banks.transition
	if data.pictures.size()<9:return
	head_prop=Sprite2D.new();head_prop.texture=data.pictures[8];head_prop.centered=false
	head_prop.offset=-Vector2(data.anchors[8],data.bounds[8].end.y)
	var unit=120.0/maxf(1,float(data.bounds[0].size.y))*.70
	head_prop.scale=Vector2(-phase_drop_facing*unit,unit);head_prop.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	head_prop.position=phase_drop_position+Vector2(phase_drop_facing*45,0);head_prop.z_index=0
	game.world.add_child(head_prop)
func candidates():
	var signed_distance=(target_node().position.x-position.x)*facing
	var distance=absf(signed_distance)
	var ids=["M01","M02","M03","M06"] if phase==1 and phase_moves<4 else (["M01","M02","M03","M04","M05","M06","M07","M08"] if phase==1 else ["M09","M10","M11","M13"] if phase_moves<4 else ["M09","M10","M11","M12","M13","M14","M15","M16","M17","M18"])
	if phase==1 and phase_moves>=6:ids.append("M19")
	if phase==2 and phase_moves>=4 and hp/max_hp<cfg("finale_fraction"):ids.append("M20")
	var valid=[]
	for id in ids:
		if cfg(id+"_weight")<=0:continue
		if (signed_distance<0)!=(id=="M05"):continue
		# Selection must respect the authored reach, not just a generous AI radius.
		var reach=0.0
		for index in CATALOG.MOVES[id].beats.size():
			var prefix=id+"_"+str(index)+"_"
			var shift=cfg(id+"_travel")
			if id=="M08":shift*=float(index+1)/3.0
			reach=maxf(reach,maxf(absf(cfg(prefix+"near")+shift),absf(cfg(prefix+"far")+shift)))
		if distance>reach+8:continue
		if distance<cfg(id+"_range_min") or distance>cfg(id+"_range_max"):continue
		if not history.is_empty() and (history[-1]==id or (history[-1] in LONG_MOVES and id in LONG_MOVES)):continue
		if id in ["M04","M05","M14"] and (position.x<arena.position.x+cfg("wall_margin") or position.x>arena.end.x-cfg("wall_margin")):continue
		valid.append(id)
	var fresh=valid.filter(func(id):return not history.has(id))
	return fresh if not fresh.is_empty() else valid
func choose(dt=1.0/60.0):
	var target=target_node()
	var direction=signf(target.position.x-position.x) if absf(target.position.x-position.x)>3 else facing
	if direction!=facing:
		if phase==1 and "M05" in candidates():begin("M05");return
		turn_pending=direction;turn_total=cfg("turn_duration");turn_left=turn_total;audio.cue("turn",1,"material");return
	var distance=absf(target.position.x-position.x)
	if phase==1 and pending_spit and ranged_ready<=0:begin_spit(true);return
	if pending_rush and distance<=cfg("rush_stop")+38:pending_rush=false
	if pending_rush and ranged_ready<=0:begin_rush();return
	far_time=far_time+dt if distance>cfg("far_range") else 0.0
	if far_time>=cfg("far_patience") and ranged_ready<=0:
		far_time=0
		if phase==1:begin_spit(false)
		else:begin_rush()
		return
	if phase==2 and since_rest>=cfg("rest_min_moves") and rest_ready<=0:
		if since_rest>=cfg("rest_max_moves") or randf()<.35:begin_rest();return
	var pool=candidates()
	if pool.is_empty():
		# Outside range: walk normally; at close range allow a short non-repeat move.
		if distance>30:
			var speed=cfg("chase_speed") if distance>cfg("far_range") else cfg("walk_speed")
			var old=position.x;position.x=clampf(position.x+facing*speed*dt,arena.position.x+40,arena.end.x-40)
			var bank="common_lion" if phase==1 else "common_elder"
			# All eight authored side-on step frames, so the gait advances a foot per
			# frame instead of looping four poses twice as fast.
			if visual.banks.has(bank):visual.pose(bank,int(time*10)%8,true)
			step_distance+=absf(position.x-old)
			if step_distance>=22:step_distance=0;step_side=1-step_side;audio.cue("step_left" if step_side==0 else "step_right",randi_range(1,3),"material")
			return
		idle=.7;return
	var total=0.0
	for id in pool:total+=cfg(id+"_weight")
	var roll=randf()*total
	for id in pool:
		roll-=cfg(id+"_weight")
		if roll<=0:begin(id);return
	begin(pool[-1])
func begin_rest():
	clear_attacks(false,false);action="rest";t=0;move={};rest_ready=cfg("rest_cooldown");since_rest=0
	# The last three breathers never repeat, so the gag keeps changing.
	var pool=RESTS.keys().filter(func(k):return not rest_history.has(k))
	rest_kind=pool[randi()%pool.size()]
	rest_history.append(rest_kind)
	while rest_history.size()>3:rest_history.pop_front()
	if rest_kind=="sip":speak_event("rest")
	audio.cue("cloth",1,"material")
func rest_length():
	return cfg("rest_duration") if rest_kind=="sip" else RESTS[rest_kind][1]
func shout(text,color,size=18):
	if game.fx.has_method("callout"):game.fx.callout(position-Vector2(0,(150 if phase==1 else 120)),text,color,size)
func begin_spit(arrows):
	clear_attacks(false,false);action="spit";t=0;move={"arrows":arrows};lock_dir=facing
	pending_spit=false;ranged_ready=cfg("ranged_cooldown")
	shout("还给你！" if arrows else "吐灯火！",CALL_CATCH);audio.cue("pounce",1,"warning")
func begin_rush():
	clear_attacks(false,false);action="rush";t=0;lock_dir=facing;origin=position
	# The landing point is promised at the tell, never steered after release.
	var destination=clampf(game.player.position.x-lock_dir*cfg("rush_stop"),arena.position.x+40,arena.end.x-40)
	var distance=clampf((destination-position.x)*lock_dir,0,cfg("rush_speed")*cfg("rush_duration"))
	move={"distance":distance,"duration":distance/cfg("rush_speed")}
	pending_rush=false;ranged_ready=cfg("ranged_cooldown")
	shout("狮子赶场！" if phase==1 else "醉步撞肩！",CALL_SWAY);audio.cue("pounce" if phase==1 else "shuffle",1,"warning")
# Called by combat before a player/brother shot lands. True means no damage.
func answer_projectile(shot):
	if shot.faction!="player" or shot.kind!="arrow":return false
	if dead or not active_battle or phase_shift>0 or stagger_left>0:return false
	# Only shots flying into his face. The back, and any swing already thrown
	# (strike and recovery), stay open: that is how you are meant to hurt him.
	if signf(shot.v.x)!=-facing:return false
	if action in ["rest","rush"]:return false
	if action=="spit" and t>=cfg("spit_windup"):return false
	if action!="" and not beats.is_empty() and t>=beats[0].time:return false
	if phase==1:
		if caught>=int(cfg("catch_limit")):return false
		caught+=1;shout("叼住！",CALL_CATCH,16)
		game.fx.burst(position+Vector2(facing*55,-70),5,CALL_CATCH,60);audio.cue("turn",1,"material")
		if caught>=cfg("catch_limit"):pending_spit=true
		return true
	if ranged_ready>0 or sway_ready>0:return false
	if randf()*100.0>=cfg("sway_chance"):return false
	sway_ready=cfg("sway_cooldown");sway_left=.28;shout("醉闪！",CALL_SWAY,16);audio.cue("cloth",1,"material")
	pending_rush=true
	return true
func begin(id):
	if not CATALOG.MOVES.has(id):return false
	clear_attacks(false,false);cancelled=false;action=id;t=0
	move=CATALOG.MOVES[id].duplicate(true);move.source_dir=facing;origin=position;lock_dir=facing
	travel=cfg(id+"_travel");recovery=cfg(id+"_recovery")*cfg("recovery_scale")
	beats=[]
	var first=cfg(id+"_windup")
	var shift=first-float(move.beats[0][0]);var previous=-1.0
	for index in move.beats.size():
		var prefix=id+"_"+str(index)+"_"
		var at=maxf(previous+.40,cfg(prefix+"time")+shift);previous=at
		var low=cfg(prefix+"low");var high=maxf(low+1,cfg(prefix+"high"))
		beats.append({"time":at,"near":cfg(prefix+"near"),"far":cfg(prefix+"far"),"low":low,"high":high,"damage":cfg(prefix+"damage"),"window":cfg(prefix+"window")})
	windup=beats[0].time
	# Preview poses are explicitly provisional; replace with per-move authored banks.
	var sequence=[]
	for index in beats.size():
		sequence.append({"time":maxf(0,beats[index].time-.38),"index":maxi(0,move.contacts[index]-2)})
		sequence.append({"time":beats[index].time,"index":move.contacts[index],"snap":true})
	sequence.append({"time":beats[-1].time+beats[-1].window,"index":15})
	if visual.banks.has(id) and POSES.TIMES.has(id):
		move.bank=id;sequence=POSES.sequence(id,beats,move,recovery)
	move.poses=sequence
	shout(move.title+"！",CALL_MOVE)
	shown_moves[id]=true;history.append(id)
	while history.size()>int(cfg("history_size")):history.pop_front()
	phase_moves+=1;since_rest+=1;cue(0,"warning");speak_event(move.voice)
	return true
func once(key,at):
	if t<at or fired.has(key):return false
	fired[key]=true;return true
func movement_at(at):
	if beats.is_empty():return 0.0
	var start=beats[0].time;var span=beats[0].window
	if action=="M14":return travel*smoothstep(0,.8,at)
	if action=="M08":
		var distance=0.0
		for b in beats:distance+=travel/3.0*smoothstep(b.time-.16,b.time,at)
		return distance
	return travel*smoothstep(start,start+span,at)
func beat_rect(index,from_x,to_x):
	var b=beats[index];var a=lock_dir*b.near;var z=lock_dir*b.far
	return Rect2(minf(from_x,to_x)+minf(a,z),450-b.high,absf(to_x-from_x)+absf(z-a),b.high-b.low)
func advance_action(dt):
	var before=t;t+=dt
	if action=="spit":
		var wind=cfg("spit_windup")
		if visual.banks.has("common_lion"):visual.pose("common_lion",1 if t<wind else 5,true)
		if once("spit_charge",wind-.22):audio.cue("pounce",1,"charge")
		if once("spit",wind):
			audio.cue("pounce",1,"release")
			var p=game.player.position-Vector2(0,24);var from=position+Vector2(lock_dir*62,-64)
			var aim=(p-from).normalized()
			if aim.x*lock_dir<.3:aim=Vector2(lock_dir,0)
			if move.arrows:
				var count=clampi(caught,1,3);caught=0
				# First arrow dead on, the rest fan out so a jump does not dodge all of them.
				for i in count:
					game.combat.fire(from,aim.rotated([0.0,-.05,.05][i])*cfg("spit_speed")*1.3,cfg("spit_damage")*cfg("damage_scale"),"enemy","arrow",{"owner":get_instance_id(),"life":2.2})
			else:
				game.combat.fire(from,aim*cfg("spit_speed"),cfg("flame_damage")*cfg("damage_scale"),"enemy","flame",{"owner":get_instance_id(),"life":3.0,"radius":18.0})
			audio.cue("effort_hei",1,"effort")
		if once("spit_landing",wind+.12):audio.cue("pounce",1,"landing")
		if once("spit_recover",wind+.16):audio.cue("pounce",1,"recover")
		if t>=wind+cfg("spit_recovery"):
			finish()
			if absf(game.player.position.x-position.x)>cfg("far_range"):pending_rush=true
		return
	if action=="rush":
		var wind=cfg("rush_windup")
		var bank="common_lion" if phase==1 else "common_elder"
		if once("rush_charge",wind-.22):audio.cue("pounce" if phase==1 else "shuffle",1,"charge")
		if t<wind:
			if visual.banks.has(bank):visual.pose(bank,1 if phase==1 else 11,true)
			return
		var elapsed=minf(t-wind,move.duration)
		var old=position.x
		position.x=origin.x+lock_dir*minf(move.distance,elapsed*cfg("rush_speed"))
		if t<wind+move.duration:
			if visual.banks.has(bank):visual.pose(bank,2+int(elapsed*12)%4,true)
			if once("rush_release",wind):audio.cue("pounce" if phase==1 else "shuffle",1,"release")
			var p=game.player
			var contact=Rect2(minf(old,position.x)-30,398,absf(position.x-old)+60,52)
			if not victims.has("rush") and contact.intersects(Rect2(p.position-Vector2(8,38),Vector2(16,38))):
				victims["rush"]=true
				if p.take_damage(cfg("rush_damage")*cfg("damage_scale"),lock_dir,"lion_melee"):
					audio.cue("pounce" if phase==1 else "shuffle",1,"impact")
		else:
			# Overshooting a dodge leaves a visible, punishable recovery.
			if visual.banks.has(bank):visual.pose(bank,5,true)
			if once("rush_landing",wind+move.duration):audio.cue("pounce" if phase==1 else "shuffle",1,"landing")
			if once("rush_recover",wind+move.duration+.04):audio.cue("pounce" if phase==1 else "shuffle",1,"recover")
		if t>=wind+move.duration+cfg("rush_recovery"):finish()
		return
	if action=="rest":
		var frames=RESTS[rest_kind][0]
		if visual.banks.has("reactions"):visual.pose("reactions",frames[0] if t<rest_length()*.47 else frames[1],true)
		else:visual.pose("backfall",1 if t<.7 else 0,true)
		if t>=rest_length():finish()
		return
	if action=="M20" and once("return_lock",beats[-1].time-cfg("turn_duration")):
		lock_dir=-lock_dir;facing=lock_dir
	if action=="M14" and once("return_lock",.8):facing=lock_dir
	var old_x=position.x
	var travel_dir=lock_dir
	position.x=clampf(origin.x+travel_dir*movement_at(t),arena.position.x+40,arena.end.x-40)
	windup=maxf(0,beats[0].time-t)
	visual.sync_pose(0)
	for index in beats.size():
		var b=beats[index]
		if index>0 and once("warning"+str(index),b.time-.40):cue(index,"warning")
		if once("charge"+str(index),maxf(0,b.time-.22)):cue(index,"charge")
		if once("release"+str(index),b.time):
			cue(index,"release");audio.cue("effort_hei",randi_range(1,2),"effort")
		if t>=b.time and before<b.time+b.window:
			strike=.10
			contact(index,beat_rect(index,old_x,position.x))
		if once("landing"+str(index),b.time+b.window):cue(index,"landing")
		if once("recover"+str(index),b.time+b.window+.04):cue(index,"recover")
	if t>=beats[-1].time+beats[-1].window+recovery:finish()
func contact(index,rect):
	if not rect.has_area():return
	var p=game.player;var key=str(index)+":player"
	var player_contact=rect.intersection(Rect2(p.position-Vector2(8,38),Vector2(16,38)))
	if not victims.has(key) and visual.silhouette_intersects(player_contact,position):
		victims[key]=true
		var dodged=p.invincible>0 and p.roll_guard>0
		var landed=p.take_damage(beats[index].damage*cfg("damage_scale"),signf(p.position.x-position.x),"lion_melee")
		if landed:
			cue(index,"impact");damage_log.append({"move":action,"beat":index,"time":t,"rect":rect})
			if beats[index].damage>=22:speak_event("player_heavy")
		elif dodged:speak_event("perfect_dodge")
	var ally=game.summon.brother
	if game.summon.phase!="active" or not is_instance_valid(ally):return
	key=str(index)+":ally"
	if not victims.has(key) and visual.silhouette_intersects(rect.intersection(ally.hurt_rect()),position):
		victims[key]=true
		if ally.take_damage(beats[index].damage*cfg("damage_scale"),lock_dir,"",get_instance_id()):cue(index,"impact")
func finish():
	var peak=0
	for b in beats:peak=maxi(peak,int(b.damage))
	var whiffed=action!="" and not beats.is_empty() and victims.is_empty() and peak>=22
	action="";move={};beats.clear();windup=0;strike=0;idle=.35
	# A heavy swing that touched nobody leaves him embarrassed for a moment. This is
	# the reward for reading the tell and simply walking out, not only for i-frames.
	if whiffed and whiff_ready<=0 and randf()*100.0<cfg("whiff_chance"):
		whiff_ready=cfg("whiff_cooldown")
		stagger("perfect_dodge",cfg("whiff_stagger"));audio.cue("cloth",2,"material")
func stagger(event,duration):
	clear_attacks();stagger_kind=event;stagger_left=duration;move={"stagger_duration":duration};idle=.35
	audio.cue(event,1,"material");speak_event(event,true)
func on_projectile_contact(shot):
	projectile_contact=shot.faction in ["player","brother"]
func take_hit(amount,faction,direction,breaking=false,with_sound=true,with_debris=true):
	var was_projectile=projectile_contact;projectile_contact=false
	if dead or not active_battle or phase_shift>0:return
	hp=maxf(0,hp-amount);hurt=.12;hurt_front=direction*facing<0
	game.fx.hit_mark(position-Vector2(0,body_height*.45),direction,game.GOLD,1.2)
	game.fx.number(position-Vector2(0,body_height),amount,game.TEAL if faction=="brother" else game.GOLD)
	if with_debris:game.fx.burst(position-Vector2(0,35),4,game.GOLD,55)
	if with_sound:audio.cue("hurt",randi_range(1,3),"material")
	if faction=="player":game.player.current_target=self;game.player.reward(amount,hp<=0);game.hitstop=maxf(game.hitstop,.045)
	if hp<=0:
		clear_attacks();dead=true;stagger_left=0;turn_left=0;audio.cue("defeat",1,"material");speak_event("defeat",true)
		game.kills+=1;game.boss_defeated();return
	if phase==1 and hp/max_hp<=cfg("phase_fraction"):begin_phase_shift();return
	if hp/max_hp<cfg("finale_fraction") and not low_spoken:low_spoken=speak_event("low")
	if action in ["M03","M13","M15"]:
		var start=cfg(action+"_break_start");var end=cfg(action+"_break_end")
		var eligible=breaking if action!="M15" else was_projectile
		if eligible and t>=start and t<=end:
			var duration=cfg(action+"_stagger")
			stagger({"M03":"counter_head","M13":"counter_support","M15":"counter_gourd"}[action],duration)
	elif action=="rest" and rest_kind=="sip" and t>=.45 and t<=1.10:stagger("counter_gourd",cfg("rest_stagger"))
	projectile_contact=false
func apply_slow(_duration):pass

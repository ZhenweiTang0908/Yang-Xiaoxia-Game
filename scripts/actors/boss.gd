extends CharacterBody2D
const DIALOGUE=preload("res://scripts/core/boss_dialogue.gd")
var game
var art
var spec
var kind="boss"
var spawn_id="boss"
var dead=false
var active_battle=false
var hp=1000.0
var max_hp=1000.0
var body_height=106.0
var radius=34.0
var facing=-1.0
var phase=1
var phase_shift=0.0
var time=0.0
var cooldown=1.5
var windup=0.0
var hurt=0.0
var strike=0.0
var dead_time=0.0
var move_index=-1
var move={}
var target=Vector2.ZERO
var events=[]
var dash_left=0.0
var dash_velocity=0.0
var leap_left=0.0
var leap_start=Vector2.ZERO
var leap_end=Vector2.ZERO
var shown_moves={}
var arena=Rect2(14300,80,900,370)
var cycle=[]
var beam_high=false
var safe_x=0.0
var breath_face=1.0
var speech_cooldown=0.0
var speech_history=[]
var low_spoken=false
func setup(world,id,x):
	game=world;spec=load("res://data/bosses/"+id+".tres");position=Vector2(x,450)
	if game.level.arena.has_area():arena=game.level.arena
	hp=spec.health;max_hp=hp;body_height=110 if id=="priest" else (94 if id=="duelist" else 90)
func _ready():
	collision_layer=0;collision_mask=1;floor_snap_length=5
	var c=CollisionShape2D.new();var s=CapsuleShape2D.new();s.radius=23;s.height=body_height*.85;c.shape=s;c.position.y=-s.height*.5;add_child(c)
	art=load("res://scripts/actors/boss_art.gd").new();art.actor=self;add_child(art)
	art.configure("res://assets/art/v2/bosses.png",6,3,body_height)
	var row=["lantern","duelist","priest"].find(spec.id);art.scale_unit=body_height/maxf(1,art.bounds[row*6].size.y)
func _physics_process(dt):
	if not game.active() or game.hitstop>0:return
	time+=dt;speech_cooldown=maxf(0,speech_cooldown-dt)
	if dead:
		dead_time+=dt;art.frame=["lantern","duelist","priest"].find(spec.id)*6+5;art.tint.a=maxf(0,1-dead_time/1.3)
		if dead_time>1.4:visible=false;set_physics_process(false)
		return
	if not active_battle:
		if game.player.position.x>arena.position.x+15:
			active_battle=true;game.audio.change_music(game.level.number,true);game.show_hint(spec.title+" · 观察预兆，寻找破绽",4);speak_event("intro",true)
		else:return
	game.player.position.x=clampf(game.player.position.x,arena.position.x+10,arena.end.x-10)
	var next_phase=desired_phase()
	if next_phase>phase:begin_phase_shift(next_phase)
	hurt=maxf(0,hurt-dt);strike=maxf(0,strike-dt)
	facing=signf(game.player.position.x-position.x) if absf(game.player.position.x-position.x)>2 else facing
	var row=["lantern","duelist","priest"].find(spec.id)
	if phase_shift>0:
		phase_shift=maxf(0,phase_shift-dt);velocity=Vector2.ZERO
		art.frame=row*6+1;art.facing=-facing;art.tint=Color("d8c58d") if phase_shift>0 else Color.WHITE
		queue_redraw();return
	for e in events:
		e.delay-=dt
		if e.delay<=0 and not e.done:e.done=true;execute_event(e.type,e.payload)
	events=events.filter(func(e):return not e.done)
	if leap_left>0:
		leap_left=maxf(0,leap_left-dt)
		var t=1-leap_left/.55
		position=leap_start.lerp(leap_end,t)+Vector2(0,-sin(t*PI)*115)
	elif dash_left>0:
		dash_left=maxf(0,dash_left-dt);velocity=Vector2(dash_velocity,0);move_and_slide()
		position.x=clampf(position.x,arena.position.x+40,arena.end.x-40)
	else:
		velocity=Vector2(0,1080*dt);move_and_slide()
	if windup>0:
		windup-=dt
		if windup<=0:release_move()
	else:
		cooldown-=dt
		if cooldown<=0 and events.is_empty() and dash_left<=0 and leap_left<=0:start_next()
	art.frame=row*6+(2 if windup>0 else (3 if strike>0 or dash_left>0 or leap_left>0 else (4 if hurt>0 else int(time*3)%2)))
	if move.get("id","")=="beam" and (windup>0 or strike>0):
		facing=breath_face
		art.frame=14 if windup>0 else 15
	art.motion=Vector2(sin(time*22)*1.1,0) if strike>0 and move.get("id","")=="beam" else Vector2.ZERO
	art.facing=-facing;art.tint=preload("res://scripts/combat/hit_feedback.gd").tint(hurt,.12)
	queue_redraw()
func desired_phase():
	var ratio=hp/maxf(1,max_hp)
	return 3 if spec.id=="priest" and ratio<.3 else (2 if ratio<(.65 if spec.id=="priest" else .5) else 1)
func phase_title(value=phase):
	var titles={
		"lantern":["守灯","灯火暴走"],
		"duelist":["试刃","影刃加速"],
		"priest":["迎月","月蚀初临","噬月终仪"]
	}
	var names=titles.get(spec.id,["第一阶段","第二阶段","第三阶段"])
	return names[clampi(int(value)-1,0,names.size()-1)]
func begin_phase_shift(next_phase):
	phase=next_phase;phase_shift=1.25;windup=0;strike=0;events.clear();dash_left=0;leap_left=0;velocity=Vector2.ZERO;cycle.clear();cooldown=.65
	position.y=450;game.scene_motion.reset(self);game.combat.remove_owner(get_instance_id())
	game.fx.ring(position-Vector2(0,body_height*.55),game.GOLD,82,.8);game.audio.play("boss_release",-1);speak_event("phase_"+str(phase),true)
func start_next():
	if cycle.is_empty():
		for i in spec.moves.size():cycle.append(i)
		if phase>1:cycle.reverse()
		if cycle[0]==move_index:cycle.append(cycle.pop_front())
	start_move(cycle.pop_front())
func start_move(index):
	move_index=index;move=spec.moves[index];windup=move.windup
	speak_event(move.id)
	target=game.ally_target(position).position;shown_moves[move.id]=true
	breath_face=facing
	if move.id=="beam":art.frame=14;art.facing=-breath_face
	beam_high=(int(time)%2==0);safe_x=clampf(target.x+(180 if target.x<arena.get_center().x else -180),arena.position.x+100,arena.end.x-100)
	game.audio.enemy_cue(game.audio.ENEMY_AUDIO.for_actor(self),"warning")
func later(delay,type,payload={}):events.append({"delay":delay,"type":type,"payload":payload,"done":false})
func release_move():
	strike=.45;cooldown=move.recovery+maxf(.55,1.25-phase*.18)
	if move.id not in ["triple","four_slash"]:game.audio.enemy_cue(game.audio.ENEMY_AUDIO.for_actor(self),"release")
	if move.id in ["flash","horn","pounce","leap","triple","four_slash"]:game.audio.exertion(spec.id)
	var damage=float(move.damage)
	match move.id:
		"flash","horn":
			var dir=signf(target.x-position.x)
			dash_velocity=dir*900;dash_left=.32
			var kind="blade_sweep" if spec.id=="duelist" else ("spectral_horn" if spec.id=="priest" else "sweep")
			var cut=game.combat.hazard(Rect2(minf(position.x,target.x)-12,415,absf(target.x-position.x)+65,35),0,.18,damage,get_instance_id(),kind)
			cut.face=dir
		"triple","four_slash":
			var count=4 if move.id=="four_slash" else 3
			for i in count:
				later(i*.38,"close_slash",{"damage":24 if count==4 and i==3 else damage,"step":i})
				later(i*.38+.12,"weapon_air",{"identity":game.audio.ENEMY_AUDIO.for_actor(self)})
		"sweep","low_sweep":
			var cut=game.combat.hazard(Rect2(position.x-115,429,230,21),0,.2,damage,get_instance_id(),"antler_sweep" if spec.id=="lantern" else "blade_sweep")
			cut.face=facing
		"pounce","leap":
			leap_start=position;leap_end=Vector2(clampf(target.x,arena.position.x+45,arena.end.x-45),450);leap_left=.55
			game.combat.hazard(Rect2(leap_end.x-48,398,96,52),.5,.22,damage,get_instance_id(),"stone_impact" if spec.id=="lantern" else "slam")
		"fan":
			var origin=position-Vector2(0,45);var aim=(target-Vector2(0,25)-origin).normalized()
			for a in [-.6,-.3,0,.3,.6]:game.combat.fire(origin,aim.rotated(a)*250,damage,"enemy","blade",{"owner":get_instance_id()})
		"boomerang":game.combat.fire(position-Vector2(0,25),Vector2(facing*400,0),damage,"enemy","blade",{"owner":get_instance_id(),"returning":true,"life":1.4})
		"shadow","rift":
			var at=clampf(target.x+(-75 if target.x>arena.get_center().x else 75),arena.position.x+40,arena.end.x-40)
			game.fx.blink_fold(position-Vector2(0,40),true,Color("cda080"));position=Vector2(at,450);game.scene_motion.reset(self)
			game.fx.blink_fold(position-Vector2(0,40),false,Color("cda080"))
			game.combat.hazard(Rect2(target.x-48,404,96,46),.25,.18,damage,get_instance_id(),"rift")
			if move.id=="shadow":game.combat.hazard(Rect2(target.x+75,404,45,46),.4,.18,damage,get_instance_id(),"shadow")
		"ground_wave":
			for dir in [-1,1]:
				for i in 8:game.combat.hazard(Rect2(position.x+dir*i*48-22,420,44,30),i*.1,1.1 if spec.id=="priest" else .3,damage,get_instance_id(),"ground_rift" if spec.id=="priest" else "stone_wave")
		"lightning":
			for i in 3:later(i*.55,"lightning",{"damage":damage})
		"ring":
			var origin=position-Vector2(0,75)
			# Leave a broad, visible lower-left escape wedge; bullets travel rather than fill the arena.
			for i in 14:
				var a=i*TAU/14
				if a>1.7 and a<2.8:continue
				game.combat.fire(origin,Vector2.from_angle(a)*155,damage,"enemy","ghost_orb",{"owner":get_instance_id(),"life":3.5})
		"homing":
			for i in 3:later(i*.45,"homing",{"damage":damage})
		"beam":
			art.frame=15;art.facing=-breath_face
			var emitter=art.to_global(art.casting_socket(15))
			var beam=game.combat.hazard(Rect2(emitter.x if breath_face>0 else emitter.x-330,emitter.y-20,330,60),0,.85,damage,get_instance_id(),"spirit_beam")
			beam.face=breath_face;beam.staff_emitter=true;strike=.85
		"rain":
			for x in range(int(arena.position.x),int(arena.end.x),60):
				if absf(x-safe_x)<90:continue
				game.combat.hazard(Rect2(x,100,25,350),.25,.2,damage,get_instance_id(),"rain")
		"ritual":
			create_ritual(safe_x,.05,damage)
			later(1.1,"ritual_second",{"damage":damage})
func create_ritual(safe,delay,damage):
	game.combat.hazard(Rect2(arena.position.x,100,maxf(0,safe-75-arena.position.x),350),delay,.25,damage,get_instance_id(),"ritual")
	game.combat.hazard(Rect2(safe+75,100,maxf(0,arena.end.x-safe-75),350),delay,.25,damage,get_instance_id(),"ritual")
func execute_event(type,payload):
	match type:
		"weapon_air":game.audio.enemy_cue(payload.identity,"release")
		"close_slash":
			var dir=signf(game.ally_target(position).position.x-position.x)
			position.x=clampf(position.x+dir*25,arena.position.x+35,arena.end.x-35)
			var cut=game.combat.hazard(Rect2(position.x+(0 if dir>0 else -115),400,115,50),.12,.15,payload.damage,get_instance_id(),"blade_sweep")
			cut.face=dir
		"lightning":game.combat.hazard(Rect2(game.ally_target(position).position.x-23,130,46,320),.6,.18,payload.damage,get_instance_id(),"spirit_lightning")
		"homing":game.combat.fire(position-Vector2(0,60),Vector2(facing*130,-25),payload.damage,"enemy","ghost_orb",{"owner":get_instance_id(),"homing":true,"life":3.2})
		"ritual_second":
			safe_x=clampf(safe_x+(160 if safe_x<arena.get_center().x else -160),arena.position.x+100,arena.end.x-100)
			create_ritual(safe_x,1.2,payload.damage)
func take_hit(amount,faction,direction,_breaking=false,with_sound=true,with_debris=true):
	if dead or not active_battle or phase_shift>0:return
	hp-=amount;hurt=.12
	if hp>0 and hp<max_hp*.25 and not low_spoken:low_spoken=speak_event("low")
	preload("res://scripts/combat/hit_feedback.gd").apply(art,hurt,.12,direction,.65)
	game.fx.hit_mark(position-Vector2(0,body_height*.45),direction,game.GOLD,1.2)
	game.fx.number(position-Vector2(0,body_height),amount,game.TEAL if faction=="brother" else game.GOLD)
	if with_debris:game.fx.burst(position-Vector2(0,35),5,game.GOLD,70)
	if with_sound:game.audio.play("hit_boss",-3)
	if faction=="player":game.player.current_target=self;game.player.reward(amount,hp<=0);game.hitstop=maxf(game.hitstop,.045)
	if hp<=0:
		dead=true;events.clear();game.combat.remove_owner(get_instance_id());game.audio.play("boss_death",0);game.kills+=1;game.boss_defeated();speak_event("death",true)
func speak_event(event,priority=false):
	if not priority and speech_cooldown>0:return false
	var voice=game.audio.voice_player
	if voice.playing and not game.audio.is_boss_voice(game.audio.voice_identity):return false
	var bank=DIALOGUE.BOSSES.get(spec.id,{})
	var pool=bank.get("groups",{}).get(event,[])
	if pool.is_empty():return false
	var last=""
	for index in range(speech_history.size()-1,-1,-1):
		if speech_history[index] in pool:last=speech_history[index];break
	var fresh=pool.filter(func(id):return id!=last)
	if fresh.is_empty():fresh=pool
	var id=fresh[randi()%fresh.size()]
	if not game.say_line(spec.title+"："+bank.lines[id],spec.id+"_"+id):return false
	speech_cooldown=12.0;speech_history.append(id)
	if speech_history.size()>40:speech_history.pop_front()
	return true
func apply_slow(_time):pass
func warning_hint():
	match move.get("id",""):
		"horn":return "冲刺将至 · 离开红色直线"
		"four_slash":return "四连斩 · 远离祭主"
		"ground_wave":return "地裂波 · 跳起躲避"
		"lightning":return "连续落雷 · 保持移动"
		"ring":return "幽火扩散 · 向左下方避让"
		"homing":return "追魂弹 · 留意追踪弹道"
		"beam":return "灵束将至 · 离开红色区域"
		"rain","ritual":return "进入青色安全区"
		"rift":return "换位斩 · 离开锁定区域"
	return ""
func draw_priest_warning():
	var progress=clampf(1-windup/maxf(.001,float(move.windup)),0,1)
	var danger=Color("ff9474")
	var pulse=.75+.2*sin(time*14)
	var zones=[]
	match move.id:
		"horn":zones.append(Rect2(minf(position.x,target.x)-12,415,absf(target.x-position.x)+65,35))
		"four_slash":zones.append(Rect2(position.x-140,400,280,50))
		"ground_wave":zones.append(Rect2(position.x-358,420,716,30))
		"lightning":zones.append(Rect2(game.ally_target(position).position.x-23,130,46,320))
		"rift":zones.append(Rect2(target.x-48,404,96,46))
		"beam":
			var emitter=art.to_global(art.casting_socket(15))
			zones.append(Rect2(emitter.x if breath_face>0 else emitter.x-330,emitter.y-20,330,60))
		"rain":
			for x in range(int(arena.position.x),int(arena.end.x),60):
				if absf(x-safe_x)>=90:zones.append(Rect2(x,100,25,350))
		"ritual":
			zones.append(Rect2(arena.position.x,100,safe_x-75-arena.position.x,350))
			zones.append(Rect2(safe_x+75,100,arena.end.x-safe_x-75,350))
	for zone in zones:
		var rect=Rect2(zone.position-position,zone.size)
		draw_rect(rect,Color(danger,.12+progress*.12))
		draw_rect(rect,Color(danger,pulse),false,2.5)
		var floor_y=rect.end.y-3
		draw_line(Vector2(rect.position.x,floor_y),Vector2(rect.end.x,floor_y),Color("ffe5ac"),3)
	if move.id in ["rain","ritual"]:
		# The inner 130 pixels are safe for both patterns, including the player's width.
		var safe=Rect2(safe_x-65-position.x,100-position.y,130,350)
		draw_rect(safe,Color("8ce8cc",.18))
		draw_rect(safe,Color("a5ffe2",pulse),false,3)
	if move.id in ["ring","homing"]:
		var focus=to_local(art.to_global(art.casting_socket(14)))
		draw_arc(focus,24+progress*12,0,TAU,40,Color(danger,pulse),3)
		if move.id=="ring":
			# Match the actual fixed escape wedge used when the projectiles spawn.
			for angle in [1.7,2.8]:draw_line(focus,focus+Vector2.from_angle(angle)*100,Color("a5ffe2",pulse),3)
		else:
			draw_arc(target-position-Vector2(0,22),18,0,TAU,24,Color(danger,pulse),3)
	var center=Vector2(0,-body_height-18)
	draw_circle(center,11,Color("281e30",.95))
	draw_arc(center,14,-PI/2,-PI/2+TAU*maxf(.01,progress),32,Color("ffe5ac"),3)
	draw_line(center-Vector2(0,6),center+Vector2(0,2),danger,3)
	draw_circle(center+Vector2(0,6),1.8,danger)
func _draw():
	if dead or not active_battle:return
	if phase_shift>0:
		var u=1-phase_shift/1.25;var center=Vector2(0,-body_height*.55)
		for i in 3:draw_arc(center,30+i*13+sin(time*7+i)*3,-PI*.85+u,PI*.85-u,24,Color(game.GOLD,.75-i*.18),2-i*.35)
	if windup>0:
		if spec.id=="priest":
			draw_priest_warning()
			return
		var local_target=target-position
		var c=Color("bbd0cb") if spec.id=="lantern" else Color("efb28f")
		match move.id:
			"flash","horn":
				var tint=Color("9f94be") if move.id=="horn" else c
				var finish=Vector2(local_target.x,-15)
				draw_line(Vector2(0,-15),finish,Color(tint,.30),1)
				var face=signf(local_target.x)
				for i in 3:
					var p=Vector2(lerpf(0,local_target.x,(i+1)/4.0),-15)
					draw_polyline(PackedVector2Array([p-Vector2(face*5,4),p,p-Vector2(face*5,-4)]),Color(tint,.48),1)
			"leap","pounce","shadow":draw_rect(Rect2(local_target.x-42,450-position.y-3,84,3),c)
			"ring":
				var focus=to_local(art.to_global(art.casting_socket(14)))
				var pulse=.55+.25*sin(time*12)
				for i in 6:
					var angle=i*TAU/6+time*.8
					if angle>1.7 and angle<2.8:continue
					var p=focus+Vector2.from_angle(angle)*(14+windup*5)
					draw_arc(p,2.5,0,TAU,7,Color("a99bc7",pulse),1)
				draw_arc(focus,10,PI*.15,TAU-PI*.15,16,Color("7f719d",.35),1)
			"homing":
				var lock=local_target-Vector2(0,22);var size=9+sin(time*14)*1.5
				var tint=Color("a99bc7",.55+.2*sin(time*11))
				draw_polyline(PackedVector2Array([lock+Vector2(-size,0),lock+Vector2(0,-size*.65),lock+Vector2(size,0),lock+Vector2(0,size*.65),lock+Vector2(-size,0)]),tint,1)
				draw_circle(lock,1.5,Color("e2e4ef",.8))
			"rift":
				var ground=450-position.y
				var crack=PackedVector2Array([Vector2(local_target.x,ground),Vector2(local_target.x-2,ground-7),Vector2(local_target.x+2,ground-14),Vector2(local_target.x-1,ground-22)])
				draw_polyline(crack,Color("9e91bd"),1.3)
			"beam":
				var focus=to_local(art.to_global(art.casting_socket(14)))
				draw_circle(focus,3+sin(time*15)*.6,Color("a99bc7"))
				var release=to_local(art.to_global(art.casting_socket(15)))
				var end=Vector2(release.x+breath_face*330,-5)
				draw_line(Vector2(release.x,-9),end-Vector2(0,4),Color("7f719d",.42),1)
				draw_line(Vector2(release.x,-1),end+Vector2(0,4),Color("7f719d",.42),1)
			"rain":draw_rect(Rect2(safe_x-65-position.x,450-position.y-9,130,9),Color("8cd8bd"))
			"ritual":
				var ground=450-position.y
				var left=safe_x-65-position.x;var right=safe_x+65-position.x
				draw_polyline(PackedVector2Array([Vector2(left-10,ground-2),Vector2(left,ground-2),Vector2(left,ground-12)]),Color("9b8fbc"),1.5)
				draw_polyline(PackedVector2Array([Vector2(right+10,ground-2),Vector2(right,ground-2),Vector2(right,ground-12)]),Color("9b8fbc"),1.5)
				draw_arc(Vector2((left+right)*.5,ground-8),7,-PI*.15,PI*.85,8,Color("c3c9d7"),1)

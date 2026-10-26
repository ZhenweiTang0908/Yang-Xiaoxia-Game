extends CharacterBody2D
# 断誓枪骑 · a mounted first phase, then a foot duel. Every threat is read from the
# knight's own body (lance, reins, shoulder, bowstring, spinning spear) and its sound.
# It never draws danger boxes, aim lines, exclamation marks or countdowns.
const GROUND=450.0
const ARROW_SPEED=780.0
const EMPOWERED_ARROW_SPEED=1100.0
const ARROW_DAMAGE=8.0
const EMPOWERED_ARROW_DAMAGE=12.0
# Spear waves hit a low band 2–12 px above the floor across the whole arena.
const WAVE_LOW=2.0
const WAVE_HIGH=12.0
const WAVE_PREP=.42
const WAVE_DAMAGE=24.0
const DISMOUNT_RISE=.45
const DISMOUNT_LAND=.9
const DISMOUNT_TOTAL=2.5
const SWITCH_TIME=.5
const GUARD_TIME=.7
const ADVANCE_GAP=.5
const KICK_FOLLOWUP=.85
const BOW_FOLLOWUP=.9
# Dash-in techniques hit slightly harder; their wind-up times stay unchanged.
const DASH_DAMAGE=1.08
const WAVE_DIRECT_CHANCE=.07
const PRESSURE_MOVES=["spin_rush","spear_return","triple_dash","bow_volley","spear_slam"]
const SPEAR=preload("res://scripts/actors/knight_spear.gd")
const DIALOGUE=preload("res://scripts/core/knight_dialogue.gd")
const LONG_COMBOS=["double_charge","advance","kick_thrust","bow_double","wave","spin_rush","triple_dash","bow_volley","spear_chain","dragon_sweep","dragon_rise","dragon_break"]
const NEW_MOVES=["advance","uppercut","lunge","kick_thrust","bow_double"]
const SOUNDS={"paw":"knight_hoof_paw","gallop":"knight_gallop","neigh":"knight_neigh","skid":"knight_skid","stomp":"knight_hoof_slam","kick":"knight_kick","armor":"knight_armor","lance":"knight_lance","press":"knight_butt","thrust":"knight_thrust","wave_raise":"knight_wave_raise","wave":"knight_wave","bow_draw":"knight_bow_draw","bow_shot":"knight_bow_release","guard":"knight_guard","clang":"knight_parry","switch":"knight_switch","dust":"knight_dust","land":"knight_land","snort":"knight_snort","step_a":"knight_armor_step_a","step_b":"knight_armor_step_b","ghost_summon":"knight_ghost_summon","ghost_rise":"knight_ghost_rise","ghost_glide":"knight_ghost_glide","ghost_fade":"knight_ghost_fade"}
var game
var spec
var kind="boss"
var spawn_id="boss"
var section=0
var dead=false
var active_battle=false
var intro=1.0
var hp=2400.0
var max_hp=2400.0
var body_height=148.0
var radius=52.0
var facing=-1.0
var phase=1
var phase_shift=0.0
var dismount_t=-1.0
var landed=false
var time=0.0
var hurt=0.0
var dead_time=0.0
var arena=Rect2(0,80,960,370)
var move={}
var windup=0.0
var action=""
var t=0.0
var fired={}
var idle=1.2
var history=[]
var pending=""
var lock_dir=1.0
var speed=0.0
var stop_t=0.0
var hit_box=null
var lance_damage=24.0
var behind_time=0.0
var turn_anim=0.0
var turn_total=.3
var weapon="spear"
var next_weapon=""
var wave_uses=0
var sets_since_wave=99
var wave_times=[]
var wave_fx=[]
var strike_fx=[]
var aim=Vector2.RIGHT
var guard_triggered=false
var counter_pending=false
var dust_age=-1.0
var horse_x=0.0
var horse_away=-1.0
var stride=0.0
var walking=false
var shown_moves={}
var damage_log=[]
var visual
var recovering_move=""
var recover_time=0.0
var hoof_step=-1
var speech_cooldown=0.0
var speech_history=[]
var low_spoken=false
var catch_flash=0.0
var soul
var spear
var empowered=false
var ancient_pending=null
var ancient_target=null
var flight_from=Vector2.ZERO
var queued_empower=false
var foot_travel=0.0
var step_clock=0.0
var step_side=0
var snort_clock=3.0
var motion_trail=[]
var trail_clock=0.0
func setup(world,id,x):
	game=world;spec=load("res://data/bosses/"+id+".tres");position=Vector2(x,GROUND)
	if game.level.arena.has_area():arena=game.level.arena
	hp=cfg("knight_mount_hp");max_hp=hp
func cfg(key):return game.tuning.get_value(key)
func _ready():
	collision_layer=0;collision_mask=0
	# Runs after the player so spear waves test the hero's moved collision box this frame.
	process_physics_priority=10
	z_index=1
	visual=preload("res://scripts/animation/knight_visual.gd").new();visual.actor=self;add_child(visual)
	soul=preload("res://scripts/actors/knight_soul.gd").new();soul.actor=self;add_child(soul)
	spear=SPEAR.new();spear.actor=self
func sound(key,volume=-4.0):
	if not SOUNDS.has(key):return
	var warning=key in ["paw","armor","wave_raise","bow_draw","guard","switch","snort","step_a","step_b","ghost_rise","ghost_glide","ghost_fade"]
	game.audio.physical_cue(SOUNDS[key],"warning" if warning else "release",volume+(6 if warning else 0))
func move_sound(stage,volume=0.0):
	game.audio.enemy_cue("knight:"+action,stage,volume)
# A short battle shout on most blows, throttled by the audio director.
func shout(chance=.8):
	if randf()<chance:game.audio.exertion("knight")
func enter_foot_challenge():
	phase=2;landed=true;body_height=106;radius=24;weapon="spear"
	hp=cfg("knight_foot_hp");max_hp=hp;horse_away=-1;idle=.4
func speak(id,priority=false):
	if not DIALOGUE.LINES.has(id):return false
	if not priority and speech_cooldown>0:return false
	var voice=game.audio.voice_player
	if voice.playing and not game.audio.is_boss_voice(game.audio.voice_identity):return false
	if not game.say_line("断誓枪骑："+DIALOGUE.LINES[id],"knight_"+id):return false
	game.subtitle_time=clampf(voice.stream.get_length()+.4,2.0,6.0)
	speech_cooldown=12.0;speech_history.append(id)
	if speech_history.size()>40:speech_history.pop_front()
	return true
func speak_event(event,priority=false):
	var pool=DIALOGUE.GROUPS.get(event,[event])
	var last=""
	for index in range(speech_history.size()-1,-1,-1):
		if speech_history[index] in pool:last=speech_history[index];break
	var fresh=pool.filter(func(id):return id!=last)
	if fresh.is_empty():fresh=pool
	return speak(fresh[randi()%fresh.size()],priority)
func target_node():return game.ally_target(position)
func target_dx():return target_node().position.x-position.x
func face_target():
	var dx=target_dx()
	if absf(dx)>3:facing=signf(dx)
func margin():return 66.0 if phase==1 else 30.0
func _physics_process(dt):
	if not game.active() or game.hitstop>0:return
	for trail in motion_trail:trail.age+=dt
	motion_trail=motion_trail.filter(func(trail):return trail.age<.20)
	var old_position=position.x
	soul.advance(dt)
	time+=dt;speech_cooldown=maxf(0,speech_cooldown-dt);catch_flash=maxf(0,catch_flash-dt)
	for w in wave_fx:w.age+=dt
	wave_fx=wave_fx.filter(func(w):return w.age<.12)
	for s in strike_fx:s.age+=dt
	strike_fx=strike_fx.filter(func(s):return s.age<s.life)
	if dust_age>=0:dust_age+=dt;if dust_age>1.1:dust_age=-1
	if horse_away>=0:horse_away+=dt
	self_modulate=Color(1,.82,.74) if hurt>0 else Color.WHITE
	if dead:
		dead_time+=dt;self_modulate.a=maxf(0,1-dead_time/1.4);visual.sync_pose(dt);queue_redraw();return
	if not active_battle:
		intro-=dt;face_target()
		if intro<=0:
			active_battle=true;game.audio.change_music(game.level.number,true)
			game.show_hint(spec.title+" · 看清抬手与声音，再出手",4);sound("neigh",-3);speak_event("intro" if phase==1 else "foot",true)
		visual.sync_pose(dt);queue_redraw();return
	hurt=maxf(0,hurt-dt);turn_anim=maxf(0,turn_anim-dt);windup=maxf(0,windup-dt)
	game.player.position.x=clampf(game.player.position.x,arena.position.x+10,arena.end.x-10)
	walking=false
	if dismount_t>=0:update_dismount(dt)
	elif action!="":
		t+=dt;call("act_"+action,dt)
	else:idle_tick(dt)
	if action!="ancient_spear":position.y=GROUND
	position.x=clampf(position.x,arena.position.x+margin(),arena.end.x-margin())
	visual.sync_pose(dt)
	trail_clock+=dt
	if absf(position.x-old_position)>dt*250 and trail_clock>=.04 and visual.selected:
		motion_trail.append({"x":position.x,"age":0.0,"dir":facing,"art":visual.selected,"frame":visual.selected_frame});trail_clock=0
	foot_sounds(dt,old_position)
	queue_redraw()
# Armour clinks while walking on foot; the horse snorts while it waits.
func foot_sounds(dt,old_position):
	step_clock=maxf(0,step_clock-dt)
	if phase==2 and landed and dismount_t<0:
		foot_travel+=absf(position.x-old_position)
		if foot_travel>=40 and step_clock<=0:
			foot_travel=0;step_clock=.17;step_side=1-step_side
			sound("step_a" if step_side==0 else "step_b",-8)
	elif phase==1 and action=="":
		snort_clock-=dt
		if snort_clock<=0:snort_clock=randf_range(3.5,6.5);sound("snort",-7)
# ---------------------------------------------------------------- selection
func idle_tick(dt):
	idle-=dt;recover_time+=dt
	if recover_time<.28:return
	var dx=target_dx();var behind=dx*facing<0
	if phase==1:
		if behind and absf(dx)<125:behind_time+=dt
		else:behind_time=0
		# A rider far behind wheels the horse round; one standing close behind is kicked
		# only after lingering, never the instant they step there.
		if behind and absf(dx)>=125 and turn_anim<=0:turn(.3)
	else:
		if behind and absf(dx)>4 and turn_anim<=0:turn(.15)
		# Recover in place, then attack the gap; never spend seconds slowly walking.
		if absf(dx)>220 and recover_time>=.55:idle=0
	if idle<=0:choose()
func turn(duration):
	facing=-facing;turn_anim=duration;turn_total=duration
	sound("skid" if phase==1 else "armor",-9)
func allowed(id):
	return not (history.size()>=2 and history[-1]==id and history[-2]==id)
func pick(options):
	var valid=options.filter(func(o):return allowed(o))
	if valid.is_empty():valid=options
	var fresh=valid.filter(func(o):return not history.has(o))
	var pool=fresh if not fresh.is_empty() else valid
	return pool[randi()%pool.size()]
func without_chained_combos(options):
	if not history.is_empty() and history[-1] in LONG_COMBOS:
		return options.filter(func(id):return id not in LONG_COMBOS)
	return options
func choose():
	if phase==1:
		choose_mounted();return
	if is_instance_valid(ancient_pending):
		var ally=ancient_pending
		ancient_pending=null
		if not ally.dead and game.summon.phase=="active" and ally==game.summon.brother and ally.pinned_left<=0:
			ancient_target=weakref(ally);start_move("ancient_spear");return
	var cells=soul.ready_cells()
	# A full bar always calls the ghost regiment; two cells call it half the time,
	# otherwise one cell is spent to empower an ordinary attack.
	if cells>=3 or (cells==2 and randf()<.5):
		face_target();start_move("soul_legion");return
	if cells==2:soul.spend_cell();queued_empower=true
	var dist=absf(target_dx())
	face_target()
	# The spear-wave set can open any exchange, at any range, but never twice in a row.
	if sets_since_wave>=1 and randf()<WAVE_DIRECT_CHANCE:
		start_move("wave");return
	var options=[]
	if dist<75:options=["butt_spin","thrust","guard","kick_thrust","spear_slam","spear_chain","dragon_sweep","wave"]
	elif dist<155:options=["thrust","guard","kick_thrust","spear_slam","lunge","spear_chain","dragon_rise","dragon_sweep","wave"]
	elif dist<310:options=["lunge","spin_rush","triple_dash","spear_return","bow_double","wave","dragon_break"]
	else:options=["spin_rush","triple_dash","spear_return","bow_volley","bow_double","bow","wave","dragon_break"]
	if target_node().position.y<GROUND-50 and dist<200:options.append("dragon_rise")
	# Do not repeat the arena-wide finisher immediately after a wave sequence.
	if not history.is_empty() and history[-1] in ["wave","dragon_break"]:options=options.filter(func(id):return id!="dragon_break")
	if sets_since_wave<1:options=options.filter(func(id):return id!="wave")
	options=without_chained_combos(options)
	start_move(pick(options))
# Mounted duel: hooves, lance and horse only. Rage, ghosts and spear waves wait
# for the foot phase.
func choose_mounted():
	var dx=target_dx();var dist=absf(dx);var front=dx*facing>=0
	if not front and dist<125:
		if behind_time>=.6 and allowed("kick"):start_move("kick")
		elif behind_time>=.6:start_move("charge")
		else:idle=.6-behind_time
		return
	if not front:turn(.3);idle=.35;return
	var options=[]
	if dist<100:options=["butt","rear","advance","trample"]
	elif dist<210:options=["rear","advance","charge","trample","halt_thrust"]
	else:options=["charge","double_charge","halt_thrust","trample"]
	if dist<190:
		options.append("uppercut")
		if target_node().position.y<GROUND-32:options.append("uppercut")
	options=without_chained_combos(options)
	start_move(pick(options))
const TITLES={"charge":"骑枪掠袭","double_charge":"往返冲杀","halt_thrust":"急停突刺","trample":"冲阵踏蹄","rein":"勒马折返","rear":"前蹄重踏","kick":"后蹄蹬踢","butt":"枪柄压击","thrust":"测距点刺","butt_spin":"枪尾回敲","guard":"绞枪架势","counter":"绞枪反刺","wave":"三叠枪气","bow":"定弦直射","switch":"换持武器","stagger":"架势被破","advance":"三步逼阵","uppercut":"回缰挑枪","lunge":"贯甲进刺","kick_thrust":"蹬踢接刺","bow_double":"退步双矢","spin_rush":"旋枪破阵","spear_return":"回锋掷矛","triple_dash":"三折追刺","bow_volley":"追猎三矢","spear_slam":"踏进重挑","soul_legion":"幽军降阵","ancient_spear":"上古镇魂枪","spear_chain":"刺进连挑","dragon_sweep":"蛟龙扫阵","dragon_rise":"伏龙旋挑","dragon_break":"龙王破阵"}
func weapon_for(id):return "bow" if id in ["bow","bow_double","bow_volley"] else "spear"
func start_move(id):
	if phase==2 and weapon_for(id)!=weapon:
		# Changing weapons is a visible, harmless half-second action.
		pending=id;next_weapon=weapon_for(id);begin("switch",SWITCH_TIME,false);sound("switch",-6);return
	begin(id,prep_for(id))
	if id!="wave":sets_since_wave+=1
func prep_for(id):
	if id=="soul_legion":return .9
	if id=="ancient_spear":return 1.1
	if id in SPEAR.MOVES:return cfg("knight_"+id+"_windup")+(.08 if empowered else 0)
	if id in NEW_MOVES or id in PRESSURE_MOVES:return cfg("knight_"+id+"_windup")+(.1 if empowered else 0)
	match id:
		"charge":return cfg("knight_charge_windup")
		"rein":return cfg("knight_turn_windup")
		"double_charge":return cfg("knight_charge_windup")+.1
		"halt_thrust":return .6
		"trample":return .55
		"rear":return cfg("knight_rear_windup")
		"kick":return cfg("knight_kick_windup")
		"butt":return cfg("knight_butt_windup")
		"thrust":return cfg("knight_thrust_windup")
		"counter":return .45
		"butt_spin":return .5
		"guard":return GUARD_TIME
		"wave":return (.54 if empowered else WAVE_PREP)
		"bow":return cfg("knight_bow_draw")+(.1 if empowered else 0)
	return 0.0
func begin(id,prep,record=true):
	empowered=false
	if id=="soul_legion":soul.spend();queued_empower=false
	elif phase==2 and id not in ["switch","stagger","guard","ancient_spear"]:empowered=queued_empower or soul.consume();queued_empower=false
	if id in NEW_MOVES or id in PRESSURE_MOVES or id in SPEAR.MOVES or id in ["bow","wave"]:prep=prep_for(id)
	if id=="ancient_spear":
		end_box();flight_from=position;game.audio.enemy_cue("knight:"+id,"warning",-3)
	action=id;t=0;fired={};windup=prep;move={"id":id,"title":TITLES.get(id,id)};shown_moves[id]=true
	if id in NEW_MOVES or id in PRESSURE_MOVES or id in SPEAR.MOVES:lock_dir=facing;move_sound("warning",-2)
	if id in ["spin_rush","spear_return","triple_dash","bow_volley","wave","lunge","counter","guard","stagger","soul_legion","ancient_spear","bow","bow_double","spear_slam","kick_thrust"] or id in SPEAR.MOVES:speak_event(id)
	if record:
		history.append(id)
		if history.size()>6:history.pop_front()
	match id:
		"charge":lock_dir=facing;lance_damage=24*DASH_DAMAGE;speed=0;sound("paw",-6)
		"rein":lance_damage=22*DASH_DAMAGE;speed=0;sound("neigh",-4)
		"rear":sound("neigh",-5)
		"kick","butt":sound("armor",-7)
		"thrust","counter":sound("armor",-8)
		"butt_spin":sound("switch",-9)
		"guard":guard_triggered=false;counter_pending=false;sound("guard",-6)
		"wave":
			sets_since_wave=0
			var gap=maxf(1.0,cfg("knight_wave_gap")) if empowered else cfg("knight_wave_gap");var late=cfg("knight_wave_late")
			# First set on foot is even, the second delays the third thrust, then mixed.
			var delayed=wave_uses==1 or (wave_uses>1 and randf()<.5)
			wave_uses+=1
			wave_times=[.54,.54+gap,.54+gap*2+.25,.54+gap*3+.25,.54+gap*4+.8] if empowered else [WAVE_PREP,WAVE_PREP+gap,WAVE_PREP+gap+(late if delayed else gap)]
			move.delayed=delayed
		"bow":sound("bow_draw",-5)
func once(key,at):
	if t>=at and not fired.has(key):fired[key]=true;return true
	return false
func finish(recover):
	recovering_move=action;recover_time=0;empowered=false
	end_box();action="";windup=0;idle=maxf(.45,recover*cfg("knight_recovery_scale")*(.75 if phase==2 else .9))
func end_box():
	if hit_box!=null:hit_box.rect=Rect2();hit_box.duration=0;hit_box=null
func span(near,far,top,bottom=0.0,dir=facing):
	var a=position.x+dir*near;var b=position.x+dir*far*(1.23 if empowered and phase==2 and near>=0 else 1.0)
	return Rect2(minf(a,b),GROUND-top,absf(b-a),top-bottom)
func scaled_damage(amount):
	return amount*cfg("knight_damage_scale")
func strike(rect,duration,damage,source,seal=0.0):
	var h=game.combat.hazard(rect,0,duration,scaled_damage(damage)*(1.12 if empowered else 1.0),get_instance_id(),source)
	shout()
	h.invisible=true;h.sounded=true;h.seal=seal
	return h
func travel_interval(dt,start,end,speed,dir):
	# Integrate only the overlap with this action window, independent of frame rate.
	var overlap=maxf(0,minf(t,end)-maxf(t-dt,start))
	position.x=clampf(position.x+dir*speed*overlap,arena.position.x+margin(),arena.end.x-margin())
# ---------------------------------------------------------------- additional physical techniques
func act_advance(dt):
	var prep=prep_for("advance")
	# Empowered: a fourth step closes the gap the hero opened.
	var steps=4 if empowered else 3
	for i in steps:
		var at=prep+i*ADVANCE_GAP
		travel_interval(dt,at-.18,at,28.0/.18,lock_dir)
		if i>0 and once("step_ready"+str(i),at-.3):windup=.3;move_sound("warning",-5)
		if once("step"+str(i),at):
			strike(span(22,100,42,0,lock_dir),.12,cfg("knight_advance_damage"),"knight_advance")
			move_sound("release");game.fx.burst(position+Vector2(lock_dir*65,-2),5,Color("9b8a70"),48)
	if t>=prep+(steps-1)*ADVANCE_GAP+.18:finish(.95)
func act_uppercut(dt):
	var prep=prep_for("uppercut")
	travel_interval(dt,0,.3,180,-lock_dir)
	if once("lift",prep):
		strike(span(10,154,168,48,lock_dir),.12,cfg("knight_uppercut_damage"),"knight_uppercut")
		move_sound("release")
		if empowered:soul.queue_soldiers()
	if t>=prep+.16:finish(1.0)
func approach_interval(dt,start,end,speed,dir,stop_distance):
	var overlap=maxf(0,minf(t,end)-maxf(t-dt,start))
	var gap=maxf(0,target_dx()*dir-stop_distance)
	position.x=clampf(position.x+dir*minf(gap,speed*overlap),arena.position.x+margin(),arena.end.x-margin())
func dash_strike(dt,start,duration,speed,damage,key,reach=142.0,top=52.0,bottom=6.0):
	var end=start+duration
	if empowered:reach*=1.23
	if once(key,start):
		end_box();hit_box=strike(Rect2(),duration+.2,damage*DASH_DAMAGE,"knight_"+action)
		move_sound("release");pressure_flash("rush",.32)
		if empowered and action!="spin_rush" and not fired.has("soul_soldiers"):
			fired.soul_soldiers=true;soul.queue_soldiers()
	var old=position.x
	travel_interval(dt,start,end,speed,lock_dir)
	if hit_box!=null and t>=start and t-dt<=end:
		var near=old+lock_dir*12;var far=position.x+lock_dir*reach
		hit_box.rect=Rect2(minf(near,far),GROUND-top,absf(far-near),top-bottom)
		if once(key+"dust"+str(int((t-start)*18)),start):game.fx.burst(position+Vector2(-lock_dir*25,-3),3,Color("bbaa86"),55)
	if t-dt>=end:end_box()
func lock_for_dash(key,at):
	if once(key,at):face_target();lock_dir=facing;windup=.3;move_sound("warning",-4)
func pressure_flash(kind,life=.32):
	strike_fx.append({"kind":kind,"age":0.0,"life":life,"dir":facing,"x":position.x})
func act_spear_chain(dt):spear.advance(dt)
func act_dragon_sweep(dt):spear.advance(dt)
func act_dragon_rise(dt):spear.advance(dt)
func act_dragon_break(dt):spear.advance(dt)
func act_lunge(dt):
	var prep=prep_for("lunge")
	lock_for_dash("lock",prep-.24)
	dash_strike(dt,prep,.42,cfg("knight_dash_speed"),cfg("knight_lunge_damage"),"drive",142,43,15)
	if t>=prep+.56:finish(.7)
func act_spin_rush(dt):
	var prep=prep_for("spin_rush")
	lock_for_dash("lock",prep-.24)
	dash_strike(dt,prep,.64,cfg("knight_spin_speed")*(1.12 if empowered else 1.0),cfg("knight_spin_rush_damage"),"spin",92,100,4)
	if empowered and once("echo",prep):soul.queue_echo()
	if t>=prep and t<prep+.64:
		if once("spin_sound"+str(int((t-prep)/.16)),prep):sound("lance",-4)
	if t>=prep+.78:finish(.85)
func pursuit_times():
	var prep=prep_for("triple_dash")
	return [prep,prep+.92,prep+2.05,prep+2.92,prep+4.22] if empowered else [prep,prep+.88,prep+1.76]
func act_triple_dash(dt):
	var times=pursuit_times()
	for i in times.size():
		var at=times[i]
		if t>=at-.34 and t<at+.38:
			lock_for_dash("lock"+str(i),at-.30)
			dash_strike(dt,at,.30,cfg("knight_triple_speed"),cfg("knight_triple_dash_damage"),"drive"+str(i),136,50,8)
	if t>=times[-1]+.45:finish(1.0)
func spear_in_flight():
	return game.combat.shots.any(func(shot):return shot.owner==get_instance_id() and shot.kind=="knight_spear")
func act_spear_return(dt):
	var prep=prep_for("spear_return")
	lock_for_dash("lock",prep-.24)
	approach_interval(dt,prep-.2,prep,320,lock_dir,130)
	if once("throw",prep):
		game.combat.fire(position+Vector2(lock_dir*42,-32),Vector2(lock_dir*cfg("knight_throw_speed"),0),scaled_damage(cfg("knight_spear_return_damage")),"enemy","knight_spear",{"owner":get_instance_id(),"life":3.2,"returning":true,"return_after":.72,"radius":31 if empowered else 24})
		game.combat.shots[-1].empowered=empowered
		move_sound("release");pressure_flash("throw",.28);shout(1.0)
		if empowered:soul.queue_echo()
	if t>prep+.3 and not spear_in_flight():
		if once("catch",prep):catch_flash=.24;sound("armor",-2);pressure_flash("catch",.3)
		finish(.55)
	elif t>=prep+3.25:finish(.6)
func act_spear_slam(dt):
	var prep=prep_for("spear_slam")
	lock_for_dash("lock",prep-.3)
	approach_interval(dt,prep-.3,prep,720,lock_dir,70)
	if once("slam",prep):
		strike(span(6,154,142,0,lock_dir),.14,cfg("knight_spear_slam_damage")*DASH_DAMAGE,"knight_spear_slam")
		move_sound("release");pressure_flash("sweep",.32)
		if empowered:soul.queue_soldiers()
		game.shake=maxf(game.shake,4)
		game.fx.burst(position+Vector2(lock_dir*100,-4),12,Color("d6c08c"),100)
	if t>=prep+.2:finish(.85)
func bow_times(id):
	var prep=prep_for(id)
	if id=="bow_volley":return [prep,prep+.52,prep+1.12,prep+1.67,prep+2.35] if empowered else [prep,prep+.55,prep+1.18]
	if id=="bow_double":return [prep,prep+.40,prep+.84,prep+1.42,prep+1.84,prep+2.36,prep+2.82] if empowered else [prep,prep+.43,prep+.99,prep+1.43,prep+2.04]
	return [prep,prep+.4,prep+.8,prep+1.2,prep+1.6,prep+2.0] if empowered else [prep,prep+.43,prep+.86,prep+1.29]
func bow_releasing(at):
	for release in bow_times(action):
		if at>=release and at<release+.15:return true
	return false
func run_bow(dt,id):
	var times=bow_times(id)
	if id=="bow_double":travel_interval(dt,0,.22,250,-lock_dir)
	elif id=="bow_volley":travel_interval(dt,0,.18,360,-lock_dir if absf(target_dx())<240 else lock_dir)
	for i in times.size():
		var at=times[i];var ready=0.0 if i==0 else times[i-1]+.15
		if t>=ready and t<at-.18:aim_bow()
		if i>0 and once("draw"+str(i),ready):windup=at-ready;sound("bow_draw",-8)
		if once("arrow"+str(i),at):
			for angle in ([-.14,0.0,.14] if id=="bow_volley" else [0.0]):
				release_arrow("knight:"+id,angle)
			move_sound("release");pressure_flash("bow",.24)
	if t>=times[-1]+.18:finish(.8)
func act_bow_volley(dt):run_bow(dt,"bow_volley")
func act_kick_thrust(dt):
	var prep=prep_for("kick_thrust");var second=prep+KICK_FOLLOWUP
	approach_interval(dt,prep-.2,prep,500,lock_dir,42)
	approach_interval(dt,second-.25,second,650,lock_dir,80)
	if once("kick",prep):
		strike(span(8,65,62,0,lock_dir),.1,cfg("knight_kick_thrust_damage"),"knight_boot")
		move_sound("release")
	if once("draw",second-.5):windup=.5;move_sound("warning",-2)
	if once("follow",second):
		strike(span(12,142,43,15,lock_dir),.1,cfg("knight_kick_thrust_damage")*2,"knight_follow_thrust")
		sound("thrust",-3)
		if empowered:soul.queue_soldiers()
	if t>=second+.15:finish(.85)
func aim_bow():
	face_target()
	var node=target_node()
	var travel=clampf(absf(node.position.x-position.x)/(EMPOWERED_ARROW_SPEED if empowered else ARROW_SPEED),.08,.6)
	var lead=clampf(node.velocity.x*travel,-135,135)
	var target=node.position+Vector2(lead,-21)
	var dir=(target-bow_origin()).normalized()
	var angle=clampf(Vector2(dir.x*facing,dir.y).angle(),-.6,.6)
	aim=Vector2(cos(angle)*facing,sin(angle))
func release_arrow(identity,spread=0.0):
	var shot=game.combat.fire(bow_origin(),aim.rotated(spread)*(EMPOWERED_ARROW_SPEED if empowered else ARROW_SPEED),(EMPOWERED_ARROW_DAMAGE if empowered else ARROW_DAMAGE),"enemy","knight_arrow",{"owner":get_instance_id(),"life":2.2})
	shout(.5)
	shot.seal=cfg("knight_hit_seal");shot.attack_sound=identity;shot.empowered=empowered;shot.radius=19 if empowered else 13
	soul.queue_echo()
func act_bow_double(dt):run_bow(dt,"bow_double")
# ---------------------------------------------------------------- mounted
func act_charge(dt):run_lance(dt,cfg("knight_charge_windup"),.9,.75)
func act_double_charge(dt):run_lance(dt,prep_for("double_charge"),.9,1.0)
# Gallop at the rider and stop short; true once halted (target reached, distance run or wall).
func gallop(dt,prep,max_travel,stop_gap):
	if fired.has("halt"):return true
	if t<prep:
		if once("paw2",prep*.5):sound("paw",-7)
		return false
	if once("go",prep):speed=0;move.travel=0.0;sound("lance",-8)
	speed=minf(640,speed+2600*dt)
	var old_stride=stride
	var step=minf(speed*dt,maxf(0,max_travel-move.travel))
	var gap=target_dx()*lock_dir-stop_gap
	if gap>=0:step=minf(step,gap)
	position.x+=lock_dir*step;move.travel+=step;stride+=dt*speed/38
	for contact in [0.0,.41,.52,.89]:
		if floorf(old_stride/TAU-contact)<floorf(stride/TAU-contact):sound("gallop",-7)
	var limit=arena.end.x-margin() if lock_dir>0 else arena.position.x+margin()
	var walled=(lock_dir>0 and position.x>=limit) or (lock_dir<0 and position.x<=limit)
	if walled or gap<=step or move.travel>=max_travel-.01:
		fired.halt=true;stop_t=t;speed=0;sound("skid",-5)
		game.fx.burst(position+Vector2(lock_dir*30,-4),6,Color("8a8478"),60)
		return true
	return false
func act_halt_thrust(dt):
	var prep=prep_for("halt_thrust")
	if t<prep:face_target();lock_dir=facing
	if not gallop(dt,prep,420,95):return
	# A visible half-second brace after the skid, then the lance drives forward.
	var at=stop_t+.38
	if once("brace",stop_t):windup=.38;sound("armor",-6)
	if once("hit",at):
		position.x+=lock_dir*20;strike(span(20,180,58,12,lock_dir),.12,24,"knight_lance");sound("thrust",-2)
		strike_fx.append({"kind":"thrust","age":0.0,"life":.16,"dir":lock_dir,"x":position.x})
	if t>=at+.2:finish(.75)
func act_trample(dt):
	var prep=prep_for("trample")
	if t<prep:face_target();lock_dir=facing
	if once("body",prep):hit_box=strike(Rect2(),.8,16,"knight_hoof")
	var halted=gallop(dt,prep,260,-40)
	if hit_box!=null and not halted:hit_box.rect=span(-20,96,62,0,lock_dir)
	if not halted:return
	if once("rear",stop_t):end_box();windup=.3;sound("neigh",-5)
	if once("stomp",stop_t+.3):
		strike(span(25,135,36,0,lock_dir),.14,22,"knight_hoof");sound("stomp",-2);game.shake=maxf(game.shake,3.5)
		game.fx.burst(position+Vector2(lock_dir*85,-3),9,Color("8a8478"),75)
	if t>=stop_t+.5:finish(.85)
func act_rein(dt):
	var prep=cfg("knight_turn_windup")
	if once("turn",prep*.55):facing=-facing;lock_dir=facing;turn_anim=.22;turn_total=.22;sound("skid",-6)
	run_lance(dt,prep,1.1,0.0)
func run_lance(dt,prep,recover,turn_chance):
	if t<prep:
		if once("paw2",prep*.5):sound("paw",-7)
		return
	if once("run",prep):
		hit_box=strike(Rect2(),30.0,lance_damage,"knight_lance");sound("lance",-6)
		if empowered:soul.queue_echo()
	if not fired.has("stop"):
		speed=minf(680,speed+2800*dt)
		var old_tip=position.x+lock_dir*lance_reach()
		var old_stride=stride
		position.x+=lock_dir*speed*dt;stride+=dt*speed/38
		# Four physical hoof contacts follow the painted gallop cycle, never a free-running loop.
		for contact in [0.0,.41,.52,.89]:
			if floorf(old_stride/TAU-contact)<floorf(stride/TAU-contact):sound("gallop",-7)
		var limit=arena.end.x-margin() if lock_dir>0 else arena.position.x+margin()
		var stopped=(lock_dir>0 and position.x>=limit) or (lock_dir<0 and position.x<=limit)
		if stopped:position.x=limit
		var tip=position.x+lock_dir*lance_reach()
		# Only the lance tip deals damage; the swept span prevents tunnelling at speed.
		if hit_box!=null:hit_box.rect=Rect2(minf(old_tip,tip)-12,GROUND-46,absf(tip-old_tip)+24,32)
		if stopped:
			fired.stop=true;stop_t=t;end_box();sound("skid",-5)
			game.fx.burst(position+Vector2(lock_dir*30,-4),6,Color("8a8478"),60)
		return
	if turn_chance>0:
		var dx=target_dx()
		# At most one reverse charge follows the first: always for the double charge,
		# otherwise only when the rider overshot.
		if turn_chance>=1.0 or (dx*lock_dir<0 and absf(dx)>90 and randf()<turn_chance):begin("rein",prep_for("rein"));return
	if t-stop_t>=.05:finish(recover)
func lance_reach():return 118.0
func act_rear(dt):
	var prep=cfg("knight_rear_windup")
	approach_interval(dt,prep-.22,prep,480,facing,85)
	if once("hit",prep):
		strike(span(30,125,34,0),.14,22,"knight_hoof");sound("stomp",-2);game.shake=maxf(game.shake,3.0)
		# Empowered: the stomp's shock also runs out behind the horse.
		if empowered:strike(span(-20,-120,30,0),.14,16,"knight_hoof");game.fx.burst(position-Vector2(facing*70,3),8,Color("c0a5e9"),70)
		game.fx.burst(position+Vector2(facing*80,-3),8,Color("8a8478"),70)
	if t>=prep+.2:finish(.85)
func act_kick(_dt):
	var prep=cfg("knight_kick_windup")
	if once("hit",prep):
		strike(span(-40,-125,44,0),.12,18,"knight_hoof");sound("kick",-3)
		if empowered:soul.queue_echo()
	if t>=prep+.16:finish(.7)
func act_butt(dt):
	var prep=cfg("knight_butt_windup")
	approach_interval(dt,prep-.2,prep,500,facing,65)
	if once("hit",prep):
		strike(span(16,92,70,0),.12,16,"knight_butt");sound("press",-3)
		if empowered:soul.queue_soldiers()
	if t>=prep+.14:finish(.55)
# ---------------------------------------------------------------- dismount
func begin_dismount():
	position.y=GROUND
	end_box();action="";windup=0;pending="";idle=0;queued_empower=false
	game.combat.remove_owner(get_instance_id());soul.clear_attacks()
	speak_event("dismount",true)
	dismount_t=0;landed=false;phase_shift=DISMOUNT_TOTAL;move={"id":"dismount","title":"下马"}
	horse_x=position.x;sound("neigh",-2)
func update_dismount(dt):
	dismount_t+=dt;phase_shift=maxf(0,DISMOUNT_TOTAL-dismount_t)
	if dismount_t>=DISMOUNT_LAND and not landed:land()
	if dismount_t>=DISMOUNT_TOTAL:
		dismount_t=-1;phase_shift=0;idle=.05;behind_time=0
func land():
	landed=true;phase=2
	game.challenge_entry_phase=2
	if game.boss_rush:game.progress.rush_knight_foot=true;game.save_progress()
	hp=cfg("knight_foot_hp");max_hp=hp;body_height=106;radius=24;weapon="spear"
	position.x=clampf(horse_x-facing*46,arena.position.x+40,arena.end.x-40);horse_away=0
	game.scene_motion.reset(self)
	sound("land",-1);sound("dust",0)
	game.shake=maxf(game.shake,6.0);dust_age=0
	for i in 9:game.fx.burst(Vector2(arena.position.x+60+i*105,GROUND-4),4,Color("9b9384"),55)
	release_dust()
# The landing dust always reaches the hero: fixed 10 damage plus a 10 s gourd seal.
func release_dust():
	game.summon.seal(cfg("knight_dust_seal"))
	var p=game.player
	if is_instance_valid(p) and not p.is_carried():
		p.take_damage(10,signf(p.position.x-position.x) if absf(p.position.x-position.x)>1 else 1.0,"knight_dust","knight:dismount",true,true)
		damage_log.append("dust")
# ---------------------------------------------------------------- foot
func act_switch(_dt):
	if once("swap",SWITCH_TIME*.5):weapon=next_weapon;sound("armor",-9)
	if t>=SWITCH_TIME:
		var id=pending;pending="";action=""
		begin(id,prep_for(id))
		if id!="wave":sets_since_wave+=1
func act_thrust(dt):
	approach_interval(dt,cfg("knight_thrust_windup")-.22,cfg("knight_thrust_windup"),680,facing,80)
	thrust(cfg("knight_thrust_windup"),20,"knight_thrust")
func act_counter(dt):
	approach_interval(dt,.20,.45,760,facing,75)
	thrust(.45,24,"knight_counter")
func thrust(prep,damage,source):
	# Direction keeps tracking until the last 0.2 s before the thrust.
	if t<prep-.2:face_target()
	if once("hit",prep):
		position.x+=facing*16;strike(span(12,142,40,16),.1,damage,source);sound("thrust",-3)
		if empowered:soul.queue_soldiers()
		strike_fx.append({"kind":"thrust","age":0.0,"life":.16,"dir":facing,"x":position.x})
	if t>=prep+.12:finish(.6)
func act_butt_spin(dt):
	approach_interval(dt,.2,.5,500,facing,35)
	if once("hit",.5):
		strike(span(-72,38,56,0),.12,16,"knight_butt");sound("press",-4)
		if empowered:soul.queue_soldiers()
	if t>=.64:finish(.7)
func act_guard(dt):
	approach_interval(dt,0,.25,420,facing,75)
	if counter_pending:
		counter_pending=false;begin("counter",.45,false);return
	if t>=GUARD_TIME:finish(.55)
func act_stagger(_dt):
	if t>=.9:finish(.3)
func act_wave(dt):
	for at in wave_times:
		approach_interval(dt,at+.15,at+.45,300,facing,150)
	for i in wave_times.size():
		var at=wave_times[i]
		if once("prep"+str(i),at-WAVE_PREP):face_target();sound("wave_raise",-6)
		if once("wave"+str(i),at):fire_wave()
	if t>=wave_times[-1]+.5:finish(1.0)
func wave_band():return Rect2(arena.position.x,GROUND-WAVE_HIGH,arena.size.x,WAVE_HIGH-WAVE_LOW)
# A one-shot, arena-wide low strike. Rolling, sprinting and transform invulnerability
# do not pass through it; only lifting the feet above the band avoids it.
func fire_wave(identity="knight:wave",damage=WAVE_DAMAGE):
	var band=wave_band();var p=game.player
	shout()
	if is_instance_valid(p) and p.is_carried() and p.carried_by.hurt_rect().intersects(band):
		# The low wave hits a grounded mount too. Seat height is not a jump.
		p.carried_by.demon_controller.release_player()
	if is_instance_valid(p) and not p.is_carried():
		var body=Rect2(p.position-Vector2(8,p.HEIGHT),Vector2(16,p.HEIGHT))
		if body.intersects(band) and p.take_damage(scaled_damage(damage)*(1.1 if empowered else 1.0),signf(p.position.x-position.x),"knight_wave",identity,true):damage_log.append("wave")
	if game.summon.phase=="active" and is_instance_valid(game.summon.brother):
		var ally=game.summon.brother
		if ally.hurt_rect().intersects(band):ally.take_damage(scaled_damage(damage)*(1.1 if empowered else 1.0),facing,identity,get_instance_id())
	wave_fx.append({"age":0.0,"dir":facing,"x":position.x+facing*92})
	sound("wave",-2);game.shake=maxf(game.shake,2.0)
func act_soul_legion(_dt):
	if once("summon",.9):soul.begin_legion();sound("guard",-6);sound("ghost_summon",0);shout(1.0)
	if t>=1.0:finish(.35)
func on_ally_hit(ally,_identity="",forced_roll=-1.0):
	if dead or not active_battle or phase==1 or dismount_t>=0 or not is_instance_valid(ally) or ally.dead:return false
	if is_instance_valid(ancient_pending) or ancient_target!=null or ally.pinned_left>0:return false
	var roll=randf() if forced_roll<0 else forced_roll
	if roll>=.15:return false
	ancient_pending=ally
	return true
func ancient_ally():
	if ancient_target==null:return null
	var ally=ancient_target.get_ref()
	return ally if is_instance_valid(ally) and not ally.dead and game.summon.phase=="active" and ally==game.summon.brother else null
func flight_position(top,land_at,total):
	if t<.65:position=flight_from.lerp(top,smoothstep(0,.65,t))
	elif t<land_at:position=top
	else:position=top.lerp(Vector2(top.x,GROUND),smoothstep(land_at,total,t))
func act_ancient_spear(_dt):
	var ally=ancient_ally()
	if ally==null:
		ancient_target=null;position.y=GROUND;finish(.45);return
	var top=Vector2(clampf(ally.position.x,arena.position.x+35,arena.end.x-35),arena.position.y+70)
	if t<.65 or not fired.has("pin"):move.flight_top=top
	flight_position(move.get("flight_top",top),1.45,2.0)
	if once("throw",.65):move_sound("release",-2)
	if once("pin",1.1):
		ally.pin(10);move_sound("impact",-1);game.shake=maxf(game.shake,4)
		game.fx.burst(ally.position-Vector2(0,15),20,Color("bd92f0"),100)
	if t>=2.05:ancient_target=null;position.y=GROUND;finish(.5)
func act_bow(dt):run_bow(dt,"bow")
func bow_origin():
	if is_instance_valid(visual):return visual.projectile_origin()
	return position+Vector2(facing*30,-78)
# ---------------------------------------------------------------- damage
func take_hit(amount,faction,direction,breaking=false,with_sound=true,with_debris=true):
	if dead or not active_battle or phase_shift>0:return
	if action=="guard" and t<GUARD_TIME:
		if breaking:
			# Heavy hits (rising slash, charged blast) break the stance and open a window.
			end_box();begin("stagger",0,false);sound("clang",-2)
			game.fx.ring(position-Vector2(0,60),game.GOLD,40,.35)
		elif direction*facing<0:
			amount*=.5
			if not guard_triggered:guard_triggered=true;counter_pending=true
			sound("clang",-4);game.fx.hit_mark(position+Vector2(facing*20,-70),direction,Color("f2e3b5"),1.0,"block")
	var rage_damage=minf(amount,maxf(0,hp-(max_hp*.5 if phase==1 else 0)))
	# Rage only gathers on foot; the mounted duel is purely physical.
	if phase==2:soul.absorb(rage_damage)
	hp-=amount;hurt=.12
	if phase==2 and hp>0 and hp<max_hp*.3 and not low_spoken:low_spoken=speak_event("low")
	game.fx.hit_mark(position-Vector2(0,body_height*.45),direction,game.GOLD,1.2)
	game.fx.number(position-Vector2(0,body_height),amount,game.TEAL if faction=="brother" else game.GOLD)
	if with_debris:game.fx.burst(position-Vector2(0,body_height*.4),5,game.GOLD,70)
	if with_sound:game.audio.play("hit_boss",-3)
	if faction=="player":game.player.current_target=self;game.player.reward(amount,phase==2 and hp<=0);game.hitstop=maxf(game.hitstop,.045)
	# Mounted damage stops at the threshold: the foot phase always starts at full health.
	if phase==1 and hp<max_hp*.5:hp=maxf(hp,0);begin_dismount()
	elif phase==2 and hp<=0:
		hp=0;dead=true;end_box();action="";game.combat.remove_owner(get_instance_id());soul.clear_attacks();game.player.soul_slow=0
		game.audio.play("boss_death",0);game.boss_defeated();speak_event("death",true);game.challenge_finish=4.8
func apply_slow(_time):pass
func phase_title(value=-1):
	if value<0:value=2 if dismount_t>=0 else phase
	return ["马战 · 骑枪","下马步战"][clampi(int(value)-1,0,1)]
# Painted key poses share the original boss renderer; combat remains authoritative.
func _draw():
	draw_effects()
func draw_effects():
	preload("res://scripts/animation/knight/pressure_effects.gd").draw(self)
	preload("res://scripts/animation/knight/meteor_effects.gd").draw(self)
	# Effects are drawn in world-local space without the facing flip.
	draw_set_transform(Vector2.ZERO)
	for w in wave_fx:
		# Harmless ~0.12 s residue; damage was settled once when the wave fired.
		var u=w.age/.12
		var y=-(WAVE_LOW+WAVE_HIGH)*.5
		var left=arena.position.x-position.x;var right=arena.end.x-position.x
		var flash=1-u
		# Bright, full-width low streak with crescents running outward from the spear.
		draw_line(Vector2(left,y),Vector2(right,y),Color(.92,.95,1,(1-u)*.35),WAVE_HIGH-WAVE_LOW)
		draw_line(Vector2(left,y),Vector2(right,y),Color(1,.98,.9,flash*.95),2.5)
		var origin=w.x-position.x
		for i in 7:
			for side in [-1,1]:
				var x=origin+side*(u*180+i*72)
				if x<left or x>right:continue
				draw_arc(Vector2(x,y),7,-PI*.5 if side>0 else PI*.5,PI*.5 if side>0 else PI*1.5,6,Color(.85,.92,1,(1-u)*.7),1.4)
	for s in strike_fx:
		var u=s.age/s.life;var dir=s.dir;var base=Vector2(s.x-position.x,0)
		match s.kind:
			"thrust":
				draw_line(base+Vector2(dir*30,-28),base+Vector2(dir*146,-28),Color(1,.96,.86,(1-u)*.8),3-2*u)
	if dust_age>=0:
		var u=clampf(dust_age/1.1,0,1)
		var left=arena.position.x-position.x;var right=arena.end.x-position.x
		for i in 26:
			var x=lerpf(left,right,(i+.5)/26.0)
			var reach=absf(x)/maxf(1,maxf(absf(left),absf(right)))
			var grow=clampf(u*3.2-reach*.4,0,1)
			if grow<=0:continue
			var r=8+grow*16+sin(i*1.7)*3
			draw_circle(Vector2(x,-r*.55),r,Color(.62,.58,.52,(1-u)*.42*grow))

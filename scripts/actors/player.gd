extends CharacterBody2D
signal health_changed(value)
signal form_changed(active)
const HEIGHT=38.0
const WORLD_TOP_Z=4096
const SPEED=225.0
const JUMP_SPEED=520.0
const GRAVITY=1080.0
const DODGE_SOURCES=["spikes","ritual","dart","blade","orb","ghost_orb","binding_rune","pounce_impact","sweep","blade_sweep","antler_sweep","spectral_horn","slam","stone_impact","rift","shadow","ground_rift","stone_wave","spirit_lightning","rain","spirit_beam","breath","fire"]
var game
var art
var heavy_art
var health=100.0
var rage=0.0
var spirit=0.0
var has_bow=false
var facing=1.0
var invincible=0.0
var soul_slow=0.0
var sheep_time=0.0
var form_transition=0.0
var form_visual=false
var dash_time=0.0
var dash_cd=0.0
var roll_guard=0.0
var dodge_rewarded=false
var dodge_flash=0.0
var dodge_message=""
var bow_cd=0.0
var bow_anim=0.0
var charge=0.0
var charging_sound=false
var coyote=0.0
var jump_buffer=0.0
var drop_time=0.0
var attack_elapsed=-1.0
var attack_duration=.36
var attack_hit=false
var attack_queue=0.0
var combo=0
var combo_window=0.0
var blast_anim=0.0
var hurt_anim=0.0
var land_anim=0.0
var sprinting=false
var step_time=0.0
var anim_clock=0.0
var edges={}
var current_target=null
var dash_victims={}
var saved_velocity=Vector2.ZERO
var environment_force=0.0
var carried_by=null
var rider_art
var skeletal_visual
var pending_bow=false
var attack_sounded=false
var command_input=preload("res://scripts/combat/command_input.gd").new()
var pending_command={}
var command_buffer=0.0
var special_id=""
var special_cd=0.0
const SPECIAL_NAMES={"wave":"踏月剑气","spin":"回风斩","rising":"升龙斩"}
const MOTION=preload("res://scripts/animation/hero_motion.gd")
# The sheep spirit attacks 1.3× faster than the hero, for both blade and ranged.
const SHEEP_RATE=1.3
# Holding the attack key this long (after the opening slash ends) starts a charge.
const CHARGE_HOLD=.26
# Damage taken while charging is reduced to 85%.
const CHARGE_GUARD=.85
var attack_hold=0.0
# The hurt reaction keeps recovering visually after control returns at hurt_anim.
const HURT_RECOVER=.42
var hurt_time=-1.0
var hurt_push=-1.0
func _ready():
	collision_layer=2; collision_mask=5; floor_snap_length=7
	# The hero draws above bosses so an overlapping silhouette never disappears.
	z_index=WORLD_TOP_Z
	var shape=CollisionShape2D.new(); var capsule=CapsuleShape2D.new()
	capsule.radius=8; capsule.height=HEIGHT
	shape.shape=capsule; shape.position.y=-HEIGHT*.5; add_child(shape)
	art=load("res://scripts/actors/atlas_actor.gd").new(); add_child(art)
	set_form_art(false)
	heavy_art=load("res://scripts/actors/atlas_actor.gd").new();add_child(heavy_art)
	heavy_art.configure("res://assets/art/v2/uppercut.png",4,2,52.8);heavy_art.visible=false
	rider_art=load("res://scripts/actors/atlas_actor.gd").new();add_child(rider_art);rider_art.configure("res://assets/art/v3/rider.png",1,1,42);rider_art.hide();rider_art.pivot_override=Vector2(500,860)
	skeletal_visual=load("res://scripts/animation/hero_visual.gd").new();skeletal_visual.actor=self;add_child(skeletal_visual)
	var aura=load("res://scripts/animation/awaken_aura.gd").new();aura.actor=self;add_child(aura)
	var backlight=load("res://scripts/animation/hero_backlight.gd").new();backlight.actor=self;add_child(backlight)
	var spirit_rig=load("res://scripts/animation/cast_visual.gd").new();spirit_rig.actor=self;spirit_rig.species="sheep";spirit_rig.height=52.8
	var reference=load("res://scripts/actors/atlas_actor.gd").new();reference.configure("res://assets/art/v2/sheep.png",6,4,52.8)
	spirit_rig.source_art=reference;add_child(spirit_rig);reference.free();spirit_rig.source_art=art
func set_form_art(sheep):
	form_visual=sheep
	# Repacked atlases (tools/repack_atlas.gd) keep poses that overflow the source grid intact.
	art.configure("res://assets/art/v2/sheep_clean.png" if sheep else "res://assets/art/v2/hero_clean.png",6 if sheep else 8,4 if sheep else 5,52.8)
func sample_command_direction():
	command_input.sample(Vector2(Input.get_axis("left","right"),Input.get_action_strength("down")),facing)
func clear_commands():
	command_input.clear();pending_command.clear();command_buffer=0
func enqueue(action):
	if action=="attack" and game and game.active() and not sheep() and not is_carried() and form_transition<=0:
		sample_command_direction()
		var command=command_input.take()
		if not command.is_empty() and special_cd<=0 and dash_time<=0 and charge==0 and bow_anim<=0 and blast_anim<=0 and hurt_anim<=0:
			pending_command=command;command_buffer=.8
	edges[action]=true
func consume(action):
	var yes=edges.get(action,false); edges.erase(action); return yes
func sheep(): return sheep_time>0
func reset(at:Vector2,bow:bool):
	position=at; velocity=Vector2.ZERO; health=100;rage=0;spirit=0;has_bow=bow
	soul_slow=0;invincible=1; sheep_time=0; form_transition=0; dash_time=0;dash_cd=0;roll_guard=0;dodge_rewarded=false;dodge_flash=0;dodge_message="";bow_cd=0
	cancel_action();combo=0;combo_window=0;drop_time=0;hurt_anim=0;hurt_time=-1.0;land_anim=0;sprinting=false
	current_target=null;edges.clear();collision_mask=5
	clear_commands();special_id="";special_cd=0
	environment_force=0
	if form_visual: set_form_art(false)
func _physics_process(dt):
	if not game or not game.active(): return
	if sheep() or is_carried() or form_transition>0:clear_commands()
	else:sample_command_direction()
	if game.hitstop>0:
		if consume("attack"): attack_queue=.18
		if consume("jump"): jump_buffer=.15
		return
	command_input.tick(dt)
	special_cd=maxf(0,special_cd-dt);command_buffer=maxf(0,command_buffer-dt)
	if command_buffer<=0:pending_command.clear()
	anim_clock+=dt
	for key in ["soul_slow","invincible","dash_cd","roll_guard","dodge_flash","bow_cd","bow_anim","blast_anim","hurt_anim","land_anim","combo_window","attack_queue"]: set(key,maxf(0,get(key)-dt))
	# Sheep bow animation runs at the faster spirit attack rate.
	if sheep():bow_anim=maxf(0,bow_anim-dt*(SHEEP_RATE-1))
	attack_hold=attack_hold+dt if Input.is_action_pressed("attack") else 0.0
	if hurt_time>=0:hurt_time=hurt_time+dt if hurt_time+dt<HURT_RECOVER else -1.0
	rage=maxf(0,rage-dt*3.5)
	if sheep_time>0:
		sheep_time=maxf(0,sheep_time-dt)
		if sheep_time==0: begin_form(false)
	form_transition=maxf(0,form_transition-dt)
	if form_transition>0 and form_transition<.24 and form_visual!=sheep(): set_form_art(sheep())
	if is_on_floor(): coyote=.12
	else: coyote=maxf(0,coyote-dt)
	if consume("jump"): jump_buffer=.15
	else: jump_buffer=maxf(0,jump_buffer-dt)
	drop_time=maxf(0,drop_time-dt); set_collision_mask_value(3,drop_time==0)
	if jump_buffer>0:
		if is_carried():
			# A deliberate jump hands control back before applying the usual jump impulse.
			carried_by.demon_controller.release_player()
			velocity.y=-JUMP_SPEED;jump_buffer=0;coyote=0
			game.audio.play("jump");game.terrain.presence.step(position)
		elif Input.is_action_pressed("down") and is_on_floor():
			drop_time=.22;set_collision_mask_value(3,false);position.y+=3;velocity.y=40;jump_buffer=0;coyote=0
		elif coyote>0:
			velocity.y=-JUMP_SPEED;coyote=0;jump_buffer=0
			game.audio.play("jump");game.terrain.presence.step(position)
	if consume("jump_release") and velocity.y < -190: velocity.y=-190
	var direction=Input.get_axis("left","right")
	if direction!=0 and attack_elapsed<0 and bow_anim<=0 and dash_time<=0 and charge<=0 and blast_anim<=0: facing=signf(direction)
	var wants_roll=consume("dash");var wants_sprint=consume("sprint")
	if (wants_roll or wants_sprint) and form_transition<=0 and not is_carried() and dash_cd<=0 and (attack_elapsed<0 or attack_hit):
		sprinting=wants_sprint and not wants_roll
		dash_cd=1.0 if sheep() else .7
		if not sprinting:invincible=maxf(invincible,.23);roll_guard=.23;dodge_rewarded=false
		else:roll_guard=0
		cancel_action();dash_time=.18;clear_commands();dash_victims.clear();game.audio.play("horn" if sheep() else "dash")
	if not pending_command.is_empty() and special_cd<=0 and dash_time<=0 and charge==0 and bow_anim<=0 and blast_anim<=0 and hurt_anim<=0 and (attack_elapsed<0 or attack_hit):
		start_special(pending_command);pending_command={};command_buffer=0;consume("attack")
	if consume("attack") and hurt_anim<=0 and form_transition<=0 and dash_time<=0 and bow_anim<=0 and charge==0 and blast_anim<=0:
		if attack_elapsed<0: start_attack()
		else: attack_queue=maxf(.18,attack_duration-attack_elapsed+.10)
	if attack_elapsed>=0:
		attack_elapsed+=dt*attack_rate()
		var impact=MOTION.ATTACKS[combo-1].hit if sheep() or game.use_skeletal else .12
		var sound_lead=.035 if sheep() else game.audio.SWING_LEAD[combo-1]
		if not attack_sounded and attack_elapsed>=impact-sound_lead:
			attack_sounded=true
			if sheep():game.audio.play("sheep_slash"+str(combo))
			else:game.audio.melee_swing(combo)
		if not attack_hit and attack_elapsed>=impact:
			attack_hit=true
			if special_id!="":game.combat.command_attack(self,special_id)
			else:game.combat.melee(self)
		var chain_ready=special_id=="" and (sheep() or game.use_skeletal) and combo<3 and attack_queue>0 and attack_elapsed>=MOTION.ATTACKS[combo-1].chain
		if attack_elapsed>=attack_duration or chain_ready:
			attack_elapsed=-1;special_id=""
			if attack_queue>0: start_attack();attack_queue=0
	# The touch "蓄" button still presses the unbound charge action directly.
	var wants_charge=Input.is_action_pressed("charge") or game.gamepad.charge_active or (attack_hold>=CHARGE_HOLD and special_id=="" and pending_command.is_empty())
	if wants_charge and hurt_anim<=0 and form_transition<=0 and dash_time<=0 and bow_anim<=0 and attack_elapsed<0 and blast_anim<=0:
		if charge==0: game.audio.play("sheep_charge" if sheep() else "charge")
		charge=minf(charge+dt,1.1)
	elif charge>0:
		if charge>=.32: game.combat.blast(self,charge/1.1);blast_anim=.35
		charge=0
	if consume("bow") and hurt_anim<=0 and form_transition<=0 and dash_time<=0 and attack_elapsed<0 and blast_anim<=0 and bow_cd<=0 and charge==0:
		if sheep() or has_bow:
			bow_cd=.48/attack_rate();bow_anim=MOTION.BOW_DURATION
			if not sheep() and not game.use_skeletal:game.combat.player_shot(self)
			else:pending_bow=true
		else: game.show_hint("在上方石台拾取山行弓，之后按 K 射箭。")
	if pending_bow and MOTION.bow_released(MOTION.BOW_DURATION-bow_anim):
		pending_bow=false;game.combat.player_shot(self)
	if consume("transform"):
		if spirit>=100 and not sheep(): spirit=0;sheep_time=sheep_duration();begin_form(true)
	if consume("summon"): game.summon.request()

	if is_carried():
		position=carried_by.demon_controller.carry_position();velocity=Vector2.ZERO;collision_mask=0
		dash_time=0;jump_buffer=0;invincible=maxf(invincible,.2)
		facing=carried_by.facing
		update_animation();art.tint=Color.WHITE
		if not sheep():
			art.hide();heavy_art.hide();rider_art.show();rider_art.facing=carried_by.facing
		else:rider_art.hide();art.visible=not game.use_skeletal;art.frame=19
		return
	var old_floor=is_on_floor()
	if dash_time>0:
		dash_time=maxf(0,dash_time-dt);velocity=Vector2(facing*(610 if sprinting or sheep() else 490)+environment_force,0)
		game.fx.trail(position,game.TEAL if not sheep() else game.GOLD)
		if sheep(): game.combat.horn(self)
	else:
		var speed=SPEED*(1.12 if sheep() else 1.0)*(.78 if soul_slow>0 else 1.0)
		# Charging is a planted stance; only a slow shuffle remains.
		if charge>0:speed*=.12
		if attack_elapsed>=0:speed*=.55
		velocity.x=move_toward(velocity.x,direction*speed+environment_force,1800*dt)
		velocity.y+=GRAVITY*dt
	environment_force=0
	move_and_slide()
	position.x=clampf(position.x,12,game.level.length-20)
	if is_on_floor() and not old_floor:
		land_anim=.18;game.audio.play("land",-5);game.terrain.presence.step(position,true)
	if is_on_floor() and absf(velocity.x)>40 and (sheep() or not game.use_skeletal):
		step_time-=dt
		if step_time<=0:step_time=.27;game.audio.play("step"+str(int(anim_clock*10)%3),-12);game.terrain.presence.step(position)
	if position.y>700: game.fall_recover()
	update_animation()
func attack_rate():return SHEEP_RATE if sheep() else 1.0
func sheep_duration():return 15.0+game.upgrade_level("spirit")*2.0
func begin_form(enabled):
	clear_commands();cancel_action();combo=0;combo_window=0;edges.clear()
	form_transition=.48;invincible=maxf(invincible,.55)
	game.audio.play("transform" if enabled else "revert")
	game.fx.ring(position-Vector2(0,23),game.GOLD if enabled else game.TEAL,65,.5)
	game.fx.burst(position-Vector2(0,23),8,game.GOLD,65)
	form_changed.emit(enabled)
func cancel_action():
	attack_elapsed=-1;attack_queue=0;attack_hit=false;attack_sounded=false;special_id=""
	pending_bow=false;bow_anim=0;charge=0;blast_anim=0;dash_time=0
func start_attack():
	special_id=""
	combo=combo%3+1 if combo_window>0 else 1;combo_window=.8
	attack_elapsed=0;attack_duration=MOTION.ATTACKS[combo-1].duration if sheep() or game.use_skeletal else (.40 if combo==3 else .34);attack_hit=false;attack_sounded=false
func start_special(command):
	special_id=command.id;facing=command.face;special_cd=1.0
	combo={"wave":1,"spin":2,"rising":3}[special_id];combo_window=0;attack_queue=0
	attack_elapsed=0;attack_duration=MOTION.ATTACKS[combo-1].duration;attack_hit=false;attack_sounded=false
	# Each technique opens with its own footwork: a forward lunge, a planted whirl, a crouch.
	match special_id:
		"wave":velocity.x=facing*360
		"spin":velocity.x*=.2
		"rising":velocity.x=facing*120
	if game.fx:game.fx.burst(position-Vector2(0,3),6,Color("cbbf9f"),70)
# unblockable ignores every invulnerability window (roll, sprint, transform, hurt);
# fixed skips the journey-mode damage scaling.
func take_damage(amount:float,direction:float,source="unknown",attack_sound="",unblockable=false,fixed=false):
	if is_carried() or not game.active():return false
	if invincible>0 and not unblockable:
		if roll_guard>0 and not dodge_rewarded and source in DODGE_SOURCES:perfect_dodge()
		return false
	if not fixed:amount=game.incoming_damage(amount)
	if charge>0:amount*=CHARGE_GUARD
	health=maxf(0,health-amount);invincible=.8;hurt_anim=.22
	# +1: pushed toward facing (hit from behind), -1: knocked back.
	hurt_time=0.0;hurt_push=1.0 if direction*facing>0 else -1.0
	velocity=Vector2(direction*180,-150);cancel_action()
	clear_commands();special_id="";attack_queue=0
	if not game.audio.enemy_cue(attack_sound,"impact"):game.audio.play("hurt")
	game.fx.hit_mark(position-Vector2(0,20),direction,Color("ffac82"),1.25)
	game.fx.number(position-Vector2(0,60),amount,Color("ffb99e"))
	game.hitstop=maxf(game.hitstop,.06);game.shake=maxf(game.shake,4.5)
	update_animation()
	if is_instance_valid(skeletal_visual) and is_instance_valid(skeletal_visual.painted_motion):skeletal_visual.painted_motion.modulate=render_tint()
	health_changed.emit(health)
	if health<=0:game.die(source)
	return true
func perfect_dodge():
	dodge_rewarded=true;dodge_flash=.7
	var rage_gain=minf(15,100-rage);var spirit_gain=minf(12,100-spirit)
	rage+=rage_gain;spirit+=spirit_gain
	dodge_message="踏月闪 · 战意 +"+str(int(rage_gain))+" · 觉醒 +"+str(int(spirit_gain))
	game.fx.ring(position-Vector2(0,20),game.TEAL,42,.35);game.audio.play("pickup",-7)
func render_tint():
	# Keep invulnerability readable without a hard on/off transparency flash.
	var alpha=1.0 if invincible<=0 else .91+.09*sin(anim_clock*TAU*7)
	var strength=1-smoothstep(.02,.20,.22-hurt_anim) if hurt_anim>0 else 0.0
	var color=Color.WHITE.lerp(Color(1.0,.48,.34),strength)
	# A brief white flash on contact, before the red recoil tint.
	if hurt_time>=0 and hurt_time<.06:color=Color(1.7,1.6,1.5)
	color.a=alpha
	return color
func reward(damage:float,killed:bool):
	rage=minf(100,rage+10);spirit=minf(100,spirit+5+(6 if killed else 0))
	if killed:health=minf(100,health+1)
# Sheep combo frame orders: quick horizontal draw, overhead chop, full sweeping arc.
# Each list lands its hit frame (index SHEEP_HIT_FRAME) exactly on the damage event.
const SHEEP_SLASHES=[[12,16,16,17],[12,13,14,15,17],[12,13,14,15,16,17]]
const SHEEP_HIT_FRAME=[1,3,4]
func hurt_weight():
	if hurt_time<0:return 0.0
	return smoothstep(0,.06,hurt_time)*(1-smoothstep(.10,HURT_RECOVER,hurt_time))
func timed_frame(frames,hit_index,t,hit,duration):
	# Spread the frames before the hit over [0,hit] and the rest over [hit,duration].
	if t<hit:return frames[mini(int(t/maxf(hit,.001)*hit_index),hit_index)]
	var rest=frames.size()-1-hit_index
	if rest<=0:return frames[-1]
	return frames[mini(hit_index+int((t-hit)/maxf(duration-hit,.001)*(rest+1)),frames.size()-1)]
func update_animation():
	if not art:return
	art.facing=facing
	art.tint=render_tint()
	var frame=0
	var rot=0.0;var offset=Vector2.ZERO;var turn=1.0
	if form_visual:
		if dash_time>0:frame=20
		elif blast_anim>0:frame=22
		# Gathering power: the flaming stance, trembling harder as the charge builds.
		elif charge>0:frame=23;offset.x=sin(anim_clock*55)*charge*.9
		elif bow_anim>0:frame=21
		elif attack_elapsed>=0:
			var index=clampi(combo-1,0,2)
			frame=timed_frame(SHEEP_SLASHES[index],SHEEP_HIT_FRAME[index],attack_elapsed,MOTION.ATTACKS[index].hit,attack_duration)
		elif not is_on_floor():frame=18 if velocity.y<0 else 19
		elif absf(velocity.x)>20:frame=6+int(anim_clock*12)%6
		else:frame=int(anim_clock*6)%6
	else:
		if hurt_anim>0:frame=36
		elif dash_time>0:frame=37
		elif blast_anim>0:frame=29
		elif charge>0:frame=24;offset=Vector2(sin(anim_clock*55)*charge*.8,1.5*smoothstep(0,.2,charge))
		elif bow_anim>0:frame=38 if bow_anim>.15 else 39
		elif attack_elapsed>=0:frame=16+mini(combo-1,1)*8+clampi(int(attack_elapsed/attack_duration*8),0,7)
		elif land_anim>0:frame=35
		elif not is_on_floor():frame=32 if velocity.y< -400 else (33 if velocity.y<0 else 34)
		elif absf(velocity.x)>20:frame=8+int(anim_clock*14)%8
		else:frame=int(anim_clock*6)%8
		# Command techniques move the whole painted sprite.
		if attack_elapsed>=0 and special_id!="":
			var move=MOTION.ATTACKS[combo-1];var t=attack_elapsed;var hit=move.hit
			match special_id:
				"wave":
					var lunge=smoothstep(0,hit,t)*(1-smoothstep(hit+.05,move.duration,t))
					offset.x+=facing*5*lunge;offset.y+=2*lunge;rot+=facing*.14*lunge
				"spin":
					turn=cos(clampf(t/attack_duration,0,1)*TAU)
					if absf(turn)<.35:turn=.35 if turn>=0 else -.35
				"rising":
					var stretch=smoothstep(hit*.8,hit+.05,t)*(1-smoothstep(hit+.12,move.duration,t))
					rot-=facing*.16*stretch
	# Hurt recoil: lean away from the blow, then settle; it keeps easing out after control returns.
	var hurt=hurt_weight()
	if hurt>0:
		rot+=hurt_push*facing*.24*hurt
		offset.x+=hurt_push*facing*3*hurt+sin(hurt_time*70)*(1-smoothstep(0,.16,hurt_time))
	art.frame=frame
	var heavy=not form_visual and attack_elapsed>=0 and combo==3
	art.visible=not heavy;heavy_art.visible=heavy
	if heavy:
		heavy_art.frame=clampi(int(attack_elapsed/attack_duration*8),0,7);heavy_art.facing=facing;heavy_art.tint=art.tint
	art.facing=facing*turn
	art.motion=(Vector2(0,sin(anim_clock*7)*.25) if attack_elapsed<0 and charge==0 else Vector2.ZERO)+offset
	heavy_art.motion=offset
	if not is_carried():art.rotation=rot;heavy_art.rotation=rot
	if game.use_skeletal and not form_visual and not is_carried():art.hide();heavy_art.hide()

func _process(_dt):
	if is_carried():
		position=carried_by.demon_controller.carry_position();facing=carried_by.facing;rider_art.facing=facing
func rider_foot_drop():return (rider_art.bounds[0].end.y-rider_art.pivot_override.y)*rider_art.scale_unit
func is_carried():return is_instance_valid(carried_by)
func attach_to(ally):
	clear_commands();cancel_action()
	carried_by=ally;collision_mask=0;velocity=Vector2.ZERO;dash_time=0;jump_buffer=0;charge=0
	invincible=maxf(invincible,.2);edges.clear();z_index=WORLD_TOP_Z
func detach_from(at):
	carried_by=null;position=at;game.scene_motion.reset(self);velocity=Vector2.ZERO;collision_mask=5
	jump_buffer=0;drop_time=0;dash_time=0;invincible=maxf(invincible,.8);art.rotation=0;rider_art.hide();art.show();z_index=WORLD_TOP_Z

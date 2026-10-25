extends CharacterBody2D
var game
var art
var kind="imp"
var spawn_id=""
var section=0
var dead=false
var hp=100.0
var max_hp=100.0
var radius=19.0
var body_height=46.0
var facing=-1.0
var ai_time=0.0
var gait_phase=0.0
var cooldown=1.0
var windup=0.0
var strike=.0
var release_delay=.0
var hurt=.0
var dead_time=.0
var slow=.0
var home=Vector2.ZERO
var target=Vector2.ZERO
var diving=false
var offscreen=true
const KINDS=["imp","spirit","guardian","pouncer","bat","dart","shield","shaman"]
func setup(world,data):
	game=world;kind=data.kind;position=Vector2(data.x,data.y);home=position;spawn_id=data.id;section=data.section
	max_hp={"imp":100.0,"spirit":80.0,"guardian":220.0,"pouncer":95.0,"bat":65.0,"dart":90.0,"shield":160.0,"shaman":100.0}[kind]
	hp=max_hp
	body_height=65 if kind=="guardian" else (34 if kind=="bat" else 46)
	radius=26 if kind=="guardian" else 17
func _ready():
	collision_layer=0;collision_mask=5;floor_snap_length=8
	var c=CollisionShape2D.new();var s=CapsuleShape2D.new();s.radius=radius*.65;s.height=body_height*.8;c.shape=s;c.position.y=-s.height*.5;add_child(c)
	art=load("res://scripts/actors/enemy_art.gd").new();art.actor=self;add_child(art)
	art.configure("res://assets/art/v2/mobs.png",6,8,body_height)
	# Scale each species independently using its idle frame height.
	var row=KINDS.find(kind);art.scale_unit=body_height/maxf(1,art.bounds[row*6].size.y)
func _physics_process(dt):
	if not game.active() or game.hitstop>0:return
	ai_time+=dt
	if dead:
		dead_time+=dt;art.frame=KINDS.find(kind)*6+5;art.tint.a=maxf(0,1-dead_time/.5)
		if dead_time>.6:visible=false;set_physics_process(false)
		return
	offscreen=absf(position.x-game.player.position.x)>760
	if offscreen:return
	hurt=maxf(0,hurt-dt);strike=maxf(0,strike-dt);slow=maxf(0,slow-dt);cooldown-=dt
	if release_delay>0:
		release_delay-=dt
		if release_delay<=0:release_attack()
	var victim=game.ally_target(position)
	var dx=victim.position.x-position.x
	var dy=victim.position.y-position.y
	facing=signf(dx) if absf(dx)>2 else facing
	var fly=kind in ["bat","spirit"]
	if windup>0:
		windup-=dt;velocity.x=move_toward(velocity.x,0,dt*600)
		if windup<=0:perform_attack()
	elif strike>0:
		if release_delay<=0 and kind in ["pouncer","bat"]:velocity.x=facing*230
		else:velocity.x=move_toward(velocity.x,0,dt*600)
	else:
		var reach=340 if kind in ["spirit","dart","shaman"] else (160 if kind in ["pouncer","bat"] else 67)
		if absf(dx)<reach and absf(dy)<(200 if fly else 100) and cooldown<=0:
			windup=.65 if kind!="guardian" else .85;cooldown=2.0;target=victim.position
			game.audio.enemy_cue(game.audio.ENEMY_AUDIO.for_actor(self),"warning")
		elif absf(dx)>50:
			var speed=60.0 if kind!="guardian" else 36.0
			if kind in ["dart","shaman"] and absf(dx)<155:speed=-speed
			velocity.x=facing*speed*(.7 if slow>0 else 1)
			if not fly:
				var foot=position+Vector2(signf(velocity.x)*24,0)
				var q=PhysicsRayQueryParameters2D.create(foot-Vector2(0,4),foot+Vector2(0,30),5)
				if not game.get_world_2d().direct_space_state.intersect_ray(q):velocity.x=0
		else:velocity.x=0
	if fly:
		if strike>0 and release_delay<=0 and kind=="bat":velocity.y=(target.y-20-position.y)*4
		else:velocity.y=(home.y+sin(ai_time*2)*9-position.y)*3
	else:velocity.y+=1080*dt
	var before_move=position
	move_and_slide()
	if not fly and is_on_floor() and strike<=0 and windup<=0:
		gait_phase=fposmod(gait_phase+absf(position.x-before_move.x)/30.0,1.0)
	if position.y>690:position=home;velocity=Vector2.ZERO
	var walking_frame=int(ai_time*8)%2 if fly else int(gait_phase*2)%2
	var col=2 if windup>0 else (3 if strike>0 else (4 if hurt>0 else (1 if absf(velocity.x)>5 and walking_frame else 0)))
	art.frame=KINDS.find(kind)*6+col;art.facing=-facing
	art.motion=Vector2.ZERO
	art.tint=preload("res://scripts/combat/hit_feedback.gd").tint(hurt,.18)
	queue_redraw()
func perform_attack():
	strike=.45
	release_delay=.06
	# The strike pose starts first. Damage, movement and sound share the authored
	# release point instead of appearing while the body is still in anticipation.
func release_attack():
	var origin=position-Vector2(0,body_height*.5)
	game.audio.enemy_cue(game.audio.ENEMY_AUDIO.for_actor(self),"release")
	match kind:
		"spirit":game.combat.fire(origin,(target-Vector2(0,20)-origin).normalized()*190,12,"enemy","orb",{"owner":get_instance_id()})
		"dart":
			for angle in [-.11,0,.11]:game.combat.fire(origin,Vector2(facing,0).rotated(angle)*300,10,"enemy","dart",{"owner":get_instance_id()})
		"shaman":game.combat.hazard(Rect2(target.x-30,408,60,42),.8,.25,17,get_instance_id(),"binding_rune")
		"pouncer","bat":
			if kind=="pouncer":velocity.y=-210
			game.combat.hazard(Rect2(target-Vector2(25,36),Vector2(50,36)),.32,.2,14,get_instance_id(),"pounce_impact")
		_:
			var reach=95 if kind=="guardian" else 60
			var x=position.x if facing>0 else position.x-reach
			game.combat.hazard(Rect2(x,position.y-45,reach,45),0,.16,20 if kind=="guardian" else 12,get_instance_id(),"sweep")
func take_hit(amount,faction,direction,breaking=false,with_sound=true,with_debris=true):
	if dead:return
	var blocked=kind=="shield" and direction==-facing and not breaking
	if blocked:amount*=.2
	if kind=="shaman" and windup>0:windup=0;cooldown=1.1
	hp-=amount;hurt=.18
	preload("res://scripts/combat/hit_feedback.gd").apply(art,hurt,.18,direction)
	game.fx.hit_mark(position-Vector2(0,body_height*.5),direction,game.GOLD if blocked else Color("ffe1ad"),.65 if blocked else 1.0,"block" if blocked else "hit")
	game.fx.number(position-Vector2(0,body_height+5),amount,game.TEAL if faction=="brother" else game.GOLD)
	var debris=Color("8d9b96") if kind in ["imp","guardian","shield"] else (Color("9caaa6") if kind in ["spirit","shaman"] else Color("ad8c79"))
	if with_debris:game.fx.burst(position-Vector2(0,body_height*.5),4,debris,55)
	if with_sound:game.audio.play("shield_block" if blocked else ("hit_stone" if kind in ["imp","guardian","shield"] else "hit_soft"),-3)
	if faction=="player":game.hitstop=maxf(game.hitstop,.045);game.player.current_target=self;game.player.reward(amount,hp<=0)
	if hp<=0:
		dead=true;release_delay=0;game.kills+=1;game.audio.play("death_"+kind,-3);game.combat.remove_owner(get_instance_id());game.fx.burst(position-Vector2(0,20),6,debris,65);game.on_enemy_defeated(self)
func apply_slow(time):slow=maxf(slow,time)
func _draw():
	if dead or offscreen:return
	if windup>0:
		draw_circle(Vector2(0,-body_height-9),3,Color("edb28b"))
	if hp<max_hp:
		draw_rect(Rect2(-18,-body_height-5,36,2),Color("233846"));draw_rect(Rect2(-18,-body_height-5,36*maxf(0,hp/max_hp),2),Color("81c5b2"))

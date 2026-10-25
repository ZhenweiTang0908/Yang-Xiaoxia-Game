extends Node2D
# The awakened brother is a quadruped mount. Damage comes from its travelled body,
# never a screen-wide slash or an invisible weapon swing.
var actor
var game
var rig
var age=0.0
var transform_left=.65
var carrying=true
var carry_age=0.0
var carry_total=7.0
var heal_total=5.0
var heal_amount=3.0
var heal_ticks=0
var carry_start=Vector2.ZERO
var home=Vector2.ZERO
var attack_cd=.6
var attack_age=10.0
var rush_windup=0.0
var rush_left=0.0
var rush_heavy=false
var rush_hits={}
var dust_time=0.0
var blink_cd=2.0
var lock_left=0.0
var lock_total=0.0
var lock_target=null
var lock_point=Vector2.ZERO
var charged=false
var next_charged=false
var attack_target=null
func cfg(key):
	var value=game.tuning.get_value(key)
	if key in ["demon_damage","charged_damage"]:value*=game.upgrade_multiplier("brother",.12)
	return value
func start(_restoring=false):
	carry_total=cfg("carry_duration");heal_total=cfg("heal_duration");heal_amount=cfg("heal_rate")
	carrying=false;transform_left=0
	carry_start=game.player.position-Vector2(0,game.player.rider_foot_drop());home=actor.position
	rig=load("res://scripts/actors/demon_rig.gd").new();rig.owner_actor=actor;rig.controller=self;add_child(rig)
func begin_assistance():
	carry_start=game.player.position-Vector2(0,game.player.rider_foot_drop());home=actor.position
	carrying=not game.level.no_carry;carry_age=0;heal_ticks=0
	if carrying:game.player.attach_to(actor)
	game.audio.play("bull_moo",-2);game.fx.ring(actor.position-Vector2(0,28),effect_color(),48,.5)
func effect_color():return Color("a4c2ad")
func carry_position():
	# The player root is the seated hips while mounted, not the sprite feet.
	var seat=rig.seat_position()
	if carry_age<.45:return carry_start.lerp(seat,smoothstep(0,.45,carry_age))
	if carry_age>carry_total-.55:
		return seat.lerp(game.safe_ground(actor.position+Vector2(-actor.facing*65,0))-Vector2(0,game.player.rider_foot_drop()),smoothstep(carry_total-.55,carry_total,carry_age))
	return seat
func release_player():
	if not carrying:return
	carrying=false
	if is_instance_valid(game.player) and game.player.carried_by==actor:
		game.player.detach_from(game.safe_ground(actor.position+Vector2(-actor.facing*65,0)))
func target_valid(target):
	return is_instance_valid(target) and not target.dead and (target.kind!="boss" or target.active_battle)
func tick(dt):
	age+=dt;attack_age+=dt;attack_cd-=dt;blink_cd-=dt;dust_time-=dt
	if transform_left>0:
		transform_left=maxf(0,transform_left-dt);rig.scale.y=lerpf(.75,1,1-transform_left/.65)
		actor.velocity.x=0;actor.velocity.y+=1080*dt;actor.move_and_slide();rig.tick(dt);return
	rig.scale.y=1
	if carrying:
		carry_age+=dt
		while heal_ticks<int(minf(carry_age,heal_total)):
			heal_ticks+=1
			var healed=minf(heal_amount,100-game.player.health);game.player.health+=healed
			if healed>0:game.fx.number(game.player.position-Vector2(0,40),healed,effect_color());game.audio.play("pickup",-12)
		if carry_age>=carry_total:release_player()
	var mounting=carrying and (carry_age<.45 or carry_age>carry_total-.55)
	var target=actor.choose_target()
	var rushing_this_frame=false
	if carrying and target_valid(target) and target.position.distance_to(home)>360:target=null
	if mounting:
		rush_left=0;rush_windup=0;lock_left=0;actor.velocity.x=0
	elif lock_left>0:
		lock_left=maxf(0,lock_left-dt);actor.velocity.x=0
		if lock_left==0:complete_blink()
	elif rush_windup>0:
		rush_windup=maxf(0,rush_windup-dt);actor.velocity.x=0
		if rush_windup==0:start_rush()
	elif rush_left>0:
		rush_left=maxf(0,rush_left-dt)
		actor.velocity.x=actor.facing*cfg("rush_speed")
		if not ground_ahead(actor.facing*62):rush_left=0;actor.velocity.x=0
		rushing_this_frame=actor.velocity.x!=0
		if dust_time<=0:
			dust_time=.12;game.fx.burst(actor.position-Vector2(actor.facing*35,1),3,Color("71867f"),24)
	elif target_valid(target) and blink_cd<=0 and absf(target.position.y-actor.position.y)<100:
		begin_lock(target)
	elif target_valid(target) and attack_cd<=0 and actor.position.distance_to(target.position)<cfg("demon_range")+45:
		begin_rush(target)
	else:
		var desired=target.position if target_valid(target) else (home if carrying else game.player.position-Vector2(game.player.facing*70,0))
		var dx=desired.x-actor.position.x
		if absf(dx)>10:actor.facing=signf(dx)
		actor.velocity.x=move_toward(actor.velocity.x,signf(dx)*150 if absf(dx)>65 else 0,1100*dt)
		actor.drop_time=maxf(0,actor.drop_time-dt);actor.set_collision_mask_value(3,actor.drop_time==0)
		if actor.is_on_floor():
			if desired.y<actor.position.y-45 and absf(dx)<170:actor.velocity.y=-520
			elif desired.y>actor.position.y+45:actor.drop_time=.22;actor.set_collision_mask_value(3,false);actor.position.y+=3
			elif not ground_ahead(signf(dx)*62):actor.velocity.x=0
	var old=actor.position
	actor.velocity.y+=1080*dt;actor.move_and_slide()
	if rushing_this_frame:
		strike(old)
		if actor.is_on_wall():rush_left=0;actor.velocity.x=0
	if not carrying and actor.position.distance_to(game.player.position)>500:
		actor.position=game.safe_ground(game.player.position-Vector2(game.player.facing*70,0));actor.velocity=Vector2.ZERO
	if actor.position.y>680:actor.position=game.last_safe;actor.velocity=Vector2.ZERO
	rig.tick(dt);queue_redraw()
func ground_ahead(offset):
	var foot=actor.position+Vector2(offset,0)
	return not game.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(foot-Vector2(0,8),foot+Vector2(0,35),5)).is_empty()
func begin_rush(target,heavy=false):
	if not target_valid(target):return
	attack_target=target;actor.facing=1 if target.position.x>=actor.position.x else -1
	rush_heavy=heavy;rush_windup=cfg("rush_windup");actor.velocity.x=0
	game.audio.play("charge",-9)
func start_rush():
	rush_left=cfg("demon_range")/cfg("rush_speed");rush_hits.clear();attack_age=0
	attack_cd=cfg("demon_interval")+rush_left
	game.audio.play("horn",-4)
func begin_lock(target):
	if not target_valid(target):return
	lock_target=target;lock_point=target.position;charged=next_charged;next_charged=not next_charged
	lock_total=cfg("charge_time") if charged else cfg("lock_time");lock_left=lock_total
	blink_cd=cfg("blink_cooldown");rush_left=0;rush_windup=0;actor.velocity.x=0
	game.audio.play("charge",-7)
func landing_clear(at):
	var shape=RectangleShape2D.new();shape.size=Vector2(82,46)
	var query=PhysicsShapeQueryParameters2D.new();query.shape=shape;query.transform=Transform2D(0,at-Vector2(0,25));query.collision_mask=1
	return game.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()
func complete_blink():
	if not target_valid(lock_target) or actor.position.distance_to(lock_target.position)>500:
		lock_target=null;return
	var target=lock_target;var landing=game.safe_ground(target.position-Vector2(target.facing*92,0))
	if landing.distance_to(target.position)>145 or not landing_clear(landing):lock_target=null;return
	game.fx.blink_fold(actor.position-Vector2(0,28),true,Color("be6765"))
	actor.position=landing;game.scene_motion.reset(actor);actor.facing=1 if target.position.x>=landing.x else -1
	actor.invincible=maxf(actor.invincible,.22);game.audio.play("dash",-5)
	game.fx.blink_fold(actor.position-Vector2(0,28),false,Color("be6765"))
	attack_target=target;rush_heavy=charged;start_rush();lock_target=null
func strike(previous_position):
	var left=minf(previous_position.x,actor.position.x)-48
	var area=Rect2(left,minf(previous_position.y,actor.position.y)-52,absf(previous_position.x-actor.position.x)+96,52+absf(previous_position.y-actor.position.y))
	var targets=[]
	for e in game.enemies:
		if not target_valid(e) or rush_hits.has(e.get_instance_id()):continue
		if area.intersects(Rect2(e.position-Vector2(e.radius,e.body_height),Vector2(e.radius*2,e.body_height))):targets.append(e)
	targets.sort_custom(func(a,b):return a.position.distance_squared_to(previous_position)<b.position.distance_squared_to(previous_position))
	for e in targets:
		if rush_hits.size()>=int(cfg("max_targets")):break
		rush_hits[e.get_instance_id()]=true
		e.take_hit(cfg("charged_damage") if rush_heavy else cfg("demon_damage"),"brother",actor.facing,true);actor.heal_on_hit()
		game.fx.melee_contact(e.position-Vector2(actor.facing*e.radius,22),"stone",actor.facing)
func _draw():
	if lock_left<=0:return
	var p=lock_point-actor.position-Vector2(0,28)
	if is_instance_valid(lock_target):p=lock_target.position-actor.position-Vector2(0,28)
	draw_arc(p,20,0,TAU*(1-lock_left/lock_total),20,effect_color(),2)
	draw_line(p-Vector2(27,0),p-Vector2(19,0),effect_color(),2)
	draw_line(p+Vector2(19,0),p+Vector2(27,0),effect_color(),2)

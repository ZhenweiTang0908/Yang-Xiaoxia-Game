extends CharacterBody2D
# The companion always spawns as the quadruped bull. No human actor or random transformation.
var game
var summon
var art
var skeletal_visual
var facing=1.0
var landing_time=0.0
var drop_time=0.0
var health=50.0
var max_health=50.0
var invincible=0.0
var hurt_time=0.0
var dead=false
var demon=true
var demon_controller
var body_height=52.0
var body_collision
var pinned_left=0.0
var pin_anchor=Vector2.ZERO
var pending_skill=""
var attack_anim=0.0
var casting=false
var arrived=false
func cfg(key):return game.tuning.get_value(key)
func _ready():
	max_health=cfg("ally_hp");health=max_health
	collision_layer=0;collision_mask=5;floor_snap_length=8
	body_collision=CollisionShape2D.new();var shape=RectangleShape2D.new();shape.size=Vector2(84,48)
	body_collision.shape=shape;body_collision.position=Vector2(0,-24);add_child(body_collision)
	demon_controller=load("res://scripts/actors/demon_controller.gd").new()
	demon_controller.actor=self;demon_controller.game=game;add_child(demon_controller);demon_controller.start(true)
	art=demon_controller.rig.art
func arrive():
	if arrived or dead or summon.phase!="active":return false
	arrived=true;demon_controller.rig.scale=Vector2.ONE;demon_controller.modulate=Color.WHITE
	invincible=maxf(invincible,.65);demon_controller.begin_assistance()
	return true
func _physics_process(dt):
	if not game.active() or game.hitstop>0:return
	invincible=maxf(0,invincible-dt);hurt_time=maxf(0,hurt_time-dt);apply_hit_tint()
	if summon.phase!="active":
		if summon.phase=="entering":
			var u=clampf((1.2-summon.remaining)/1.2,0,1)
			demon_controller.modulate.a=smoothstep(0,.35,u)
			demon_controller.rig.scale=Vector2.ONE*lerpf(.65,1,smoothstep(0,1,u))
			position=summon.anchor+Vector2(0,-sin(u*PI)*12)
		else:demon_controller.modulate.a=clampf(summon.remaining/.8,0,1)
		return
	if pinned_left>0:
		pinned_left=maxf(0,pinned_left-dt);position=pin_anchor;velocity=Vector2.ZERO
		attack_anim=0;pending_skill=""
		if pinned_left==0:clear_pin()
		return
	if not arrived:arrive()
	demon_controller.tick(dt)
# Kept as harmless compatibility hooks for older QA scripts, never a transformation route.
func try_transform(_forced_roll=-1.0):return false
func become_demon(_restoring=false):return false
func choose_target():
	var focus=game.player.current_target
	if is_instance_valid(focus) and not focus.dead and (focus.kind!="boss" or focus.active_battle) and absf(focus.position.x-game.player.position.x)<650:return focus
	var best=null;var dist=550.0
	for e in game.enemies:
		if not is_instance_valid(e) or e.dead or (e.kind=="boss" and not e.active_battle):continue
		var d=e.position.distance_to(game.player.position)
		if d<dist:best=e;dist=d
	return best
func release_child():
	if is_instance_valid(demon_controller):demon_controller.release_player()
func hurt_rect():return Rect2(position-Vector2(48 if demon else 12,body_height),Vector2(96 if demon else 24,body_height))
func apply_hit_tint():
	var tint=preload("res://scripts/combat/hit_feedback.gd").tint(hurt_time,.12)
	art.tint=tint
	if is_instance_valid(skeletal_visual):skeletal_visual.self_modulate=tint
	if demon and is_instance_valid(demon_controller) and is_instance_valid(demon_controller.rig):
		demon_controller.rig.art.tint=tint
		if is_instance_valid(demon_controller.rig.continuous):demon_controller.rig.continuous.self_modulate=tint
func pin(duration):
	if dead or summon.phase!="active":return false
	release_child();pinned_left=maxf(pinned_left,duration);pin_anchor=position;velocity=Vector2.ZERO
	pending_skill="";attack_anim=0;casting=false
	if demon and is_instance_valid(demon_controller):
		demon_controller.rush_left=0;demon_controller.rush_windup=0;demon_controller.lock_left=0;demon_controller.attack_age=10
	game.combat.remove_owner(get_instance_id())
	return true
func clear_pin():
	pinned_left=0;velocity=Vector2.ZERO
func take_damage(amount,direction=0.0,attack_sound="",source_owner=0,fixed=false):
	if dead or (invincible>0 and not fixed) or summon.phase!="active" or not game.active():return false
	var actual=amount if fixed else amount*cfg("demon_incoming")
	health=maxf(0,health-actual)
	invincible=cfg("ally_iframes");hurt_time=.12;apply_hit_tint()
	if not game.audio.enemy_cue(attack_sound,"impact",-5):game.audio.play("hurt",-7)
	game.fx.hit_mark(position-Vector2(0,body_height*.5),direction,Color("ffe1ad"),1.1)
	game.fx.number(position-Vector2(0,body_height),actual,Color("dca28d"))
	if health<=0:
		dead=true;clear_pin();release_child();summon.begin_leaving();game.show_hint("牛大侠灵体耗尽，暂归葫芦。",3)
	if not dead and is_instance_valid(game.boss) and source_owner==game.boss.get_instance_id() and game.boss.spec.id=="knight":
		game.boss.on_ally_hit(self,attack_sound)
	return true
func heal_on_hit():
	if demon and not dead and summon.phase=="active":health=minf(max_health,health+cfg("lifesteal"))

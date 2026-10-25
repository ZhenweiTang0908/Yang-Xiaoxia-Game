extends Node2D
var game
var unlocked=false
var phase="locked"
var remaining=0.0
var brother=null
var gourd=Vector2.ZERO
var anchor=Vector2.ZERO
var clock=0.0
var transition_started=0.0
# Gourd seal: a temporary lockout separate from the normal leave → cooldown flow.
const SEAL_RETURN=.35
var sealed=0.0
var seal_total=0.0
var seal_return=0.0
var seal_from=Vector2.ZERO
var seal_ground=Vector2.ZERO
var seal_fall=0.0
var seal_resume={}
var entry_penalty=0.0
func reset(available):
	if is_instance_valid(brother):brother.release_child();game.combat.remove_owner(brother.get_instance_id());brother.queue_free()
	brother=null;unlocked=available;phase="ready" if available else "locked";remaining=0
	sealed=0;seal_total=0;seal_return=0;seal_resume={};entry_penalty=0
	gourd=game.player.position+Vector2(-20,-30);anchor=gourd
func unlock():
	unlocked=true;phase="ready";remaining=0;game.progress.gourd=true;game.progress.story_seen=true;game.save_progress()
func arrow_hit():
	if phase=="active" and is_instance_valid(brother) and not brother.dead:
		remaining=maxf(minf(remaining,1.0),remaining-8.0)
		game.audio.play("gourd_seal",-6);game.fx.ring(brother.position-Vector2(0,35),Color("b397d1"),28,.3)
	elif phase=="entering" and is_instance_valid(brother):entry_penalty+=8
	else:seal(game.tuning.get_value("knight_hit_seal"))
func is_sealed():return phase=="sealed"
func seal_left():return sealed+seal_return if is_sealed() else 0.0
func request():
	if not unlocked:game.show_hint("通关月下山门后，牛大侠会赠予召唤葫芦。");return false
	if is_sealed():game.show_hint("葫芦被封 · "+str(ceili(seal_left()))+" 秒后归位",2);return false
	if phase!="ready":return false
	phase="entering";remaining=1.2;entry_penalty=0
	anchor=game.safe_ground(game.player.position+Vector2(-game.player.facing*35,0))
	gourd=anchor-Vector2(0,24)
	brother=load("res://scripts/actors/brother.gd").new();brother.game=game;brother.summon=self;brother.position=anchor;add_child(brother);game.scene_motion.register(brother)
	game.audio.play("gourd_grow",-3);game.audio.play("gourd_open",0);game.fx.ring(gourd,game.TEAL,40,.6)
	return true
# Repeated seals keep the longer remaining time and never spawn a second gourd.
func seal(duration):
	if not unlocked or duration<=0:return false
	if is_sealed():
		sealed=maxf(sealed,duration);seal_total=maxf(seal_total,sealed)
		if seal_return>0:seal_return=0;seal_fall=0;seal_ground=drop_point(gourd)
		return true
	match phase:
		"entering":seal_resume={"phase":"ready","remaining":0.0}
		"active":
			seal_resume={"phase":"active","remaining":remaining}
			if is_instance_valid(brother):seal_resume.health=brother.health;seal_resume.demon=brother.demon
		"leaving":seal_resume={"phase":"cooldown","remaining":game.tuning.get_value("summon_cooldown")}
		"cooldown":seal_resume={"phase":"cooldown","remaining":remaining}
		_:seal_resume={"phase":"ready","remaining":0.0}
	if is_instance_valid(brother):
		var at=brother.position
		brother.clear_pin();brother.release_child();brother.pending_skill="";game.combat.remove_owner(brother.get_instance_id());brother.queue_free()
		game.fx.blink_fold(at-Vector2(0,40),true,Color("8a8f9a"))
	brother=null;phase="sealed";sealed=duration;seal_total=duration;seal_return=0;seal_fall=0
	seal_ground=drop_point(gourd)
	game.audio.play("gourd_seal",-2)
	return true
# Ends a seal early (the knight fell): the gourd still flies home before it works again.
func clear_seal():
	if is_sealed() and sealed>0:sealed=0;seal_return=SEAL_RETURN;seal_from=gourd
func drop_point(from):
	var side=-1.0 if game.player.facing>0 else 1.0
	return game.safe_ground(Vector2(clampf(from.x+side*26,30,game.level.length-30),minf(from.y,440)))-Vector2(0,6)
func restore_from_seal():
	phase=seal_resume.get("phase","ready");remaining=float(seal_resume.get("remaining",0.0))
	if phase=="active":
		var at=game.safe_ground(game.player.position+Vector2(-game.player.facing*40,0))
		anchor=at
		brother=load("res://scripts/actors/brother.gd").new();brother.game=game;brother.summon=self;brother.position=at;add_child(brother);game.scene_motion.register(brother)
		brother.health=minf(brother.max_health,float(seal_resume.get("health",brother.max_health)))
		brother.arrived=true;brother.invincible=maxf(brother.invincible,.65)
		game.fx.blink_fold(at-Vector2(0,35),false,game.TEAL)
	seal_resume={}
	game.audio.play("gourd_return",-2);game.fx.ring(gourd,game.TEAL,26,.35)
func _physics_process(dt):
	if not game or not game.active() or game.hitstop>0:return
	clock+=dt
	match phase:
		"entering":
			remaining=maxf(0,remaining-dt)
			if remaining==0:phase="active";remaining=maxf(1,game.tuning.get_value("assist_duration")+game.upgrade_level("brother")*4-entry_penalty);entry_penalty=0;brother.arrive()
		"active":
			remaining=maxf(0,remaining-dt)
			if remaining==0:
				begin_leaving()
		"leaving":
			remaining=maxf(0,remaining-dt)
			if remaining==0:
				if is_instance_valid(brother):brother.release_child();game.combat.remove_owner(brother.get_instance_id());brother.queue_free()
				brother=null;phase="cooldown";remaining=game.tuning.get_value("summon_cooldown");game.audio.play("gourd_close",-3);game.audio.play("card_recall",-5)
		"cooldown":
			remaining=maxf(0,remaining-dt)
			if remaining==0:phase="ready";game.audio.play("summon_ready",-2)
		"sealed":
			if sealed>0:
				sealed=maxf(0,sealed-dt)
				# The gourd drops beside the hero and rests on the ground; it does not follow.
				seal_fall+=1080*dt
				gourd.x=move_toward(gourd.x,seal_ground.x,120*dt)
				gourd.y=minf(seal_ground.y,gourd.y+seal_fall*dt)
				if gourd.y>=seal_ground.y:seal_fall=0
				if sealed==0:seal_return=SEAL_RETURN;seal_from=gourd
			else:
				seal_return=maxf(0,seal_return-dt)
				var u=1-seal_return/SEAL_RETURN
				var goal=game.player.position+Vector2(-game.player.facing*23,-34)
				gourd=seal_from.lerp(goal,smoothstep(0,1,u))+Vector2(0,-sin(u*PI)*26)
				if seal_return==0:restore_from_seal()
	if phase not in ["entering","sealed"]:
		var goal=game.player.position+Vector2(-game.player.facing*23,-34+sin(clock*3)*2)
		gourd=gourd.lerp(goal,1-exp(-dt*7))
	queue_redraw()
func _draw():
	if not unlocked:return
	var scale_factor=1.0
	if phase=="entering":scale_factor=1+sin((1.2-remaining)/1.2*PI)*3.3
	var c=Color("b38b55") if phase=="cooldown" else Color("d5bb78")
	var angle=sin(clock*22)*.06 if phase=="entering" else sin(clock*2)*.06
	if phase=="sealed":
		c=Color("7c776c")
		angle=1.25 if sealed>0 and seal_fall==0 else sin(clock*14)*.3
	draw_set_transform(gourd,angle,Vector2.ONE*scale_factor)
	draw_circle(Vector2(0,-4),3.5,c);draw_circle(Vector2(0,3),5,c)
	draw_line(Vector2(-4,-1),Vector2(4,-1),Color("4c5a52") if phase=="sealed" else Color("658970"),2);draw_rect(Rect2(-2,-9-(sin((1.2-remaining)/1.2*PI)*4 if phase=="entering" else 0),4,2),Color("795740"))
	if phase=="sealed" and sealed>0:
		# A dim binding band shows the gourd is sealed without a floating marker.
		draw_line(Vector2(-6,1),Vector2(6,5),Color("cfc6b0",.55),1.2)
	draw_set_transform(Vector2.ZERO)
	if phase in ["entering","leaving"]:
		var center=anchor-Vector2(0,35) if phase=="entering" else (brother.position-Vector2(0,40) if is_instance_valid(brother) else gourd)
		for i in 5:
			var a=clock*5+i*TAU/5;var p=center+Vector2(cos(a)*27,sin(a)*16)
			if phase=="leaving":p=p.lerp(gourd,1-remaining/.8)
			draw_set_transform(p,a);draw_rect(Rect2(-3,-5,6,10),Color("c7dec2"))
		draw_set_transform(Vector2.ZERO)

# The eagle cancels every summon state and starts a fresh, full cooldown.
func force_cooldown():
	if not unlocked:return false
	if is_instance_valid(brother):
		var at=brother.position-Vector2(0,35)
		brother.clear_pin();brother.release_child();brother.pending_skill=""
		game.combat.remove_owner(brother.get_instance_id());brother.hide();brother.queue_free()
		game.fx.blink_fold(at,true,game.TEAL)
	brother=null;phase="cooldown";remaining=game.tuning.get_value("summon_cooldown")
	sealed=0;seal_total=0;seal_return=0;seal_resume={};entry_penalty=0
	gourd=game.player.position+Vector2(-game.player.facing*23,-34)
	game.audio.play("card_recall",-5);game.audio.play("gourd_close",-3);queue_redraw()
	return true
func begin_leaving():
	if phase=="leaving":return
	phase="leaving";remaining=.8;game.audio.play("brother_leave",0)
	if is_instance_valid(brother):
		brother.clear_pin();brother.release_child();brother.pending_skill="";game.combat.remove_owner(brother.get_instance_id())

extends Node2D
# One boss resource: anger charges, delayed archer echoes and single-use ghost blows.
const ARROW_DAMAGE=5.0
const EMPOWERED_ARROW_DAMAGE=7.0
var actor
var rage=0.0
var release_ready=false
var legion=[]
var echoes=[]
var soldiers=[]
var last_echo=-100.0
var textures=[]
var clock=0.0
var empowered_count=0
func _ready():
	z_index=2
	for i in 12:textures.append(load("res://assets/art/knight_frames/soul/%02d.png"%i))
func absorb(damage,forced_roll=-1.0):
	var before=int(floor(rage+.00001))
	rage=minf(3.0,rage+maxf(0,damage)/maxf(1,actor.max_hp*actor.cfg("knight_rage_fraction")))
	var after=int(floor(rage+.00001))
	if after>before:
		actor.game.fx.ring(actor.position-Vector2(0,actor.body_height*.5),Color("c79de7"),54,.5)
		actor.game.fx.burst(actor.position-Vector2(0,actor.body_height*.45),7,Color("d4b3ff"),62)
		actor.sound("armor",-4)
		for cell in range(before+1,after+1):
			if release_ready:break
			var roll=randf() if forced_roll<0 else forced_roll
			if cell==3 or roll<actor.cfg("knight_rage_release")/100.0:release_ready=true
func ready_cells():
	return int(floor(rage+.00001)) if release_ready or rage>=2.999 else 0
func spend():
	rage=0;release_ready=false
func consume():
	if ready_cells()!=1:return false
	spend();empowered_count+=1
	actor.game.fx.burst(actor.position-Vector2(0,65),9,Color("c0a5e9"),70)
	actor.sound("guard",-2)
	return true
func queue_echo():
	if absf(actor.time-last_echo)<.02:return
	last_echo=actor.time
	var p=actor.game.player
	var x=clampf(actor.position.x+actor.facing*70,actor.arena.position.x+70,actor.arena.end.x-70)
	var at=Vector2(x,actor.GROUND-190)
	var target=p.position+Vector2(clampf(p.velocity.x*.25,-80,80),-23)
	if echoes.size()>=3:echoes.pop_front()
	echoes.append({"p":at,"aim":(target-at).normalized(),"age":0.0,"fired":false,"strong":actor.empowered})
func queue_soldiers():
	for i in 2:
		soldiers.append({"p":actor.position+Vector2(actor.facing*30,-30),"dir":actor.facing,"delay":.32+i*.27,"variant":"blade" if i==0 else "spear"})
func clear_attacks():
	echoes.clear();soldiers.clear();legion.clear()
	actor.ancient_pending=null;actor.ancient_target=null
	var ally=actor.game.summon.brother
	if is_instance_valid(ally) and ally.pinned_left>0:ally.clear_pin()
	queue_redraw()
func advance(dt):
	clock+=dt
	if actor.dead or actor.dismount_t>=0:clear_attacks();return
	advance_legion(dt)
	for ghost in echoes:
		ghost.age+=dt
		var release=.62 if ghost.strong else .55
		if ghost.age>=release and not ghost.fired:
			ghost.fired=true
			var shot=actor.game.combat.fire(ghost.p,ghost.aim*(608 if ghost.strong else 488),(EMPOWERED_ARROW_DAMAGE if ghost.strong else ARROW_DAMAGE),"enemy","soul_eagle" if ghost.strong else "soul_arrow",{"owner":actor.get_instance_id(),"life":1.7,"radius":17 if ghost.strong else 13})
			shot.slow=1.4;shot.attack_sound="knight:soul_arrow"
			actor.game.audio.enemy_cue("knight:soul_arrow","release",-5)
	echoes=echoes.filter(func(ghost):return ghost.age<1.05)
	for soldier in soldiers:
		soldier.delay-=dt
		if soldier.delay<=0:
			var shot=actor.game.combat.fire(soldier.p,Vector2(soldier.dir*560,0),actor.scaled_damage(10),"enemy","soul_soldier",{"owner":actor.get_instance_id(),"life":.9,"radius":24,"variant":soldier.variant})
			shot.attack_sound="knight:phantom"
			actor.game.audio.enemy_cue("knight:phantom","release",-5)
	soldiers=soldiers.filter(func(soldier):return soldier.delay>0)
	queue_redraw()
# The reinforced regiment (full three-cell rage) adds a fourth spear and a second
# blade that arrives in front of the hero later; every unit still telegraphs and
# strikes on its own, so there is never an unavoidable arena-wide hit.
func begin_legion(strong=false):
	var hero=actor.game.player
	var left=actor.arena.position.x+45;var right=actor.arena.end.x-45
	var spears=4 if strong else 3
	var blades=2 if strong else 1
	for i in 3+spears+blades:
		var kind="archer" if i<3 else ("spear" if i<3+spears else "blade")
		var side=-1.0 if i<3+spears+1 else 1.0
		var x=lerpf(left,right,(float(i%3)+.5)/3.0)
		if kind=="spear":x=clampf(hero.position.x-actor.arena.size.x*.38+float(i-3)*64,left,right)
		if kind=="blade":x=clampf(hero.position.x+side*hero.facing*85,left,right)
		var ground=Vector2(x,actor.GROUND-38)
		var age=-.09*i-(.45 if side>0 else 0.0)
		legion.append({"p":ground-Vector2(0,110),"ground":ground,"age":age,"kind":kind,"strong":strong or actor.empowered,"side":side,"dir":1.0,"aim":Vector2.RIGHT,"hits":0,"locked":false,"travel":0.0,"box":null})
func advance_legion(dt):
	for unit in legion:
		unit.age+=dt
		if unit.age<0:continue
		unit.p.y=lerpf(unit.ground.y-110,unit.ground.y,smoothstep(0,.5,unit.age))
		if unit.kind=="archer":
			for i in 3:
				var release=1.1+i*.95
				if unit.age>=release-.35 and unit.hits==i:
					var target=actor.game.player.position-Vector2(0,22)
					unit.dir=1.0 if target.x>unit.p.x else -1.0
					if unit.age-dt<release-.18:unit.aim=(target-unit.p).normalized()
				if unit.age>=release and unit.hits==i:
					unit.hits+=1
					var shot=actor.game.combat.fire(unit.p,unit.aim*510,(EMPOWERED_ARROW_DAMAGE if unit.strong else ARROW_DAMAGE),"enemy","soul_eagle" if unit.strong else "soul_arrow",{"owner":actor.get_instance_id(),"life":2.2})
					shot.empowered=unit.strong;shot.radius=17 if unit.strong else 13
					shot.attack_sound="knight:soul_arrow";actor.game.audio.enemy_cue(shot.attack_sound,"release",-6)
		elif unit.kind=="spear":
			if unit.age>=.8 and not unit.locked:
				unit.locked=true;unit.dir=1.0 if actor.game.player.position.x>unit.p.x else -1.0
				actor.game.audio.enemy_cue("knight:phantom","warning",-6)
			var overlap=maxf(0,minf(unit.age,1.9)-maxf(unit.age-dt,1.15))
			if overlap>0:
				if unit.box==null:
					unit.box=actor.game.combat.hazard(Rect2(),0,.95,unit_damage(unit),actor.get_instance_id(),"soul_soldier")
					unit.box.invisible=true;unit.box.sounded=true;unit.box.attack_sound="knight:phantom"
					unit.hits=1;actor.game.audio.enemy_cue("knight:phantom","release",-5)
				var old=unit.p.x;var distance=actor.arena.size.x/3.0/.75*overlap
				unit.travel+=distance;unit.p.x=clampf(old+unit.dir*distance,actor.arena.position.x+20,actor.arena.end.x-20)
				unit.box.rect=Rect2(minf(old,unit.p.x)-18,actor.GROUND-65,absf(unit.p.x-old)+100,60)
				if unit.dir<0:unit.box.rect.position.x-=64
			elif unit.age>=1.9 and unit.box!=null:
				unit.box.rect=Rect2();unit.box.duration=0;unit.box=null
		else:
			if unit.age>=.55 and not unit.locked:
				unit.locked=true
				var hero=actor.game.player
				unit.p.x=clampf(hero.position.x+unit.get("side",-1.0)*hero.facing*70,actor.arena.position.x+25,actor.arena.end.x-25)
				unit.dir=1.0 if hero.position.x>unit.p.x else -1.0
				actor.game.fx.blink_fold(unit.p,true,Color("b299e4"));actor.game.audio.enemy_cue("knight:phantom","warning",-4)
			if unit.age>=1.05 and unit.hits==0:
				unit.hits=1
				var a=unit.p.x;var b=a+unit.dir*112
				var box=actor.game.combat.hazard(Rect2(minf(a,b),actor.GROUND-83,absf(b-a),80),0,.16,unit_damage(unit),actor.get_instance_id(),"soul_soldier")
				box.invisible=true;box.sounded=true;box.attack_sound="knight:phantom"
				actor.game.fx.slash(unit.p,unit.dir,Color("c3a1fb"),62);actor.game.audio.enemy_cue("knight:phantom","release",-3)
	legion=legion.filter(func(unit):return unit.age<(3.65 if unit.kind=="archer" else 2.35))
func unit_damage(unit):return 14.0 if unit.strong else 12.0
func draw_sprite(index,at,dir,height,alpha):
	var texture=textures[index];var size=texture.get_size();var scale=height/size.y
	draw_set_transform(at,0,Vector2(-dir,1))
	draw_texture_rect(texture,Rect2(Vector2(-size.x*scale*.5,-height*.6),size*scale),false,Color(1,1,1,alpha))
	draw_set_transform(Vector2.ZERO)
func _draw():
	if actor.dead:return
	draw_divine_effects()
	for unit in legion:
		if unit.age<0:continue
		var active=unit.hits>0 if unit.kind!="archer" else false
		for i in 3:
			if absf(unit.age-(1.1+i*.95))<.18:active=true
		var index=(1 if active else 0) if unit.kind=="archer" else ((5 if active else 4) if unit.kind=="blade" else (6 if active else 7))
		draw_sprite(index,unit.p-actor.position,unit.dir,112,minf(1,unit.age/.2)*(1-smoothstep(3.25 if unit.kind=="archer" else 1.95,3.65 if unit.kind=="archer" else 2.35,unit.age)))
	for ghost in echoes:
		var fade=minf(1,ghost.age/.12)*(1-smoothstep(.8,1.05,ghost.age))
		var at=ghost.p-actor.position
		draw_circle(at,34,Color(.48,.22,.75,.12*fade))
		draw_sprite(1 if ghost.fired else 2,at,signf(ghost.aim.x),116,fade*.88)
		for i in 4:
			var a=clock*2+i*TAU/4
			draw_arc(at+Vector2(0,28),16+i*3,a,a+.8,8,Color(.72,.49,.96,.25*fade),1.4,true)
	if rage>=1 and actor.action=="":
		var center=Vector2(0,-actor.body_height*.48)
		for i in 3:
			var a=clock*1.6+i*TAU/3
			draw_arc(center,28+i*5,a,a+1.3,9,Color(.76,.55,.96,.20),1.4,true)
	if actor.empowered and actor.action!="":
		var center=Vector2(0,-actor.body_height*.48)
		for i in 5:
			var a=clock*3+i*TAU/5
			var at=center+Vector2(cos(a)*34,sin(a)*48)
			draw_line(at,at+Vector2(-actor.facing*9,-7),Color(.94,.72,1,.55),2,true)
		if actor.windup>0:draw_arc(center,44,clock*4,clock*4+PI,22,Color(1,.78,.42,.35),2,true)
	var p=actor.game.player
	if is_instance_valid(p) and p.soul_slow>0:
		var at=p.position-actor.position-Vector2(0,14)
		draw_arc(at,15,clock*4,clock*4+PI*1.5,18,Color(.75,.48,1,.65),2,true)

func draw_divine_effects():
	var ally=actor.game.summon.brother
	if is_instance_valid(ally) and ally.pinned_left>0:
		var at=ally.pin_anchor-actor.position
		draw_line(at-Vector2(0,150),at-Vector2(0,10),Color("20172e"),8,true)
		draw_line(at-Vector2(0,150),at-Vector2(0,10),Color("c6a4f4"),3,true)
		draw_colored_polygon(PackedVector2Array([at+Vector2(-8,-28),at+Vector2(0,8),at+Vector2(8,-28),at+Vector2(0,-19)]),Color("e3d2ff"))
		for i in 3:
			var y=-25-i*24
			draw_arc(at+Vector2(0,y),21+i*3,clock*2+i,clock*2+i+PI*1.6,22,Color(.65,.4,.9,.6),2,true)
	if actor.action=="ancient_spear" and actor.t>=.65 and actor.t<1.12:
		var target=actor.ancient_ally()
		if is_instance_valid(target):
			var end=target.position-actor.position
			var tip=Vector2(0,-45).lerp(end,(actor.t-.65)/.47)
			draw_line(tip-Vector2(0,120),tip,Color("d8baff"),6,true)
			draw_line(tip-Vector2(0,120),tip,Color("fff0ff"),2,true)

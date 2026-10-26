extends Node2D
# One boss resource: anger charges, delayed archer echoes and single-use ghost blows.
const ARROW_DAMAGE=6.0
const EMPOWERED_ARROW_DAMAGE=8.0
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
func spend_cell():
	# Two ready cells may pay for one empowered attack; the other cell stays charged.
	rage=maxf(0,rage-1.0);empowered_count+=1
	actor.game.fx.burst(actor.position-Vector2(0,65),9,Color("c0a5e9"),70)
	actor.sound("guard",-2)
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
	actor.sound("ghost_rise",-4)
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
			actor.sound("ghost_glide",-3)
			var shot=actor.game.combat.fire(soldier.p,Vector2(soldier.dir*560,0),actor.scaled_damage(10),"enemy","soul_soldier",{"owner":actor.get_instance_id(),"life":.9,"radius":24,"variant":soldier.variant})
			shot.attack_sound="knight:phantom"
			actor.game.audio.enemy_cue("knight:phantom","release",-5)
	soldiers=soldiers.filter(func(soldier):return soldier.delay>0)
	queue_redraw()
# Three archers, three charging spears and one blade behind the hero; every unit
# telegraphs and strikes on its own, so there is never an unavoidable arena-wide hit.
func begin_legion():
	var hero=actor.game.player
	var left=actor.arena.position.x+45;var right=actor.arena.end.x-45
	var spears=3
	for i in 3+spears+1:
		var kind="archer" if i<3 else ("spear" if i<3+spears else "blade")
		var side=-1.0
		var x=lerpf(left,right,(float(i%3)+.5)/3.0)
		if kind=="spear":x=clampf(hero.position.x-actor.arena.size.x*.38+float(i-3)*64,left,right)
		if kind=="blade":x=clampf(hero.position.x+side*hero.facing*85,left,right)
		var ground=Vector2(x,actor.GROUND-38)
		var age=-.09*i-(.45 if side>0 else 0.0)
		legion.append({"p":ground-Vector2(0,110),"ground":ground,"age":age,"kind":kind,"side":side,"dir":1.0,"aim":Vector2.RIGHT,"hits":0,"locked":false,"travel":0.0,"box":null})
func advance_legion(dt):
	for unit in legion:
		unit.age+=dt
		if unit.age<0:continue
		if unit.age-dt<=0:actor.sound("ghost_rise",-5)
		var fade_at=3.25 if unit.kind=="archer" else 1.95
		if unit.age>=fade_at and unit.age-dt<fade_at:actor.sound("ghost_fade",-6)
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
					var shot=actor.game.combat.fire(unit.p,unit.aim*510,ARROW_DAMAGE,"enemy","soul_arrow",{"owner":actor.get_instance_id(),"life":2.2})
					shot.radius=13
					shot.attack_sound="knight:soul_arrow";actor.game.audio.enemy_cue(shot.attack_sound,"release",-6)
		elif unit.kind=="spear":
			if unit.age>=.8 and not unit.locked:
				unit.locked=true;unit.dir=1.0 if actor.game.player.position.x>unit.p.x else -1.0
				actor.sound("ghost_glide",-4)
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
				actor.game.fx.blink_fold(unit.p,true,Color("b299e4"));actor.sound("ghost_glide",-3);actor.game.audio.enemy_cue("knight:phantom","warning",-4)
			if unit.age>=1.05 and unit.hits==0:
				unit.hits=1
				var a=unit.p.x;var b=a+unit.dir*112
				var box=actor.game.combat.hazard(Rect2(minf(a,b),actor.GROUND-83,absf(b-a),80),0,.16,unit_damage(unit),actor.get_instance_id(),"soul_soldier")
				box.invisible=true;box.sounded=true;box.attack_sound="knight:phantom"
				actor.game.fx.slash(unit.p,unit.dir,Color("c3a1fb"),62);actor.game.audio.enemy_cue("knight:phantom","release",-3)
	legion=legion.filter(func(unit):return unit.age<(3.65 if unit.kind=="archer" else 2.35))
func unit_damage(_unit):return 12.0
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
		var ground=ally.pin_anchor-actor.position
		var left=clampf(ally.pinned_left/10.0,0,1)
		# Flattened binding seal on the floor; its ring drains with the remaining pin time.
		draw_set_transform(ground,0,Vector2(1,.24))
		draw_circle(Vector2.ZERO,30,Color(.45,.25,.7,.12))
		draw_arc(Vector2.ZERO,30,-PI/2,-PI/2+TAU*left,40,Color(.80,.62,1,.75),3,true)
		draw_arc(Vector2.ZERO,22,clock*.8,clock*.8+TAU,32,Color(.66,.45,.95,.35),1.5,true)
		for i in 6:
			var a=clock*.8+i*TAU/6
			draw_line(Vector2.from_angle(a)*22,Vector2.from_angle(a)*27,Color(.85,.72,1,.6),2)
		draw_set_transform(Vector2.ZERO)
		# Cracks where the point bit into the floor.
		for i in 4:
			var d=Vector2(-1 if i%2 else 1,0).rotated((i/2)*.25)*(10+i*3)
			draw_polyline(PackedVector2Array([ground,ground+d*.5+Vector2(0,1),ground+d]),Color("2a2236"),1.2)
		var dir=Vector2(.17,1).normalized()
		var tip=ground+Vector2(0,3)
		# Two thin wisps coil around the shaft.
		for k in 2:
			var points=PackedVector2Array()
			for i in 13:
				var u=i/12.0
				var along=tip-dir*(30+u*90)
				points.append(along+dir.orthogonal()*sin(u*TAU*1.5+clock*3+k*PI)*5)
			draw_polyline(points,Color(.78,.6,1,.35),1.2,true)
		draw_spear(tip,dir,128,1.0)
	if actor.action=="ancient_spear" and actor.t>=.65 and actor.t<1.12:
		var target=actor.ancient_ally()
		if is_instance_valid(target):
			var hand=Vector2(0,-45)
			var end=target.position-actor.position
			var u=(actor.t-.65)/.47
			var tip=hand.lerp(end,u)
			var dir=(end-hand).normalized()
			# Motion streak behind the thrown spear.
			for i in 5:
				draw_line(tip-dir*(40+i*14),tip-dir*(70+i*18),Color(.75,.55,1,.28-i*.05),4.0-i*.6,true)
			draw_spear(tip,dir,128,1.0)
# A single spear: lacquered shaft, bronze fittings, leaf blade with a ridge, red tassel.
# `tip` is the blade point and `dir` the direction the point faces.
func draw_spear(tip,dir,length,alpha):
	var n=dir.orthogonal()
	var blade=24.0
	var base=tip-dir*blade
	var butt=tip-dir*length
	# Soft violet aura along the whole weapon.
	draw_line(butt,tip,Color(.62,.42,.95,.16*alpha),9,true)
	# Shaft: dark outline, lacquer, and a thin highlight on one side.
	draw_line(butt,base,Color(.08,.06,.11,alpha),5,true)
	draw_line(butt,base,Color("3d2c44",alpha),3,true)
	draw_line(butt+n*.8,base+n*.8,Color("7a6488",.8*alpha),1,true)
	# Bronze butt cap and collar.
	draw_line(butt,butt+dir*5,Color("b89a5e",alpha),5,true)
	draw_line(base-dir*5,base,Color("c9ab6a",alpha),6,true)
	draw_line(base-dir*5+n*1.5,base+n*1.5,Color("efd9a0",.7*alpha),1,true)
	# Leaf-shaped blade: widest a third of the way up, then a long taper.
	var leaf=PackedVector2Array([base+n*2.5,base+dir*8+n*5,base+dir*17+n*3.2,tip,base+dir*17-n*3.2,base+dir*8-n*5,base-n*2.5])
	var outline=PackedVector2Array(leaf);outline.append(leaf[0])
	draw_colored_polygon(leaf,Color("dcd7ea",alpha))
	draw_colored_polygon(PackedVector2Array([base,base+dir*8+n*5,base+dir*17+n*3.2,tip]),Color("f4f1fb",alpha))
	draw_line(base,tip-dir*2,Color("8a82a6",alpha),1.2,true)
	draw_polyline(outline,Color(.11,.08,.16,alpha),1.0,true)
	# Crimson tassel hanging from the collar, fluttering slightly.
	var hang=base-dir*6
	for i in 3:
		var sway=sin(clock*5+i*1.3)*2.5
		var end=hang+Vector2(sway+(i-1)*2.5,12+i*1.5)
		draw_line(hang,end,Color("8e3048",alpha),2,true)
		draw_line(hang,hang.lerp(end,.5),Color("c4566a",.8*alpha),1,true)
	draw_circle(hang,2.2,Color("c9ab6a",alpha))

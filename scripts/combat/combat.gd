extends Node2D
const SHAPES=preload("res://scripts/combat/vfx_shapes.gd")
const FINISH=preload("res://scripts/combat/skill_finish.gd")
const ENEMY_AUDIO=preload("res://scripts/combat/enemy_audio.gd")
# The sheep spirit deals 1.4× the hero's blade and ranged damage, 1.5× on a charged blast.
const SHEEP_HIT=1.4
const SHEEP_BLAST=1.5
var remnants=[]
var game
var shots=[]
var shot_endings=[]
var hazards=[]
var groups={}
var serial=0
var visual_clock=0.0
var fire_atlas:Texture2D
var projectile_visual
func _ready():
	projectile_visual=preload("res://scripts/combat/projectile_visual.gd").new();projectile_visual.combat=self;projectile_visual.z_index=2;add_child(projectile_visual)
	fire_atlas=load("res://assets/art/environment/fire.png")
	material=ShaderMaterial.new();material.shader=load("res://scripts/actors/chroma.gdshader")
func fire_sprite(rect,face,ground=false,offset=0.0):
	var frame=int((visual_clock+offset)*12)%4
	var source=Rect2(frame*384+40,610,300,310) if ground else Rect2(frame*384+20,125,364,290)
	if ground:draw_texture_rect_region(fire_atlas,rect,source)
	else:
		draw_set_transform(Vector2(rect.position.x if face>0 else rect.end.x,rect.get_center().y),0,Vector2(face,1))
		draw_texture_rect_region(fire_atlas,Rect2(0,-rect.size.y*.5,rect.size.x,rect.size.y),source)
		draw_set_transform(Vector2.ZERO)
func clear():
	shots.clear();hazards.clear();groups.clear();remnants.clear();shot_endings.clear()
	queue_redraw()
	if is_instance_valid(projectile_visual):projectile_visual.queue_redraw()
func remove_owner(owner):
	shots=shots.filter(func(s):return s.owner!=owner)
	shot_endings=shot_endings.filter(func(s):return s.owner!=owner)
	remnants=remnants.filter(func(e):return e.owner!=owner)
	hazards=hazards.filter(func(h):return h.owner!=owner)
	queue_redraw()
	if is_instance_valid(projectile_visual):projectile_visual.queue_redraw()
func fire(p,v,damage,faction="player",kind="arrow",opts={}):
	var s={"p":p,"origin":p,"v":v,"damage":damage,"faction":faction,"kind":kind,"variant":opts.get("variant","plain"),"life":opts.get("life",3.0),"age":0.0,"hits":{},"leg":0,"pierce":opts.get("pierce",0),"owner":opts.get("owner",0),"group":opts.get("group",0),"cap":opts.get("cap",999.0),"homing":opts.get("homing",false),"demon_hit":opts.get("demon_hit",false),"returning":opts.get("returning",false)}
	s.return_after=opts.get("return_after",.55);s.radius=opts.get("radius",13.0)
	s.attack_sound=opts.get("attack_sound",ENEMY_AUDIO.for_owner(s.owner))
	shots.append(s);return s
func new_group():serial+=1;return serial
func hazard(rect,delay,duration,damage,owner=0,kind="zone"):
	hazards.append({"rect":rect,"delay":delay,"duration":duration,"total":duration,"warning_total":delay,"damage":damage,"owner":owner,"kind":kind,"hit":false,"ally_hit":false,"sounded":false,"face":1.0,"age":0.0})
	hazards.back().attack_sound=ENEMY_AUDIO.for_owner(owner)
	return hazards.back()
func melee(p):
	var contact=""
	var blade_multiplier=game.upgrade_multiplier("blade",.15)
	var reach=80.0 if p.sheep() else (42.0 if game.use_skeletal else 58.0)
	if p.sheep() or not game.use_skeletal:game.fx.slash(p.position-Vector2(0,24),p.facing,game.GOLD if p.sheep() else game.TEAL,reach,p.combo if p.sheep() else 0)
	for e in game.enemies:
		if not is_instance_valid(e) or e.dead or (e.kind=="boss" and not e.active_battle):continue
		var d=e.position-p.position
		if d.x*p.facing>=-16 and d.x*p.facing<=reach+e.radius and absf(d.y)<e.body_height+25:
			p.current_target=e
			var surface="block" if e.kind=="shield" and p.facing==-e.facing else ("boss" if e.kind=="boss" else ("stone" if e.kind in ["imp","guardian","shield"] else "soft"))
			if contact=="" or ["block","soft","stone","boss"].find(surface)>["block","soft","stone","boss"].find(contact):contact=surface
			e.take_hit((18+p.combo*6)*(SHEEP_HIT if p.sheep() else 1.0)*blade_multiplier,"player",p.facing,false,p.sheep(),p.sheep())
			var point=Vector2(e.position.x-p.facing*e.radius,clampf(p.position.y-24,e.position.y-e.body_height+5,e.position.y-5))
			game.fx.melee_contact(point,surface,p.facing)
	if contact!="":
		game.shake=maxf(game.shake,1.0 if contact=="block" else (2.5 if p.combo==3 else 1.4))
		if not p.sheep():game.audio.melee_contact(contact,p.combo)
	if p.sheep() and p.combo==3:fire(p.position-Vector2(0,24),Vector2(p.facing*430,0),20*blade_multiplier,"player","wave",{"life":.65,"pierce":1})
func command_attack(p,id):
	var multiplier=game.upgrade_multiplier("blade",.15)
	var origin=p.position-Vector2(0,24)
	game.fx.command_effect(origin,id,p.facing,p if id=="rising" else null)
	var landed=false
	match id:
		"wave":
			fire(origin+Vector2(p.facing*18,0),Vector2(p.facing*460,0),42*multiplier,"player","wave",{"owner":p.get_instance_id(),"life":.8,"pierce":2})
			game.audio.play("ghostflame",-4)
		"spin","rising":
			var rising=id=="rising"
			if rising:p.velocity.y=-380;p.coyote=0;p.jump_buffer=0
			game.audio.play("blade_air_heavy",-3)
			for e in game.enemies:
				if not is_instance_valid(e) or e.dead or (e.kind=="boss" and not e.active_battle):continue
				var delta=e.position-p.position
				var in_range=absf(delta.x)<=90+e.radius and absf(delta.y)<e.body_height+25
				if rising:in_range=delta.x*p.facing>=-16 and delta.x*p.facing<=65+e.radius and delta.y>=-120 and delta.y<=e.body_height+15
				if in_range:e.take_hit((56 if rising else 38)*multiplier,"player",p.facing if rising else (-1 if delta.x<0 else 1),rising);landed=true
			# Connecting command blows land with a heavier stop and shake than a normal slash.
			if landed:game.hitstop=maxf(game.hitstop,.07);game.shake=maxf(game.shake,4.0 if rising else 3.0)
func blast(p,power):
	var radius=90+90*power
	var damage=(28+34*power+p.rage*.35)*(SHEEP_BLAST if p.sheep() else 1.0)
	p.rage=0;game.audio.play("sheep_blast" if p.sheep() else "blast");game.shake=5
	game.fx.ring(p.position-Vector2(0,20),game.GOLD,radius,.5);game.fx.burst(p.position-Vector2(0,20),22,game.GOLD,150)
	for e in game.enemies:
		if is_instance_valid(e) and not e.dead and (e.kind!="boss" or e.active_battle) and e.position.distance_to(p.position)<radius:
			e.take_hit(damage,"player",signf(e.position.x-p.position.x),true)
			if e.dead and p.sheep():p.health=minf(100,p.health+4)
func horn(p):
	for e in game.enemies:
		if not is_instance_valid(e) or e.dead or (e.kind=="boss" and not e.active_battle) or p.dash_victims.has(e.get_instance_id()):continue
		if e.position.distance_to(p.position)<e.radius+24:
			p.dash_victims[e.get_instance_id()]=true;e.take_hit(32,"player",p.facing,true)
func player_shot(p):
	game.audio.play("ghostflame" if p.sheep() else "bow")
	var damage=23*SHEEP_HIT+game.upgrade_level("spirit")*4 if p.sheep() else 23.0
	fire(p.position+Vector2(p.facing*16,-25),Vector2(p.facing*(440 if p.sheep() else 650),0),damage,"player","flame" if p.sheep() else "arrow",{"pierce":1 if p.sheep() else 0})
func _physics_process(dt):
	if not game or not game.active() or game.hitstop>0:return
	visual_clock+=dt
	for e in shot_endings:e.elapsed+=dt
	shot_endings=shot_endings.filter(func(e):return e.elapsed<.18)
	for e in remnants:e.age+=dt
	remnants=remnants.filter(func(e):return e.age<e.life)
	for s in shots:
		s.life-=dt;s.age+=dt
		if s.life<=0:
			continue
		if s.returning and s.age>s.return_after and s.leg==0:s.v=-s.v;s.leg=1
		if s.kind in ["return_card","knight_spear"] and s.leg==1:
			var caster=instance_from_id(s.owner)
			if is_instance_valid(caster):
				var destination=caster.position-Vector2(0,32 if s.kind=="knight_spear" else 49)
				s.v=(destination-s.p).normalized()*(940 if s.kind=="knight_spear" else 360)
				if destination.distance_to(s.p)<maxf(14,s.v.length()*dt+2):
					s.life=0
					if s.kind=="knight_spear":caster.catch_flash=.24;caster.sound("armor",-3)
					else:game.audio.play("card_recall",-8)
			elif s.kind=="knight_spear":s.life=0
		if s.kind=="knight_spear":
			var caster=instance_from_id(s.owner)
			if not is_instance_valid(caster) or caster.dead:s.life=0;continue
			if s.leg==0 and (s.p.x<caster.arena.position.x+18 or s.p.x>caster.arena.end.x-18):
				s.p.x=clampf(s.p.x,caster.arena.position.x+18,caster.arena.end.x-18);s.leg=1;s.v=-s.v
		if s.life<=0:continue
		if s.homing and s.age<1.3:
			var target=game.ally_target(s.p).position-Vector2(0,22)
			s.v=s.v.lerp((target-s.p).normalized()*s.v.length(),dt*1.8)
		var old=s.p;s.previous=s.p;s.p+=s.v*dt
		var query=PhysicsRayQueryParameters2D.create(old,s.p,1)
		var wall=game.get_world_2d().direct_space_state.intersect_ray(query)
		if wall:
			s.p=wall.position;s.wall_stop=true;s.life=0;game.fx.impact(wall.position,s.kind,s.v.normalized(),preload("res://scripts/combat/projectile_visual.gd").semantic_tint(s.kind,s.faction) if s.kind in ["orb","flame","ghost_orb"] else null)
		if s.life<=0:continue
		if s.faction=="enemy":
			var target=game.player.position-Vector2(0,21)
			var hero_key="hero:"+str(s.leg)
			if not s.hits.has(hero_key) and not game.player.is_carried() and Geometry2D.get_closest_point_to_segment(target,old,s.p).distance_to(target)<s.radius:
				# Seals apply only when the shot actually wounds the hero.
				if game.player.take_damage(s.damage,signf(s.v.x),s.kind,s.attack_sound):
					if s.kind in ["knight_arrow","soul_arrow","soul_eagle"]:game.summon.arrow_hit()
					elif s.get("seal",0.0)>0:game.summon.seal(s.seal)
					if s.get("slow",0.0)>0:game.player.soul_slow=maxf(game.player.soul_slow,minf(1.6,s.slow))
				s.hits[hero_key]=true
				if s.kind!="knight_spear":s.life=0

			if s.life>0 and game.summon.phase=="active" and is_instance_valid(game.summon.brother):
				var ally=game.summon.brother;var rect=ally.hurt_rect()
				var ally_key="ally:"+str(s.leg)
				if not s.hits.has(ally_key) and segment_hits_rect(old,s.p,rect):
					ally.take_damage(s.damage,signf(s.v.x),s.attack_sound,s.owner);s.hits[ally_key]=true
					if s.kind!="knight_spear":s.life=0
		else:
			for e in game.enemies:
				if not is_instance_valid(e) or e.dead or (e.kind=="boss" and not e.active_battle):continue
				var key=str(e.get_instance_id())+":"+str(s.leg)
				if s.hits.has(key):continue
				var center=e.position-Vector2(0,e.body_height*.5)
				if Geometry2D.get_closest_point_to_segment(center,old,s.p).distance_to(center)<e.radius+6:
					s.hits[key]=true
					var amount=s.damage
					if s.group>0:
						var gkey=str(s.group)+":"+str(e.get_instance_id())
						amount=minf(amount,maxf(0,s.cap-groups.get(gkey,0.0)));groups[gkey]=groups.get(gkey,0.0)+amount
					if amount>0:
						e.take_hit(amount,s.faction,signf(s.v.x),false)
						game.fx.impact(s.p,s.kind,s.v.normalized(),preload("res://scripts/combat/projectile_visual.gd").semantic_tint(s.kind,s.faction) if s.kind in ["orb","flame","ghost_orb"] else null)
						if s.faction=="brother":game.audio.play("card_hit",-6)
						if s.demon_hit:
							var caster=instance_from_id(s.owner)
							if is_instance_valid(caster):caster.heal_on_hit()
					if not s.returning:
						if s.pierce<=0:s.life=0;break
						s.pierce-=1
	# Expiry and collision share the same harmless visual tail. Previously a
	# collision removed the shot before the next tick could create its ending.
	for s in shots:
		if s.life<=0 and shot_endings.size()<24:
			shot_endings.append({"p":s.p,"v":s.v,"kind":s.kind,"variant":s.get("variant","plain"),"faction":s.faction,"owner":s.owner,"age":s.age,"elapsed":0.0,"wall_stop":s.get("wall_stop",false),"homing":s.homing})
	shots=shots.filter(func(s):return s.life>0)
	if shots.is_empty():groups.clear()
	for h in hazards:
		if h.delay>0:h.delay-=dt
		else:
			if not h.sounded:
				if h.attack_sound!="":
					if h.warning_total>0:game.audio.enemy_cue(h.attack_sound,"release",-3)
				else:game.audio.play("hit_stone" if h.kind in ["stone_impact","stone_wave"] else ("swing2" if h.kind in ["antler_sweep","blade_sweep","spectral_horn","sweep"] else ("ghostflame" if h.kind in ["fire","breath"] else "impact_magic")),-5)
				h.sounded=true
			h.duration-=dt;h.age+=dt
			var active_rect=damage_rect(h)
			if active_rect.has_area() and not game.player.is_carried() and not h.hit and hazard_hits(h,Rect2(game.player.position-Vector2(8,38),Vector2(16,38))):
				if game.player.take_damage(h.damage,signf(game.player.position.x-h.rect.get_center().x),h.kind,h.attack_sound) and h.get("seal",0.0)>0:game.summon.seal(h.seal)
				h.hit=true
			if not h.ally_hit and game.summon.phase=="active" and is_instance_valid(game.summon.brother):
				var ally=game.summon.brother
				if active_rect.has_area() and hazard_hits(h,ally.hurt_rect()):ally.take_damage(h.damage,0,h.attack_sound,h.owner);h.ally_hit=true
	for h in hazards:
		if h.duration<=0 and remnants.size()<24 and h.kind in ["fire","breath","spirit_beam","ritual","ground_rift","spirit_lightning","stone_wave","stone_impact","rain","antler_sweep","blade_sweep","spectral_horn","rift","binding_rune","pounce_impact"]:
			remnants.append({"kind":h.kind,"rect":damage_rect(h) if h.kind=="rain" else h.rect,"age":0.0,"life":.20 if h.kind=="rain" else .35,"owner":h.owner})
	hazards=hazards.filter(func(h):return h.duration>0)
	queue_redraw()
func _draw():
	for e in remnants:FINISH.draw_finish(self,e)
	for h in hazards:
		# The knight's hitboxes are shown by its own weapons, never as zones.
		if h.get("invisible",false):continue
		var c=Color("b0c2bd") if h.kind in ["stone_wave","stone_impact","antler_sweep"] else Color("ee9860");var r=h.rect
		if h.delay>0:
			FINISH.warning(self,h)
			continue
		match h.kind:
			"slam":
				var u=clampf(h.age/maxf(.001,h.total),0,1)
				var center=Vector2(r.get_center().x,r.end.y)
				var height=r.size.y*(1-u*.65)
				draw_colored_polygon(PackedVector2Array([center+Vector2(-3,-height),center+Vector2(3,-height),center+Vector2(1,0),center+Vector2(-1,0)]),Color(.91,.85,.72,1-u*.6))
				for side in [-1,1]:
					var reach=r.size.x*.5
					var front=lerpf(8,reach,smoothstep(0,.35,u))
					draw_polyline(PackedVector2Array([center+Vector2(side*3,-1),center+Vector2(side*front*.4,-5),center+Vector2(side*front*.7,-2),center+Vector2(side*front,-1)]),Color(.69,.64,.57,.8-u*.35),1.5)
					draw_line(center+Vector2(side*8,-2-u*8),center+Vector2(side*(12+u*17),-4-u*10),Color(.67,.70,.67,(1-u)*.55),1)
			"stone_wave","stone_impact":
				preload("res://scripts/combat/stone_motion.gd").draw_effect(self,h)
			"antler_sweep":
				var age=clampf(h.age/.2,0,1)
				for i in 2:
					var radius=r.size.x*.44-i*5
					var start=PI*.85+age*.5;var finish=TAU*.97+age*.4
					var center=r.get_center()+Vector2(i*6,4*i)
					var tint=Color(.82,.91,.87,(1-age)*(.88-i*.38))
					draw_arc(center,radius,start,finish,22,tint,2.4-i*.9)
					# Two short tines preserve a readable horn silhouette during the sweep.
					for u in [.42,.68]:
						var angle=lerpf(start,finish,u);var base=center+Vector2.from_angle(angle)*radius
						draw_line(base,base+Vector2.from_angle(angle-.52)*(12-i*3),Color(tint,tint.a*.9),1.4-i*.3)
			"blade_sweep":SHAPES.blade_sweep(self,r,h.face,h.age/maxf(.001,h.total),Color("d9e5df"))
			"spectral_horn":SHAPES.spectral_horn(self,r,h.face,h.age/maxf(.001,h.total),Color("9f94be"))
			"rift":SHAPES.rift(self,r,h.age/maxf(.001,h.total),Color("9e91bd"))
			"ground_rift":SHAPES.ground_rift(self,r,h.age/maxf(.001,h.total),Color("9484b2"))
			"fire":
				var count=mini(14,maxi(1,ceili(r.size.x/48)))
				for i in count:
					fire_sprite(fire_column(h,i,count),1,true,i*.073)
				for i in mini(4,count):
					var rise=fposmod(h.age*.8+i*.23,1)
					draw_line(Vector2(r.position.x+(i+.5)*r.size.x/mini(4,count),r.end.y-rise*minf(r.size.y,90)),Vector2(r.position.x+(i+.5)*r.size.x/mini(4,count)+1,r.end.y-rise*minf(r.size.y,90)-3),Color(1,.70,.36,(1-rise)*.55),1)
			"ritual":SHAPES.moon_ritual(self,r,h.age/maxf(.001,h.total),visual_clock,Color("9b8fbc"))
			"breath":
				var quad=breath_quad(h,true)
				if not quad.is_empty():
					var frame=int(visual_clock*12)%4
					var source=Rect2(frame*384+20,125,364,290)
					var uv=PackedVector2Array([source.position,Vector2(source.end.x,source.position.y),source.end,Vector2(source.position.x,source.end.y)])
					for i in uv.size():uv[i]/=fire_atlas.get_size()
					draw_polygon(quad,PackedColorArray([Color.WHITE]),uv,fire_atlas)
			"spirit_beam":SHAPES.spirit_beam(self,breath_quad(h,true),visual_clock,Color("a99bc7"))
			"lightning":SHAPES.bolt(self,Vector2(r.get_center().x,r.position.y),Vector2(r.get_center().x,r.end.y),visual_clock,c)
			"spirit_lightning":SHAPES.spirit_lightning(self,r,h.age/maxf(.001,h.total),visual_clock,Color("9f94be"))
			"binding_rune":SHAPES.binding_rune(self,r,h.age/maxf(.001,h.total),visual_clock,Color("9b8fbc"))
			"pounce_impact":SHAPES.pounce_impact(self,r,h.age/maxf(.001,h.total),Color("c0b6a0"))
			"beam":
				draw_line(Vector2(r.position.x,r.get_center().y),Vector2(r.end.x,r.get_center().y),Color(c,.2),r.size.y)
				draw_line(Vector2(r.position.x,r.get_center().y),Vector2(r.end.x,r.get_center().y),Color("fff0bf"),4)
			"rain":
				var blade=damage_rect(h);var x=blade.get_center().x;var tip=blade.end.y
				draw_line(Vector2(x,r.position.y),Vector2(x,blade.position.y),Color(.66,.70,.84,.18),1)
				FINISH.falling_blade(self,blade)
			"sweep","shadow":draw_arc(r.get_center(),r.size.x*.5,PI*.95,TAU*1.05,18,c,4)
			_:
				for x in range(int(r.position.x)+5,int(r.end.x),16):
					draw_colored_polygon(PackedVector2Array([Vector2(x-7,r.end.y),Vector2(x-3,r.position.y+5),Vector2(x+3,r.position.y),Vector2(x+8,r.end.y)]),Color(c,.8))

func segment_hits_rect(a,b,rect):
	if rect.has_point(a) or rect.has_point(b):return true
	var corners=[rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]
	for i in 4:
		if Geometry2D.segment_intersects_segment(a,b,corners[i],corners[(i+1)%4])!=null:return true
	return false

func breath_quad(h,render=false):
	var r=h.rect
	var extension=smoothstep(0,.10,h.age)*smoothstep(0,.12,maxf(0,h.duration))
	if extension<=0:return PackedVector2Array()
	var origin=Vector2(r.position.x if h.face>0 else r.end.x,r.get_center().y)
	var drop=0.0
	if h.get("staff_emitter",false):
		var caster=instance_from_id(h.owner)
		if is_instance_valid(caster):
			origin=caster.art.to_global(caster.art.casting_socket(15))
			if render:origin+=game.scene_motion.offset(caster)
		drop=10.0
	var tip=origin+Vector2(h.face*r.size.x*extension,drop*extension)
	var half=Vector2(0,r.size.y*.5)
	return PackedVector2Array([origin-half,tip-half,tip+half,origin+half])
func fire_column(h,index,count):
	var r=h.rect
	var x=r.position.x+index*r.size.x/count
	var growth=lerpf(.70,1.0,smoothstep(0,.07,h.age))
	var height=minf(r.size.y,95)*growth*(.86+.14*sin(index*2.4+h.age*2))
	return Rect2(x,r.end.y-height,minf(r.size.x/count+4,r.end.x-x),height)
func hazard_hits(h,rect):
	if h.kind=="fire":
		var count=mini(14,maxi(1,ceili(h.rect.size.x/48)))
		for i in count:
			if fire_column(h,i,count).intersects(rect):return true
		return false
	if h.kind not in ["breath","spirit_beam"]:return damage_rect(h).intersects(rect)
	var quad=breath_quad(h)
	if quad.is_empty():return false
	var target=PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
	return not Geometry2D.intersect_polygons(quad,target).is_empty()
func damage_rect(h):
	if h.kind in ["breath","spirit_beam"]:
		var quad=breath_quad(h)
		if quad.is_empty():return Rect2()
		var area=Rect2(quad[0],Vector2.ZERO)
		for point in quad:area=area.expand(point)
		return area
	if h.kind!="rain":return h.rect
	var r=h.rect
	var tip=lerpf(r.position.y+60,r.end.y,clampf(h.age/.12,0,1))
	return Rect2(r.get_center().x-7,maxf(r.position.y,tip-64),14,minf(64,tip-r.position.y))

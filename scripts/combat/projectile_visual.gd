extends Node2D
const SHAPES=preload("res://scripts/combat/vfx_shapes.gd")
var combat
var soul_textures={}
func _ready():
	for i in [5,6,11]:soul_textures[i]=load("res://assets/art/knight_frames/soul/%02d.png"%i)
static func faction_tint(faction):
	return Color("f0b086") if faction=="enemy" else (Color("a8dac0") if faction=="brother" else Color("92ddd2"))
static func semantic_tint(kind,faction):
	return Color("a99bc7") if kind=="ghost_orb" else faction_tint(faction)
func _process(_dt):queue_redraw()
func _draw():
	if not is_instance_valid(combat):return
	for e in combat.shot_endings:draw_ending(e)
	for s in combat.shots:
		var position=s.get("previous",s.p).lerp(s.p,combat.game.scene_motion.fraction())
		var c=semantic_tint(s.kind,s.faction)
		if s.kind in ["card","return_card"]:
			var direction=s.v.normalized()
			for i in [1,2]:draw_line(position-direction*(i*5+3),position-direction*(i*5),Color(c,.25/i),1)
			draw_set_transform(position,s.age*10,Vector2(.78+.22*cos(s.age*12),1))
			draw_card(c,1.0,s.get("variant","loop" if s.kind=="return_card" else "plain"))
			draw_set_transform(Vector2.ZERO)
		elif s.kind in ["orb","flame"]:
			draw_set_transform(position,s.v.angle()+PI/2)
			SHAPES.flame(self,Vector2(0,9),13,28,s.age,c)
			draw_set_transform(Vector2.ZERO)
		elif s.kind=="ghost_orb":
			draw_set_transform(position,s.v.angle())
			draw_ghost_orb(c,s.age,s.homing,1.0)
			draw_set_transform(Vector2.ZERO)
		elif s.kind=="blade":
			draw_set_transform(position,s.v.angle())
			draw_blade(c)
			draw_set_transform(Vector2.ZERO)
		elif s.kind=="wave":
			# Fading crescents trail the wave so its speed and path stay readable.
			var back=-s.v.normalized()
			for i in range(3,0,-1):
				draw_set_transform(position+back*i*11,s.v.angle(),Vector2.ONE*(1-i*.08))
				draw_wave(Color(c,c.a*(.42-i*.11)),1.0)
			draw_set_transform(position,s.v.angle(),Vector2.ONE*1.25)
			draw_wave(Color(c,c.a*.25),1.0)
			draw_set_transform(position,s.v.angle())
			draw_wave(c,1.0)
			draw_set_transform(Vector2.ZERO)
		elif s.kind in ["soul_arrow","soul_eagle","soul_soldier"]:
			var d=s.v.normalized();var purple=Color("c5a0fa")
			for i in 4:draw_line(position-d*(12+i*12),position-d*(25+i*12),Color(purple,.45/(i+1)),4-i*.65,true)
			if s.kind=="soul_arrow":
				draw_line(position-d*27,position,Color("d4b3ff"),3,true)
				draw_line(position-d*22,position+d*9,Color("f3e8ff"),1.5,true)
			else:
				var index=11 if s.kind=="soul_eagle" else (6 if s.variant=="spear" else 5)
				var texture=soul_textures[index]
				var size=texture.get_size();var height=52.0 if index==11 else 86.0
				var scale=height/size.y
				draw_set_transform(position,0,Vector2(-signf(s.v.x),1))
				draw_texture_rect(texture,Rect2(-size*scale*.5,size*scale),false,Color(1,1,1,minf(1,s.age/.08)))
				draw_set_transform(Vector2.ZERO)
		elif s.kind=="knight_spear":
			var angle=s.age*24*(1 if s.v.x>0 else -1)
			var gold=Color("e1c48c")
			for i in 4:
				var a=angle-i*.20
				draw_arc(position,43,a-1.3,a+.5,18,Color(gold,(4-i)*.09),3-i*.45,true)
			draw_set_transform(position,angle,Vector2.ONE*(1.23 if s.get("empowered",false) else 1.0))
			draw_line(Vector2(-45,0),Vector2(34,0),Color("201c23"),5)
			draw_line(Vector2(-45,0),Vector2(34,0),Color("ac8859"),2.5)
			draw_colored_polygon(PackedVector2Array([Vector2(32,-5),Vector2(55,0),Vector2(32,5),Vector2(36,0)]),Color("e0e6ec"))
			draw_colored_polygon(PackedVector2Array([Vector2(28,1),Vector2(13,12),Vector2(25,9)]),Color("a32e3f"))
			draw_set_transform(Vector2.ZERO)
		elif s.kind=="knight_arrow":
			var d=s.v.normalized();var n=d.orthogonal()
			if s.get("empowered",false):
				draw_line(position-d*70,position+d*8,Color(.72,.46,1,.22),13,true)
				draw_line(position-d*57,position+d*8,Color(1,.85,.56,.85),5,true)
				draw_line(position-d*45,position+d*8,Color(1,.98,.87,1),2,true)
			for i in 3:draw_line(position-d*(34+i*12),position-d*(43+i*12),Color(.93,.79,.52,.3/(i+1)),2.5-i*.6)
			draw_line(position-d*30,position,Color("16161f"),3.2);draw_line(position-d*30,position,Color("d7c8a4"),1.6)
			draw_colored_polygon(PackedVector2Array([position+n*3,position+d*7,position-n*3]),Color("dfe5ea"))
			for side in [-1,1]:draw_line(position-d*28,position-d*34+n*side*4,Color("c9453e"),1.6)
		elif s.kind=="dart":
			draw_set_transform(position,s.v.angle())
			draw_dart(c,1.0)
			draw_set_transform(Vector2.ZERO)
		else:
			var d=s.v.normalized();draw_line(position-d*16,position,c,2);draw_line(position,position-d.rotated(.5)*6,c,2)

func draw_ending(e):
	var u=clampf(e.elapsed/.18,0,1)
	var c=semantic_tint(e.kind,e.faction)
	c.a=(1-u)*.7
	var at=e.p if e.get("wall_stop",false) else e.p+e.v.normalized()*u*5
	if e.kind in ["card","return_card"]:
		draw_set_transform(at,e.age*10+u*.5,Vector2((.78+.22*cos(e.age*12))*(1-u*.85),1-u*.25))
		draw_card(c,c.a,e.get("variant","loop" if e.kind=="return_card" else "plain"))
	elif e.kind in ["orb","flame"]:
		draw_set_transform(at,e.v.angle()+PI/2)
		SHAPES.flame(self,Vector2(0,9*(1-u)),13*(1-u),28*(1-u),e.age+e.elapsed,c)
	elif e.kind=="ghost_orb":
		draw_set_transform(at,e.v.angle()+u*.2)
		draw_ghost_orb(c,e.age+e.elapsed,e.get("homing",false),1-u)
	elif e.kind=="blade":
		draw_set_transform(at,e.v.angle()+u*.15,Vector2(1-u*.2,1-u*.65))
		draw_blade(c)
	elif e.kind=="wave":
		draw_set_transform(at,e.v.angle(),Vector2.ONE*(1-u*.35))
		draw_wave(c,1-u)
	elif e.kind=="dart":
		draw_set_transform(at,e.v.angle()+u*.2,Vector2(1-u*.25,1-u*.55))
		draw_dart(c,1-u)
	else:
		draw_set_transform(at,e.v.angle())
		draw_line(Vector2(-12*(1-u),0),Vector2.ZERO,c,1)
	draw_set_transform(Vector2.ZERO)
func draw_blade(tint):
	draw_colored_polygon(PackedVector2Array([Vector2(-12,-3),Vector2(5,-2),Vector2(10,0),Vector2(3,3),Vector2(-12,2)]),tint)
	draw_line(Vector2(-10,-3),Vector2(7,-1),Color(1,.94,.85,tint.a),1)
func draw_dart(tint,alpha):
	var c=Color(tint,tint.a*alpha)
	draw_line(Vector2(-10,0),Vector2(6,0),c,1.3)
	draw_colored_polygon(PackedVector2Array([Vector2(6,-2),Vector2(11,0),Vector2(6,2)]),Color(.86,.87,.80,c.a))
	draw_line(Vector2(-8,0),Vector2(-12,-3),Color(c,c.a*.72),1)
	draw_line(Vector2(-8,0),Vector2(-12,3),Color(c,c.a*.72),1)
func draw_ghost_orb(tint,age,homing,alpha):
	var c=Color(tint,tint.a*alpha)
	if homing:
		# The eye-like soul core and bent tail make its steering intent readable.
		draw_colored_polygon(PackedVector2Array([Vector2(-7,0),Vector2(0,-6),Vector2(7,0),Vector2(0,6)]),Color(.18,.14,.28,.82*alpha))
		draw_circle(Vector2.ZERO,3.2,c)
		draw_circle(Vector2(1,0),1.1,Color(.88,.91,1,.9*alpha))
		var tail=PackedVector2Array([Vector2(-6,1),Vector2(-12,-2+sin(age*9)*2),Vector2(-18,2+sin(age*9+1)*2)])
		draw_polyline(tail,Color(c,c.a*.55),1.4)
	else:
		# A hollow flame wheel reads as one spoke in the radial ring attack.
		draw_arc(Vector2.ZERO,6,0,TAU,14,c,1.7)
		for i in 3:
			var a=age*4+i*TAU/3;var base=Vector2.from_angle(a)*6
			draw_line(base,base+Vector2.from_angle(a-.35)*5,Color(c,c.a*.62),1.2)
func draw_wave(tint,strength):
	# A tapered crescent points along velocity, including left/up/down shots.
	var edge=PackedVector2Array();var inner=PackedVector2Array()
	for i in 13:
		var u=float(i)/12
		var angle=lerpf(-1.1,1.1,u)
		edge.append(Vector2.from_angle(angle)*18)
		inner.append(Vector2.from_angle(angle)*(18-3*sin(u*PI)*strength))
	var shape=edge.duplicate()
	for i in range(inner.size()-1,-1,-1):shape.append(inner[i])
	draw_colored_polygon(shape,tint)
func draw_card(tint,alpha,variant="plain"):
	# Clipped corners and one central suit remain readable at native scale.
	var outline=PackedVector2Array([Vector2(-3,-7),Vector2(3,-7),Vector2(4,-6),Vector2(4,6),Vector2(3,7),Vector2(-3,7),Vector2(-4,6),Vector2(-4,-6)])
	draw_colored_polygon(outline,Color(.91,.93,.88,alpha))
	draw_rect(Rect2(-3,-5.5,6,11),Color(tint,alpha*.8),false,.7)
	var ink=Color(.25,.4,.36,alpha)
	match variant:
		"leaf":
			for angle in [-PI/2,PI/6,PI*5/6]:
				var tip=Vector2.from_angle(angle)*2.7
				draw_colored_polygon(PackedVector2Array([Vector2.ZERO,tip.rotated(-.34),tip,tip.rotated(.34)]),ink)
		"loop":
			draw_arc(Vector2.ZERO,2.4,-PI*.2,PI*1.45,9,ink,1)
			var tip=Vector2.from_angle(PI*1.45)*2.4
			draw_polyline(PackedVector2Array([tip+Vector2(-1,-1),tip,tip+Vector2(1,-1)]),ink,1)
		_:draw_colored_polygon(PackedVector2Array([Vector2(0,-3),Vector2(2,0),Vector2(0,3),Vector2(-2,0)]),ink)

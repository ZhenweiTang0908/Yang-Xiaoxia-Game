extends Node2D
var seals=[]
var impacts=[]
var particles=[]
var rings=[]
var slashes=[]
var labels=[]
var trails=[]
var game
var folds=[]
var recovery_glints=[]
var hit_marks=[]
var command_effects=[]
var hit_overlay:Node2D
func _ready():
	hit_overlay=Node2D.new();hit_overlay.z_index=5;add_child(hit_overlay);hit_overlay.draw.connect(draw_hit_marks)
func command_effect(p,id,face,actor=null):
	if command_effects.size()<6:
		var e={"p":p,"id":id,"face":face,"age":0.0}
		if actor!=null:e.actor=actor
		command_effects.append(e)
	if is_instance_valid(hit_overlay):hit_overlay.queue_redraw()
func hit_mark(p,direction,color,weight=1.0,style="hit"):
	if hit_marks.size()<16:hit_marks.append({"p":p,"direction":direction,"color":color,"weight":weight,"style":style,"age":0.0})
	if is_instance_valid(hit_overlay):hit_overlay.queue_redraw()
func recovery(p):
	if recovery_glints.size()<6:recovery_glints.append({"p":p,"age":0.0})
func blink_fold(p,entering,c):
	if folds.size()<8:folds.append({"p":p,"entering":entering,"color":c,"age":0.0})
var melee_contacts=[]
func melee_contact(p,surface,face):
	if melee_contacts.size()<12:melee_contacts.append({"p":p,"surface":surface,"face":face,"age":0.0})
func burst(p,count,c,speed):
	for i in mini(count,180-particles.size()):
		particles.append({"p":p,"v":Vector2.from_angle(randf()*TAU)*randf_range(speed*.25,speed),"life":randf_range(.18,.48),"color":c,"size":randf_range(1,3)})
func ring(p,c,r=70.0,time=.4):rings.append({"p":p,"color":c,"r":r,"left":time,"total":time})
func slash(p,face,c,radius=49.0,combo=0):slashes.append({"p":p,"face":face,"color":c,"left":.17,"r":radius,"combo":combo})
func number(p,amount,c):
	# Rapid hits share one number instead of stacking text over the actors.
	for entry in labels:
		if not entry.has("size") and entry.color==c and entry.left>.42 and entry.p.distance_to(p)<44:
			entry.text=str(int(entry.text)+int(amount));return
	if labels.size()>=6:labels.pop_front()
	# Stack above a number still fading at the same spot instead of overprinting it.
	for entry in labels:
		if absf(entry.p.x-p.x)<30 and entry.p.y<=p.y+4 and entry.p.y>p.y-14:p.y=entry.p.y-14
	labels.append({"p":p,"text":str(int(amount)),"left":.65,"color":c})
# A boss shouting its move or reaction: bigger, longer-lived, never merged.
func callout(p,text,c,size=18,life=1.1):
	labels=labels.filter(func(e):return not (e.has("size") and absf(e.p.x-p.x)<90 and e.p.y<p.y+30))
	if labels.size()>=6:labels.pop_front()
	labels.append({"p":p,"text":text,"left":life,"color":c,"size":size})
func trail(p,c,face=0):
	if trails.size()<24:
		var direction=signf(face) if absf(face)>.01 else (game.player.facing if is_instance_valid(game) and is_instance_valid(game.player) else 1)
		trails.append({"p":p,"color":c,"face":direction,"left":.16})
func clear(): particles.clear();rings.clear();slashes.clear();labels.clear();trails.clear();impacts.clear();seals.clear();melee_contacts.clear();folds.clear();recovery_glints.clear();hit_marks.clear();command_effects.clear()
func card_seal(p):
	if seals.size()<4:seals.append({"p":p,"age":0.0})
func impact(p,kind,direction,tint=null):
	if impacts.size()<24:impacts.append({"p":p,"kind":kind,"direction":direction,"age":0.0,"tint":tint})
func _process(dt):
	if is_instance_valid(hit_overlay):hit_overlay.queue_redraw()
	if game and (not game.active() or game.hitstop>0):queue_redraw();return
	for e in command_effects:e.age+=dt
	command_effects=command_effects.filter(func(e):return e.age<preload("res://scripts/combat/command_vfx.gd").life(e.id))
	for e in hit_marks:e.age+=dt
	hit_marks=hit_marks.filter(func(e):return e.age<.24)
	for e in recovery_glints:e.age+=dt
	recovery_glints=recovery_glints.filter(func(e):return e.age<.5)
	for e in folds:e.age+=dt
	folds=folds.filter(func(e):return e.age<.24)
	for e in melee_contacts:e.age+=dt
	melee_contacts=melee_contacts.filter(func(e):return e.age<.20)
	for e in seals:e.age+=dt
	seals=seals.filter(func(e):return e.age<.6)
	for e in impacts:e.age+=dt
	impacts=impacts.filter(func(e):return e.age<.24)
	for e in particles:e.p+=e.v*dt;e.v.y+=140*dt;e.life-=dt
	particles=particles.filter(func(e):return e.life>0)
	for list in [rings,slashes,labels,trails]:
		for e in list:e.left-=dt
	for e in labels:e.p.y-=dt*25
	rings=rings.filter(func(e):return e.left>0);slashes=slashes.filter(func(e):return e.left>0)
	labels=labels.filter(func(e):return e.left>0);trails=trails.filter(func(e):return e.left>0)
	queue_redraw()
func draw_hit_marks():
	for e in command_effects:preload("res://scripts/combat/command_vfx.gd").draw_effect(hit_overlay,e)
	for e in melee_contacts:preload("res://scripts/combat/melee_contact.gd").draw_effect(hit_overlay,e)
	for e in hit_marks:
		var u=e.age/.24;var fade=1-u;var radius=(10+u*22)*e.weight
		if e.style=="block":
			var angle=PI if e.direction>0 else 0.0
			hit_overlay.draw_arc(e.p,14+u*8,angle-1.0,angle+1.0,20,Color("4d9fca",fade*.28),7,true)
			hit_overlay.draw_arc(e.p,14+u*8,angle-1.0,angle+1.0,20,Color("bce9ff",fade),2.5,true)
			hit_overlay.draw_arc(e.p,8+u*5,angle-.72,angle+.72,16,Color("fff4c9",fade*.75),1.2,true)
			for i in 5:
				var ray=Vector2(-e.direction,0).rotated((i-2)*.42)
				var start=e.p+ray*(8+u*15);var finish=e.p+ray*(16+u*23)
				hit_overlay.draw_line(start,finish,Color("69b7db",fade*.42),3.5,true)
				hit_overlay.draw_line(start,finish,Color("fff4c9",fade),1.35,true)
			var block_flash=4*(1-smoothstep(.02,.30,u))
			var block_center=PackedVector2Array([e.p+Vector2(0,-block_flash*1.5),e.p+Vector2(block_flash,0),e.p+Vector2(0,block_flash*1.5),e.p+Vector2(-block_flash,0)])
			hit_overlay.draw_colored_polygon(block_center,Color("fff8df",fade*.88))
			continue
		for i in 6:
			var direction=Vector2.from_angle(i*TAU/6+.25*e.direction)
			var start=e.p+direction*radius*.34;var end=e.p+direction*radius
			var normal=direction.orthogonal()
			var shard=PackedVector2Array([start+normal*1.8*fade,end,end-normal*1.8*fade])
			hit_overlay.draw_colored_polygon(shard,Color(e.color,fade*.38))
			hit_overlay.draw_line(start,end,Color(e.color,fade*.22),4.2*fade+.5,true)
			hit_overlay.draw_line(start,end,Color(e.color,fade*.96),1.5*fade+.35,true)
		var arc_start=u*TAU*.55
		hit_overlay.draw_arc(e.p,radius*.72,arc_start,arc_start+PI*1.38,24,Color(e.color,fade*.56),1.25,true)
		if u<.35:
			var hit_flash=5*e.weight*(1-u/.35)
			var hit_center=PackedVector2Array([e.p+Vector2(0,-hit_flash*1.5),e.p+Vector2(hit_flash,0),e.p+Vector2(0,hit_flash*1.5),e.p+Vector2(-hit_flash,0)])
			hit_overlay.draw_colored_polygon(hit_center,Color("fff5de",fade*.90))
func _draw():
	for e in recovery_glints:
		for i in 3:
			var u=clampf((e.age-i*.035)/.4,0,1)
			var p=e.p+Vector2((i-1)*11,-8-i%2*6-u*18)
			var fade=sin(u*PI)*.55
			draw_colored_polygon(PackedVector2Array([p+Vector2(-1.5,0),p+Vector2(0,-4),p+Vector2(1.5,0),p+Vector2(0,2)]),Color(.62,.83,.73,fade))
	for e in folds:
		var u=clampf(e.age/.24,0,1)
		var spread=(1-u if e.entering else sin(u*PI))*18
		var fade=(1-u if e.entering else sin(u*PI))
		var phase=e.age*5.5*(1 if e.entering else -1)
		var lens=PackedVector2Array()
		for i in 25:
			var a=float(i)/24*TAU+phase
			lens.append(e.p+Vector2(cos(a)*spread,sin(a)*spread*.34))
		draw_colored_polygon(lens,Color(e.color,fade*.08))
		draw_polyline(lens,Color(e.color,fade*.28),5,true)
		draw_polyline(lens,Color(e.color,fade*.82),1.4,true)
		for side in [-1,1]:
			var x=side*spread
			draw_colored_polygon(PackedVector2Array([e.p+Vector2(x,-23),e.p+Vector2(x+side*4,-7),e.p+Vector2(x,20),e.p+Vector2(x-side*3,4)]),Color(e.color,fade*.56))
			var inner=e.p+Vector2(side*spread*.20,0)
			var outer=e.p+Vector2(side*spread*.86,-3)
			draw_line(inner,outer,Color(e.color,fade*.34),4,true)
			draw_line(inner,outer,Color("fff1d2",fade*.78),1.1,true)
		if u<.55:
			var core=12*(1-u/.55)
			draw_line(e.p-Vector2(core,0),e.p+Vector2(core,0),Color("fff5df",fade*.78),1.4,true)
		for i in 4:
			var a=i*TAU/4+phase*.42
			var radial=Vector2(cos(a),sin(a)*.34)
			var from=e.p+radial*(spread*.28)
			var to=e.p+radial*(spread*.92)
			draw_line(from,to,Color(e.color,fade*.58),1.1,true)
			var spark=to+radial*2
			draw_colored_polygon(PackedVector2Array([spark+Vector2(0,-2),spark+Vector2(1,0),spark+Vector2(0,2),spark+Vector2(-1,0)]),Color("fff4dc",fade*.8))
	for e in seals:
		var fade=1-e.age/.6;var radius=22+sin(clampf(e.age/.6,0,1)*PI)*4
		var points=PackedVector2Array()
		for i in 4:
			var a=i*TAU/4+.5;var p=e.p+Vector2(cos(a)*radius,sin(a)*radius*.3)
			points.append(p);draw_set_transform(p,a*.15)
			draw_rect(Rect2(-3,-5,6,10),Color(.88,.95,.88,fade*.8))
			draw_line(Vector2(0,-2),Vector2(0,2),Color(.25,.44,.36,fade),1)
			draw_set_transform(Vector2.ZERO)
		points.append(points[0]);draw_polyline(points,Color(.56,.79,.68,fade*.45),1)
	for e in impacts:
		var u=e.age/.24;var fade=1-u;var c=Color("bfdac7") if e.kind in ["card","return_card"] else (Color("a99bc7") if e.kind=="ghost_orb" else (Color("edb58b") if e.kind in ["orb","flame"] else Color("d7d7c2")))
		if e.kind=="hurt":c=Color("d79a88")
		if e.get("tint")!=null:c=e.tint
		var direction=e.direction.normalized() if e.direction.length_squared()>.01 else Vector2.RIGHT
		draw_arc(e.p,2+u*12,0,TAU,24,Color(c,fade*.38),1.35,true)
		draw_arc(e.p,3+u*7,PI*.15,PI*1.15,14,Color("fff1cf",fade*.52),.9,true)
		var ray_count=3 if e.kind in ["card","return_card"] else 5
		for i in ray_count:
			var angle=i*TAU/ray_count+e.age*2.8
			var ray=direction.rotated(angle-PI/ray_count)
			var start=e.p+ray*(2+u*5);var finish=e.p+ray*(7+u*12)
			draw_line(start,finish,Color(c,fade*.32),3.2*fade+.4,true)
			draw_line(start,finish,Color("fff2d5",fade*.9),1.0,true)
			if e.kind in ["card","return_card"]:
				var side=ray.orthogonal()
				draw_colored_polygon(PackedVector2Array([start+side*1.5*fade,finish,start-side*1.5*fade]),Color(c,fade*.78))
		if u<.38:
			var flash=4.5*(1-u/.38)
			var center=PackedVector2Array([e.p+Vector2(0,-flash),e.p+Vector2(flash*.7,0),e.p+Vector2(0,flash),e.p+Vector2(-flash*.7,0)])
			draw_colored_polygon(center,Color("fff8e5",fade*.9))

	for e in trails:
		var u=1-clampf(e.left/.16,0,1)
		var fade=clampf(e.left/.16,0,1)
		var center=e.p-Vector2(e.face*(5+u*12),u*4)
		var shape=PackedVector2Array()
		for point in [Vector2(-15,-20),Vector2(-3,-43),Vector2(9,-35),Vector2(13,-6),Vector2(-3,0)]:
			shape.append(center+Vector2(point.x*e.face,point.y))
		draw_colored_polygon(shape,Color(e.color,fade*.14))
		draw_polyline(shape,Color(e.color,fade*.28),6,true)
		draw_polyline(shape,Color(e.color.lerp(Color.WHITE,.32),fade*.65),1.25,true)
		for i in 3:
			var start=center+Vector2(-e.face*(14+i*4),-14+i*10)
			var finish=start+Vector2(-e.face*(7+u*5),-2+i*2)
			draw_line(start,finish,Color(e.color,fade*.46),1.15,true)
	for e in particles:
		var direction=e.v.normalized() if e.v.length_squared()>.01 else Vector2.UP
		var side=direction.orthogonal()
		var fade=clampf(e.life/.16,0,1)
		var length=4+e.size*2.2+minf(e.v.length()*.035,6)
		var tail=e.p-direction*length
		var tip=e.p+direction*e.size
		var width=e.size*.7*fade
		var shard=PackedVector2Array([tip, e.p+side*width, tail+direction*2, e.p-side*width])
		draw_line(tail,e.p,Color(e.color,fade*.20),e.size*1.8,true)
		draw_colored_polygon(shard,Color(e.color,fade*.68))
		draw_line(tail,tip,Color(e.color.lerp(Color.WHITE,.38),fade*.88),maxf(.8,e.size*.62),true)
	for e in rings:
		var progress=clampf(1-e.left/e.total,0,1)
		var fade=clampf(e.left/e.total,0,1)
		var radius=e.r*progress
		var rotation=progress*1.6
		var outer=PackedVector2Array()
		var inner=PackedVector2Array()
		for i in 49:
			var angle=float(i)/48*TAU
			var ripple=1+sin(angle*5+progress*TAU)*.012
			outer.append(e.p+Vector2.from_angle(angle+rotation)*(radius*ripple))
			inner.append(e.p+Vector2.from_angle(angle-rotation*.72)*(radius*.79*ripple))
		draw_polyline(outer,Color(e.color,fade*.18),6,true)
		draw_polyline(outer,Color(e.color,fade*.82),1.7,true)
		draw_polyline(inner,Color(e.color,fade*.38),1.0,true)
		var glint=Color(e.color.lerp(Color.WHITE,.45),fade*.72)
		draw_arc(e.p,radius*.94,rotation,rotation+PI*.58,24,glint,1.5,true)
		draw_arc(e.p,radius*.94,rotation+PI,rotation+PI*1.31,14,glint,1.1,true)
		for i in 6:
			var angle=i*TAU/6-rotation*.55
			var direction=Vector2.from_angle(angle)
			var start=e.p+direction*radius*.88
			var finish=e.p+direction*(radius+3+2*sin(progress*PI))
			draw_line(start,finish,Color(e.color,fade*.55),1.0,true)
	for e in slashes:
		if e.get("combo",0)>0:
			var u=1-e.left/.17;var points=PackedVector2Array()
			var rising=e.combo==3;var reverse=e.combo==2
			for i in 19:
				var fraction=float(i)/18
				var sweep=fraction*(.4+u*.6)
				var angle=lerpf(.85,-.95,sweep) if rising or reverse else lerpf(-.95,.85,sweep)
				var reach=e.r*(.72+.28*sin(fraction*PI))
				points.append(e.p+Vector2(cos(angle)*reach*e.face,sin(angle)*reach*(.60 if rising else .30)+u*4))
			draw_polyline(points,Color(.48,.78,.61,(1-u)*.20),5,true)
			draw_polyline(points,Color(.78,.96,.80,(1-u)*.82),1.5,true)
			continue
		var u=clampf(1-e.left/.17,0,1)
		var reveal=.16+.84*smoothstep(0,.44,u)
		var fade=1-u
		var center_angle=0.0 if e.face>0 else PI
		var start_angle=center_angle-1.2
		var sweep=2.3*reveal
		var outer=PackedVector2Array()
		var inner=PackedVector2Array()
		for i in 21:
			var t=float(i)/20
			var angle=start_angle+sweep*t
			var reach=e.r*(.78+.22*u)+sin(t*PI)*e.r*.035
			var thickness=(2.5+sin(t*PI)*4.5)*(1-u*.42)
			outer.append(e.p+Vector2(cos(angle),sin(angle)*.72)*reach)
			inner.append(e.p+Vector2(cos(angle),sin(angle)*.72)*(reach-thickness))
		var blade=outer.duplicate()
		for i in range(inner.size()-1,-1,-1):blade.append(inner[i])
		draw_colored_polygon(blade,Color(e.color,fade*.20))
		draw_polyline(outer,Color(e.color,fade*.22),6,true)
		draw_polyline(outer,Color(e.color.lerp(Color.WHITE,.38),fade*.92),1.8,true)
		draw_polyline(inner,Color(e.color,fade*.62),1.0,true)
		var tip=outer[outer.size()-1]
		var base=inner[inner.size()-1]
		var direction=Vector2.from_angle(start_angle+sweep)
		var point=tip+direction*4
		draw_colored_polygon(PackedVector2Array([tip,base,point]),Color(e.color.lerp(Color.WHITE,.52),fade*.9))
	for e in labels:
		if game:
			var size=e.get("size",13)
			var width=game.font.get_string_size(e.text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
			if e.has("size"):draw_string_outline(game.font,e.p-Vector2(width*.5,0),e.text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,4,Color(0,0,0,minf(.85,e.left*3)))
			draw_string(game.font,e.p-Vector2(width*.5,0),e.text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color(e.color,minf(1,e.left*3)))

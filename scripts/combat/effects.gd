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
		if entry.color==c and entry.left>.42 and entry.p.distance_to(p)<44:
			entry.text=str(int(entry.text)+int(amount));return
	if labels.size()>=6:labels.pop_front()
	labels.append({"p":p,"text":str(int(amount)),"left":.65,"color":c})
func trail(p,c):
	if trails.size()<24:trails.append({"p":p,"color":c,"left":.16})
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
			hit_overlay.draw_arc(e.p,14+u*8,angle-1.0,angle+1.0,20,Color("bce9ff",fade),2.5,true)
			for i in 4:
				var ray=Vector2(-e.direction,0).rotated((i-1.5)*.5)
				hit_overlay.draw_line(e.p+ray*(9+u*18),e.p+ray*(17+u*23),Color("fff4c9",fade),1.5,true)
			continue
		for i in 6:
			var direction=Vector2.from_angle(i*TAU/6+.25*e.direction)
			var start=e.p+direction*radius*.45;var end=e.p+direction*radius
			hit_overlay.draw_line(start,end,Color(e.color,fade*.9),2.2*fade+.5,true)
		if u<.35:
			hit_overlay.draw_line(e.p-Vector2(5,0)*e.weight,e.p+Vector2(5,0)*e.weight,Color("fff5de",fade),3,true)
			hit_overlay.draw_line(e.p-Vector2(0,5)*e.weight,e.p+Vector2(0,5)*e.weight,Color("fff5de",fade),3,true)
func _draw():
	for e in recovery_glints:
		for i in 3:
			var u=clampf((e.age-i*.035)/.4,0,1)
			var p=e.p+Vector2((i-1)*11,-8-i%2*6-u*18)
			var fade=sin(u*PI)*.55
			draw_colored_polygon(PackedVector2Array([p+Vector2(-1.5,0),p+Vector2(0,-4),p+Vector2(1.5,0),p+Vector2(0,2)]),Color(.62,.83,.73,fade))
	for e in folds:
		var u=e.age/.24
		var width=(1-u if e.entering else sin(u*PI))*17
		var fade=1-u
		for side in [-1,1]:
			var x=side*width
			draw_colored_polygon(PackedVector2Array([e.p+Vector2(x,-23),e.p+Vector2(x+side*3,-7),e.p+Vector2(x,20),e.p+Vector2(x-side*2,4)]),Color(e.color,fade*.5))
		if u<.5:draw_line(e.p-Vector2(0,18*(1-u)),e.p+Vector2(0,18*(1-u)),Color(e.color,fade*.65),1)
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
		var u=e.age/.24;var c=Color("bfdac7") if e.kind in ["card","return_card"] else (Color("a99bc7") if e.kind=="ghost_orb" else (Color("edb58b") if e.kind in ["orb","flame"] else Color("d7d7c2")))
		if e.kind=="hurt":c=Color("d79a88")
		if e.get("tint")!=null:c=e.tint
		for i in 3:
			var direction=e.direction.rotated((i-1)*.9+PI)
			var p=e.p+direction*(2+u*12)
			if e.kind in ["card","return_card"]:
				draw_colored_polygon(PackedVector2Array([p+Vector2(-2,0),p+Vector2(0,-2),p+Vector2(2,1)]),Color(c,(1-u)*.8))
			else:draw_line(p,p+direction*(3*(1-u)),Color(c,(1-u)*.9),1)

	for e in trails:
		draw_colored_polygon(PackedVector2Array([e.p+Vector2(-15,-20),e.p+Vector2(-3,-43),e.p+Vector2(9,-35),e.p+Vector2(13,-6),e.p+Vector2(-3,0)]),Color(e.color,e.left*2))
	for e in particles:
		var d=e.v.normalized()*e.size*2
		draw_line(e.p-d,e.p+d,Color(e.color,minf(1,e.life*4)),maxf(1,e.size*.6))
	for e in rings:draw_arc(e.p,e.r*(1-e.left/e.total),0,TAU,32,Color(e.color,e.left/e.total),2)
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
		var a=0 if e.face>0 else PI
		draw_arc(e.p,e.r,a-1.2,a+1.1,16,Color(e.color,e.left*5),3)
	for e in labels:
		if game:draw_string(game.font,e.p,e.text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color(e.color,minf(1,e.left*3)))

extends RefCounted
# Directional command techniques. Each has its own silhouette so the three read
# apart at a glance: a forward crescent, a two-sided whirl, a rising golden spiral.
const LIFE=.6
const LIVES={"wave":.42,"spin":.5,"rising":.6}
static func life(id):return LIVES.get(id,LIFE)
static func draw_effect(canvas,e):
	var u=clampf(e.age/life(e.id),0,1);var fade=1-u
	match e.id:
		"wave":wave(canvas,e,u,fade)
		"spin":spin(canvas,e,u,fade)
		"rising":rising(canvas,e,u,fade)
	canvas.draw_set_transform(Vector2.ZERO)
static func wave(canvas,e,u,fade):
	var jade=Color("8fe7dc");var white=Color("f1fff8")
	canvas.draw_set_transform(e.p,0,Vector2(e.face,1))
	# Launch flash: a tall crescent the hero slashes through.
	var grow=smoothstep(0,.25,u)
	for layer in 3:
		var r=26+grow*22+layer*5
		canvas.draw_arc(Vector2(6+u*18,0),r,-1.05,1.05,28,Color(jade if layer else white,fade*(.85-layer*.25)),4.0-layer*1.2,true)
	# Speed lines stretch forward along the blade's path.
	for i in 5:
		var y=(i-2)*7.0
		var x0=-20+u*40+absf(y)*.8;var x1=x0+30+u*70
		canvas.draw_line(Vector2(x0,y),Vector2(x1,y*.4),Color(white,fade*(.7 if i==2 else .3)),2.0 if i==2 else 1.0,true)
	# Ground streak under the lunge.
	canvas.draw_line(Vector2(-30,24),Vector2(-30+u*120,24),Color(jade,fade*.45),3,true)
	for i in 4:
		var x=-26+i*18+u*40
		canvas.draw_circle(Vector2(x,22-sin(u*PI+i)*5),2.2*fade,Color("cfe9df",fade*.6))
static func spin(canvas,e,u,fade):
	var jade=Color("8fe7dc");var white=Color("eaffef")
	canvas.draw_set_transform(e.p,0,Vector2(e.face,1))
	# Two full whirl rings, slightly offset, sweep both sides at once.
	for ring in 2:
		var rx=48+u*42+ring*12;var ry=14+u*10+ring*4
		var start=u*TAU*1.4+ring*PI
		var points=PackedVector2Array()
		for i in 33:
			var a=start+i/32.0*TAU*.82
			points.append(Vector2(cos(a)*rx,sin(a)*ry+4))
		canvas.draw_polyline(points,Color(jade,fade*(.55-ring*.2)),5.0-ring*2,true)
		canvas.draw_polyline(points,Color(white,fade*(.9-ring*.3)),1.4,true)
		canvas.draw_circle(points[points.size()-1],2.4-ring,Color(white,fade))
	# Leaves flung outward on both sides.
	for i in 8:
		var side=-1.0 if i%2 else 1.0
		var d=Vector2(side*(30+u*(70+i*6)),-6-i*3+u*u*30)
		var leaf=PackedVector2Array([d+Vector2(-3,0),d+Vector2(0,-2),d+Vector2(3,0),d+Vector2(0,2)])
		canvas.draw_colored_polygon(leaf,Color(.62,.86,.62,fade*.8))
	# Dust kicked up at both feet.
	for side in [-1,1]:
		canvas.draw_arc(Vector2(side*(20+u*50),24),10+u*10,PI+.3,TAU-.3,10,Color("cbbf9f",fade*.45),2,true)
static func rising(canvas,e,u,fade):
	var gold=Color("ffe2a0");var white=Color("fff5d5")
	# The spiral follows the hero upward from the launch point.
	var top=e.p
	if e.has("actor") and is_instance_valid(e.actor):top=e.actor.position-Vector2(0,30)
	var base=e.p+Vector2(0,24)
	canvas.draw_set_transform(Vector2.ZERO)
	# Flattened shock ring where the hero pushed off.
	canvas.draw_set_transform(base,0,Vector2(1,.22))
	canvas.draw_arc(Vector2.ZERO,20+u*60,0,TAU,40,Color(gold,fade*.6),6,true)
	canvas.draw_set_transform(Vector2.ZERO)
	var height=maxf(30,base.y-top.y+20)
	for strand in 2:
		var points=PackedVector2Array()
		for i in 29:
			var t=i/28.0
			var swirl=sin(t*TAU*1.5+u*8+strand*PI)*(12+t*10)
			points.append(Vector2(lerpf(base.x,top.x,t)+swirl*e.face,base.y-t*height))
		canvas.draw_polyline(points,Color(gold,fade*(.8 if strand==0 else .45)),3.5-strand*1.5,true)
		if strand==0:canvas.draw_polyline(points,Color(white,fade*.8),1.0,true)
	# Sparks crown the apex of the climb.
	for i in 6:
		var a=i*TAU/6+u*3
		var d=Vector2(cos(a),sin(a))*(8+u*26)
		canvas.draw_line(top+d*.5,top+d,Color(white,fade),1.6,true)

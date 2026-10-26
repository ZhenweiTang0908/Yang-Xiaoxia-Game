extends Node2D
# Feedback drawn on the hero instead of the HUD: purple-white wisps once the
# awakening gauge is full, fading sparks in the sheep form's last seconds, and the
# charge build-up (converging motes, a tightening ring, a flash when full).
const CENTER=Vector2(0,-22)
var actor
var clock=0.0
var ready_age=-1.0
var full_flash=-1.0
const CHARGE_FULL=1.1
func _ready():z_index=3
func _process(dt):
	if is_instance_valid(actor) and actor.game and (not actor.game.active() or actor.game.hitstop>0):
		queue_redraw();return
	clock+=dt
	var ready=is_instance_valid(actor) and actor.spirit>=100 and not actor.sheep() and actor.visible and not actor.is_carried()
	if ready:ready_age=0.0 if ready_age<0 else ready_age+dt
	else:ready_age=-1.0
	if is_instance_valid(actor):actor.ready_tint=(1.0-smoothstep(.12,1.2,ready_age)) if ready_age>=0 else 0.0
	if is_instance_valid(actor) and actor.charge>=CHARGE_FULL:full_flash=0.0 if full_flash<0 else full_flash+dt
	elif is_instance_valid(actor) and actor.charge<=0:full_flash=-1.0
	queue_redraw()
func _draw():
	if not is_instance_valid(actor):return
	if actor.charge>0:draw_charge()
	if actor.special_id=="wave" and actor.attack_elapsed>=0 and actor.attack_elapsed<.2:draw_lunge()
	if ready_age>=0:draw_wisps()
	elif actor.sheep() and actor.sheep_time<3.0:draw_fading()
func draw_wisps():
	# One converging surge, then only the two familiar orbiting wisps remain.
	if ready_age<.8:
		var u=clampf(ready_age/.8,0,1)
		for i in 32:
			var angle=i*2.399+u*1.5
			var radius=lerpf(64.0+(i%5)*5,2.0,smoothstep(0,1,u))
			var at=CENTER+Vector2(cos(angle)*radius,sin(angle)*radius*.65)
			var tail=at+Vector2(cos(angle-.15),sin(angle-.15)*.65)*(8+12*(1-u))
			var opacity=(1-smoothstep(.65,1,u))*.8
			draw_line(tail,at,Color(.72,.45,1,opacity*.55),2,true)
			draw_circle(at,2.0,Color(.92,.8,1,opacity))
	# A brief flare marks the moment the gauge fills.
	if ready_age<.45:
		var u=ready_age/.45
		draw_arc(CENTER,14+u*26,0,TAU,40,Color(.86,.78,1,(1-u)*.7),2.5,true)
	var grow=smoothstep(0,.35,ready_age)
	for i in 2:
		var a=clock*3.1+i*PI
		# Spiral orbit: each wisp rises and sinks while circling; behind the body it dims.
		for k in 10:
			var b=a-k*.17
			var at=CENTER+Vector2(cos(b)*16,sin(b*.5+i*1.7)*15+sin(b)*3)
			var behind=sin(b)<0
			var fade=(1-k/10.0)*grow*(.35 if behind else 1.0)
			var color=Color(.97,.95,1,.9*fade) if k==0 else Color(.74,.55,1,.6*fade)
			if k==0:draw_circle(at,4.5,Color(.8,.65,1,.22*fade))
			draw_circle(at,1.8 if k==0 else 1.5-k*.08,color)
	# Faint motes rising off the shoulders.
	for j in 4:
		var rise=fposmod(clock*.9+j*.27,1.0)
		var at=CENTER+Vector2(sin(j*2.3+clock)*9,8-rise*30)
		draw_circle(at,1.1,Color(.85,.75,1,(1-rise)*.5*grow))
func draw_fading():
	var u=actor.sheep_time/3.0
	for j in 5:
		var rise=fposmod(clock*1.4+j*.21,1.0)
		var at=CENTER+Vector2(sin(j*1.9+clock*2)*14,10-rise*34)
		draw_circle(at,1.3,Color(1,.86,.55,(1-rise)*.55*(1-u*.4)))
func draw_lunge():
	# Speed streaks behind the Moon-Step lunge.
	var u=clampf(actor.attack_elapsed/.2,0,1)
	for i in 5:
		var y=-6-i*8.0
		var length=(18+i%2*10)*(1-u*.6)
		var x=-actor.facing*(10+i*3)
		draw_line(Vector2(x,y),Vector2(x-actor.facing*length,y),Color(.68,.95,.88,.55*(1-u)),1.2,true)
func draw_charge():
	var u=clampf(actor.charge/CHARGE_FULL,0,1)
	var color=Color(1,.86,.5) if actor.sheep() else Color(.62,.95,.86)
	var core=CENTER+Vector2(0,2)
	# Motes stream inward from a wide circle; more of them as the charge grows.
	for i in 6+int(u*8):
		var k=fposmod(clock*1.6+i*.137,1.0)
		var a=i*2.39+floor(clock*1.6+i*.137)*1.3
		var from=core+Vector2(cos(a)*46,sin(a)*30)
		var at=from.lerp(core,k*k)
		draw_line(at,at.lerp(core,.12),Color(color,.75*(1-k)+.15),1.4,true)
	# Ring tightens and brightens toward full charge.
	var r=34-u*16+sin(clock*14)*1.2
	draw_arc(core,r,0,TAU,36,Color(color,.18+.4*u),1.5+u*1.5,true)
	draw_arc(core,r*.55,clock*6,clock*6+PI*1.2,18,Color(1,1,1,.25+.35*u),1.2,true)
	# Ground glow under the planted stance.
	draw_set_transform(Vector2(0,0),0,Vector2(1,.22))
	draw_circle(Vector2.ZERO,18+u*14,Color(color,.10+.12*u))
	draw_set_transform(Vector2.ZERO)
	if full_flash>=0 and full_flash<.3:
		var f=full_flash/.3
		draw_arc(core,20+f*40,0,TAU,40,Color(1,1,1,(1-f)*.9),3,true)
	elif full_flash>=.3:
		draw_circle(core,6+sin(clock*20)*1.5,Color(1,1,1,.35))

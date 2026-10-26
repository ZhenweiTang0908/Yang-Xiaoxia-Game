extends Node2D
# A faint backlight behind the hero, shown only while overlapping a boss, so a
# dark sprite (the sheep spirit especially) stays readable against dark robes.
var actor
var strength=0.0
func _ready():z_index=-1
func _process(dt):
	if is_instance_valid(actor) and actor.game and (not actor.game.active() or actor.game.hitstop>0):
		queue_redraw();return
	var target=0.0
	var boss=actor.game.boss if is_instance_valid(actor) and actor.game else null
	if is_instance_valid(boss) and not boss.dead and boss.visible:
		var gap=absf(boss.position.x-actor.position.x)
		target=1.0-smoothstep(30,70,gap)
	strength=move_toward(strength,target,dt*6)
	queue_redraw()
func _draw():
	if strength<=0.01:return
	var tint=Color(1,.86,.55) if actor.sheep() else Color(.75,.95,.9)
	for i in 3:
		draw_set_transform(Vector2(0,-24),0,Vector2(.62,1))
		draw_circle(Vector2.ZERO,32-i*9,Color(tint,.11*strength*(i+1)))
	draw_set_transform(Vector2.ZERO)

extends Node2D
# Eight restrained pixel-art poses of one four-legged bull; no humanoid rig.
var owner_actor
var controller
var art
var clock=0.0
var continuous
func _ready():
 art=load("res://scripts/actors/atlas_actor.gd").new();add_child(art)
 art.configure("res://assets/art/v3/bull.png",4,2,62)
 continuous=load("res://scripts/animation/bull_visual.gd").new();continuous.actor=owner_actor;continuous.source_art=art;add_child(continuous)
func seat_position():return continuous.seat_position() if continuous and owner_actor.game.use_skeletal else owner_actor.position+Vector2(-owner_actor.facing*8,-43)
func back_bob():return seat_position().y-owner_actor.position.y+39
func tick(dt):
 clock+=dt;art.facing=owner_actor.facing
 if controller.rush_left>0:art.frame=2+int(clock*16)%4
 elif controller.rush_windup>0 or controller.lock_left>0:art.frame=1
 elif absf(owner_actor.velocity.x)>15:art.frame=2+int(clock*10)%4
 elif controller.attack_age<.8:art.frame=6
 else:art.frame=0
 art.motion=Vector2(0,sin(clock*3)*.3)

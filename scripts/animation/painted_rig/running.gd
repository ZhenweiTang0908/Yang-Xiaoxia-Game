extends "res://scripts/animation/painted_rig/body.gd"
func _init():running=true
func _ready():
 super._ready()
 var atlas=load("res://scripts/actors/atlas_actor.gd").new()
 atlas.configure("res://assets/art/v2/hero.png",8,5,52.8)
 game_scale=atlas.scale_unit
 atlas.free()

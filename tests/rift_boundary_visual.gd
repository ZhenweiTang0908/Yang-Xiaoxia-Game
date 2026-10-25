extends SceneTree

class BoundaryCanvas extends Node2D:
	func _draw():
		var shapes=preload("res://scripts/combat/vfx_shapes.gd")
		for i in 3:
			shapes.rift(self,Rect2(40+i*130,40,96,96),[0.0,.5,1.0][i],Color("9e91bd"))

func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(430,180);root.add_child(BoundaryCanvas.new())
	await process_frame;await RenderingServer.frame_post_draw
	print("RIFT_BOUNDARY_RENDER phases=0,0.5,1")
	quit()

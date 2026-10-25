extends SceneTree
func _initialize():call_deferred("run")
func run():
 var art=load("res://scripts/actors/boss_art.gd").new();root.add_child(art)
 art.configure("res://assets/art/v2/bosses.png",6,3,110)
 art.scale_unit=110.0/art.bounds[12].size.y
 for pose in [14,15]:print("CAST_SOCKET pose=",pose," offset=",art.casting_socket(pose)," scale=",art.scale_unit)
 art.queue_free();await process_frame;quit()

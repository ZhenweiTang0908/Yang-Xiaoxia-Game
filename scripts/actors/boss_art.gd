extends "res://scripts/animation/actor_pose_art.gd"
func configure(path:String,cols:int,row_count:int,height:float):
 super.configure(path,cols,row_count,height)
 load_frames("res://assets/art/boss_frames",18)
func casting_socket(index=-1):
 var pose=frame if index<0 else index
 # Center of the crescent focus, measured in the isolated painted frames.
 var pixel=Vector2(183,29) if pose==14 else Vector2(42,126)
 return source_socket(pose,pixel)

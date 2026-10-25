extends SceneTree
func _initialize():call_deferred("run")
func run():
 var lab=load("res://tests/interactive_motion_lab.gd").new();root.add_child(lab)
 await physics_frame
 Input.action_press("right")
 var platform=false
 for i in 110:
  if i==40:Input.action_press("jump")
  if i==80:Input.action_release("jump")
  await physics_frame
  if lab.actor.is_on_floor() and lab.actor.position.y<400:platform=true
 Input.action_release("right")
 lab.actor.position=Vector2(680-38*lab.actor.rig.game_scale,450);lab.actor.velocity=Vector2.ZERO;lab.actor.rig.planted=[null,null]
 for i in 100:
  if i in [2,12,34]:Input.action_press("attack")
  if i in [3,13,35]:Input.action_release("attack")
  await physics_frame
 Input.action_press("left")
 for i in 10:await physics_frame
 Input.action_release("left")
 var ok=platform and lab.actor.jump_count==1 and lab.target.hits==3 and lab.actor.facing==-1
 print("INTERACTIVE_LAB platform=",platform," jumps=",lab.actor.jump_count," target_hits=",lab.target.hits," facing=",lab.actor.facing)
 lab.queue_free();await process_frame;quit(0 if ok else 1)

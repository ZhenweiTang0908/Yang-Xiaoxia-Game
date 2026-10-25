extends SceneTree
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(1280,680);root.content_scale_size=root.size
 var canvas=Node2D.new();root.add_child(canvas)
 var bg=ColorRect.new();bg.color=Color("17252b");bg.size=Vector2(1280,680);canvas.add_child(bg)
 var actions=["idle","run","slash1","slash2","slash3","cast","charge","release","dash","jump"]
 for i in actions.size():
  var ref=load("res://scripts/actors/atlas_actor.gd").new();ref.configure("res://assets/art/v2/sheep.png",6,4,52.8);canvas.add_child(ref);ref.hide()
  var rig=load("res://scripts/animation/cast_visual.gd").new();rig.species="sheep";rig.source_art=ref;rig.preview=true;rig.height=160;canvas.add_child(rig);rig.set_process(false)
  var state=actions[i];var t=.13
  if state.begins_with("slash"):t=rig.MOTION.ATTACKS[int(state.right(1))-1].hit
  rig.position=Vector2(115+(i%5)*240,270+(i/5)*300);rig.state=state
  rig.pose=rig.sample(state,t,1.2,1.0 if state=="run" else 0.0);rig.model.apply_pose(rig.pose);rig.queue_redraw()
  var label=Label.new();label.text=state;label.position=rig.position+Vector2(-28,24);canvas.add_child(label)
 for i in 8:await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/sheep-form-poses.png")
 canvas.queue_free();await process_frame;quit()

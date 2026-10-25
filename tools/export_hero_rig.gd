extends SceneTree
const MOTION=preload("res://scripts/animation/hero_motion.gd")
func own(node,owner):
 for child in node.get_children():child.owner=owner;own(child,owner)
func _initialize():call_deferred("run")
func run():
 var model=load("res://scripts/animation/hero_model.gd").new();root.add_child(model);model.name="YangXiaoxia"
 var library=AnimationLibrary.new()
 var lengths={"idle":TAU/2.6,"run":MOTION.RUN_PERIOD,"jump":.42,"fall":.42,"land":.18,"slash1":.38,"slash2":.41,"slash3":.49,"dash":.18,"bow":.32,"charge":1.1,"hurt":.22}
 for state in lengths:
  var animation=Animation.new();animation.length=lengths[state]
  animation.loop_mode=Animation.LOOP_LINEAR if state in ["idle","run","charge"] else Animation.LOOP_NONE
  var tracks={}
  for key in model.bones:
   var index=animation.add_track(Animation.TYPE_ROTATION_3D);animation.track_set_path(index,NodePath("HeroSkeleton:"+key));tracks[key]=index
  var offset_track=animation.add_track(Animation.TYPE_POSITION_3D);animation.track_set_path(offset_track,NodePath("HeroSkeleton:hips"))
  var count=ceili(animation.length*60)
  for i in count+1:
   var t=minf(i/60.0,animation.length);var pose=MOTION.sample(state,t,t*TAU/MOTION.RUN_PERIOD)
   if i==count and animation.loop_mode==Animation.LOOP_LINEAR:pose=MOTION.sample(state,0,0)
   for key in model.bones:animation.rotation_track_insert_key(tracks[key],t,Quaternion.from_euler(pose.get(key,Vector3.ZERO)))
   animation.position_track_insert_key(offset_track,t,Vector3(0,.59,0)+pose.offset)
  library.add_animation(state,animation)
 ResourceSaver.save(library,"res://assets/animation/hero_animations.tres")
 var player=AnimationPlayer.new();player.name="AnimationPlayer";model.add_child(player);player.add_animation_library("",library)
 model.apply_pose(MOTION.sample("idle",0));own(model,model)
 model.set_script(null)
 var packed=PackedScene.new();packed.pack(model);ResourceSaver.save(packed,"res://scenes/animation/hero_rig.tscn")
 print("EXPORTED 17 bones / 12 reusable clips")
 model.queue_free();await process_frame;quit()

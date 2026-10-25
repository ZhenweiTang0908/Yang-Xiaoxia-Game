extends SceneTree
func _initialize():call_deferred("run")
func run():
 var rig=load("res://scripts/animation/painted_rig/body.gd").new();rig.rebuild_source=true;root.add_child(rig);rig.set_process(false)
 var data=load("res://scripts/animation/painted_rig/rig_data.gd").new()
 data.meshes.assign(rig.parts);data.joints.assign(rig.joints);data.soles.assign(rig.soles);data.leg_height_scale.assign(rig.leg_height_scale)
 var result=ResourceSaver.save(data,"res://assets/animation/painted_rig/hero.res")
 print("BAKE_PAINTED_RIG result=",result," meshes=",data.meshes.size()," strips=",rig.strip_count)
 rig.queue_free();await process_frame;quit(result)

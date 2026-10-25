extends SceneTree
func _initialize():call_deferred("run")
func run():
 var rig=load("res://scripts/animation/hero_visual.gd").new();rig.preview=true;root.add_child(rig);rig.set_process(false);rig.preview_state="run"
 var previous=Vector2.ZERO;var previous_foot=-1;var distance=0.0;var time=0.0;var segments=[];var start=Vector2.ZERO;var samples=[]
 for i in 240:
  var dt=1.0/240;rig._process(dt);time+=dt;distance+=225*dt
  var foot=4 if rig.current_targets[4].y>=rig.current_targets[5].y else 5
  var point=rig.current_targets[foot]+Vector2(distance,0)
  if foot!=previous_foot:
   if previous_foot>=0:segments.append({"foot":previous_foot,"world_drift":previous.x-start.x})
   previous_foot=foot;start=point
  previous=point;samples.append({"time":time,"foot":foot,"x":point.x,"local_x":rig.current_targets[foot].x})
 var out=FileAccess.open("res://builds/qa/run-stride-audit.json",FileAccess.WRITE);out.store_string(JSON.stringify({"speed":225,"segments":segments,"samples":samples}," "));out.close()
 print("STRIDE_AUDIT ",JSON.stringify(segments));rig.queue_free();await process_frame;quit()

extends SceneTree
func _initialize():call_deferred("run")
func run():
 var failures=0
 for fps in [30,60,120]:
  var rig=load("res://scripts/animation/hero_visual.gd").new();rig.preview=true;rig.preview_state="run";root.add_child(rig);rig.set_process(false)
  var previous=-1;var contacts=0
  for i in fps*3:
   rig._process(1.0/fps)
   if previous!=rig.support_foot:
    contacts+=1;previous=rig.support_foot
    if absf(rig.current_targets[previous].y)>.01:failures+=1
  print("CONTACT_TIMING fps=",fps," contacts=",contacts)
  if contacts<10 or contacts>12:failures+=1
  rig.preview_ground=false;rig._process(1.0/fps)
  if rig.support_foot!=-1:failures+=1
  rig.preview_ground=true;rig.preview_state="idle";rig._process(1.0/fps)
  if rig.support_foot!=-1:failures+=1
  rig.queue_free();await process_frame
 print("CONTACT_TIMING failures=",failures);quit(failures)

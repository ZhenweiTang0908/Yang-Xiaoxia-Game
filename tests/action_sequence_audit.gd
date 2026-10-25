extends SceneTree
func _initialize():call_deferred("run")
func run():
 var rig=load("res://tests/hero_combo_gait.gd").new();root.add_child(rig)
 var timeline=load("res://tests/action_timeline.gd").new(rig);timeline.advance_to(4.2)
 var counts={"jump":0,"land":0,"swing":0,"hit":0,"step":0}
 for event in timeline.events:
  if event.path.ends_with("jump.wav"):counts.jump+=1
  elif event.path.ends_with("land.wav"):counts.land+=1
  elif event.path.contains("melee_swing"):counts.swing+=1
  elif event.has("damage"):counts.hit+=1
  elif event.path.contains("step"):counts.step+=1
 var before=timeline.events.size();timeline.advance_to(4.2)
 var ok=counts.jump==1 and counts.land==1 and counts.swing==3 and counts.hit==3 and counts.step>0 and before==timeline.events.size()
 print("ACTION_SEQUENCE counts=",counts," repeated_sample_duplicates=",timeline.events.size()-before," foot_releases=",rig.released_unreachable)
 rig.queue_free();await process_frame;quit(0 if ok else 1)

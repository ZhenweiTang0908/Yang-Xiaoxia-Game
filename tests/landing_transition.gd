extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 await create_timer(.15).timeout
 var p=game.player;p.set_physics_process(false)
 var rig=load("res://scripts/animation/hero_visual.gd").new();rig.actor=p;root.add_child(rig);rig.set_process(false)
 var failures=0
 p.land_anim=.18;p.velocity=Vector2(0,-520);p.move_and_slide()
 if p.is_on_floor() or rig.desired_state()!="jump":failures+=1
 p.velocity=Vector2(0,80)
 if rig.desired_state()!="fall":failures+=1
 var preview=load("res://scripts/animation/hero_visual.gd").new();preview.preview=true;preview.preview_state="land";root.add_child(preview);preview.set_process(false)
 preview.preview_time=.04;preview._process(.04)
 if preview.skin.current!=35:failures+=1
 preview.preview_time=.17;preview._process(.13)
 if preview.skin.current!=0:failures+=1
 preview.queue_free()
 print("LAND_TRANSITION failures=",failures)
 rig.queue_free();game.queue_free();await process_frame;quit(failures)

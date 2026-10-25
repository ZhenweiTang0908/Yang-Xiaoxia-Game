extends SceneTree
var game
var failed=0
func _initialize():call_deferred("run")
func check(ok,label):
 if not ok:failed+=1;push_error(label)
 else:print("PASS ",label)
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.use_skeletal=true;game.start_new(false)
 for e in game.enemies:e.dead=true;e.set_physics_process(false)
 game.summon.reset(true);game.summon.request();game.summon.phase="active";game.summon.remaining=30
 var b=game.summon.brother;b.arrive();b.set_physics_process(false)
 var c=b.demon_controller;c.carry_age=1.0;c.transform_left=0;c.rig.scale=Vector2.ONE
 var p=game.player;p.set_physics_process(false);var v=c.rig.continuous
 for direction in [-1,1]:
  b.facing=direction
  for frame in 8:
   c.rig.art.frame=frame;v._process(1.0/60);p._process(0)
   check(p.position.distance_to(v.seat_position())<.01 and p.rider_art.facing==direction,"hip socket and facing pose "+str(frame)+" direction "+str(direction))
 p.sheep_time=10;p.set_form_art(true)
 var spirit
 for child in p.get_children():
  if child.get_script() and child.get_script().resource_path.ends_with("cast_visual.gd"):spirit=child
 spirit._process(1.0/60)
 check(spirit.visible and spirit.state=="ride","sheep form has a seated pose instead of disappearing")
 c.release_player();check(not p.is_carried() and p.collision_mask==5 and not p.rider_art.visible,"dismount restores normal collision and removes rider")
 game.audio.stop_all();game.queue_free();await process_frame;print("RIDER_ALIGNMENT failures=",failed);quit(failed)

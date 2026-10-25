extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 await process_frame
 var c=game.combat;c.set_physics_process(false);c.clear();var errors=0
 var hp=game.player.health
 for kind in ["card","flame","blade","dart"]:c.fire(game.player.position-Vector2(0,21),Vector2.ZERO,99,"enemy",kind,{"life":.001,"owner":991})
 c._physics_process(.01)
 if not c.shots.is_empty() or c.shot_endings.size()!=4 or game.player.health!=hp:errors+=1
 game.state="paused";c._physics_process(.1)
 if c.shot_endings[0].elapsed!=0:errors+=1
 game.state="playing";c.remove_owner(991)
 if not c.shot_endings.is_empty():errors+=1
 for i in 40:c.fire(Vector2(300,100),Vector2.ZERO,1,"player","card",{"life":.001})
 c._physics_process(.01)
 if c.shot_endings.size()!=24:errors+=1
 c._physics_process(.2)
 if not c.shot_endings.is_empty():errors+=1
 c.fire(Vector2(300,100),Vector2.ZERO,1,"player","card",{"life":.001});c._physics_process(.01);c.clear()
 if not c.shot_endings.is_empty():errors+=1
 print("PROJECTILE_ENDINGS failures=",errors)
 game.queue_free();await process_frame;quit(errors)

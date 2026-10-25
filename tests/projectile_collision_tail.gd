extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 await physics_frame
 var combat=game.combat;combat.set_physics_process(false);combat.clear()
 for enemy in game.enemies:enemy.dead=true
 game.player.set_physics_process(false);game.player.position=Vector2(300,450);game.player.invincible=0
 combat.fire(Vector2(280,429),Vector2(300,0),5,"enemy","wave")
 combat._physics_process(.05)
 var ok=combat.shots.is_empty() and combat.shot_endings.size()==1
 var health=game.player.health
 combat._physics_process(.05)
 ok=ok and combat.shot_endings.size()==1 and game.player.health==health
 combat._physics_process(.14)
 ok=ok and combat.shot_endings.is_empty()
 combat.clear()
 combat.fire(Vector2(300,440),Vector2(0,400),5,"enemy","blade")
 combat._physics_process(.05)
 ok=ok and combat.shots.is_empty() and combat.shot_endings.size()==1
 if combat.shot_endings.size()==1:
  var tail=combat.shot_endings[0]
  ok=ok and tail.get("wall_stop",false) and absf(tail.p.y-450)<.01
 combat.clear();game.fx.impacts.clear()
 combat.fire(Vector2(300,440),Vector2(0,400),5,"player","flame")
 combat._physics_process(.05)
 ok=ok and game.fx.impacts.size()==1
 if game.fx.impacts.size()==1:ok=ok and game.fx.impacts[0].tint==Color("92ddd2")
 print("COLLISION_TAIL ","PASS" if ok else "FAIL")
 game.audio.stop_all();game.queue_free();await process_frame;quit(0 if ok else 1)

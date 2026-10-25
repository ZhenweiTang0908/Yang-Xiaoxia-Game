extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 for e in game.enemies:e.set_physics_process(false)
 var p=game.player;p.set_physics_process(false);p.position=Vector2(200,450)
 var actor=game.enemies[0];actor.position=Vector2(240,370);actor.velocity=Vector2.ZERO
 var effect=game.terrain.presence;effect.set_physics_process(false)
 await physics_frame
 effect.dust.clear();effect.landing_tracks.clear()
 var emitted=0
 for i in 60:
  await physics_frame
  actor.velocity.y+=1080.0/60
  actor.move_and_slide()
  var count=effect.dust.size()
  effect._physics_process(1.0/60)
  if effect.dust.size()>count:emitted+=effect.dust.size()-count
 var passed=emitted==2 and actor.is_on_floor()
 print("ACTOR_LANDING one_pair=",emitted," grounded=",actor.is_on_floor())
 effect.dust.clear();actor.position=Vector2(400,450);effect._physics_process(1.0/60)
 passed=passed and effect.dust.is_empty()
 print("ACTOR_LANDING teleport_quiet=",effect.dust.is_empty())
 game.audio.stop_all();game.queue_free();await process_frame
 await create_timer(.1).timeout
 quit(0 if passed else 1)

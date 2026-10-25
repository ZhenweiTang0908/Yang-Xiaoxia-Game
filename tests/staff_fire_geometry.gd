extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.jump_to_stage(3,2)
 var boss=game.boss;boss.set_physics_process(false);game.combat.set_physics_process(false);game.player.set_physics_process(false)
 var error=0.0;var cases=0
 for face in [-1.0,1.0]:
  boss.facing=face;boss.start_move(6);boss.windup=0;boss.release_move()
  var h=game.combat.hazards.back();h.age=.2;h.duration=.65
  for lean in [-.045,0.0,.045]:
   boss.art.lean=lean;boss.art.sink=.7
   var quad=game.combat.breath_quad(h)
   var root_point=(quad[0]+quad[3])*.5
   var tip=(quad[1]+quad[2])*.5
   error=maxf(error,root_point.distance_to(boss.art.to_global(boss.art.casting_socket(15))))
   error=maxf(error,absf((tip.x-root_point.x)*face-330))
   var safe=Rect2(root_point+Vector2(-face*35,-15),Vector2(12,30))
   if game.combat.hazard_hits(h,safe):error=100
   cases+=1
  game.combat.clear()
 print("STAFF_FIRE_GEOMETRY cases=",cases," error=",error)
 game.audio.stop_all();await create_timer(.1).timeout;game.queue_free();await process_frame
 quit(0 if cases==6 and error<.001 else 1)

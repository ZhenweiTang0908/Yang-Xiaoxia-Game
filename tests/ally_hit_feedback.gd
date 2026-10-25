extends SceneTree
var failed=[]
func check(ok,label):
 if ok:print("PASS ",label)
 else:failed.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 for e in game.enemies:e.set_physics_process(false);e.dead=true
 game.progress.gourd=true;game.summon.reset(true);game.summon.request();await create_timer(1.4).timeout
 var ally=game.summon.brother;ally.invincible=0;ally.take_damage(5)
 check(ally.hurt_time==.12,"normal ally starts restrained hit highlight")
 check(ally.art.tint.r>1.0 and ally.skeletal_visual.self_modulate.r>1.0,"painted and continuous normal visuals share highlight")
 ally._physics_process(.04)
 check(ally.art.tint.r>1.0 and ally.art.tint.r<1.15,"normal highlight decays continuously")
 ally._physics_process(.09)
 check(ally.hurt_time==0 and ally.art.tint.is_equal_approx(Color.WHITE),"normal highlight returns to painted color")
 ally.health=29;ally.become_demon();ally.invincible=0;ally.take_damage(5)
 check(ally.hurt_time==.12 and ally.demon_controller.rig.art.tint.r>1.0,"bull form receives the same short highlight")
 ally._physics_process(.13)
 check(ally.demon_controller.rig.art.tint.is_equal_approx(Color.WHITE),"bull highlight leaves no persistent aura")
 game.audio.stop_all();game.queue_free();await process_frame;print("ALLY_HIT_FEEDBACK failures=",failed);quit(failed.size())

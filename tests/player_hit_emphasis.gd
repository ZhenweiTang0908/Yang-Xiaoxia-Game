extends SceneTree
var failures=[]
func _initialize():call_deferred("run")
func check(ok,label):
 print("PASS " if ok else "FAIL ",label)
 if not ok:failures.append(label)
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 for enemy in game.enemies:enemy.set_physics_process(false);enemy.dead=true
 var player=game.player;player.set_physics_process(false)
 player.invincible=.8;player.hurt_anim=.22
 var lowest=1.0;var highest=0.0
 var all_warm=true
 for sample in 15:
  player.anim_clock=sample/60.0
  var tint=player.render_tint();lowest=minf(lowest,tint.a);highest=maxf(highest,tint.a)
  all_warm=all_warm and tint.r>tint.g and tint.g>tint.b
 check(all_warm,"hurt emphasis uses a restrained warm tint")
 check(lowest>=.82 and highest<=1.001,"invulnerability pulse never becomes a harsh transparency flash")
 player.hurt_anim=0;player.anim_clock=.13
 var recovery=player.render_tint()
 check(is_equal_approx(recovery.r,recovery.g) and is_equal_approx(recovery.g,recovery.b),"warm tint ends with the short hurt pose")
 player.invincible=0
 check(player.render_tint()==Color.WHITE,"normal rendering returns to neutral")
 game.audio.stop_all();game.queue_free();await process_frame
 print("PLAYER_HIT_EMPHASIS failures=",failures," alpha_range=",Vector2(lowest,highest))
 quit(0 if failures.is_empty() else 1)

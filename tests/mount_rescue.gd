extends SceneTree
var game
var checks=0
var failures=[]
func _initialize():call_deferred("run")
func verify(ok,label):
 checks+=1
 if ok:print("PASS ",label)
 else:failures.append(label);push_error("FAIL "+label)
func summon_bull():
 var p=game.player
 game.hitstop=0;p.health=29;p.invincible=0
 game.summon.reset(true);game.summon.set_physics_process(false);game.summon.request()
 game.summon.phase="active";game.summon.remaining=200.0/3.0
 var b=game.summon.brother;b.set_physics_process(false)
 verify(b.arrive(),"bull arrival starts assistance without a transformation")
 b.demon_controller.transform_left=0;b.demon_controller.carry_age=1
 p._process(0)
 return b
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.tuning.reset();game.start_new(false)
 for level in [1,2,3,4]:
  if level==4:game.start_challenge()
  else:game.jump_to_stage(level,0)
  await process_frame
  for enemy in game.enemies:enemy.set_physics_process(false)
  game.player.set_physics_process(false);game.combat.set_physics_process(false)
  var b=summon_bull();var p=game.player
  verify(p.is_carried() and p.carried_by==b and b.demon_controller.carrying,"stage "+str(level)+" automatically pulls the hero onto the bull")
  verify(p.collision_mask==0 and p.position.distance_to(b.demon_controller.carry_position())<.01,"stage "+str(level)+" uses the actual seat and suspended terrain collision")
  verify(is_equal_approx(game.summon.remaining,200.0/3.0),"stage "+str(level)+" keeps the normal assistance duration")
  Input.action_press("jump");p.enqueue("jump");p._physics_process(1.0/60);Input.action_release("jump")
  verify(not p.is_carried() and not b.demon_controller.carrying and p.velocity.y<0,"stage "+str(level)+" jump dismounts and immediately launches upward")
  verify(p.collision_mask==5 and not p.rider_art.visible,"stage "+str(level)+" dismount restores normal collision and removes the seated sprite")
 # A grounded bull's seat cannot turn the arena wave into a free dodge.
 var b=summon_bull();var p=game.player;var knight=game.boss
 knight.active_battle=true;knight.phase=2;p.health=100
 verify(p.is_carried() and p.position.y<440,"test hero starts raised on the bull's back")
 knight.fire_wave()
 verify(not p.is_carried() and not b.demon_controller.carrying and is_equal_approx(p.health,78.4),"grounded mounted hero is dismounted and takes 21.6 wave damage")
 # A real jump from the mount clears the same strike.
 b=summon_bull();p.health=100
 Input.action_press("jump");p.enqueue("jump")
 for i in 5:game.hitstop=0;p._physics_process(1.0/60)
 Input.action_release("jump")
 var before=p.health;game.hitstop=0;knight.fire_wave()
 verify(p.position.y<438 and p.health==before,"jumping from the mount genuinely clears the low wave")
 # The transition must still hit and seal a carried hero, with no orphan attachment.
 b=summon_bull();p.health=100;knight.phase=1;knight.begin_dismount();knight.land()
 verify(p.health==90 and game.summon.is_sealed() and not p.is_carried(),"landing dust still deals fixed 10 and seals/dismounts the rider")
 verify(game.summon.brother==null and game.summon.seal_resume.demon,"sealed bull is withdrawn with its demon form saved")
 var remaining=game.summon.seal_resume.remaining
 game.hitstop=0;game.summon.clear_seal()
 for i in 23:game.hitstop=0;game.summon._physics_process(1.0/60)
 verify(game.summon.phase=="active" and game.summon.brother.demon,"gourd return restores the bull after the seal")
 verify(not p.is_carried() and not game.summon.brother.demon_controller.carrying,"seal recovery does not start a second protection/healing cycle")
 verify(absf(game.summon.remaining-remaining)<.1,"seal recovery does not add another assist extension")
 game.summon.reset(true)
 verify(not p.is_carried() and p.collision_mask==5,"summon reset leaves the hero free with normal collision")
 Input.action_release("jump");game.audio.stop_all();game.queue_free();await process_frame;await process_frame
 print("MOUNT_RESCUE_RESULT checks=",checks," failures=",failures)
 quit(0 if failures.is_empty() else 1)

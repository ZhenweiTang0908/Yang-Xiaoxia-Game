extends SceneTree
var game
var errors=[]
func _initialize():call_deferred("run")
func check(ok,label):
 if not ok:errors.append(label);push_error(label)
 else:print("PASS ",label)
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false);await process_frame;game.start_challenge(4,2);await process_frame
 var k=game.boss;k.set_physics_process(false);k.active_battle=true;game.player.set_physics_process(false);game.combat.set_physics_process(false);game.tuning.reset()
 seed(892)
 var held=0
 for i in 500:
  k.soul.spend();k.soul.absorb(k.max_hp*k.cfg("knight_rage_fraction"))
  if not k.soul.release_ready:held+=1
 check(held>90 and held<165,"newly full cell holds approximately twenty-five percent of the time")
 k.soul.rage=3;k.soul.release_ready=true;k.weapon="spear";k.choose()
 check(k.action=="soul_legion" and k.soul.rage==0,"a full bar summons the legion and consumes all rage")
 game.player.position=Vector2(480,450);game.player.invincible=99
 for i in 522:
  game.hitstop=0;k._physics_process(1.0/120);game.combat._physics_process(1.0/120)
 check(k.soul.legion.size()>0,"archers remain while boss resumes its own attacks")
 check(k.soul.legion.filter(func(unit):return unit.kind=="archer").size()==3 and k.soul.legion.filter(func(unit):return unit.kind=="archer").all(func(unit):return unit.hits==3),"stationary archers complete three separate shots")
 k.begin_dismount();check(k.soul.legion.is_empty(),"phase transition cancels the legion")
 k.dismount_t=-1;k.weapon="bow";k.soul.rage=0;k.begin("bow",.7);k.release_arrow("knight:bow")
 check(is_equal_approx(game.combat.shots[-1].v.length(),780),"ordinary arrows return to the earlier 780 px/s speed")
 check(is_equal_approx(k.cfg("knight_damage_scale"),.9) and k.cfg("knight_hit_seal")==2,"previous damage and seal balance remains applied")
 game.state="settings";game.hud.canvas.queue_redraw();await process_frame;await process_frame;check(game.hud.buttons.any(func(b):return b.action=="hero_legacy"),"settings expose both hero animation versions")
 var rig=game.player.skeletal_visual.painted_motion.rig
 rig.sample_action("bow",.10)
 var hand=rig.sampled_pose[8]*Vector2(130,148)
 var pulling=rig.sampled_pose[7]*Vector2(74,149)
 check(hand.x>pulling.x+12,"bow grip hand extends beyond the string hand")
 for index in 3:
  rig.sample_attack(index,rig.MOTION.ATTACKS[index].hit,0)
  var base=rig.sampled_pose[7]*Vector2(74,149)
  check(base.x>90,"sword strike extends the hand in front of the torso")
 game.audio.stop_all();game.queue_free();await process_frame
 print("KNIGHT_LEGION failures=",errors);quit(0 if errors.is_empty() else 1)

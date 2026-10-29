extends SceneTree
var game
var checks=0
var failures=[]
func _initialize():call_deferred("run")
func verify(ok,label):
 checks+=1
 if not ok:failures.append(label);push_error("FAIL "+label)
func run():
 root.unfocusable=true
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.tuning.reset();game.use_skeletal=true;game.start_new(false)
 game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false);game.combat.set_physics_process(false);game.summon.set_physics_process(false)
 for e in game.enemies:e.set_physics_process(false);e.dead=true
 game.summon.reset(true);game.summon.request()
 var b=game.summon.brother
 verify(is_instance_valid(b),"summon creates bull")
 if not is_instance_valid(b):quit(1);return
 b.set_physics_process(false);game.summon._physics_process(1.2)
 var p=game.player;var c=b.demon_controller
 c.carry_age=1;c.attack_cd=99;c.blink_cd=99
 verify(b.health==200,"starts with 200 stamina")
 for i in 60:b._physics_process(1.0/60)
 verify(absf(b.health-197)<.001,"one active second consumes three stamina")
 b.heal_on_hit();verify(absf(b.health-197)<.001,"hit cannot restore stamina")
 var saved=b.health;game.state="paused";b._physics_process(1);verify(b.health==saved,"pause freezes stamina")
 game.state="playing";game.hitstop=.1;b._physics_process(1);verify(b.health==saved,"hitstop freezes stamina");game.hitstop=0
 var motion=p.skeletal_visual.painted_motion
 p.combo=1;p.attack_elapsed=.05;p.attack_duration=.38;p.update_animation();p.skeletal_visual._process(.016);motion._physics_process(.016)
 verify(p.skeletal_visual.visible and motion.visible,"continuous painted rider owns rendering")
 verify(motion.rig.sampled_pose.size()==11,"mounted rig has complete pose")
 if motion.rig.sampled_pose.size()!=11:quit(1);return
 var before=motion.rig.sampled_pose[7]
 p.attack_elapsed=.18;motion._physics_process(.13)
 verify(not motion.rig.sampled_pose[7].is_equal_approx(before),"rider sword arm changes through impact")
 p.sheep_time=10;p.set_form_art(true)
 var spirit=p.mounted_spirit
 verify(is_instance_valid(spirit),"spirit visual exists")
 if not is_instance_valid(spirit):quit(1);return
 spirit._process(.016);verify(spirit.state=="slash1","mounted spirit displays attack instead of static ride")
 p.attack_elapsed=-1;p.charge=.3;spirit._process(.1);verify(spirit.state=="charge","mounted spirit displays charge")
 p.charge=0;p.bow_anim=.25;spirit._process(.1);verify(spirit.state=="cast","mounted spirit displays ranged action")
 p.bow_anim=0;c.release_player()
 var target=game.enemies[0];target.dead=false;target.hp=500;target.position=b.position+Vector2(35,0)
 c.rush_hits.clear();var health=b.health;var hp=target.hp
 c.strike(b.position)
 verify(target.hp<hp and b.health==health,"physical contact damages enemy without healing bull")
 verify(game.hitstop>0 and game.shake>0 and not game.fx.hit_marks.is_empty(),"actual impact has hitstop shake and contact mark")
 game.hitstop=0;c.rush_left=0;c.attack_target=target;c.queue_blink(b.position+Vector2(180,0));var origin=b.position
 c.tick_blink(.10);verify(b.position==origin and c.rig.modulate.a<1,"blink folds before changing position")
 c.tick_blink(.06);verify(b.position.distance_to(origin)>100 and c.rig.modulate.a<1,"blink relocates while folded")
 c.tick_blink(.15);verify(c.blink_left==0 and c.rig.modulate.a==1 and c.rush_windup>0,"arrival restores visibility and anticipates rush")
 b.health=200;b.pinned_left=100;b.pin_anchor=b.position
 for i in 310:
  b._physics_process(.1);game.summon._physics_process(.1)
 verify(game.summon.phase=="active" and absf(b.health-107)<.001,"stamina drains while pinned and survives former thirty-second cutoff")
 for i in 357:
  b._physics_process(.1)
  if game.summon.phase=="active":game.summon._physics_process(.1)
 verify(game.summon.phase=="leaving","full stamina lifetime ends after about 66.7 seconds")
 game.summon._physics_process(.8);verify(game.summon.phase=="cooldown" and game.summon.remaining==20,"departure starts twenty-second cooldown")
 game.summon._physics_process(20);verify(game.summon.phase=="ready","cooldown completes after twenty seconds")
 game.audio.stop_all();game.queue_free();await process_frame;await process_frame
 print("HERO_MOUNT_POLISH_RESULT checks=",checks," failures=",failures);quit(0 if failures.is_empty() else 1)

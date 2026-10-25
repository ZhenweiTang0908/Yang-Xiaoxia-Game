extends SceneTree
var game
var failures=[]
var checks=0
func _initialize():call_deferred("run")
func verify(ok,label):
 checks+=1
 if ok:print("PASS ",label)
 else:failures.append(label);push_error(label)
func prepare(mesh=true):
 game.release_inputs();game.hitstop=0;game.combat.clear();game.use_skeletal=mesh
 var p=game.player;p.reset(Vector2(500,450),true);p.sheep_time=10;p.set_form_art(true);p.invincible=0;p.facing=1
 for e in game.enemies:e.dead=true
 return p
func tick(p,seconds):
 var remaining=seconds
 while remaining>0:
  var dt=minf(.01,remaining);game.hitstop=0;p._physics_process(dt);remaining-=dt
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.start_new(false)
 game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false);game.combat.set_physics_process(false)
 for e in game.enemies:e.set_physics_process(false)
 await process_frame
 for mesh in [true,false]:
  for index in 3:
   var p=prepare(mesh);p.combo=index;p.combo_window=1;p.start_attack()
   var target=game.enemies[0];target.dead=false;target.hp=1000;target.position=p.position+Vector2(45,0)
   var hp=target.hp;var impact=p.MOTION.ATTACKS[index].hit/p.SHEEP_RATE
   tick(p,impact-.025);verify(target.hp==hp,"sheep anticipation "+str(index)+" mesh="+str(mesh))
   tick(p,.04);verify(target.hp<hp,"sheep impact "+str(index)+" mesh="+str(mesh))
   hp=target.hp;tick(p,.04);verify(target.hp==hp,"single melee settlement "+str(index))
   verify(game.combat.shots.size()==(1 if index==2 else 0),"only finisher emits a wave")
 var p=prepare();p.enqueue("bow");tick(p,.01)
 verify(game.combat.shots.is_empty(),"flame waits for hand release")
 p.enqueue("attack");tick(p,.02);verify(p.attack_elapsed<0,"casting does not overlap melee")
 tick(p,.12);verify(game.combat.shots.size()==1 and game.combat.shots[0].kind=="flame" and game.combat.shots[0].pierce==1,"release emits one piercing flame")
 tick(p,.12);verify(game.combat.shots.size()==1,"flame emits only once")
 p=prepare();p.start_attack();p.enqueue("bow");tick(p,.02);verify(p.bow_anim==0 and game.combat.shots.is_empty(),"melee cannot be hidden by casting")
 p=prepare();p.enqueue("bow");tick(p,.03);p.enqueue("dash");tick(p,.15)
 verify(game.combat.shots.is_empty() and not p.pending_bow,"dodge cancels unreleased flame")
 p=prepare();p.enqueue("bow");tick(p,.02);p.take_damage(1,1);tick(p,.2)
 verify(game.combat.shots.is_empty() and p.bow_anim==0,"hurt cancels cast and its pose")
 p=prepare();p.start_attack();p.pending_bow=true;p.bow_anim=.25;p.charge=.6;p.dash_time=.1;p.sheep_time=0;p.begin_form(false)
 verify(p.attack_elapsed<0 and not p.pending_bow and p.bow_anim==0 and p.charge==0 and p.dash_time==0,"reversion clears every unfinished action")
 p.enqueue("attack");p.enqueue("bow");tick(p,.1)
 verify(p.attack_elapsed<0 and game.combat.shots.is_empty(),"transition rejects combat inputs")
 p=prepare();p.sheep_time=0;p.set_form_art(false);p.enqueue("bow");tick(p,.02);p.spirit=100;p.enqueue("transform");tick(p,.25)
 verify(p.sheep() and p.form_visual and game.combat.shots.is_empty(),"transformation cancels human arrow instead of turning it into flame")
 p=prepare();p.bow_anim=.2;p.blast_anim=.3;p.hurt_anim=.1;p.reset(Vector2(500,450),true)
 verify(p.bow_anim==0 and p.blast_anim==0 and p.hurt_anim==0,"reset removes stale action poses")
 var rig
 for child in p.get_children():
  if child.get_script() and child.get_script().resource_path.ends_with("cast_visual.gd"):rig=child
 p=prepare();p.combo=3;p.attack_elapsed=.22;p.attack_duration=p.MOTION.ATTACKS[2].duration
 game.hitstop=.05;rig._process(.016)
 verify(rig.state=="slash3" and is_equal_approx(rig.pose.near_arm.z,rig.sample("slash3",.22,rig.phase,0).near_arm.z),"hitstop displays actual finisher impact")
 var pose=rig.pose.duplicate(true);rig._process(.016);verify(pose==rig.pose,"hitstop freezes pose after impact")
 game.hitstop=0;p.attack_elapsed=-1;p.blast_anim=.3;verify(rig.active_state()=="release","blast has a dedicated release pose")
 p=prepare();p.start_attack();p.enqueue("attack");tick(p,.28)
 verify(p.combo==2 and p.attack_elapsed>=0,"buffered sheep combo chains without waiting for full recovery")
 p=prepare();var target=game.enemies[0];target.dead=false;target.hp=500;target.position=p.position+Vector2(18,0)
 game.combat.horn(p);var hp=target.hp;game.combat.horn(p)
 verify(hp<500 and target.hp==hp,"horn hits each enemy only once per dash")
 p=prepare();p.sheep_time=.01;tick(p,.02)
 verify(not p.sheep() and p.form_transition>0 and p.attack_elapsed<0,"expiry enters a clean reversion")
 tick(p,.26);verify(not p.form_visual,"expiry restores human art at transition midpoint")
 for index in 3:
  for direction in [-1,1]:
   p=prepare();p.combo=index+1;p.attack_elapsed=p.MOTION.ATTACKS[index].hit;p.facing=direction;rig._process(.2)
   var transform=rig.model.skeleton.get_bone_global_pose(rig.model.bones.near_hand)
   var tip=rig.camera.unproject_position(transform*(rig.model.blade.transform*Vector3(.56,0,0)))
   verify(tip.x>2 and tip.x<rig.viewport.size.x-2 and tip.y>2 and tip.y<rig.viewport.size.y-2,"full blade stays inside render surface "+str(index)+" facing="+str(direction))
 game.audio.stop_all();game.queue_free();await process_frame;await process_frame
 print("SHEEP_FORM_RESULT checks=",checks," failures=",failures);quit(0 if failures.is_empty() else 1)

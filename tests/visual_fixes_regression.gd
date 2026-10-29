extends SceneTree
var game
var checks=0
var failures=[]
func _initialize():root.unfocusable=true;call_deferred("run")
func verify(ok,label):
 checks+=1
 if not ok:failures.append(label);print("FAIL ",label)
func rigid(art,label):
 verify(art.rigid_frames,label+" rigid silhouettes")
 for i in art.isolated.size():
  art.frame=i;art.update_pose_mesh()
  var target=art.posed_vertices()
  verify(art.displayed==target,label+" authored geometry "+str(i))
  verify(art.frame_unit(i)>0 and art.frame_unit(i)<3,label+" finite anatomical unit "+str(i))
func calibration(art,key):
 var profile=JSON.parse_string(FileAccess.get_file_as_string("res://assets/animation/boss_scale_guides.json")).profiles[key]
 var checked={}
 for i in profile.frames.size():
  var guide=profile.frames[i]
  if guide.unit==null:continue
  var ref=int(guide.reference)
  verify(is_equal_approx(art.frame_unit(i),art.frame_unit(ref)),key+" fixed unit within source family")
  if checked.has(ref):continue
  checked[ref]=true
  if key=="reset/priest" and ref==162:continue # Kneeling/dissolving, calibrated by head size.
  var head=profile.frames[ref].head
  verify(head!=null,key+" anatomical reference exists")
  if head==null:continue
  var base=art.bounds[ref].end.y
  if key.begins_with("knight/"):base=float(art.frame_info[ref].baseline)
  verify(absf((base-float(head[1]))*art.frame_unit(ref)-art.body_height)<1.5,key+" reference body height")
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.tuning.reset();game.start_new(false)
 game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false);game.combat.set_physics_process(false);game.summon.set_physics_process(false)
 for e in game.enemies:e.set_physics_process(false);e.dead=true
 game.summon.reset(true);game.summon.request();var bull=game.summon.brother
 verify(is_instance_valid(bull),"bull exists")
 if not is_instance_valid(bull):quit(1);return
 bull.set_physics_process(false);game.summon._physics_process(1.2);bull.demon_controller.carry_age=1
 var p=game.player
 for mode in [false,true]:
  game.use_skeletal=mode
  for form in [false,true]:
   p.sheep_time=10 if form else 0;p.set_form_art(form)
   p.cancel_action();p.combo_window=0;p.hurt_anim=0;p.form_transition=0;p.edges.clear();p.enqueue("attack");p._physics_process(1.0/60)
   verify(p.is_carried() and p.attack_elapsed>=0 and p.combo==1,"actual attack input starts while mounted")
   for combo in 3:
    var points=[]
    p.combo=combo+1;p.attack_duration=p.MOTION.ATTACKS[combo].duration if form or mode else (.40 if combo==2 else .34)
    var origin=p.position
    for at in [.03,.12,.21,.30]:
     p.attack_elapsed=at;p.update_animation();p.skeletal_visual._process(.04);p.skeletal_visual.painted_motion._physics_process(.04);p.mounted_spirit._process(.04)
     if form:
      verify(p.mounted_spirit.visible and p.mounted_spirit.state=="slash"+str(combo+1),"spirit attack visible mode "+str(mode))
      points.append(p.mounted_spirit.blade_tip)
     else:
      var motion=p.skeletal_visual.painted_motion
      verify(p.skeletal_visual.visible and motion.visible,"human attack visible mode "+str(mode))
      points.append(motion.rig.sampled_pose[7])
     verify(p.position==origin,"seat root stays attached during attack")
    verify(points[0]!=points[1] or points[0]!=points[2] or points[0]!=points[3],"weapon actually moves combo "+str(combo+1)+" form "+str(form))
 p.sheep_time=0;p.set_form_art(false);bull.demon_controller.release_player()
 for stage in [1,2,3,4]:
  game.jump_to_stage(stage);await process_frame;game.state="playing"
  var b=game.boss;b.set_physics_process(false)
  if stage<4:
   rigid(b.art,"boss "+str(stage))
   if stage==3:calibration(b.art,"reset/priest")
  else:
   var stable=b.visual.foot;stable.lean=0;stable.sink=0;stable.weapon_extension=0
   var torso=stable.deform(Vector2(-35,-60));stable.weapon_extension=.23
   verify(stable.deform(Vector2(-35,-60))==torso,"empowered spear does not stretch the torso");stable.weapon_extension=0
   var arts=[b.visual.foot,b.visual.mounted,b.visual.extra,b.visual.horse,b.visual.arsenal,b.visual.mounted_arsenal,b.visual.pressure,b.visual.reset_art]
   var keys=["knight/foot","knight/mounted","knight/extra","knight/extra","knight/arsenal","knight/mounted_arsenal","knight/pressure","reset/knight"]
   for i in arts.size():
    rigid(arts[i],"knight")
    if i!=3:calibration(arts[i],keys[i])
 game.audio.stop_all();game.queue_free();await process_frame
 print("VISUAL_FIXES_REGRESSION_RESULT checks=",checks," failures=",failures);quit(0 if failures.is_empty() else 1)

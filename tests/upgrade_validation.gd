extends SceneTree
var game
var failed=0
var count=0
func _initialize():call_deferred("run")
func check(ok,label):
 count+=1
 if not ok:failed+=1;push_error(label)
 else:print("PASS ",label)
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true
 for stage in [1,2,3]:
  game.load_stage(stage,0)
  for enemy in game.enemies:enemy.set_physics_process(false)
  check(game.level.section_names.size()==4 and game.level.length==16000,"four rooms stage "+str(stage))
  var features
  for child in game.terrain.get_children():
   if child.get_script() and child.get_script().resource_path.ends_with("room_features.gd"):features=child
  var ferry=features.items.filter(func(i):return i.kind=="ferry")[0];var before=ferry.body.position
  features._physics_process(.7);check(ferry.body.position!=before,"moving ferry stage "+str(stage))
  var plate=features.items.filter(func(i):return i.kind=="plate")[0];var gate=features.items.filter(func(i):return i.kind=="gate")[0]
  game.player.position=Vector2(plate.x+plate.w*.5,plate.y);features._physics_process(.1)
  check(plate.open and gate.open and gate.body.position.y<gate.y,"pressure seal opens gate stage "+str(stage))
  check(game.boss.art.isolated.size()==18,"isolated boss frame bank stage "+str(stage))
  check(game.player.skeletal_visual.skin!=null,"approved 2D hero skin loaded stage "+str(stage))
  check(game.player.skeletal_visual.find_children("*","SubViewport",true,false).is_empty(),"hero stays entirely 2D stage "+str(stage))
 game.load_stage(1,2)
 var b=game.boss;b.active_battle=true;b.set_physics_process(false)
 for move in range(3):
  game.combat.clear();b.start_move(move);b.release_move()
  check(game.combat.hazards.any(func(h):return h.kind in ["stone_impact","stone_wave","antler_sweep"]),"first boss physical visual "+str(move))
 game.load_stage(3,2);b=game.boss;b.active_battle=true;b.set_physics_process(false)
 game.combat.clear();b.start_move(0);b.release_move()
 check(game.combat.hazards.size()==1 and game.combat.hazards[0].kind=="spectral_horn","priest horn charge uses spectral horn trail")
 game.combat.clear();b.start_move(4);b.release_move()
 check(game.combat.shots.size()==11 and game.combat.shots.all(func(s):return s.kind=="ghost_orb" and not s.homing),"ring uses hollow ghost-fire projectiles")
 game.combat.clear();b.execute_event("homing",{"damage":22})
 check(game.combat.shots.size()==1 and game.combat.shots[0].kind=="ghost_orb" and game.combat.shots[0].homing,"homing move uses soul-core projectile")
 game.combat.clear();b.start_move(2);b.release_move()
 check(game.combat.hazards.size()==16 and game.combat.hazards.all(func(h):return h.kind=="ground_rift"),"priest ground wave uses sequential rifts")
 game.combat.clear();b.execute_event("lightning",{"damage":24})
 check(game.combat.hazards.size()==1 and game.combat.hazards[0].kind=="spirit_lightning","priest lightning uses suspended sigil")
 game.combat.clear();b.start_move(6);b.release_move()
 check(game.combat.hazards.size()==1 and game.combat.hazards[0].kind=="spirit_beam","priest beam uses spirit ribbon")
 game.summon.reset(true);game.summon.request()
 var rig=game.summon.brother.skeletal_visual;rig.rebuild(0)
 check(not rig.authored_frame.is_empty() and rig.rest.size()>500,"brother uses Blender exported mesh")
 check(rig.authored_frame.angles.size()==151,"brother uses Blender baked animation curves")
 var save=load("res://scripts/core/save_store.gd");var data=save.defaults();data.entry_section=6;save.write_save(data,"user://old_entry_test.json")
 check(save.read_save("user://old_entry_test.json").entry_section==2,"old penultimate entry migrates to room three")
 DirAccess.remove_absolute("user://old_entry_test.json")
 game.audio.stop_all();game.queue_free();await process_frame;print("UPGRADE_VALIDATION checks=",count," failures=",failed);quit(failed)

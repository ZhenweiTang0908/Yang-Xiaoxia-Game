extends SceneTree
var errors=[]
func _initialize():call_deferred("run")
func check(ok,label):
 print("PASS " if ok else "FAIL ",label)
 if not ok:errors.append(label)
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 for enemy in game.enemies:enemy.set_physics_process(false);enemy.dead=true
 game.player.health=100;game.progress.gourd=true;game.summon.reset(true);game.summon.request()
 for i in 85:await physics_frame
 var brother=game.summon.brother;brother.set_physics_process(false);game.combat.set_physics_process(false)
 var target=game.enemies[0];target.dead=false;game.player.current_target=target
 for face in [-1.0,1.0]:
  game.combat.clear();brother.position=game.player.position+Vector2(0,0);brother.velocity=Vector2.ZERO;brother.facing=face
  target.position=brother.position+Vector2(face*180,0)
  brother.shot_cd=99;brother.fan_cd=99;brother.return_cd=99;brother.rune_cd=99;brother.special_gap=99
  brother.throw_card(target);brother._physics_process(.13)
  check(game.combat.shots.is_empty(),"no projectile before release "+str(face))
  brother._physics_process(.02)
  check(brother.art.frame==14 and brother.skeletal_visual.current_frame==14,"release and artwork share frame 14 "+str(face))
  var expected=brother.origin()
  check(game.combat.shots.size()==1 and game.combat.shots[0].origin.distance_to(expected)<.01,"card starts on deformed hand "+str(face))
  check(game.combat.shots[0].variant=="plain","normal throw keeps diamond card mark "+str(face))
  check(game.combat.shots[0].v.x*face>0,"card flies toward target "+str(face))
  var visual=brother.skeletal_visual;var used=brother.art.bounds[14];var region=brother.art.regions[14]
  var rendered=visual.mesh.surface_get_arrays(0)
  check(rendered[Mesh.ARRAY_TEX_UV]==visual.uv,"rendered pose already matches release on physics tick "+str(face))
  var point=(Vector2(190,78)-Vector2(region.size.x*.5,used.end.y))*brother.art.scale_unit
  check(visual.mesh_socket(point).is_finite(),"hand socket lies on actual mesh "+str(face))
  if DisplayServer.get_name()!="headless":
   game.set_process(false);game.player.hide();game.camera.position=brother.position+Vector2(face*45,-70);game.camera.zoom=Vector2(2,2)
   game.scene_motion.reset(brother)
   for enemy in game.enemies:enemy.hide()
   await process_frame;await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://builds/qa/brother-release-%s.png"%("left" if face<0 else "right"))
 game.audio.stop_all();await create_timer(.1).timeout;game.queue_free();await process_frame
 print("BROTHER_CARD_RELEASE failures=",errors)
 quit(0 if errors.is_empty() else 1)

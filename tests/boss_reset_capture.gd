extends SceneTree
var game
var frame_index=0
const OUT="res://builds/qa/boss-reset/"
func _initialize():root.unfocusable=true;call_deferred("run")
func save_frame(name=""):
 await process_frame
 RenderingServer.force_draw(false)
 var im=root.get_texture().get_image()
 if im==null or im.is_empty():quit(1);return
 im.save_png(OUT+"video/%04d.png"%frame_index);frame_index+=1
 if name!="":im.save_png(OUT+name+".png")
func setup_stage(stage):
 game.jump_to_stage(stage);await process_frame
 game.state="playing";game.stage_banner=-10;game.set_physics_process(false);game.player.set_physics_process(false);game.boss.set_physics_process(false);game.combat.set_physics_process(false);game.summon.set_physics_process(false)
 game.boss.active_battle=true;game.boss.position=Vector2(630,450);game.boss.facing=-1;
 if stage<4:game.boss.cooldown=99
 game.player.position=Vector2(380,450);game.player.invincible=999
func run():
 DirAccess.make_dir_recursive_absolute(OUT+"video")
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new();root.size=Vector2i(960,540);game.audio.stop_all()
 for stage in [1,2,3]:
  await setup_stage(stage)
  var b=game.boss;b.art.pose("idle",0);await save_frame("boss-"+str(stage)+"-idle")
  if stage==3:
   for frame in 12:
    b.art.pose("turn",float(frame)/12);b.art.advance(1.0/30);await save_frame()
   b.facing=-1
  for move_id in (["stone_lift","stone_throw"] if stage==1 else (["flash","feint"] if stage==2 else ["four_slash","moonfall"])):
   b.clear_attacks();b.position=Vector2(630,450);b.cooldown=99
   var index=0
   for i in b.spec.moves.size():
    if b.spec.moves[i].id==move_id:index=i
   b.start_move(index)
   for frame in 75:
    game.hitstop=0;b._physics_process(1.0/30)
    await save_frame("boss-"+str(stage)+"-"+move_id if frame==int(b.move.windup*30)+5 else "")
 if true:
  var b=game.boss;b.clear_attacks();b.hp=b.max_hp/3;game.audio.voice_player.stop();b.begin_phase_shift(3)
  for frame in 180:
   game.hitstop=0;b._physics_process(1.0/30)
   await save_frame("moon-form" if frame==100 else "")
  b.phase_shift=0;b.hp=1;b.take_hit(10,"brother",1)
  for frame in 194:
   b._physics_process(1.0/30)
   var label="moon-recall" if frame==90 else ("moon-collapse-last" if frame==38 else ("moon-recall-first" if frame==39 else ""))
   await save_frame(label)
 await setup_stage(4)
 var knight=game.boss;knight.enter_foot_challenge();knight.active_battle=true;knight.facing=-1;game.player.position.x=760;knight.begin("thrust",knight.prep_for("thrust"));knight.reset_turn.begin(1,0);knight.t=2;knight.face_target()
 for frame in 24:
  game.hitstop=0;knight._physics_process(1.0/60);await save_frame("knight-turn" if frame==8 else "")
 game.audio.stop_all();game.queue_free();await process_frame
 print("BOSS_RESET_CAPTURE_RESULT frames=",frame_index);quit()

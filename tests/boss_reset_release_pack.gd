extends SceneTree
# Also copied outside res:// and run against the actual exported PCK.
var game
var checks=0
var failures=[]
func verify(ok,label):
 checks+=1
 if not ok:failures.append(label);print("FAIL ",label)
func _initialize():call_deferred("run")
func run():
 for id in ["lantern","duelist","priest","knight"]:
  var path="res://assets/art/boss_reset/"+id+"/frames.json"
  verify(FileAccess.file_exists(path),id+" frame manifest included in export")
  if not FileAccess.file_exists(path):continue
  var meta=JSON.parse_string(FileAccess.get_file_as_string(path))
  verify(meta is Dictionary and meta.count>25,id+" authored bank metadata")
 var lion_path="res://assets/art/lion_elder_frames/"
 var lion_banks=0
 for folder in DirAccess.get_directories_at(lion_path):
  if FileAccess.file_exists(lion_path+folder+"/frames.json"):lion_banks+=1
 verify(lion_banks>=20,"lion frame manifests also included")
 if not failures.is_empty():finish();return
 var scene=load("res://scenes/main.tscn")
 verify(scene!=null,"exported main scene loads")
 if scene==null:finish();return
 game=scene.instantiate();game.qa_mode=true;root.add_child(game);game.progress=game.SAVE.defaults();game.tuning.reset();
 verify(not game.progress.hero_mesh and game.progress.boss_voice=="ai","export defaults to 2D and AI");
 game.set_physics_process(false)
 for stage in [1,2,3,4,5]:
  game.jump_to_stage(stage);await process_frame
  game.set_physics_process(false);game.player.set_physics_process(false);game.boss.set_physics_process(false)
  verify(game.boss.spec!=null,"exported boss "+str(stage)+" instantiates")
  game.progress.boss_voice="ai";game.audio.preview_boss_voice();verify(game.audio.voice_source=="ai","exported boss "+str(stage)+" AI audio plays")
  if stage<=3:
   var art=game.boss.art
   verify(art.isolated.size()>=98,"exported boss "+str(stage)+" uses new art rather than fallback")
   verify(not art.clips.idle.is_empty(),"exported idle pose "+str(stage))
  if stage==3:
   var b=game.boss;b.active_battle=true;b.phase_shift=0;b.hp=1;b.take_hit(10,"brother",1)
   verify(game.state=="boss_cinematic","exported moon recall starts")
   b.advance_recall(1.31)
   verify(b.art.frame==b.art.clips.recall.front(),"exported recall joins lying pose")
 if game:game.audio.stop_all();game.queue_free();await process_frame
 finish()
func finish():
 print("BOSS_RESET_RELEASE_PACK_RESULT checks=",checks," failures=",failures)
 quit(0 if failures.is_empty() else 1)

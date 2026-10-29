extends SceneTree
const STORE=preload("res://scripts/core/save_store.gd")
const SAVE_PATH="/tmp/yang-daxia-lion-route-test.json"
var failures=[]
var checks=0
func _initialize():call_deferred("run")
func verify(ok,label):
 checks+=1
 if ok:print("PASS ",label)
 else:failures.append(label);push_error("FAIL "+label)
func run():
 var old=STORE.defaults()
 old.rush_stage=4;old.rush_clears=[1,2,3,4];old.rush_completed=true
 old.upgrades=["blade","spirit","brother"];old.rush_knight_foot=true
 verify(STORE.write_save(old,SAVE_PATH),"write former completed rush")
 var migrated=STORE.read_save(SAVE_PATH)
 verify(migrated.rush_stage==5 and not migrated.rush_completed,"four-battle ending continues to fifth")
 verify(migrated.upgrades==old.upgrades and migrated.rush_clears==old.rush_clears and not migrated.rush_knight_foot,"migration preserves rewards and clears knight retry flag")
 old.rush_completed=false
 verify(STORE.write_save(old,SAVE_PATH),"write unfinished knight")
 var unfinished=STORE.read_save(SAVE_PATH)
 verify(unfinished.rush_stage==4 and unfinished.rush_knight_foot,"unfinished knight retains foot retry")
 var arena=load("res://data/arenas/boss_5.tres")
 var spec=load("res://data/bosses/lion_elder.tres")
 verify(arena!=null and spec!=null,"fifth resources load")
 if arena==null or spec==null:finish();return
 verify(arena.number==5 and arena.boss_id==spec.id and spec.title=="衔灯狮叟" and arena.boss_script=="res://scripts/actors/lion_elder.gd","fifth route identifies dedicated actor")
 verify(arena.single_boss and arena.length==960 and arena.platforms.size()==3,"fifth arena is bounded flat duel")
 verify(arena.stage_music()==5,"fifth battle uses its dedicated score")
 var palette=load("res://scripts/world/battle_architecture.gd").palette(5)
 verify(palette.size()==4,"fifth palette has all drawing colors")
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game);game.qa_mode=true;game.progress=STORE.defaults();game.start_new()
 await process_frame
 for stage in range(1,5):
  game.level=load("res://data/arenas/boss_"+str(stage)+".tres")
  game.state="playing";game.finish_level()
  verify(game.state=="stage_clear" and game.progress.rush_stage==stage+1,"stage %s advances without ending rush"%stage)
 verify(game.progress.upgrades==game.RUSH_UPGRADES,"only first three battles award arts")
 game.level=arena;game.state="playing";game.finish_level()
 verify(game.state=="win" and game.progress.rush_completed and 5 in game.progress.rush_clears,"fifth battle completes rush")
 verify(game.hud.journey_record_rows().size()==5,"record book includes fifth battle")
 verify(STORE.write_save(game.progress,SAVE_PATH),"write completed fifth")
 var completed=STORE.read_save(SAVE_PATH)
 verify(completed.rush_completed and 5 in completed.rush_clears and completed.records.has("5"),"fifth completion and record survive reload")
 game.audio.stop_all();game.queue_free();await process_frame
 finish()
func finish():
 for suffix in ["",STORE.TEMP_SUFFIX,STORE.BACKUP_SUFFIX]:
  var path=SAVE_PATH+suffix
  if FileAccess.file_exists(path):DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
 print("LION_ROUTE_RESULT checks=",checks," failures=",failures)
 quit(0 if failures.is_empty() else 1)

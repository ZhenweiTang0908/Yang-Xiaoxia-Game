extends SceneTree
const STORE=preload("res://scripts/core/save_store.gd")
const PATH="/private/tmp/yang-default-2d-ai-voice-test.json"
var checks=0
var failures=[]
var game
func verify(ok,label):
 checks+=1
 if not ok:failures.append(label);print("FAIL ",label)
func cleanup():
 for suffix in ["",STORE.TEMP_SUFFIX,STORE.BACKUP_SUFFIX]:
  if FileAccess.file_exists(PATH+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH+suffix))
func _initialize():call_deferred("run")
func run():
 cleanup()
 var fresh=STORE.defaults();verify(not fresh.hero_mesh and fresh.boss_voice=="ai","new saves default to 2D and AI")
 var f=FileAccess.open(PATH,FileAccess.WRITE)
 verify(f!=null,"test save can be created")
 if f==null:quit(1);return
 f.store_string(JSON.stringify({"version":2,"hero_mesh":true,"hero_animation_revision":1,"boss_voice":"classic","level":2,"music":.4}));f.close()
 var migrated=STORE.read_save(PATH)
 verify(not migrated.hero_mesh and migrated.boss_voice=="ai","old default choices migrate once to 2D and AI")
 verify(migrated.level==2 and is_equal_approx(migrated.music,.4),"migration preserves progress and volumes")
 migrated.hero_mesh=true;migrated.boss_voice="classic";verify(STORE.write_save(migrated,PATH),"save explicit later choices")
 var reread=STORE.read_save(PATH);verify(reread.hero_mesh and reread.boss_voice=="classic","later explicit choices survive restart")
 cleanup()
 game=load("res://scenes/main.tscn").instantiate();game.qa_mode=true;root.add_child(game);game.set_physics_process(false);game.progress=STORE.defaults();game.use_skeletal=game.progress.hero_mesh
 verify(not game.use_skeletal,"runtime uses default 2D")
 game.state="settings";game.hud.settings_return="title"
 game.hud.action("voice_classic");game.audio._process(.01)
 verify(game.progress.boss_voice=="classic" and game.audio.voice_source=="classic" and not game.audio.voice_player.stream_paused,"classic selection previews actual classic audio")
 game.hud.action("voice_ai");game.audio._process(.01)
 verify(game.progress.boss_voice=="ai" and game.audio.voice_source=="ai" and not game.audio.voice_player.stream_paused,"classic to AI selects actual AI preview")
 game.hud.action("voice_classic");verify(game.audio.voice_source=="classic","AI can switch back to classic")
 game.hud.action("voice_ai");game.audio.voice("knight_intro");game.state="boss_cinematic";game.audio._process(.01)
 verify(not game.audio.voice_player.stream_paused,"story and companion voices continue during moon cinematic")
 game.state="paused";game.audio._process(.01);verify(game.audio.voice_player.stream_paused,"pause freezes cinematic speech")
 game.cinematic_resume=true;game.resume_battle();game.audio._process(.01);verify(not game.audio.voice_player.stream_paused,"resuming cinematic restores speech")
 game.audio.stop_all();game.queue_free();await process_frame
 print("DEFAULT_2D_AI_VOICE_RESULT checks=",checks," failures=",failures);quit(0 if failures.is_empty() else 1)

extends SceneTree
var checks=0
var failures=[]
var game
func verify(ok,label):
 checks+=1
 if not ok:failures.append(label);print("FAIL ",label)
func _initialize():call_deferred("run")
func run():
 var banks=preload("res://scripts/core/boss_dialogue.gd").BOSSES
 var reset_lines=0
 for boss_id in banks:
  var seen={}
  for event in banks[boss_id].groups:
   for line in banks[boss_id].groups[event]:
    if seen.has(line):continue
    seen[line]=true
    var identity=boss_id+"_"+str(line)
    verify(ResourceLoader.exists("res://assets/voice/ai/"+identity+".wav"),identity+" has real AI recording")
    if str(line).begins_with("reset_"):reset_lines+=1
 verify(reset_lines==181,"181 active reset dialogue variants covered")
 if not failures.is_empty():finish();return
 game=load("res://scenes/main.tscn").instantiate();game.qa_mode=true;root.add_child(game);game.progress=game.SAVE.defaults();game.set_physics_process(false)
 for stage in [1,2,3,4,5]:
  game.jump_to_stage(stage);await process_frame
  game.set_physics_process(false);game.player.set_physics_process(false);game.boss.set_physics_process(false);game.state="settings"
  game.hud.action("voice_classic");game.audio._process(.01)
  var identity=game.audio.voice_identity
  verify(game.audio.voice_source=="classic" and game.audio.voice_preview and not game.audio.voice_player.stream_paused,"stage "+str(stage)+" classic preview plays")
  game.hud.action("voice_ai");game.audio._process(.01)
  verify(game.audio.voice_identity==identity and game.audio.voice_source=="ai" and not game.audio.voice_player.stream_paused,"stage "+str(stage)+" switches same line to actual AI")
  verify(game.audio.voice_path(identity).begins_with("res://assets/voice/ai/"),"stage "+str(stage)+" AI preference resolves to AI resource")
 game.audio.stop_all();game.queue_free();await process_frame;finish()
func finish():
 print("RESET_AI_VOICE_COVERAGE_RESULT checks=",checks," failures=",failures);quit(0 if failures.is_empty() else 1)

extends SceneTree
const BANK=preload("res://scripts/core/boss_dialogue.gd")
var game
var checks=0
var failures=[]
func _initialize():call_deferred("run")
func verify(ok,label):
 checks+=1
 if not ok:failures.append(label);push_error("FAIL "+label)
func tick_hud():
 game.hud.canvas.queue_redraw();await process_frame;await process_frame
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.tuning.reset();game.set_process(false);game.set_physics_process(false)
 verify(game.progress.boss_voice=="ai","AI is the default voice bank")
 for boss in BANK.BOSSES:
  var bank=BANK.BOSSES[boss]
  verify(bank.lines.size()>=16,boss+" has a rich dialogue pool")
  for event in bank.groups:
   verify(not bank.groups[event].is_empty(),boss+" event has lines: "+event)
   for line in bank.groups[event]:verify(bank.lines.has(line),boss+" event references a real line: "+line)
  for line in bank.lines:
   for folder in ["res://assets/voice/","res://assets/voice/ai/"]:
    var path=folder+boss+"_"+line+".wav"
    if not ResourceLoader.exists(path):
     verify(false,"recording missing: "+path);print("BOSS_DIALOGUE_RESULT checks=",checks," failures=",failures);quit(1);return
    var stream=load(path)
    verify(stream is AudioStreamWAV and stream.get_length()>.3 and stream.get_length()<15,"real WAV recording: "+path)
 for number in [1,2,3]:
  game.jump_to_stage(number,2);await process_frame
  game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false);game.combat.set_physics_process(false)
  var boss=game.boss;boss.set_physics_process(false);game.audio.stop_all()
  game.player.position=Vector2(boss.arena.position.x+80,450);boss.active_battle=false;game.hitstop=0;boss._physics_process(.016)
  verify(boss.active_battle and game.audio.voice_player.playing,"stage "+str(number)+" entrance triggers actual speech")
  verify(game.audio.voice_source=="ai" and game.subtitle.begins_with(boss.spec.title+"："),"stage "+str(number)+" speech and subtitles agree")
  var first=game.audio.voice_identity
  verify(not boss.speak_event("intro"),"speech cooldown prevents repeated taunts")
  boss.speech_cooldown=0;boss.speak_event("intro")
  verify(first!=game.audio.voice_identity,"variants do not repeat immediately")
  game.audio.voice("niu_demon");boss.speech_cooldown=0
  verify(not boss.speak_event("phase_2",true) and game.audio.voice_identity=="niu_demon","boss does not interrupt the brother")
  game.audio.stop_all();boss.begin_phase_shift(2)
  verify(game.audio.voice_identity.begins_with(boss.spec.id+"_phase_2"),"phase transition speaks a dedicated line")
  game.audio.stop_all();boss.phase_shift=0;boss.speech_cooldown=0;boss.hp=boss.max_hp*.2;boss.take_hit(1,"brother",1)
  verify(boss.low_spoken and game.audio.voice_identity.begins_with(boss.spec.id+"_low"),"low health speaks once")
  game.audio.stop_all();boss.hp=1;boss.take_hit(2,"brother",1)
  verify(boss.dead and game.audio.voice_identity.begins_with(boss.spec.id+"_death"),"defeat speaks a dedicated line")
 game.start_challenge(4,2);await process_frame
 var knight=game.boss;knight.set_physics_process(false);game.player.set_physics_process(false);game.combat.set_physics_process(false);game.audio.stop_all()
 for id in ["soul_eagle_burst","ancient_spear","bow","bow_double","spear_slam","kick_thrust"]:
  knight.speech_cooldown=0;game.audio.stop_all();knight.begin(id,knight.prep_for(id))
  verify(game.audio.voice_identity.trim_prefix("knight_") in knight.DIALOGUE.GROUPS.get(id,[id]) and game.audio.voice_player.playing,"knight special move speaks: "+id)
 game.state="settings";await tick_hud()
 var actions=game.hud.buttons.map(func(b):return b.action)
 verify("voice_ai" in actions and "voice_classic" in actions,"settings expose both recordings")
 game.hud.action("voice_classic");game.audio._process(.05)
 verify(game.progress.boss_voice=="classic" and game.audio.voice_source=="classic" and game.audio.voice_preview and not game.audio.voice_player.stream_paused,"classic preview really plays while game is paused in settings")
 verify(game.audio.voice_path("knight_intro")=="res://assets/voice/knight_intro.wav","classic selection resolves to the untouched old recording")
 game.hud.action("voice_ai");game.audio._process(.05)
 verify(game.progress.boss_voice=="ai" and game.audio.voice_source=="ai","AI preview resolves to the new recording")
 verify(game.audio.voice_path("niu_demon")=="res://assets/voice/niu_demon.wav","brother keeps his existing voice")
 game.state="playing";game.audio._process(.05)
 verify(not game.audio.voice_preview and not game.audio.voice_player.playing,"settings preview does not leak into combat")
 game.progress.boss_voice="classic";game.start_new(false)
 verify(game.progress.boss_voice=="classic","new journey keeps the chosen voice bank")
 var path="/private/tmp/yang-boss-voice-preference.json"
 verify(game.SAVE.write_save(game.progress,path) and game.SAVE.read_save(path).boss_voice=="classic","voice preference survives save round trip")
 for suffix in ["",game.SAVE.TEMP_SUFFIX,game.SAVE.BACKUP_SUFFIX]:
  if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
 game.audio.stop_all();game.queue_free();await process_frame;await process_frame
 print("BOSS_DIALOGUE_RESULT checks=",checks," failures=",failures);quit(0 if failures.is_empty() else 1)

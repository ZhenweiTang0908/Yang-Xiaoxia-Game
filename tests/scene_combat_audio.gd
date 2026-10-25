extends SceneTree
var failures=[]
var checks=0
var game
func _initialize():call_deferred("run")
func verify(ok,label):
 checks+=1
 if not ok:failures.append(label);push_error(label)
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.tuning.reset()
 game.start_challenge(4,2);await process_frame
 game.set_process(false);game.set_physics_process(false);game.boss.set_physics_process(false);game.player.set_physics_process(false)
 var audio=game.audio
 for stage in range(1,5):
  for boss in [false,true]:
   audio.change_music(stage,boss)
   verify(audio.music_target.ends_with("level%d_%s.ogg"%[stage,"boss" if boss else "explore"]),"scene routes to its own score")
   var stream=audio.music_players[audio.selected].stream
   verify(stream!=null and stream.loop and stream.get_length()>30,"score is a sustained loop")
 audio.stop_all();game.subtitle=""
 for boss in ["lantern","duelist","priest","knight"]:
  audio.effort_last=-10000
  verify(audio.exertion(boss),boss+" effort plays")
  verify(audio.effort_player.stream.get_length()<1.3,"effort is short")
  verify(not audio.exertion(boss),"efforts are throttled")
  verify(game.subtitle=="","effort creates no text")
 audio.voice("knight_intro");audio.effort_last=-10000
 verify(not audio.exertion("knight"),"full dialogue has priority")
 audio.stop_all();game.state="playing";audio.effort_last=-10000;audio.exertion("knight")
 game.state="paused";audio._process(.1)
 verify(audio.effort_player.stream_paused,"effort pauses with game")
 game.state="playing";audio._process(.1)
 verify(not audio.effort_player.stream_paused,"effort resumes")
 audio.stop_all();verify(not audio.effort_player.playing,"stop clears effort")
 var knight=game.boss;knight.action="lunge";audio.effort_last=-10000
 knight.move_sound("warning")
 verify(not audio.effort_player.playing,"windup does not play attack cry")
 knight.move_sound("release")
 verify(audio.effort_player.playing,"actual knight release plays attack cry")
 for key in ["knight_lunge_release","knight_spin_rush_release","enemy_duelist_triple_release"]:
  verify(audio.bank.has(key) and audio.bank[key].get_length()>.06,"weapon air available")
 game.queue_free();await process_frame;await process_frame
 print("SCENE_COMBAT_AUDIO_RESULT checks=",checks," failures=",failures);quit(0 if failures.is_empty() else 1)

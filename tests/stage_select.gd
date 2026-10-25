extends SceneTree
var game
var checks=0
func check(value,label):
 checks+=1
 if not value:push_error(label);quit(1)
 print("PASS ",label)
func _initialize():call_deferred("run")
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults()
 for number in [1,2,3,4]:
  game.jump_to_stage(number);await process_frame
  check(game.boss_rush and game.level.number==number and game.level.single_boss,"jump opens boss arena "+str(number))
  check(game.player.health==100 and game.player.has_bow and game.summon.unlocked and game.tonic_count()==game.TONIC_MAX,"ready equipment, health and tonic")
  check(is_instance_valid(game.boss) and not game.boss.dead and game.enemies.size()==1,"only the boss is present")
  game.retry();await process_frame;await process_frame
  check(game.level.number==number,"retry stays on the current boss")
  game.return_title();game.continue_game();await process_frame
  check(game.level.number==number and game.progress.rush_stage==number,"continue resumes the same boss")
 var save=load("res://scripts/core/save_store.gd")
 game.progress.rush_clears=[1,2]
 save.write_save(game.progress,"user://stage_select_test.json")
 var restored=save.read_save("user://stage_select_test.json")
 check(restored.rush_stage==4 and restored.rush_clears==[1,2],"save round trip keeps the rush stage and clears")
 DirAccess.remove_absolute("user://stage_select_test.json")
 game.hud.action("stage_select")
 check(game.state=="stage_select" and not game.active(),"selector pauses play")
 game.hud.action("stage_select_back")
 check(game.state=="playing","return resumes previous state")
 print("STAGE_SELECT_RESULT checks=",checks)
 game.audio.stop_all();await create_timer(.5).timeout
 game.queue_free();await process_frame;quit(0)

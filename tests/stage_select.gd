extends SceneTree
var game
var checks=0
func check(value,label):
 checks+=1
 if not value:push_error(label);quit(1)
 print("PASS ",label)
func _initialize():call_deferred("run")
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true
 for number in [1,2,3]:
  for section in [0,2]:
   game.jump_to_stage(number,section)
   check(game.level.number==number,"selected stage")
   check(int(game.player.position.x/4000)==section,"selected region")
   check(game.player.health==100 and game.player.has_bow and game.summon.unlocked,"ready equipment and health")
   check(game.enemies.any(func(e):return not e.dead),"enemies remain playable")
   var pos=game.player.position
   game.retry();await process_frame
   check(game.player.position.distance_to(pos)<2,"retry keeps entry")
   game.return_title();game.continue_game()
   check(game.player.position.distance_to(pos)<2,"continue keeps entry")
 var save=load("res://scripts/core/save_store.gd")
 save.write_save(game.progress,"user://stage_select_test.json")
 var restored=save.read_save("user://stage_select_test.json")
 check(restored.level==3 and restored.entry_section==2,"save round trip")
 DirAccess.remove_absolute("user://stage_select_test.json")
 game.player.position.x=13800
 await physics_frame;await physics_frame
 check(game.progress.entry_section==0 and game.checkpoint_index==2,"next checkpoint replaces jump entry")
 check(game.state=="upgrade","reached checkpoint opens martial choice")
 game.choose_upgrade("blade")
 game.hud.action("stage_select")
 check(game.state=="stage_select" and not game.active(),"selector pauses play")
 game.hud.action("stage_select_back")
 check(game.state=="playing","return resumes previous state")
 print("STAGE_SELECT_RESULT checks=",checks)
 game.audio.stop_all();await create_timer(1.5).timeout
 game.queue_free();await process_frame;await create_timer(.2).timeout;quit()

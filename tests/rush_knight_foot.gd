extends SceneTree
# After the boss-rush knight dismounts, death offers to resume the foot duel.
var game
var failures=[]
var checks=0
func _initialize():call_deferred("run")
func verify(ok,label):
 checks+=1
 if ok:print("PASS ",label)
 else:failures.append(label);push_error(label)
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.start_new()
 await process_frame
 game.jump_to_stage(4);await process_frame;await process_frame
 var k=game.boss
 verify(k.phase==1 and not game.rush_knight_foot(),"the rush knight starts mounted")
 k.land()
 verify(game.rush_knight_foot(),"dismounting records the foot phase")
 game.die("knight_thrust");await process_frame
 game.hud.canvas.queue_redraw();await process_frame
 var actions=game.hud.buttons.map(func(b):return b.action)
 verify("retry" in actions and "rush_mounted" in actions,"death offers foot continue and a mounted restart")
 game.retry();await process_frame;await process_frame
 k=game.boss
 verify(k.phase==2 and k.landed and is_equal_approx(k.hp,k.cfg("knight_foot_hp")),"retry resumes the foot duel at full foot health")
 game.die("knight_thrust");game.retry_mounted();await process_frame;await process_frame
 verify(game.boss.phase==1 and not game.rush_knight_foot(),"mounted restart rides again")
 game.boss.land();game.jump_to_stage(4);await process_frame;await process_frame
 verify(game.boss.phase==1,"a free jump to the knight always starts mounted")
 game.audio.stop_all();game.queue_free();await process_frame
 print("RUSH_KNIGHT_FOOT_RESULT checks=",checks," failures=",failures);quit(0 if failures.is_empty() else 1)

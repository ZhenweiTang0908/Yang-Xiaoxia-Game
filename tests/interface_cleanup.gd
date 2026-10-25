extends SceneTree
var failures=[]
var checks=0
var game
func _initialize():call_deferred("run")
func verify(ok,label):
 checks+=1
 if not ok:failures.append(label);push_error(label)
func redraw():
 game.hud.canvas.queue_redraw();await process_frame;await process_frame
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.start_new(false);await process_frame
 for state in ["title","settings","new_confirm","playing","paused","dead","stage_select","upgrade"]:
  game.state=state;await redraw()
  var entries=game.hud.buttons
  verify(not entries.is_empty(),state+" has actionable controls")
  var clear=true
  for i in entries.size():
   clear=clear and Rect2(0,0,960,540).encloses(entries[i].rect)
   for j in range(i+1,entries.size()):clear=clear and not entries[i].rect.intersects(entries[j].rect)
  verify(clear,state+" controls fit without overlap")
  game.pad_mode=true;game.hud.pad_focus=0;game.hud.pad_move(Vector2.DOWN)
  verify(game.hud.pad_focus>=0 and game.hud.pad_focus<entries.size(),state+" controller focus stays valid")
  game.pad_mode=false
 game.state="playing";game.player.health=100;game.hint_time=0;game.use_tonic()
 verify(game.hud.resource_feedback>0 and game.tonic_count()==2,"refused tonic has visual feedback without consuming inventory")
 for key in ["ui_focus","ui_back","ui_confirm","ui_error"]:
  verify(game.audio.bank.has(key) and game.audio.bank[key].get_length()>0,"sound available: "+key)
 game.fx.clear()
 for i in 20:game.fx.number(Vector2(100,100),2,Color.RED)
 verify(game.fx.labels.size()==1 and game.fx.labels[0].text=="40","rapid damage merges without losing total")
 for i in 20:game.fx.number(Vector2(i*100,100),1,Color.BLUE)
 verify(game.fx.labels.size()<=6,"floating numbers remain bounded")
 game.audio.stop_all();game.queue_free();await process_frame;await process_frame
 print("INTERFACE_CLEANUP checks=",checks," failures=",failures);quit(0 if failures.is_empty() else 1)

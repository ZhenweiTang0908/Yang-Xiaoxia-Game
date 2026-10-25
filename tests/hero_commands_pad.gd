extends SceneTree
var failed=0
func _initialize():call_deferred("run")
func verify(ok,label):
 if ok:print("PASS ",label)
 else:failed+=1;push_error(label)
func frames(n):
 for i in n:await physics_frame
 await process_frame
func button(index,pressed):
 var event=InputEventJoypadButton.new();event.device=0;event.button_index=index;event.pressed=pressed;Input.parse_input_event(event)
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.start_new(false);game.set_process(false);game.set_physics_process(false)
 game.gamepad.reset_bindings()
 for e in game.enemies:e.dead=true;e.set_physics_process(false)
 game.combat.set_physics_process(false)
 var p=game.player
 for face in [1,-1]:
  for id in ["wave","spin","rising"]:
   game.release_inputs();p.reset(Vector2(500,450),false);p.facing=face;game.hitstop=0;game.state="playing"
   if id=="rising":
    button(JOY_BUTTON_DPAD_RIGHT if face>0 else JOY_BUTTON_DPAD_LEFT,true);await frames(3)
    button(JOY_BUTTON_DPAD_RIGHT if face>0 else JOY_BUTTON_DPAD_LEFT,false)
   button(JOY_BUTTON_DPAD_DOWN,true);await frames(3);button(JOY_BUTTON_DPAD_DOWN,false)
   var x=-face if id=="spin" else face
   button(JOY_BUTTON_DPAD_RIGHT if x>0 else JOY_BUTTON_DPAD_LEFT,true);await frames(3)
   button(JOY_BUTTON_LEFT_SHOULDER,true);await frames(2);button(JOY_BUTTON_LEFT_SHOULDER,false);await frames(2)
   verify(p.special_id==id and p.facing==face,"controller "+id+" facing "+str(face))
   button(JOY_BUTTON_DPAD_RIGHT if x>0 else JOY_BUTTON_DPAD_LEFT,false)
 game.release_inputs();game.audio.stop_all();game.queue_free();await process_frame;await process_frame;await create_timer(.2).timeout
 print("HERO_PAD_COMMANDS failures=",failed);quit(failed)

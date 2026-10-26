extends SceneTree
var game
var failed=0
func _initialize():call_deferred("run")
func check(ok,label):
 if not ok:failed+=1;push_error(label)
 else:print("PASS ",label)
func button(index,pressed):
 var e=InputEventJoypadButton.new();e.device=0;e.button_index=index;e.pressed=pressed;Input.parse_input_event(e)
func frames(n):
 for i in n:await physics_frame
 await process_frame
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.gamepad.glyphs="switch";game.gamepad.reset_bindings();await frames(2)
 var pad=game.gamepad
 check(pad.binding_label("jump")=="A" and pad.binding_label("summon")=="B" and pad.binding_label("sprint")=="X" and pad.binding_label("transform")=="Y","Switch printed letters match requested actions")
 button(JOY_BUTTON_B,true);await frames(2);button(JOY_BUTTON_B,false)
 check(game.active(),"Switch A confirms menu")
 for e in game.enemies:
  if e==game.boss:e.set_physics_process(false)
  else:e.dead=true;e.set_physics_process(false)
 var p=game.player;p.invincible=0;await frames(5)
 button(JOY_BUTTON_B,true);await frames(2);check(p.velocity.y<0,"A jumps");button(JOY_BUTTON_B,false);await frames(50)
 button(JOY_BUTTON_LEFT_SHOULDER,true);await frames(5)
 check(p.attack_elapsed<0,"LB press waits for tap or hold classification")
 button(JOY_BUTTON_LEFT_SHOULDER,false);await frames(2);check(p.attack_elapsed>=0,"LB short release attacks")
 await frames(30);button(JOY_BUTTON_LEFT_SHOULDER,true);await frames(24)
 check(pad.charge_active and p.charge>=.32 and p.attack_elapsed<0,"LB hold charges without normal swing")
 button(JOY_BUTTON_LEFT_SHOULDER,false);await frames(2)
 check(p.blast_anim>0 and p.charge==0,"LB long release detonates")
 p.dash_cd=0;p.invincible=0;button(JOY_BUTTON_Y,true);await frames(2);button(JOY_BUTTON_Y,false)
 check(p.sprinting and p.dash_time>0 and p.invincible==0,"X forward sprint has no roll invulnerability")
 await frames(14);p.dash_cd=0
 var trigger=InputEventJoypadMotion.new();trigger.device=0;trigger.axis=JOY_AXIS_TRIGGER_RIGHT;trigger.axis_value=1;Input.parse_input_event(trigger);await frames(2)
 check(not p.sprinting and p.dash_time>0 and p.invincible>0,"ZR rolls with invulnerability")
 trigger.axis_value=0;Input.parse_input_event(trigger);await frames(14)
 p.has_bow=true;button(JOY_BUTTON_RIGHT_SHOULDER,true);await frames(2);button(JOY_BUTTON_RIGHT_SHOULDER,false);check(p.bow_cd>0,"R uses ranged attack")
 p.spirit=100;button(JOY_BUTTON_X,true);await frames(2);button(JOY_BUTTON_X,false);check(p.sheep(),"Y awakens")
 game.summon.reset(true);button(JOY_BUTTON_A,true);await frames(2);button(JOY_BUTTON_A,false);check(game.summon.phase=="entering","B summons")
 button(JOY_BUTTON_LEFT_SHOULDER,true);await frames(25);button(JOY_BUTTON_START,true);await frames(2);button(JOY_BUTTON_START,false);button(JOY_BUTTON_LEFT_SHOULDER,false)
 check(game.state=="paused" and not pad.charge_active and p.charge==0,"pause cancels held charge safely")
 button(JOY_BUTTON_A,true);await frames(2);button(JOY_BUTTON_A,false);check(game.active(),"Switch B returns from pause")
 pad.assign("attack","a"+str(JOY_AXIS_TRIGGER_LEFT))
 var custom=InputEventJoypadMotion.new();custom.device=0;custom.axis=JOY_AXIS_TRIGGER_LEFT;custom.axis_value=1;Input.parse_input_event(custom);await frames(25)
 check(pad.charge_active,"rebound trigger supports held melee charge")
 custom.axis_value=0;Input.parse_input_event(custom);await frames(2);check(not pad.melee_held and p.charge==0,"rebound trigger release clears charge")
 var config_path="/private/tmp/yang-daxia-qa-controller-layout.cfg"
 pad.save_bindings(config_path);pad.bindings=pad.defaults();pad.load_bindings(config_path)
 check(pad.bindings.attack=="a"+str(JOY_AXIS_TRIGGER_LEFT),"versioned custom controls survive reload")
 var old=ConfigFile.new();old.set_value("bindings","attack","b2");old.save(config_path);pad.load_bindings(config_path)
 check(pad.bindings==pad.defaults(),"legacy layout migrates to requested defaults")
 DirAccess.remove_absolute(config_path);pad.reset_bindings()
 button(JOY_BUTTON_DPAD_UP,true);await frames(2);button(JOY_BUTTON_DPAD_UP,false)
 check(not pad.melee_held and not pad.charge_active,"reserved item button does not start combat actions")
 game.state="paused";game.audio.stop_all();await create_timer(.2).timeout
 game.queue_free();await process_frame;await process_frame;OS.delay_msec(100)
 print("SWITCH_LAYOUT_RESULT failures=",failed);quit(failed)

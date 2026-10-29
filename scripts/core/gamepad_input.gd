extends RefCounted
var game
var device=-1
var direction=Vector2.ZERO
var repeat_left=0.0
var menu_axis=Vector2.ZERO
var trigger_held={}
var melee_held=false
var melee_hold_time=0.0
var charge_active=false
const HOLD_THRESHOLD=.26
func setup(owner):
 game=owner
 load_bindings()
 apply_bindings()
 var buttons={"left":JOY_BUTTON_DPAD_LEFT,"right":JOY_BUTTON_DPAD_RIGHT,"down":JOY_BUTTON_DPAD_DOWN}
 for action in buttons:
  var event=InputEventJoypadButton.new();event.button_index=buttons[action];event.device=-1
  if not InputMap.action_has_event(action,event):InputMap.action_add_event(action,event)
 for row in [["left",JOY_AXIS_LEFT_X,-1.0],["right",JOY_AXIS_LEFT_X,1.0],["down",JOY_AXIS_LEFT_Y,1.0]]:
  InputMap.action_set_deadzone(row[0],.25)
  var event=InputEventJoypadMotion.new();event.axis=row[1];event.axis_value=row[2];event.device=-1
  if not InputMap.action_has_event(row[0],event):InputMap.action_add_event(row[0],event)
 Input.joy_connection_changed.connect(connection_changed)
 var connected=Input.get_connected_joypads()
 if not connected.is_empty():device=connected[0];game.pad_mode=true
func connection_changed(id,connected):
 if connected:return
 if device!=id:return
 direction=Vector2.ZERO;device=-1;trigger_held.clear();game.release_inputs()
 if game.active():game.state="paused";game.show_hint("手柄已断开 · 重新连接后按 Start 继续",5)
func handle(event):
 if rebinding!="":
  if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:rebinding="";return true
  if event is InputEventJoypadButton and event.pressed:
   if event.button_index==JOY_BUTTON_START:rebinding="";return true
   if event.button_index in [JOY_BUTTON_GUIDE,JOY_BUTTON_BACK]:return true
   assign(rebinding,"b"+str(event.button_index));return true
  if event is InputEventJoypadMotion and event.axis in [JOY_AXIS_TRIGGER_LEFT,JOY_AXIS_TRIGGER_RIGHT] and event.axis_value>.65:
   assign(rebinding,"a"+str(event.axis));return true
  return true
 if event is InputEventMouseMotion:
  game.pad_mode=false;game.keyboard_nav=false;direction=Vector2.ZERO
  return false
 if event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch:
  if event.is_pressed():game.pad_mode=false;direction=Vector2.ZERO
  return false
 if not (event is InputEventJoypadButton or event is InputEventJoypadMotion):return false
 if event is InputEventJoypadButton and event.pressed or event is InputEventJoypadMotion and absf(event.axis_value)>.3:
  game.pad_mode=true;game.keyboard_nav=false;game.is_touch=false;device=event.device
 if game.state=="playing" and event is InputEventJoypadButton and ("b"+str(event.button_index))==bindings.attack:
  handle_melee_press(event.pressed)
  return true
 if event is InputEventJoypadButton and event.pressed:
  if event.button_index==JOY_BUTTON_START:
   direction=Vector2.ZERO
   if game.state in ["playing","boss_cinematic"]:game.cinematic_resume=game.state=="boss_cinematic";game.state="paused";game.release_inputs()
   elif game.state=="paused":game.resume_battle();game.release_inputs()
   elif game.state=="debug":game.debug_panel.close()
   return true
  if event.button_index==JOY_BUTTON_BACK and game.state=="playing":
   game.hud.action("stage_select");return true
 if event is InputEventJoypadMotion and event.axis in [JOY_AXIS_TRIGGER_LEFT,JOY_AXIS_TRIGGER_RIGHT]:
  var was=trigger_held.get(event.axis,false)
  var held=event.axis_value>(.35 if was else .55)
  trigger_held[event.axis]=held
  if game.state=="playing" and game.player:
   for action in ACTIONS:
    if bindings[action]=="a"+str(event.axis):
     if action=="attack":
      if held!=was:handle_melee_press(held)
     elif held and not was:game.player.enqueue(action)
     if was and not held and action=="jump":game.player.enqueue("jump_release")
  return true
 if game.state=="playing":direction=Vector2.ZERO;return false
 if event is InputEventJoypadButton and event.pressed:
  if event.button_index==(JOY_BUTTON_B if family()=="switch" else JOY_BUTTON_A):
   if game.state=="debug":game.debug_panel.pad_activate()
   else:game.hud.pad_activate()
   return true
  if event.button_index==(JOY_BUTTON_A if family()=="switch" else JOY_BUTTON_B):
   if game.state=="debug":game.debug_panel.close()
   elif game.state=="paused":game.resume_battle();game.release_inputs()
   elif game.state=="settings":game.hud.action("back")
   elif game.state=="controls":game.hud.action("controls_back")
   elif game.state=="stage_select":game.hud.action("stage_select_back")
   elif game.state=="relic_journal":game.hud.action("relic_journal_back")
   elif game.state=="journey_records":game.hud.action("journey_records_back")
   elif game.state=="new_confirm":game.hud.action("new_confirm_back")
   elif game.state=="animation_lab":game.hud.action("lab_back")
   return true
 var next=direction
 if event is InputEventJoypadMotion:
  if event.axis==JOY_AXIS_LEFT_X:menu_axis.x=event.axis_value
  elif event.axis==JOY_AXIS_LEFT_Y:menu_axis.y=event.axis_value
  if event.axis in [JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y]:
   next=Vector2.ZERO
   if maxf(absf(menu_axis.x),absf(menu_axis.y))>.55:
    next=Vector2(signf(menu_axis.x),0) if absf(menu_axis.x)>absf(menu_axis.y) else Vector2(0,signf(menu_axis.y))
 elif event is InputEventJoypadButton:
  var dirs={JOY_BUTTON_DPAD_LEFT:Vector2.LEFT,JOY_BUTTON_DPAD_RIGHT:Vector2.RIGHT,JOY_BUTTON_DPAD_UP:Vector2.UP,JOY_BUTTON_DPAD_DOWN:Vector2.DOWN}
  if dirs.has(event.button_index):next=dirs[event.button_index] if event.pressed else Vector2.ZERO
 if next!=direction:
  direction=next;repeat_left=.36
  if direction!=Vector2.ZERO:navigate()
 return true
func navigate():
 if game.state=="debug":game.debug_panel.pad_move(direction)
 else:game.hud.pad_move(direction)
func handle_melee_press(pressed):
 if pressed:
  if not melee_held:melee_held=true;melee_hold_time=0.0
 else:
  if melee_held and not charge_active and melee_hold_time<HOLD_THRESHOLD:game.player.enqueue("attack")
  melee_held=false;charge_active=false;melee_hold_time=0.0
func cancel_hold():
 melee_held=false;melee_hold_time=0.0;charge_active=false
 if is_instance_valid(game.player):game.player.charge=0
func tick(dt):
 if not game.active():
  if melee_held or charge_active:cancel_hold()
 elif melee_held and game.hitstop<=0:
  melee_hold_time+=dt
  if melee_hold_time>=HOLD_THRESHOLD and not charge_active and game.player.attack_elapsed<0:
   charge_active=true;game.player.charge=.32;game.audio.play("sheep_charge" if game.player.sheep() else "charge")
 if game.state=="playing" or not game.pad_mode:direction=Vector2.ZERO;return
 if direction==Vector2.ZERO:return
 repeat_left-=dt
 if repeat_left<=0:repeat_left=.16;navigate()

func cleanup():
 if Input.joy_connection_changed.is_connected(connection_changed):Input.joy_connection_changed.disconnect(connection_changed)

const CONFIG="user://controller.cfg"
const ACTIONS=["jump","attack","bow","dash","sprint","transform","summon","item"]
var bindings={}
var rebinding=""
var glyphs="auto"
func defaults():
 # Godot uses physical positions: Switch A=east, B=south, X=north, Y=west.
 return {"jump":"b"+str(JOY_BUTTON_B),"attack":"b"+str(JOY_BUTTON_LEFT_SHOULDER),"bow":"b"+str(JOY_BUTTON_RIGHT_SHOULDER),"dash":"a"+str(JOY_AXIS_TRIGGER_RIGHT),"sprint":"b"+str(JOY_BUTTON_Y),"transform":"b"+str(JOY_BUTTON_X),"summon":"b"+str(JOY_BUTTON_A),"item":"b"+str(JOY_BUTTON_DPAD_UP)}
func load_bindings(path=CONFIG):
 bindings=defaults()
 var config=ConfigFile.new()
 if config.load(path)==OK and config.get_value("layout","version",0)==2:
  var used=[]
  var candidate={}
  for action in ACTIONS:
   var value=str(config.get_value("bindings",action,bindings[action]))
   if not valid_binding(value) or value in used:return
   used.append(value);candidate[action]=value
  bindings=candidate;glyphs=str(config.get_value("display","glyphs","auto"))
func valid_binding(value):
 if value.begins_with("a"):return value in ["a"+str(JOY_AXIS_TRIGGER_LEFT),"a"+str(JOY_AXIS_TRIGGER_RIGHT)]
 return value.begins_with("b") and value.substr(1).is_valid_int() and int(value.substr(1)) in [JOY_BUTTON_A,JOY_BUTTON_B,JOY_BUTTON_X,JOY_BUTTON_Y,JOY_BUTTON_LEFT_STICK,JOY_BUTTON_RIGHT_STICK,JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_RIGHT_SHOULDER,JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN,JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT]
func save_bindings(path=CONFIG):
 if game.qa_mode and path==CONFIG:return
 var config=ConfigFile.new()
 for action in bindings:config.set_value("bindings",action,bindings[action])
 config.set_value("layout","version",2);config.set_value("display","glyphs",glyphs);config.save(path)
func apply_bindings():
 game.release_inputs()
 for action in ACTIONS+["charge"]:
  if not InputMap.has_action(action):InputMap.add_action(action)
  for event in InputMap.action_get_events(action):
   if event is InputEventJoypadButton or event is InputEventJoypadMotion:InputMap.action_erase_event(action,event)
  if action=="charge" or action=="attack":continue
  var value=bindings[action];var event
  if value.begins_with("b"):
   event=InputEventJoypadButton.new();event.button_index=int(value.substr(1))
  else:
   event=InputEventJoypadMotion.new();event.axis=int(value.substr(1));event.axis_value=1.0
  event.device=-1;InputMap.action_add_event(action,event);InputMap.action_set_deadzone(action,.25)
func assign(action,value):
 if not valid_binding(value):return
 var previous=bindings[action]
 for other in ACTIONS:
  if other!=action and bindings[other]==value:bindings[other]=previous
 bindings[action]=value;rebinding="";apply_bindings();save_bindings()
func reset_bindings():bindings=defaults();rebinding="";apply_bindings();save_bindings()
func family():
 if glyphs!="auto":return glyphs
 var name=Input.get_joy_name(device).to_lower() if device>=0 else ""
 if "dual" in name or "playstation" in name or "sony" in name or "ps5" in name:return "ps"
 if "nintendo" in name or "switch" in name:return "switch"
 return "xbox"
func label(value):
 var names={"xbox":["A","B","X","Y","Back","Guide","Start","LS","RS","LB","RB"],"ps":["×","○","□","△","Share","PS","Options","L3","R3","L1","R1"],"switch":["B","A","Y","X","−","Home","＋","LS","RS","L","R"]}[family()]
 var index=int(value.substr(1))
 if value.begins_with("a"):return (["L2","R2"] if family()=="ps" else (["ZL","ZR"] if family()=="switch" else ["LT","RT"]))[0 if index==JOY_AXIS_TRIGGER_LEFT else 1]
 var dpad={JOY_BUTTON_DPAD_UP:"↑",JOY_BUTTON_DPAD_DOWN:"↓",JOY_BUTTON_DPAD_LEFT:"←",JOY_BUTTON_DPAD_RIGHT:"→"}
 if dpad.has(index):return dpad[index]
 return names[index] if index<names.size() else "D"+str(index)
func binding_label(action):return label(bindings.attack)+"长按" if action=="charge" else label(bindings[action])
func summary():
 return "左摇杆移动  "+binding_label("jump")+"跳  "+binding_label("attack")+"斩  "+binding_label("bow")+"弓  "+binding_label("dash")+"翻滚  "+binding_label("sprint")+"冲刺  "+binding_label("charge")+"蓄爆  "+binding_label("transform")+"觉醒  "+binding_label("summon")+"召唤  "+binding_label("item")+"月露"

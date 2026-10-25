extends Node2D
var actor
var target
func bind_controls():
 for action in {"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"jump":[KEY_SPACE,KEY_W,KEY_UP],"attack":[KEY_J]}:
  if not InputMap.has_action(action):InputMap.add_action(action)
  for key in {"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"jump":[KEY_SPACE,KEY_W,KEY_UP],"attack":[KEY_J]}[action]:
   var event=InputEventKey.new();event.physical_keycode=key
   if not InputMap.action_has_event(action,event):InputMap.action_add_event(action,event)
 for pair in [["jump",JOY_BUTTON_A],["attack",JOY_BUTTON_LEFT_SHOULDER],["left",JOY_BUTTON_DPAD_LEFT],["right",JOY_BUTTON_DPAD_RIGHT]]:
  var event=InputEventJoypadButton.new();event.device=-1;event.button_index=pair[1]
  if not InputMap.action_has_event(pair[0],event):InputMap.action_add_event(pair[0],event)
 for pair in [["left",-1.0],["right",1.0]]:
  var event=InputEventJoypadMotion.new();event.device=-1;event.axis=JOY_AXIS_LEFT_X;event.axis_value=pair[1]
  InputMap.action_set_deadzone(pair[0],.25)
  if not InputMap.action_has_event(pair[0],event):InputMap.action_add_event(pair[0],event)
func surface(rect,one_way=false):
 var body=StaticBody2D.new();body.position=rect.position;add_child(body)
 var collision=CollisionShape2D.new();var box=RectangleShape2D.new();box.size=rect.size;collision.shape=box;collision.position=rect.size*.5;collision.one_way_collision=one_way;body.add_child(collision)
 var visual=Polygon2D.new();visual.polygon=PackedVector2Array([Vector2.ZERO,Vector2(rect.size.x,0),rect.size,Vector2(0,rect.size.y)]);visual.color=Color("516a68");body.add_child(visual)
func _ready():
 bind_controls()
 var bg=Polygon2D.new();bg.polygon=PackedVector2Array([Vector2.ZERO,Vector2(960,0),Vector2(960,540),Vector2(0,540)]);bg.color=Color("18262c");add_child(bg)
 surface(Rect2(0,450,960,90));surface(Rect2(-20,0,20,540));surface(Rect2(960,0,20,540));surface(Rect2(300,355,220,12),true)
 actor=load("res://tests/interactive_motion_actor.gd").new();actor.position=Vector2(80,450);add_child(actor)
 target=load("res://tests/practice_target.gd").new();target.scale=Vector2.ONE*actor.rig.game_scale;target.position=Vector2(680,450-64*actor.rig.game_scale);add_child(target);actor.target=target
 var label=Label.new();label.text="ANIMATION LAB   A/D: move   Space: jump   J: combo   R: reset\nGamepad: left stick / A jump / LB melee";label.position=Vector2(20,20);add_child(label)
func _unhandled_key_input(event):
 if event.pressed and event.physical_keycode==KEY_R:
  actor.position=Vector2(80,450);actor.velocity=Vector2.ZERO;actor.attack=-1;actor.rig.planted=[null,null];target.health=100;target.hits=0

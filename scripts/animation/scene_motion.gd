extends Node
# Display-only interpolation. Node/physics transforms remain authoritative.
var game
var tracks={}
var held_fraction=1.0
var enabled=true
func _ready():
 process_physics_priority=1000;process_priority=1000
func register(node,render=true):
 tracks[node.get_instance_id()]={"node":weakref(node),"previous":node.position,"current":node.position,"render":render}
func reset(node):
 if not is_instance_valid(node):return
 var key=node.get_instance_id()
 if tracks.has(key):tracks[key].previous=node.position;tracks[key].current=node.position
func clear():tracks.clear()
func fraction():
 if not enabled:return 1.0
 if game.active() and game.hitstop<=0:return clampf(Engine.get_physics_interpolation_fraction(),0,1)
 return held_fraction
func offset(node):
 if not enabled or not is_instance_valid(node):return Vector2.ZERO
 if is_instance_valid(game.player) and node==game.player and node.is_carried():return offset(node.carried_by)
 var key=node.get_instance_id()
 if not tracks.has(key):return Vector2.ZERO
 var entry=tracks[key]
 if node.position.distance_to(entry.current)>80:return Vector2.ZERO
 return entry.previous.lerp(entry.current,fraction())-entry.current
func display_position(node):return node.position+offset(node)
func _physics_process(_dt):
 if not game.active() or game.hitstop>0:return
 for key in tracks.keys():
  var entry=tracks[key];var node=entry.node.get_ref()
  if not is_instance_valid(node):tracks.erase(key);continue
  entry.previous=entry.current;entry.current=node.position
  if entry.current.distance_to(entry.previous)>80:entry.previous=entry.current
func _process(_dt):
 held_fraction=fraction()
 for key in tracks.keys():
  var entry=tracks[key];var node=entry.node.get_ref()
  if not is_instance_valid(node):tracks.erase(key);continue
  if not entry.render:continue
  var drawn=node.transform;drawn.origin+=offset(node)
  RenderingServer.canvas_item_set_transform(node.get_canvas_item(),drawn)

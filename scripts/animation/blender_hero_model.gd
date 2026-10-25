extends Node3D
var skeleton
var bones={}
var blade
var bow
var animation
var current=""
var preview_mode=false
func _ready():
 var scene=load("res://assets/animation/hero_blender.glb").instantiate();add_child(scene)
 skeleton=find_type(scene,"Skeleton3D");animation=find_type(scene,"AnimationPlayer")
 set_pixel_materials(scene)
 animation.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
 for clip in ["idle","run","charge"]:
  if animation.has_animation(clip):animation.get_animation(clip).loop_mode=Animation.LOOP_LINEAR
 for i in skeleton.get_bone_count():bones[skeleton.get_bone_name(i)]=i
 blade=scene.find_child("Sword",true,false);bow=scene.find_child("Bow",true,false)
func find_type(node,type):
 if node.is_class(type):return node
 for child in node.get_children():
  var result=find_type(child,type)
  if result:return result
 return null
func apply_pose(_pose):pass # Poses are now baked by Blender and played below.
func animate(state,time,dt):
 var clip="dash" if state=="roll" else state
 if not animation.has_animation(clip):clip="idle"
 if current!=clip:animation.play(clip,.075);current=clip
 if preview_mode:
  animation.advance(dt)
  animation.seek(fposmod(time,maxf(.001,animation.get_animation(clip).length)),true)
 else:
  animation.advance(dt)
  if clip.begins_with("slash") and absf(animation.current_animation_position-time)>.045:animation.seek(time,true)

func set_pixel_materials(node):
 if node is MeshInstance3D:
  for i in node.mesh.get_surface_count():
   var mat=node.get_active_material(i)
   if mat is StandardMaterial3D:mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
 for child in node.get_children():set_pixel_materials(child)

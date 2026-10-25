"""Import the authored Godot rig into an editable, self-contained Blender scene."""
import bpy, math, json, struct, tempfile
from pathlib import Path
from mathutils import Vector
root = Path(__file__).resolve().parents[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.scene.render.fps=60
raw=(root/'art_source/hero/yang_xiaoxia.glb').read_bytes()
size,kind=struct.unpack_from('<II',raw,12)
doc=json.loads(raw[20:20+size])
for key in ('extensionsRequired','extensionsUsed'):
 doc[key]=[e for e in doc.get(key,[]) if e!='KHR_node_visibility']
for node in doc.get('nodes',[]):node.get('extensions',{}).pop('KHR_node_visibility',None)
chunk=json.dumps(doc,separators=(',',':')).encode();chunk+=b' '*((-len(chunk))%4)
remaining=raw[20+size:]
compat=Path(tempfile.gettempdir())/'yang-blender-compatible.glb'
compat.write_bytes(struct.pack('<III',0x46546C67,2,20+len(chunk)+len(remaining))+struct.pack('<II',len(chunk),kind)+chunk+remaining)
bpy.ops.import_scene.gltf(filepath=str(compat))
scene=bpy.context.scene
scene.render.engine='BLENDER_EEVEE'
scene.render.resolution_x=384; scene.render.resolution_y=320; scene.render.resolution_percentage=100
scene.render.film_transparent=True;scene.render.fps=60
scene.view_settings.view_transform='Standard'
scene.world=bpy.data.worlds.new('Quiet studio');scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.32,.42,.5,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.5
bpy.ops.object.camera_add(location=(0,-6,.78));camera=bpy.context.object;camera.name='Pixel orthographic camera'
camera.rotation_euler=(Vector((0,0,.78))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=2.6;scene.camera=camera
for name,location,power,color in [('Warm key',(-3,-4,5),350,(1,.85,.68)),('Cool fill',(3,2,3),180,(.5,.73,1))]:
 bpy.ops.object.light_add(type='AREA',location=location);light=bpy.context.object;light.name=name;light.data.energy=power;light.data.shape='DISK';light.data.size=4;light.data.color=color;light.rotation_euler=(Vector((0,0,.7))-light.location).to_track_quat('-Z','Y').to_euler()
# glTF rigid attachments arrive as animated empties; rebuild a real editable armature.
source_names=['root','hips','chest','neck','head','far_arm','far_forearm','far_hand','far_thigh','far_shin','far_foot','near_arm','near_forearm','near_hand','near_thigh','near_shin','near_foot']
sources={name:bpy.data.objects[name] for name in source_names}
source_actions=list(bpy.data.actions)
def choose_source(clip):
 for obj in sources.values():
  data=obj.animation_data
  if not data:continue
  strip=next(s for t in data.nla_tracks for s in t.strips if s.action.name==clip)
  slot=strip.action_slot
  data.action=strip.action;data.action_slot=slot
  for track in data.nla_tracks:track.mute=True
choose_source('idle');scene.frame_set(0);bpy.context.view_layer.update()
armature=bpy.data.armatures.new('Yang Xiaoxia — 17 bones')
rig=bpy.data.objects.new('Yang Xiaoxia rig',armature);scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active=rig;rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
for name,obj in sources.items():
 bone=armature.edit_bones.new(name);bone.matrix=obj.matrix_world;bone.length=.12
 if obj.parent and obj.parent.name in sources:bone.parent=armature.edit_bones[obj.parent.name]
bpy.ops.object.mode_set(mode='OBJECT')
rig.animation_data_create();baked={}
for original in source_actions:
 choose_source(original.name)
 action=bpy.data.actions.new('Rig_'+original.name);rig.animation_data.action=action
 for frame in range(math.ceil(original.frame_range[1])+1):
  scene.frame_set(frame);bpy.context.view_layer.update()
  matrices={n:o.matrix_world.copy() for n,o in sources.items()}
  for name in source_names:
   pb=rig.pose.bones[name];pb.rotation_mode='QUATERNION';pb.matrix=matrices[name]
   bpy.context.view_layer.update()
   pb.keyframe_insert('location',frame=frame,group=name);pb.keyframe_insert('rotation_quaternion',frame=frame,group=name);pb.keyframe_insert('scale',frame=frame,group=name)
 action.use_fake_user=True;baked[original.name]=action
choose_source('idle');rig.animation_data.action=baked['idle'];scene.frame_set(0);bpy.context.view_layer.update()
for name,obj in sources.items():
 for child in list(obj.children):
  if child.name in sources:continue
  world=child.matrix_world.copy();child.parent=rig;child.parent_type='BONE';child.parent_bone=name;child.matrix_world=world
for obj in sources.values():bpy.data.objects.remove(obj,do_unlink=True)
for action in source_actions:bpy.data.actions.remove(action)
for action in baked.values():action.name=action.name.removeprefix('Rig_')
# Idle preview uses sword. Bow mesh is retained for editing the bow clip.
bow=bpy.data.objects.get('Bow')
if bow:
 bow.hide_render=True;bow.hide_viewport=True
 for child in bow.children_recursive:child.hide_render=True;child.hide_viewport=True

armatures=[obj for obj in scene.objects if obj.type=='ARMATURE']
for obj in armatures:
 obj.show_in_front=True
 if obj.animation_data:
  for track in obj.animation_data.nla_tracks:track.mute=True
  action=next((a for a in bpy.data.actions if a.name=='idle'),None)
  if action:obj.animation_data.action=action
for action in bpy.data.actions:action.use_fake_user=True
scene.frame_start=1;scene.frame_end=145;scene.frame_set(1)
for obj in scene.objects:obj.select_set(False)
if armatures:
 armatures[0].select_set(True);bpy.context.view_layer.objects.active=armatures[0]
notes=bpy.data.texts.new('READ ME — Yang Xiaoxia')
notes.write('Editable hybrid character: 3D rigid limb meshes and 17-bone skeleton; original illustrated face remains a textured card.\n12 motion clips baked as editable armature actions. Select a clip in the Action Editor.\nGodot runtime blends the authored poses continuously. This file is an editing source, not a newly sculpted volumetric face.\nOrange/cream shirt, black shorts, bare feet. Game height: 52.8 pixels.\n')
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(root/'art_source/hero/yang_xiaoxia.blend'))
scene.render.filepath=str(root/'builds/qa/animation/blender-hero.png');bpy.ops.render.render(write_still=True)
print('BLENDER_HERO',len(armatures),'armatures',sum(len(a.data.bones) for a in armatures),'bones',len(bpy.data.actions),'actions')

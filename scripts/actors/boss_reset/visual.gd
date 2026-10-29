extends "res://scripts/animation/actor_pose_art.gd"
var clips={}
var weapon_tips=[]
var weapon_hands=[]
var attack_pitch=0.0
var moon_texture:Texture2D
func configure_reset(id,height):
 body_height=height;rigid_frames=true
 if id=="priest":
  material=ShaderMaterial.new();material.shader=load("res://scripts/actors/boss_reset/palette_cleanup.gdshader")
 var folder="res://assets/art/boss_reset/"+id
 var path=folder+"/frames.json"
 if FileAccess.file_exists(path):
  var data=JSON.parse_string(FileAccess.get_file_as_string(path));clips=data.clips
  load_frames(folder,data.count);scale_unit=height/float(data.reference_height)
  use_anatomy_profile("reset/"+id,height)
  var profiles=JSON.parse_string(FileAccess.get_file_as_string("res://assets/animation/boss_scale_guides.json")).profiles
  for i in isolated.size():
   var im=isolated[i].get_image();var edge=-1;var samples=[]
   for y in im.get_height():
    for x in im.get_width():
     var pixel=im.get_pixel(x,y)
     if pixel.a>.65 and pixel.r>.5 and pixel.g>.43 and absf(pixel.r-pixel.g)<.25:
      if x>edge:edge=x;samples=[]
      if x==edge:samples.append(Vector2(x,y))
   var tip=Vector2(bounds[i].end.x,bounds[i].get_center().y)
   if not samples.is_empty():
    tip=Vector2.ZERO
    for point in samples:tip+=point
    tip/=samples.size()
   if profiles.has("reset/"+id) and profiles["reset/"+id].frames[i].has("focus"):
    var focus=profiles["reset/"+id].frames[i].focus;tip=Vector2(focus[0],focus[1])
   weapon_tips.append(tip);weapon_hands.append(Vector2(anchors[i]+8/frame_unit(i),bounds[i].end.y-height*.53/frame_unit(i)))
 else:
  load_frames("res://assets/art/boss_frames",18);scale_unit=height/maxf(1,bounds[["lantern","duelist","priest"].find(id)*6].size.y)
  for name in ["idle","death","turn","stagger","transform","recall"]:clips[name]=[["lantern","duelist","priest"].find(id)*6]
 if id=="duelist" and not clips.has("walk"):clips.walk=clips.idle.slice(0,6)
 if ResourceLoader.exists("res://assets/art/boss_reset/moon.png"):moon_texture=load("res://assets/art/boss_reset/moon.png")
 set_process(false)
func pose(clip,u):
 var indexes=clips.get(clip,clips.get("idle",[0]))
 frame=int(indexes[clampi(int(clampf(u,0,.99999)*indexes.size()),0,indexes.size()-1)])
 facing=actor.facing;queue_redraw()
func advance(dt):
 attack_pitch=lerpf(attack_pitch,.24 if actor.spec.id=="duelist" and actor.strike>0 else 0.0,1-exp(-dt*22))
 clock+=dt;bridge_left=maxf(0,bridge_left-dt)
 lean=lerpf(lean,.015 if actor.windup>0 else 0,1-exp(-dt*16))
 sink=sin(clock*3)*.12;queue_redraw()
func transition_duration(_index):return .065

func weapon_segment():
 if weapon_tips.is_empty():return [actor.position+Vector2(actor.facing*15,-55),actor.position+Vector2(actor.facing*75,-30)]
 return [to_global(source_socket(frame,weapon_hands[frame])),to_global(source_socket(frame,weapon_tips[frame]))]

func deform(p):
 var result=super.deform(p)
 if actor.spec.id=="duelist":
  var pivot=Vector2(0,-body_height*.40)
  var weight=smoothstep(body_height*.30,body_height*.43,-p.y)
  result+=((result-pivot).rotated(attack_pitch)+pivot-result)*weight
 return result

extends CanvasLayer
const MOTION=preload("res://scripts/animation/hero_motion.gd")
const SEQUENCE=[["idle",1.1],["run",1.8],["jump",.42],["fall",.42],["land",.18],["idle",.3],["slash1",.27],["slash2",.29],["slash3",.49],["idle",.65]]
var game
var rig
var legacy
var heavy
var cursor=0
var clock=0.0
var speed=1.0
var playing=true
var current="idle"
var jump_offset=0.0
var preview_offset=0.0
var previous="title"
func _ready():
 layer=21
 rig=load("res://scripts/animation/hero_visual.gd").new();rig.preview=true;rig.position=Vector2(680,372);rig.scale=Vector2.ONE*3;add_child(rig)
 legacy=load("res://scripts/actors/atlas_actor.gd").new();legacy.configure("res://assets/art/v2/hero.png",8,5,52.8);legacy.position=Vector2(265,372);legacy.scale=Vector2.ONE*3;add_child(legacy)
 heavy=load("res://scripts/actors/atlas_actor.gd").new();heavy.configure("res://assets/art/v2/uppercut.png",4,2,52.8);heavy.scale=Vector2.ONE*3;add_child(heavy);heavy.hide()
func _process(dt):
 visible=game.state=="animation_lab"
 if not visible:
  rig.set_process(false);return
 rig.set_process(playing)
 advance(dt)
 current=SEQUENCE[cursor][0];rig.preview_state=current;rig.preview_time=clock
 rig.preview_speed=225;rig.playback_rate=speed
 if current=="jump":jump_offset=-sin(clock/.84*PI)*30
 elif current=="fall":jump_offset=-sin((clock+.42)/.84*PI)*30
 else:jump_offset=0
 rig.position.y=372-preview_offset+jump_offset;legacy.position.y=rig.position.y;heavy.position=legacy.position
 var frame=0
 match current:
  "idle":frame=int(clock*6)%8
  "run":frame=8+int(clock*14)%8
  "jump":frame=32 if clock<.15 else 33
  "fall":frame=34
  "land":frame=35
  "slash1":frame=16+mini(7,int(clock/.38*8))
  "slash2":frame=24+mini(7,int(clock/.41*8))
 legacy.frame=frame;legacy.visible=current!="slash3";heavy.visible=current=="slash3"
 if heavy.visible:heavy.frame=mini(7,int(clock/.49*8))
func advance(dt):
 if not playing:return
 clock+=dt*speed
 while clock>=SEQUENCE[cursor][1]:
  clock-=SEQUENCE[cursor][1];cursor=(cursor+1)%SEQUENCE.size()
func restart():cursor=0;clock=0;playing=true
func title():
 return {"idle":"站立呼吸","run":"起跑与支撑步","jump":"起跳收腿","fall":"下落准备","land":"屈膝落地","slash1":"第一斩 · 蓄势挥出","slash2":"第二斩 · 回身连斩","slash3":"第三斩 · 蓄势上挑"}[current]

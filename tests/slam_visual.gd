extends SceneTree
var game
var panels=[]
func _initialize():call_deferred("run")
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.state="paused"
 var layer=CanvasLayer.new();layer.layer=40;root.add_child(layer)
 var back=ColorRect.new();back.color=Color("14232c");back.size=Vector2(960,540);layer.add_child(back)
 var titles=["Fire / ground","Breath / direction","Blade / impact","Falling blade","Cards / return","Fire / embers"]
 for i in 6:
  var p=Node2D.new();p.position=Vector2(25+(i%3)*315,45+(i/3)*245);layer.add_child(p)
  var label=Label.new();label.text=titles[i];label.position=Vector2(0,-26);p.add_child(label)
  var c=load("res://scripts/combat/combat.gd").new();c.game=game;p.add_child(c);c.set_physics_process(false);panels.append(c)
  if i==4:
   for j in 3:c.fire(Vector2(70+j*65,70),Vector2(150,-20),10,"brother","return_card",{"life":2})
   var fx=load("res://scripts/combat/effects.gd").new();fx.game=game;p.add_child(fx);fx.card_seal(Vector2(145,165));fx.queue_redraw()
  elif i==5:c.remnants.append({"rect":Rect2(25,30,235,140),"kind":"fire","age":.12,"life":.35,"owner":0})
  else:
   var h=c.hazard(Rect2(25,30,235,140) if i!=3 else Rect2(120,20,16,150),0,.6,0,0,["fire","breath","slam","rain"][i]);h.age=.13;h.face=1
   if i==2:h.rect=Rect2(90,118,96,52);h.total=.22
  c.queue_redraw()
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/slam-active.png")
 for c in panels:
  for h in c.hazards:h.delay=.3;h.warning_total=.6
  c.queue_redraw()
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/slam-warning.png")
 game.queue_free();layer.queue_free();await process_frame;quit()

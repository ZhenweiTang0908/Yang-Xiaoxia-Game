extends Node2D
var game
var clock=0.0
var items=[]
static func spike_state(time,period):
 var cycle=fposmod(time,period)
 var active=cycle>period-.85
 var height=4.0
 if active:height=19.0
 elif cycle>period-.98:height=lerpf(4,19,smoothstep(period-.98,period-.85,cycle))
 elif time>=period and cycle<.16:height=lerpf(19,4,smoothstep(0,.16,cycle))
 return {"active":active,"warning":cycle>period-1.4,"height":height}
static func ritual_state(time,period,phase=0.0):
 var cycle=fposmod(time+phase,period)
 return {"active":cycle>period-.28,"warning":cycle>period-1.05,"cycle":cycle}
func setup(owner):
 game=owner
 for config in game.level.features:
  var item=config.duplicate();item["open"]=false;item["body"]=null;item["announced"]=false
  if item.kind in ["ferry","lift","gate"]:
   var body=AnimatableBody2D.new();body.sync_to_physics=false;body.collision_layer=1 if item.kind=="gate" else 4;body.collision_mask=0
   var collider=CollisionShape2D.new();var shape=RectangleShape2D.new();shape.size=Vector2(item.w,item.get("h",14));collider.shape=shape;collider.position=shape.size*.5;collider.one_way_collision=item.kind!="gate";body.add_child(collider);add_child(body);body.position=Vector2(item.x,item.y);item.body=body;game.scene_motion.register(body,false)
  items.append(item)
func _physics_process(dt):
 if not game.active() or game.hitstop>0:return
 clock+=dt
 game.player.environment_force=0
 for item in items:
  if item.kind=="plate" and not item.open and absf(game.player.position.x-item.x-item.w*.5)<item.w*.6 and absf(game.player.position.y-item.y)<14:
   item.open=true;game.audio.play("checkpoint",-6);game.show_hint("石印已开启 · 前方闸门升起",3)
   for gate in items:
    if gate.kind=="gate" and gate.x==item.gate:gate.open=true
  if item.kind=="gate" and item.open:item.body.position.y=move_toward(item.body.position.y,item.y-item.h-15,90*dt)
  elif item.kind in ["lift","ferry"]:
   var shift=(1-cos(clock*item.speed))*.5*item.travel
   item.body.position=Vector2(item.x+(shift if item.kind=="ferry" else 0),item.y-(shift if item.kind=="lift" else 0))
  elif item.kind=="spikes":
   var state=spike_state(clock,item.period)
   if state.active and Rect2(item.x,item.y-18,item.w,22).intersects(Rect2(game.player.position-Vector2(12,48),Vector2(24,48))):game.player.take_damage(12,0,"spikes")
  elif item.kind=="gust":
   var zone=Rect2(item.x,item.y,item.w,item.h)
   if zone.has_point(game.player.position):
    game.player.environment_force+=item.force
    if not item.announced:
     item.announced=true;game.show_hint("雾流涌动 · 顺势前进，逆风时注意留出跳跃距离",4)
  elif item.kind=="ritual":
   var state=ritual_state(clock,item.period,item.get("phase",0.0))
   var center=Vector2(item.x,item.y)
   if state.active and game.player.position.distance_to(center)<item.radius:
    game.player.take_damage(item.get("damage",10),signf(game.player.position.x-item.x),"ritual")
 queue_redraw()
func _process(_dt):queue_redraw()
func _draw():
 if not game:return
 for item in items:
  if absf(item.x-game.player.position.x)>1150:continue
  match item.kind:
   "plate":
    draw_rect(Rect2(item.x,item.y-4,item.w,4),Color("8ac6b8") if item.open else Color("777d7b"))
    draw_line(Vector2(item.x+12,item.y-4),Vector2(item.x+item.w-12,item.y-4),Color("b0d3c3"),1)
   "gate":
    var p=game.scene_motion.display_position(item.body)
    for x in range(0,int(item.w),7):draw_line(p+Vector2(x,0),p+Vector2(x,item.h),Color("65767a"),3)
    draw_rect(Rect2(p,Vector2(item.w,6)),Color("93a49c"))
   "ferry","lift":
    var p=game.scene_motion.display_position(item.body)
    if game.level.stage_art()==3:
     draw_rect(Rect2(p,Vector2(item.w,14)),Color("393449"))
     draw_line(p,p+Vector2(item.w,0),Color("a59cae"),3)
     draw_colored_polygon(PackedVector2Array([p+Vector2(0,14),p+Vector2(item.w,14),p+Vector2(item.w-16,26),p+Vector2(item.w*.55,30),p+Vector2(12,24)]),Color("252333"))
     for x in [item.w*.25,item.w*.75]:
      draw_polyline(PackedVector2Array([p+Vector2(x-5,4),p+Vector2(x,8),p+Vector2(x+5,4)]),Color("797184"),1)
     if item.kind=="lift":
      for x in [15,item.w-15]:
       draw_line(Vector2(item.x+x,item.y-item.travel-90),p+Vector2(x,0),Color("474153"),2)
       for y in range(int(item.y-item.travel-90),int(p.y)-4,12):draw_line(Vector2(item.x+x-2,y),Vector2(item.x+x+2,y+4),Color("645a71"),1)
     continue
    draw_rect(Rect2(p,Vector2(item.w,14)),Color("594d42"));draw_line(p,p+Vector2(item.w,0),Color("a3aa8d"),3)
    for x in range(12,int(item.w),24):draw_line(p+Vector2(x,3),p+Vector2(x,12),Color("302f31"),1)
    if item.kind=="lift":
     for x in [15,item.w-15]:draw_line(Vector2(item.x+x,item.y-item.travel-90),p+Vector2(x,0),Color("687573"),2)
    else:
     var hull=PackedVector2Array([p+Vector2(-8,8),p+Vector2(item.w+8,8),p+Vector2(item.w+2,17),p+Vector2(item.w-14,27),p+Vector2(item.w-35,32),p+Vector2(35,32),p+Vector2(14,27),p+Vector2(-2,17)])
     draw_colored_polygon(hull,Color("3b4036"))
     draw_polyline(PackedVector2Array([p+Vector2(-4,13),p+Vector2(17,23),p+Vector2(item.w-17,23),p+Vector2(item.w+4,13)]),Color("60634c"),1.5)
     draw_colored_polygon(PackedVector2Array([p+Vector2(17,26),p+Vector2(item.w-17,26),p+Vector2(item.w-35,32),p+Vector2(35,32)]),Color("26383a"))
     for x in [20,item.w-20]:
      draw_line(p+Vector2(x,0),p+Vector2(x,-14),Color("645849"),3)
      draw_line(p+Vector2(x-3,-9),p+Vector2(x+3,-9),Color("838368"),2)
   "spikes":
    var state=spike_state(clock,item.period)
    for x in range(int(item.x)+6,int(item.x+item.w),16):
     draw_colored_polygon(PackedVector2Array([Vector2(x-5,item.y),Vector2(x,item.y-state.height),Vector2(x+5,item.y)]),Color("c4cfca") if state.active else Color("485a60"))
    if state.warning:draw_line(Vector2(item.x,item.y-1),Vector2(item.x+item.w,item.y-1),Color("cda889"),1)
   "gust":
    var direction=signf(item.force)
    var color=Color("8abeb8")
    for row in 5:
     var y=item.y+22+row*(item.h-35)/4.0
     for j in 6:
      var travel=fposmod(j*137+clock*absf(item.force)*1.7,item.w+90)-45
      var x=item.x+(travel if direction>0 else item.w-travel)
      var start=Vector2(x,y+sin(clock*1.8+row+j)*5)
      draw_line(start,start+Vector2(direction*(30+row*3),0),Color(color,.19+row*.022),2)
      var tip=start+Vector2(direction*(30+row*3),0)
      draw_line(tip,tip+Vector2(-direction*9,-5),Color(color,.22+row*.022),2)
      draw_line(tip,tip+Vector2(-direction*9,5),Color(color,.22+row*.022),2)
   "ritual":
    var state=ritual_state(clock,item.period,item.get("phase",0.0))
    var center=Vector2(item.x,item.y-2)
    var color=Color("d18c83") if state.active else (Color("d8b27d") if state.warning else Color("75637f"))
    var pulse=3.0*sin(clock*5+item.get("phase",0.0)) if state.warning else 0.0
    draw_arc(center,item.radius+pulse,PI,TAU,40,Color(color,.85 if state.warning else .35),3 if state.active else 2)
    draw_arc(center,item.radius*.58-pulse*.3,PI,TAU,32,Color(color,.55 if state.warning else .22),2)
    for angle in [PI,PI*1.25,PI*1.5,PI*1.75,TAU]:
     var edge=center+Vector2(cos(angle),sin(angle))*(item.radius-5)
     draw_circle(edge,3,color)

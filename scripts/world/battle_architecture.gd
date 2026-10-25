extends RefCounted
# Boss-rush arena dressing. Three layers keep combat readable:
#  backdrop()  screen-space distant silhouettes behind the painted vista's foreground veil,
#  draw_back() world-space structures behind the ledges (supports, chains, towers),
#  draw()      floor surface detail drawn after the walking surfaces.
# Every playable ledge comes from the arena resource; nothing here has collision.
const FLOOR=450.0
static func palette(stage):
 return {
  "stone":[Color("253944"),Color("273e40"),Color("322d43"),Color("343341")][stage-1],
  "edge":[Color("668083"),Color("6b8680"),Color("817190"),Color("82766d")][stage-1],
  "deep":[Color("111c26"),Color("10211f"),Color("1a1626"),Color("1a1a24")][stage-1],
  "glow":[Color("e5a65f"),Color("9fd8c8"),Color("b48cf0"),Color("e07d4f")][stage-1],
 }
static func ledges(game):
 return game.level.platforms.filter(func(p):return p.one_way)
# ---------------------------------------------------------------- behind the ledges
static func draw_back(c,game):
 var stage=game.level.number
 var t=game.clock
 var col=palette(stage)
 # Edge towers sit half outside the screen so they frame the arena without hiding ledges.
 for side in [0,1]:
  var x=-24.0 if side==0 else 912.0
  var top=150.0 if stage==3 else 175.0
  c.draw_rect(Rect2(x,top,72,FLOOR-top),col.stone.darkened(.3))
  c.draw_rect(Rect2(x-10,top-12,92,15),col.stone.lightened(.05))
  for row in range(int(top)+26,int(FLOOR)-4,30):
   c.draw_line(Vector2(x+3,row),Vector2(x+68,row),col.edge.darkened(.5),1)
  var window=x+(44 if side==0 else 10)
  for y in [top+48,top+128]:
   c.draw_rect(Rect2(window,y,16,36),Color("0e1520"))
   c.draw_rect(Rect2(window+3,y+5,10,26),Color(col.glow,.18+.06*sin(t*1.7+y)))
 for p in ledges(game):
  var top=float(p.y)+14
  match stage:
   1:
    # Stone terraces stand on squat columns; the high lantern bridge hangs from chains.
    if p.y>=330:
     for x in [p.x+16,p.x+p.w-16]:
      c.draw_rect(Rect2(x-9,top,18,FLOOR-top),col.stone.darkened(.12))
      c.draw_rect(Rect2(x-12,top,24,6),col.stone.lightened(.06))
      c.draw_rect(Rect2(x-12,FLOOR-8,24,8),col.stone.lightened(.02))
    else:
     for x in [p.x+22,p.x+p.w-22]:chain(c,Vector2(x,80),Vector2(x,top-10),col.edge.darkened(.35))
     for i in 2:
      var at=Vector2(p.x+p.w*(.3+i*.4),top+16+sin(t*1.3+i)*2)
      c.draw_line(Vector2(at.x,top),at-Vector2(0,8),col.edge.darkened(.3),1)
      lantern(c,at,col.glow,t+i)
   2:
    # Timber trestles; the two short spans over the gap are hung from a broken arch.
    if p.y>=350:
     for x in [p.x+12,p.x+p.w*.5,p.x+p.w-12]:c.draw_line(Vector2(x,top),Vector2(x,FLOOR),Color("263b37"),6)
     c.draw_line(Vector2(p.x+14,FLOOR-6),Vector2(p.x+p.w*.5,top+6),Color("1f302c"),4)
     c.draw_line(Vector2(p.x+p.w-14,FLOOR-6),Vector2(p.x+p.w*.5,top+6),Color("1f302c"),4)
    elif p.y>=290:
     var hang=p.x+p.w*.5
     c.draw_line(Vector2(p.x+10,top),Vector2(hang,top+40),Color("263b37"),5)
     c.draw_line(Vector2(p.x+p.w-10,top),Vector2(hang,top+40),Color("263b37"),5)
     c.draw_line(Vector2(hang,top+40),Vector2(hang,FLOOR),Color("1c2d2a"),7)
    else:
     for x in [p.x+14,p.x+p.w-14]:chain(c,Vector2(x,80),Vector2(x,top-10),Color("3d5a55"))
   3:
    # Altar wings are stepped masonry; the offering slab floats on violet light.
    if p.y>=320:
     var steps=int((FLOOR-top)/26.0)
     for s in steps:
      var inset=s*6.0
      c.draw_rect(Rect2(p.x+6-inset*.2,top+s*26,p.w-12+inset*.4,24),col.stone.darkened(.08+s*.04))
      c.draw_line(Vector2(p.x+8,top+s*26),Vector2(p.x+p.w-8,top+s*26),col.edge.darkened(.45),1)
     c.draw_rect(Rect2(p.x+6,top+steps*26,p.w-12,FLOOR-top-steps*26),col.stone.darkened(.2))
    else:
     var center=Vector2(p.x+p.w*.5,top+6)
     for i in 3:
      var a=float(i)/3
      c.draw_colored_polygon(PackedVector2Array([center+Vector2(-p.w*.42,0),center+Vector2(p.w*.42,0),center+Vector2(p.w*.12,26+i*8),center+Vector2(-p.w*.12,26+i*8)]),Color(.55,.38,.85,.10-a*.025))
     for i in 4:
      var y=fposmod(t*14+i*30,120)
      c.draw_circle(center+Vector2(sin(i*2.1)*p.w*.3,y+12),1.5,Color(.8,.6,1,.5*(1-y/120)))
   _:
    # Siege scaffolds: crossed beams and lashings, with one torch per tower.
    if p.y>=330:
     for x in [p.x+10,p.x+p.w-10]:c.draw_line(Vector2(x,top),Vector2(x,FLOOR),Color("3a3026"),6)
     c.draw_line(Vector2(p.x+12,FLOOR-4),Vector2(p.x+p.w-12,top+4),Color("2f271f"),4)
     c.draw_line(Vector2(p.x+p.w-12,FLOOR-4),Vector2(p.x+12,top+4),Color("2f271f"),4)
     var torch=Vector2(p.x+(p.w-8 if p.x<480 else 8),top-30)
     c.draw_line(torch,torch+Vector2(0,30),Color("4a3a2a"),3)
     preload("res://scripts/combat/vfx_shapes.gd").flame(c,torch,6,11,t,col.glow)
    else:
     for x in [p.x+14,p.x+p.w-14]:c.draw_line(Vector2(x,top),Vector2(x,FLOOR),Color("33291f"),7)
     for y in range(int(top)+30,int(FLOOR)-10,52):
      c.draw_line(Vector2(p.x+14,y),Vector2(p.x+p.w-14,y+22),Color("2a2219"),3)
     var flag=PackedVector2Array([Vector2(p.x+p.w*.5,top-58),Vector2(p.x+p.w*.5+36+sin(t*1.9)*4,top-50),Vector2(p.x+p.w*.5+30+sin(t*1.9+1)*5,top-22),Vector2(p.x+p.w*.5,top-28)])
     c.draw_line(Vector2(p.x+p.w*.5,top),Vector2(p.x+p.w*.5,top-62),Color("6e604f"),3)
     c.draw_colored_polygon(flag,Color("5a3040"))
static func chain(c,from,to,color):
 var links=int(from.distance_to(to)/9)
 for i in links:
  var a=from.lerp(to,float(i)/links);var b=from.lerp(to,float(i+1)/links)
  c.draw_line(a,b,color,2 if i%2 else 1)
static func lantern(c,at,glow,phase):
 c.draw_circle(at,10,Color(glow,.10+.04*sin(phase*2.3)))
 c.draw_rect(Rect2(at-Vector2(5,7),Vector2(10,14)),Color("6b3a2c"))
 c.draw_rect(Rect2(at-Vector2(3,5),Vector2(6,10)),Color(glow,.85))
 c.draw_line(at-Vector2(6,7),at+Vector2(6,-7),Color("3d2a24"),2)
 c.draw_line(at-Vector2(6,-7),at+Vector2(6,7),Color("3d2a24"),2)
# ---------------------------------------------------------------- floor surface
static func draw(c,game):
 var stage=game.level.number
 var t=game.clock
 var col=palette(stage)
 # Shared masonry joints and drainage channels below the walking edge.
 for j in 18:
  var x=j*58-30
  c.draw_line(Vector2(x,454),Vector2(x+19,468),col.edge.darkened(.42),1)
  if j%3==0:c.draw_polyline(PackedVector2Array([Vector2(x+8,470),Vector2(x+13,481),Vector2(x+6,491)]),col.stone.darkened(.4),2)
 match stage:
  1:
   # Courtyard paving inlays, fallen roof tiles and moss tufts at the base of each column.
   for x in range(60,920,140):
    c.draw_rect(Rect2(x,458,64,10),col.stone.lightened(.05))
    c.draw_rect(Rect2(x+4,460,56,6),col.stone.darkened(.05))
   for x in [140,330,610,840]:
    for k in 3:c.draw_colored_polygon(PackedVector2Array([Vector2(x+k*9,450),Vector2(x+k*9+4,444-k%2*2),Vector2(x+k*9+8,450)]),Color("2f4a3f"))
   for x in [270,690]:
    c.draw_colored_polygon(PackedVector2Array([Vector2(x,450),Vector2(x+14,446),Vector2(x+26,448),Vector2(x+30,450)]),col.stone.lightened(.12))
   # Standing lantern posts sit at the arena edges, never inside the duel lane.
   for x in [62,898]:
    c.draw_rect(Rect2(x-4,404,8,46),col.stone.lightened(.08))
    c.draw_rect(Rect2(x-10,394,20,12),col.stone.lightened(.14))
    preload("res://scripts/combat/vfx_shapes.gd").flame(c,Vector2(x,396),6,11,t,col.glow)
  2:
   # Bridge deck planks over the river, its piers and the current underneath.
   c.draw_rect(Rect2(0,491,960,160),Color("102b33"))
   for x in [90,330,570,810]:
    c.draw_rect(Rect2(x-28,473,56,170),col.stone)
    c.draw_arc(Vector2(x+117,540),94,PI,TAU,24,col.stone,22)
   for j in 20:
    var x=fposmod(j*67+t*10,1000)-20
    c.draw_line(Vector2(x,518+j%3*9),Vector2(x+25,518+j%3*9),Color("33535b"),1)
   for x in range(0,960,24):c.draw_line(Vector2(x,451),Vector2(x,458),Color("1b2f2c"),1)
   for x in [120,420,700]:
    c.draw_line(Vector2(x,450),Vector2(x+3,428),Color("8a7b5b"),2)
    c.draw_line(Vector2(x+3,428),Vector2(x+20,436),Color("8a7b5b"),1)
   for j in 9:
    var at=Vector2(fposmod(j*113+t*6,960),300+fposmod(j*47,120)+sin(t*1.4+j)*6)
    c.draw_circle(at,1.6,Color(.75,1,.8,.35+.25*sin(t*3+j)))
  3:
   # A faint ritual circle is inlaid in the altar floor. It stays dim so it never
   # reads like the priest's lit ritual warnings.
   var pulse=.5+.5*sin(t*1.1)
   # Drawn as flattened ellipses so the circle reads as lying on the floor.
   c.draw_set_transform(Vector2(480,472),0,Vector2(1,.07))
   c.draw_arc(Vector2.ZERO,300,0,TAU,72,Color(.62,.42,.9,.07+.03*pulse),16)
   c.draw_arc(Vector2.ZERO,200,0,TAU,64,Color(.62,.42,.9,.05+.02*pulse),10)
   for i in 8:
    var a=i*TAU/8+t*.15
    c.draw_line(Vector2(cos(a),sin(a))*200,Vector2(cos(a),sin(a))*300,Color(.62,.42,.9,.04+.02*pulse),8)
   c.draw_set_transform(Vector2.ZERO)
   for j in 10:
    var x=270+j*45
    c.draw_line(Vector2(x,480),Vector2(x+15,480),Color("63566f"),2)
   for x in [110,850]:
    c.draw_colored_polygon(PackedVector2Array([Vector2(x-24,450),Vector2(x-12,412),Vector2(x+19,400),Vector2(x+27,450)]),col.stone)
    c.draw_line(Vector2(x,420),Vector2(x+8,444),col.edge.darkened(.2),2)
   for x in [300,640]:
    c.draw_circle(Vector2(x,446),4,Color("d8cfb8"))
    c.draw_line(Vector2(x,442),Vector2(x,436),Color("2a2533"),2)
    preload("res://scripts/combat/vfx_shapes.gd").flame(c,Vector2(x,435),3,6,t+x,col.glow)
  _:
   # Trampled field: hoof ruts, scattered straw and broken lances driven into the ground.
   for j in 7:
    var x=110+j*120
    c.draw_line(Vector2(x,453),Vector2(x+46,453),Color("1d1f27"),2)
    c.draw_line(Vector2(x+20,457),Vector2(x+60,457),Color("22242c"),1)
   for x in [22,938]:
    c.draw_rect(Rect2(x-22,472,44,130),Color("161e29"))
    for step in 4:c.draw_rect(Rect2(x-22+step*6,493+step*12,44-step*12,14),col.stone)
   for x in [215,735]:
    c.draw_line(Vector2(x,450),Vector2(x-18,402),col.edge.darkened(.15),3)
    c.draw_colored_polygon(PackedVector2Array([Vector2(x-18,402),Vector2(x-22,412),Vector2(x-12,409)]),col.edge)
   for j in 14:
    var x=30+j*67
    c.draw_line(Vector2(x,450),Vector2(x+6,446),Color("8d7a52",.6),1)
# ---------------------------------------------------------------- distant layers
static func backdrop(c,game):
 var stage=game.level.number
 var t=game.clock
 match stage:
  1:
   # Paper sky lanterns drift upward far behind the courtyard.
   for j in 7:
    var x=80+j*130+sin(t*.3+j)*12
    var y=330-fposmod(t*6+j*47,240)
    var fade=clampf((y-90)/60.0,0,1)
    c.draw_circle(Vector2(x,y),6,Color(.95,.66,.35,.12*fade))
    c.draw_rect(Rect2(x-2.5,y-3.5,5,7),Color(.95,.70,.40,.55*fade))
  2:
   # Two drifting mist bands sit over the river horizon.
   for band in 2:
    var y=330+band*42
    var points=PackedVector2Array()
    for i in 13:points.append(Vector2(i*80,y+sin(t*.25+i*.7+band)*6))
    for i in range(12,-1,-1):points.append(Vector2(i*80,y+28+sin(t*.2+i*.5+band)*5))
    c.draw_colored_polygon(points,Color(.65,.80,.78,.06))
  3:
   # An eclipse halo hangs above the bell; floating rune shards orbit slowly.
   var center=Vector2(480,120)
   c.draw_arc(center,64,0,TAU,64,Color(.70,.50,1,.14),5)
   c.draw_arc(center,78+sin(t*.8)*3,0,TAU,64,Color(.70,.50,1,.06),3)
   for i in 6:
    var a=t*.18+i*TAU/6
    var at=center+Vector2(cos(a)*240,sin(a)*60+150)
    c.draw_colored_polygon(PackedVector2Array([at+Vector2(0,-7),at+Vector2(4,0),at+Vector2(0,7),at+Vector2(-4,0)]),Color(.60,.48,.80,.35))
  _:
   # A crenellated fortress wall with watch fires closes the horizon.
   var wall=Color(.11,.13,.19,.78)
   var y=346.0
   var outline=PackedVector2Array([Vector2(0,540),Vector2(0,y)])
   for x in range(0,961,40):
    var h=y-(14 if (x/40)%2==0 else 0)
    outline.append(Vector2(x,h));outline.append(Vector2(x+20,h))
   outline.append(Vector2(960,y));outline.append(Vector2(960,540))
   c.draw_colored_polygon(outline,wall)
   for row in 4:
    var ry=y+14+row*22
    c.draw_line(Vector2(0,ry),Vector2(960,ry),Color(.16,.18,.24,.55),1)
    for x in range(-40+(row%2)*30,960,60):c.draw_line(Vector2(x,ry),Vector2(x,ry+22),Color(.16,.18,.24,.45),1)
   for x in [150,480,810]:
    c.draw_rect(Rect2(x-28,y-70,56,80),wall)
    for tooth in 3:c.draw_rect(Rect2(x-28+tooth*21,y-82,14,14),wall)
    c.draw_rect(Rect2(x-5,y-48,10,18),Color(.88,.52,.28,.35+.1*sin(t*2.1+x)))
   for x in [60,300,660,900]:
    c.draw_circle(Vector2(x,y-6),9,Color(.9,.5,.25,.08+.04*sin(t*3+x)))
    c.draw_circle(Vector2(x,y-6),3,Color(1,.7,.35,.6))
 # Slow drifting leaves/embers are sparse and stay behind combat silhouettes.
 for j in 12:
  var x=fposmod(j*137+t*(6 if stage==2 else 3),1000)-20
  var y=100+fposmod(j*57+t*2,280)
  c.draw_line(Vector2(x,y),Vector2(x+3,y+2),Color(.63,.58,.48,.16),1)

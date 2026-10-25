extends RefCounted
static func walking_edge(canvas,p,stage):
 # Continuous thin top marks collision; the deeper lip belongs to the material.
 var light=[Color("8d9b89"),Color("8ba79c"),Color("a59cae")][stage-1]
 var lip=[Color("526566"),Color("536f65"),Color("665e76")][stage-1]
 canvas.draw_rect(Rect2(p.x,p.y,p.w,4),lip)
 canvas.draw_rect(Rect2(p.x,p.y,p.w,1),light)
 for x in range(int(p.x)+54,int(p.x+p.w)-8,96):
  canvas.draw_line(Vector2(x,p.y+1),Vector2(x-1,p.y+4),lip.darkened(.3),1)
# Background construction: muted surfaces have no walking-edge highlight or collision.
static func draw_support(canvas,p,stage):
 var top=float(p.y+p.h)
 if top>=430 or p.w<300 or p.one_way:return
 var bottom=450.0
 var bays=maxi(2,int(round(p.w/200.0)))
 var span=float(p.w)/bays
 for bay in bays:
  var left=p.x+bay*span;var right=left+span
  if stage==1:
   var arch=PackedVector2Array([Vector2(left,top),Vector2(right,top)])
   for i in 17:
    var t=float(i)/16
    arch.append(Vector2(lerpf(right,left,t),bottom-sin(t*PI)*(bottom-top-18)))
   canvas.draw_colored_polygon(arch,Color("111e28"))
   var curve=arch.slice(2)
   var rim=curve.duplicate()
   for i in range(curve.size()-1,-1,-1):rim.append(curve[i]-Vector2(0,7))
   canvas.draw_colored_polygon(rim,Color("23343d"))
   var crown=Vector2((left+right)*.5,top+18)
   canvas.draw_colored_polygon(PackedVector2Array([crown+Vector2(-6,-10),crown+Vector2(6,-10),crown+Vector2(4,0),crown+Vector2(-4,0)]),Color("34434a"))
   for t in [.25,.75]:
    var point=Vector2(lerpf(right,left,t),bottom-sin(t*PI)*(bottom-top-18))
    canvas.draw_line(point-Vector2(0,7),point,Color("152630"),1)
   canvas.draw_rect(Rect2(left,top,12,bottom-top),Color("162630"))
   canvas.draw_rect(Rect2(right-12,top,12,bottom-top),Color("162630"))
  elif stage==2:
   for x in [left+10,right-10]:
    canvas.draw_line(Vector2(x,top),Vector2(x,bottom),Color("1c2b28"),8)
   canvas.draw_line(Vector2(left+12,bottom-8),Vector2(right-12,top+8),Color("192623"),5)
   canvas.draw_line(Vector2(left,top+8),Vector2(right,top+8),Color("29392f"),5)
  else:
   var x=left+span*.5
   canvas.draw_colored_polygon(PackedVector2Array([Vector2(x-17,top),Vector2(x+17,top),Vector2(x+12,bottom-10),Vector2(x-12,bottom-10)]),Color("211f30"))
   canvas.draw_rect(Rect2(x-23,top,46,9),Color("302b3e"))
   canvas.draw_rect(Rect2(x-22,bottom-10,44,10),Color("302b3e"))
   canvas.draw_line(Vector2(x-9,top+12),Vector2(x-7,bottom-13),Color("343044"),2)
static func pier_support(canvas,p):
 # One diagonal per bay keeps the dock legible without a lattice of lines.
 var top=float(p.y+14)
 var xs=[float(p.x+12),float(p.x+p.w-12)]
 var bottoms=[]
 for x in xs:
  var wet=(x>=4900 and x<=5420) or (x>=6100 and x<=6580)
  var bottom=476.0 if wet else 450.0
  bottoms.append(bottom)
  canvas.draw_line(Vector2(x,top),Vector2(x,bottom),Color("263b37"),6)
  canvas.draw_rect(Rect2(x-5,top+9,10,5),Color("3b4b3c"))
  if wet:
   canvas.draw_line(Vector2(x,457),Vector2(x,476),Color("1d3337"),7)
 if top<425:
  var low=minf(bottoms[0],bottoms[1])-10
  var flip=int(p.x/100)%2==0
  canvas.draw_line(Vector2(xs[0],top+18 if flip else low),Vector2(xs[1],low if flip else top+18),Color("273b33"),4)
static func timber_face(canvas,p):
 canvas.draw_rect(Rect2(p.x,p.y+4,p.w,maxf(0,p.h-4)),Color("3b4033"))
 canvas.draw_line(Vector2(p.x,p.y+7),Vector2(p.x+p.w,p.y+7),Color("64715b"),2)
 if p.h>20:
  canvas.draw_line(Vector2(p.x,p.y+p.h-7),Vector2(p.x+p.w,p.y+p.h-7),Color("242f2b"),5)
 for x in range(int(p.x)+18,int(p.x+p.w)-8,80):
  canvas.draw_line(Vector2(x,p.y+5),Vector2(x-2,p.y+p.h-3),Color("29372f"),2)
static func altar_face(canvas,p):
 # Recessed masonry, a broad cornice and two piers give raised altar blocks
 # structure without adding bright markings that resemble extra platforms.
 if p.y>=430 or p.w<90:return
 if p.h<55:
  # Shallow altar bridges use one broad recessed band and sparse brackets.
  # Their top edge remains the only bright horizontal navigation line.
  canvas.draw_rect(Rect2(p.x+8,p.y+10,p.w-16,maxf(4,p.h-17)),Color("1d1b29"))
  canvas.draw_line(Vector2(p.x+4,p.y+9),Vector2(p.x+p.w-4,p.y+9),Color("4a4257"),2)
  canvas.draw_line(Vector2(p.x+8,p.y+p.h-6),Vector2(p.x+p.w-8,p.y+p.h-6),Color("181722"),3)
  var brackets=maxi(2,int(round(p.w/210.0)))
  for i in brackets:
   var x=p.x+(i+.5)*p.w/brackets
   canvas.draw_colored_polygon(PackedVector2Array([Vector2(x-13,p.y+10),Vector2(x+13,p.y+10),Vector2(x+8,p.y+p.h-4),Vector2(x-8,p.y+p.h-4)]),Color("302b3d"))
   canvas.draw_line(Vector2(x-7,p.y+13),Vector2(x-5,p.y+p.h-7),Color("40384c"),1)
  return
 if p.w>650:return
 var bottom=p.y+p.h
 canvas.draw_rect(Rect2(p.x+11,p.y+18,p.w-22,p.h-27),Color("1e1d2b"))
 for x in [p.x+5,p.x+p.w-17]:
  canvas.draw_rect(Rect2(x,p.y+12,12,p.h-20),Color("322e40"))
  canvas.draw_line(Vector2(x+2,p.y+18),Vector2(x+2,bottom-12),Color("41394c"),1)
 canvas.draw_rect(Rect2(p.x+2,p.y+9,p.w-4,6),Color("40394e"))
 canvas.draw_rect(Rect2(p.x+2,bottom-10,p.w-4,8),Color("302b3d"))
 var bays=maxi(1,int(p.w/100))
 var span=(p.w-38)/bays
 for i in bays:
  var x=p.x+19+i*span
  canvas.draw_rect(Rect2(x+4,p.y+26,span-8,maxf(1,p.h-47)),Color("242131"))

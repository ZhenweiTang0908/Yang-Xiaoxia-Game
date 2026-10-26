extends Node2D
var game
var props:Texture2D
var mechanisms
var presence
const SOURCES=[Rect2(0,80,384,410),Rect2(384,280,384,210),Rect2(768,70,384,420),Rect2(1152,110,384,380),Rect2(0,620,384,320),Rect2(384,620,384,320),Rect2(768,655,384,285),Rect2(1152,620,384,320)]
func build(world):
	game=world
	props=load("res://assets/art/environment/props.png")
	material=ShaderMaterial.new();material.shader=load("res://scripts/actors/chroma.gdshader")
	for p in game.level.platforms:
		var body=StaticBody2D.new();body.collision_layer=4 if p.one_way else 1;body.collision_mask=0
		var c=CollisionShape2D.new();var shape=RectangleShape2D.new();shape.size=Vector2(p.w,p.h);c.shape=shape
		body.position=Vector2(p.x+p.w*.5,p.y+p.h*.5);c.one_way_collision=p.one_way;c.one_way_collision_margin=5;body.add_child(c);add_child(body)
	mechanisms=load("res://scripts/world/room_features.gd").new();add_child(mechanisms);mechanisms.setup(game)
	presence=load("res://scripts/world/ground_presence.gd").new();presence.game=game;add_child(presence)
func _process(_dt):queue_redraw()
func _draw():
	if not game or not game.level:return
	var center=game.player.position.x if game.player else 400.0
	var tint=game.level.tint
	# Water is a visual depth plane below the solid bridge and ferry routes.
	for gap in [Vector2(4900,520),Vector2(6100,480)]:
		if absf(gap.x-center)>1500:continue
		if game.level.stage_art()==3:
			draw_rect(Rect2(gap.x,455,gap.y,220),Color("11121f"))
			continue
		draw_rect(Rect2(gap.x,455,gap.y,220),Color("142d32") if game.level.stage_art()==2 else Color("142b3b"))
		# A shallow surface band and broken piling reflections anchor the ferry.
		# Reflections remain below the waterline and never resemble walking edges.
		if game.level.stage_art()==2:
			draw_polygon(PackedVector2Array([Vector2(gap.x,455),Vector2(gap.x+gap.y,455),Vector2(gap.x+gap.y,515),Vector2(gap.x,515)]),PackedColorArray([Color("1c383b"),Color("1c383b"),Color("142d32"),Color("142d32")]))
			for p in game.level.platforms:
				if not p.one_way:continue
				for post_x in [p.x+12,p.x+p.w-12]:
					if post_x<gap.x+8 or post_x>gap.x+gap.y-8:continue
					for band in 4:
						var x=post_x+sin(game.ambience_clock*1.4+band*.9)*2
						var y=477+band*7
						var width=6-band
						draw_line(Vector2(x-width,y),Vector2(x+width,y),Color(.12,.20,.20,.7-band*.14),2)
		for row in 4:
			var y=462+row*14
			for j in 5:
				var x=gap.x+fposmod(j*103+game.ambience_clock*(5+row*2),gap.y)
				draw_line(Vector2(x,y),Vector2(minf(x+26,gap.x+gap.y),y),Color("365363"),1)
	# Decorative midground is behind the bright, collision-bearing walking surfaces.
	for section in game.level.section_names.size():
		var start=section*4000.0
		var landmark=[0,1,4,3][section] if game.level.stage_art()==1 else ([2,1,5,0][section] if game.level.stage_art()==2 else [3,4,0,3][section])
		if section==1:landmark=1 if game.level.stage_art()!=3 else 4
		# The knight arena stays an open, flat field so every silhouette reads cleanly.
		if game.level.single_boss:continue
		# The altar's painted bell and staircase already form its focal point.
		if absf(start+500-center)<1400 and not (game.level.stage_art()==3 and section in [0,3]):
			prop(landmark,Vector2(start+500,450),255,Color(.55,.66,.73))
		for j in 4:
			var x=start+1100+j*850
			if absf(x-center)>1200:continue
			# Keep freestanding props out of the duel's central silhouette space.
			# The stage backdrop and lamps still frame the encounter on both sides.
			if is_instance_valid(game.boss) and x>game.boss.arena.position.x+90 and x<game.boss.arena.end.x-90:continue
			var item=([5,4,7,5] if game.level.stage_art()==1 else ([2,5,2,6] if game.level.stage_art()==2 else [4,7,4,5]))[j]
			prop(item,Vector2(x,450),185 if item==2 else (105 if item==7 else 85),Color(.55,.67,.73))
		draw_section_identity(section,start,center)
	if game.boss_rush:preload("res://scripts/world/battle_architecture.gd").draw_back(self,game)
	for p in game.level.platforms:
		if absf(p.x+p.w*.5-center)<1500:
			preload("res://scripts/world/platform_architecture.gd").draw_support(self,p,game.level.stage_art())
	for p in game.level.platforms:
		if p.x+p.w<center-1000 or p.x>center+1300:continue
		var rect=Rect2(p.x,p.y,p.w,p.h)
		draw_rect(rect,[Color("182b37"),Color("172f32"),Color("282537")][game.level.stage_art()-1])
		preload("res://scripts/world/platform_architecture.gd").walking_edge(self,p,game.level.stage_art())
		if p.one_way:
			var wood=game.level.stage_art()!=3 and (game.level.stage_art()==2 or int(p.x/4000)==1 or (game.boss_rush and game.level.number==4))
			draw_rect(Rect2(p.x,p.y+4,p.w,9),Color("574b3c") if wood else (Color("393449") if game.level.stage_art()==3 else Color("344a54")))
			for x in range(int(p.x)+8,int(p.x+p.w)-4,32):
				draw_line(Vector2(x,p.y+5),Vector2(x-2,p.y+12),Color("273842"),1)
			if wood:
				if game.boss_rush:pass
				elif game.level.stage_art()==2:preload("res://scripts/world/platform_architecture.gd").pier_support(self,p)
				else:
					for x in [p.x+12,p.x+p.w-12]:
						draw_line(Vector2(x,p.y+14),Vector2(x,maxf(450,p.y+14)),Color("303e43"),5)
			else:
				if p.y>=350 and game.level.stage_art()!=3 and not game.boss_rush:
					draw_texture_rect_region(props,Rect2(p.x,p.y+14,p.w,450-p.y-14),SOURCES[1],Color(.35,.46,.52))
				draw_colored_polygon(PackedVector2Array([Vector2(p.x+5,p.y+14),Vector2(p.x+18,p.y+22),Vector2(p.x+p.w-22,p.y+19),Vector2(p.x+p.w-5,p.y+14)]),Color("252333") if game.level.stage_art()==3 else Color("253943"))
		else:
			if game.level.stage_art()==2 and p.h<=40:preload("res://scripts/world/platform_architecture.gd").timber_face(self,p)
			else:solid_face(p,center)

	if game.boss_rush:preload("res://scripts/world/battle_architecture.gd").draw(self,game)
	for i in (0 if game.boss_rush else game.level.checkpoints.size()):
		var x=game.level.checkpoints[i]
		if absf(x-center)>1100:continue
		var color=game.TEAL if game.checkpoint_index>=i else Color("697e79")
		prop(7,Vector2(x,450),82,Color(.85,.87,.82))
		load("res://scripts/combat/vfx_shapes.gd").flame(self,Vector2(x,417),9,16,game.ambience_clock,Color("e5a65f"))
		if absf(game.player.position.x-x)<90 and game.subtitle_time<=0 and game.hint_time<=0:
			draw_string(game.font,Vector2(x-30,356),"山灯"+(" · 已记录" if game.checkpoint_index>=i else ""),HORIZONTAL_ALIGNMENT_LEFT,-1,11,color)
	for p in game.pickups:
		if p.taken or absf(p.x-center)>1000:continue
		var pos=Vector2(p.x,p.y+sin(game.ambience_clock*3)*3)
		var color=game.GOLD if p.kind in ["bow","relic"] else game.TEAL
		if p.kind=="bow":draw_arc(pos,13,-PI/2,PI/2,12,color,2);draw_line(pos-Vector2(0,13),pos+Vector2(0,13),color,1)
		elif p.kind=="relic":
			draw_arc(pos,12,-PI*.72,PI*.72,18,color,3)
			draw_circle(pos+Vector2(5,-5),2,Color("f2dfaa"));draw_line(pos+Vector2(-7,8),pos+Vector2(1,11),game.TEAL,1.5)
		elif p.kind=="heal":
			var bottle=PackedVector2Array([Vector2(-2,-8),Vector2(2,-8),Vector2(2,-4),Vector2(5,-1),Vector2(5,6),Vector2(-5,6),Vector2(-5,-1),Vector2(-2,-4)])
			for i in bottle.size():bottle[i]+=pos
			draw_colored_polygon(bottle,Color("8caaa3"))
			draw_rect(Rect2(pos+Vector2(-3,0),Vector2(6,4)),Color("47796c"))
			draw_line(pos+Vector2(-3,-8),pos+Vector2(3,-8),Color("c4bd95"),2)
		else:
			draw_colored_polygon(PackedVector2Array([pos+Vector2(1,-10),pos+Vector2(2,-4),pos+Vector2(5,0),pos+Vector2(3,5),pos+Vector2(-2,7),pos+Vector2(-5,2),pos+Vector2(-3,-3)]),color)
			draw_line(pos+Vector2(0,-3),pos+Vector2(-1,3),Color("deeadb"),1)
	# The vista carries the arena architecture; keep its fighting plane uncluttered.
	if center>13500:
		for x in [14360,15150]:prop(7,Vector2(x,450),105,Color(.65,.71,.75))
	var gate=Vector2(15720,450)
	if absf(gate.x-center)<1500:
		# The destination repeats the stage's silhouette, not one shared temple gate.
		match game.level.stage_art():
			1:prop(0,gate,220,Color(.66,.73,.78))
			2:
				prop(6,gate,170,Color(.44,.58,.58))
				prop(2,gate+Vector2(120,0),260,Color(.34,.47,.48))
			3:prop(3,gate,280,Color(.58,.54,.65))

func draw_section_identity(section,start,center):
	var x=start+760.0
	if absf(x-center)>1450:return
	match game.level.stage_art():
		1:
			var ink=Color("263b48")
			match section:
				0:
					# Mountain gate banners use two broad shapes, not patterned cloth.
					for side in [-1,1]:
						var px=x+side*135;draw_line(Vector2(px,270),Vector2(px,432),ink,4)
						draw_colored_polygon(PackedVector2Array([Vector2(px+side*3,286),Vector2(px+side*44,294),Vector2(px+side*38,352),Vector2(px+side*4,342)]),Color("314956"))
				1:
					# Broken rope bridge silhouette explains the interrupted upper route.
					draw_polyline(PackedVector2Array([Vector2(x-170,330),Vector2(x-70,350),Vector2(x+25,360),Vector2(x+155,328)]),Color(ink,.75),2)
					for i in 5:
						var px=x-140+i*68;draw_line(Vector2(px,340+i%2*5),Vector2(px+28,347+i%2*6),Color(ink,.55),3)
				2:
					for i in 3:
						var px=x-110+i*110;draw_rect(Rect2(px,315,70,118),Color("203540"));draw_line(Vector2(px,315),Vector2(px+70,315),Color("40545a"),2)
				3:
					for side in [-1,1]:
						var px=x+side*130;draw_line(Vector2(px,300),Vector2(px,430),ink,7);draw_circle(Vector2(px,294),8,Color("4c5650"))
		2:
			var ink=Color("203b3b")
			match section:
				0:
					for i in 7:
						var px=x-150+i*48;var h=25+(i*11)%34;draw_line(Vector2(px,450),Vector2(px+sin(i)*6,450-h),Color("355754",.65),2)
				1:
					for side in [-1,1]:
						var px=x+side*145;draw_line(Vector2(px,280),Vector2(px,450),ink,6)
					draw_polyline(PackedVector2Array([Vector2(x-145,292),Vector2(x-45,330),Vector2(x+55,324),Vector2(x+145,288)]),Color("3b5650",.65),2)
				2:
					draw_colored_polygon(PackedVector2Array([Vector2(x-145,420),Vector2(x+130,420),Vector2(x+92,448),Vector2(x-105,448)]),Color("1b3435"))
					draw_line(Vector2(x-20,420),Vector2(x-20,320),Color("35504b"),4);draw_colored_polygon(PackedVector2Array([Vector2(x-16,325),Vector2(x+75,378),Vector2(x-16,378)]),Color("3b5a56",.48))
				3:
					draw_line(Vector2(x,285),Vector2(x,440),ink,7);draw_arc(Vector2(x,285),18,PI,TAU,14,Color("527069",.7),3)
		3:
			var ink=Color("302b43")
			match section:
				0:
					for side in [-1,1]:
						var px=x+side*115;draw_line(Vector2(px,235),Vector2(px,385),ink,4)
						for y in range(250,380,18):draw_arc(Vector2(px,y),5,0,TAU,10,Color("4b435d",.55),1)
				1:
					for i in 4:
						var px=x-150+i*100;draw_colored_polygon(PackedVector2Array([Vector2(px-14,430),Vector2(px-9,335-i%2*18),Vector2(px+9,335-i%2*18),Vector2(px+14,430)]),Color(ink,.9))
				2:
					for i in 4:draw_rect(Rect2(x-170+i*22,414-i*17,250-i*44,8),Color("3a3349",.75))
				3:
					for side in [-1,1]:
						var px=x+side*125;draw_rect(Rect2(px-12,285,24,150),ink);draw_arc(Vector2(px,310),7,0,TAU,12,Color("5d526e",.62),1)

func prop(index,feet,height,tint):
	var source=SOURCES[index]
	var width=height*source.size.x/source.size.y
	# Shared masonry inherits the altar's cool violet ambient light rather than
	# retaining the saturated green moss of the mountain and ferry scenery.
	if game.level.stage_art()==3:tint=Color(tint.r*.92,tint.g*.76,tint.b*.96,tint.a)
	draw_texture_rect_region(props,Rect2(feet-Vector2(width*.5,height),Vector2(width,height)),source,tint)

func solid_face(p,center):
	# Keep the collision silhouette exact; a few broad courses replace enlarged texture tiles.
	var stage=game.level.stage_art()-1
	var face=[Color("1b2c35"),Color("1b302e"),Color("252333")][stage]
	var seam=[Color("142630"),Color("172c2c"),Color("232132")][stage]
	var rim=[Color("455452"),Color("445e54"),Color("595267")][stage]
	var left=maxf(p.x,center-1000);var right=minf(p.x+p.w,center+1300)
	draw_rect(Rect2(left,p.y+4,right-left,maxf(0,p.h-4)),face)
	draw_line(Vector2(left,p.y+7),Vector2(right,p.y+7),rim,2)
	for row in range(int(ceil(p.h/34.0))):
		var offset=54 if row%2 else 0
		for bx in range(int(left/112)*112-112+offset,int(right),112):
			var x0=maxf(left,bx+1);var x1=minf(right,bx+110)
			var y0=p.y+8+row*34;var y1=minf(p.y+p.h,y0+32)
			if x1<=x0 or y1<=y0:continue
			var variation=posmod(int(bx/112)+row*3,4)
			var shade=face.lightened(.018) if variation==0 else face.darkened(.035 if variation==1 else .012)
			draw_rect(Rect2(x0,y0,x1-x0,y1-y0),shade)
			if variation==0 and y1-y0>12:
				draw_line(Vector2(x0+3,y0+1),Vector2(minf(x1-3,x0+35),y0+1),face.lightened(.045),1)
	var rows=mini(4,int(p.h/34))
	for row in rows:
		var y=p.y+32+row*34
		if y>=p.y+p.h-3:break
		draw_line(Vector2(left,y),Vector2(right,y),seam,1)
		var offset=54 if row%2 else 0
		for x in range(int(left/112)*112+offset,int(right),112):
			if x<left+3 or x>right-3:continue
			draw_line(Vector2(x,y-24),Vector2(x,y),seam,1)
	# Sparse corner wear belongs to the stone face, never the bright walking edge.
	for x in range(int(left/277)*277,int(right),277):
		if x<left+10 or x>right-12:continue
		draw_polyline(PackedVector2Array([Vector2(x,p.y+10),Vector2(x-3,p.y+16),Vector2(x+1,p.y+21)]),seam,1)
	if game.level.stage_art()==3:preload("res://scripts/world/platform_architecture.gd").altar_face(self,p)

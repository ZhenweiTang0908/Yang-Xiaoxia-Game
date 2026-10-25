extends CanvasLayer
var game
var canvas
var buttons=[]
var pad_focus=0
var pad_state=""
var backdrop:Texture2D
var vistas:Texture2D
var hero:Texture2D
var niu:Texture2D
var niu_region=Rect2()
var settings_return="title"
var controls_return="title"
var stage_select_return="title"
var relic_journal_return="title"
var journey_records_return="title"
var journey_records_mode="standard"
var new_confirm_return="title"
var resource_feedback=0.0
var hovered_action=""
# Trailing boss health: lost health lingers as a pale band before draining.
var boss_lag=1.0
var boss_lag_hold=0.0
var boss_lag_owner=0
func _ready():
	layer=20;canvas=Node2D.new();add_child(canvas);canvas.draw.connect(render)
	canvas.material=ShaderMaterial.new();canvas.material.shader=load("res://scripts/actors/chroma.gdshader")
	vistas=load("res://assets/art/environment/vistas.png")
	backdrop=load("res://assets/art/moon_shrine.png");hero=load("res://assets/art/v2/hero.png");niu=load("res://assets/art/v3/bull.png")
	var bull=load("res://scripts/actors/atlas_actor.gd").new();bull.configure("res://assets/art/v3/bull.png",4,2,62)
	niu_region=Rect2(bull.regions[0].position+Vector2(bull.bounds[0].position),Vector2(bull.bounds[0].size));bull.free()
	# Background uses a separate layer below world entities.
	var back_layer=CanvasLayer.new();back_layer.layer=-10;add_child(back_layer)
	var back=Node2D.new();back_layer.add_child(back);back.draw.connect(draw_background)
	back.set_meta("background",true)
func _process(_dt):
	resource_feedback=maxf(0,resource_feedback-_dt)
	if is_instance_valid(game.boss) and game.state=="playing" and game.hitstop<=0:
		var ratio=clampf(game.boss.hp/game.boss.max_hp,0,1)
		if boss_lag_owner!=game.boss.get_instance_id() or ratio>boss_lag:boss_lag=ratio;boss_lag_owner=game.boss.get_instance_id()
		elif boss_lag>ratio:
			boss_lag_hold-=_dt
			if boss_lag_hold<=0:boss_lag=move_toward(boss_lag,ratio,_dt*.45)
		if absf(boss_lag-ratio)<.001:boss_lag_hold=.45
	var hovered=""
	if not game.pad_mode:
		var pointer=canvas.get_global_mouse_position()
		for b in buttons:
			if b.rect.has_point(pointer):hovered=b.action;break
	if hovered!=hovered_action:
		if not hovered.is_empty():game.audio.play("ui_focus",-17)
		hovered_action=hovered
	canvas.queue_redraw()
	for c in get_children():
		if c is CanvasLayer:c.get_child(0).queue_redraw()
func draw_background():
	var b:Node2D=null
	for c in get_children():
		if c is CanvasLayer:b=c.get_child(0)
	if not b:return
	var stage=game.level.stage_art() if game.level else 1
	var px=game.player.position.x if is_instance_valid(game.player) else 0.0
	var section=clampi(int(px/4000),0,3)
	var index=stage-1
	if stage==1 and section==1:index=3
	var source=Rect2((index%2)*768,(index/2)*512,768,512)
	var drift=sin(px/2800.0)*24
	b.draw_texture_rect_region(vistas,Rect2(-40+drift,-25,1040,600),source,[Color(.53,.60,.69),Color(.48,.60,.60),Color(.56,.51,.65)][stage-1])
	# A low-contrast veil separates decorative detail from the playable plane.
	b.draw_rect(Rect2(0,0,960,540),[Color(.06,.10,.16,.13),Color(.07,.14,.15,.17),Color(.10,.07,.16,.15)][stage-1])
	if game.boss_rush:preload("res://scripts/world/battle_architecture.gd").backdrop(b,game)
	draw_stage_atmosphere(b,stage,px)
	# Fade foreground separation into the distance instead of a hard horizon band.
	b.draw_polygon(PackedVector2Array([Vector2(0,240),Vector2(960,240),Vector2(960,540),Vector2(0,540)]),PackedColorArray([Color(.025,.045,.075,0),Color(.025,.045,.075,0),Color(.025,.045,.075,.22),Color(.025,.045,.075,.22)]))

func draw_stage_atmosphere(b,stage,px):
	var t=game.clock
	match stage:
		1:
			# Two broken, high cloud wisps leave the walking plane untouched.
			for row in 2:
				var y=92+row*58+sin(t*.18+row)*5
				var offset=fposmod(t*(4+row)+px*.006+row*310,1120)-100
				for part in 3:
					var x=offset+part*165
					var points=PackedVector2Array()
					for i in 7:points.append(Vector2(x+i*18,y+sin(i*.9+row)*2))
					b.draw_polyline(points,Color(.52,.61,.70,.07),2)
		2:
			# Broad mist bands drift at different speeds and stay behind the piers.
			for row in 3:
				var base_y=250+row*64
				var points=PackedVector2Array()
				for i in 13:
					var x=-70+i*92
					var y=base_y+sin(i*.72+t*(.20+row*.04)+px*.0008)*7
					points.append(Vector2(x,y))
				b.draw_polyline(points,Color(.46,.64,.62,.055-row*.008),8-row*1.5)
		3:
			# Sparse bell dust and two dim shafts identify the altar without outlining hazards.
			for shaft in 2:
				var x=330+shaft*280+sin(t*.12+shaft)*18
				b.draw_colored_polygon(PackedVector2Array([Vector2(x-24,70),Vector2(x+18,70),Vector2(x+78,470),Vector2(x+12,470)]),Color(.47,.42,.62,.025))
			for i in 7:
				var x=170+posmod(i*127+31,650)+sin(t*.27+i)*7
				var y=120+fposmod(i*67+t*(3+i%2),300)
				b.draw_circle(Vector2(x,y),.8,Color(.61,.56,.70,.10))

func text(p,message,size=15,color=Color("eeeade")):
	if game.pad_mode:
		for pair in [["A D 移动","左摇杆移动"],["空格跳跃",game.gamepad.binding_label("jump")+" 跳跃"],["J 连按",game.gamepad.binding_label("attack")+" 连按"],["K 射箭",game.gamepad.binding_label("bow")+" 射箭"],["E 召唤",game.gamepad.binding_label("summon")+" 召唤"],["按住 U","按住 "+game.gamepad.binding_label("charge")],["按 Q","按 "+game.gamepad.binding_label("transform")],["Q  羊灵",game.gamepad.binding_label("transform")+" 羊灵"]]:message=message.replace(pair[0],pair[1])
	canvas.draw_string(game.font,p,message,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func centered(y,message,size=17,color=Color("eeeade")):
	var w=game.font.get_string_size(message,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x;text(Vector2((960-w)/2,y),message,size,color)
func panel(rect,color=Color(.03,.055,.085,.93)):
	var style=StyleBoxFlat.new();style.bg_color=color;style.border_color=Color(.45,.62,.61,.4);style.set_border_width_all(1);style.set_corner_radius_all(4);canvas.draw_style_box(style,rect)
func button(rect,label,action,primary=false):
	var hovered=rect.has_point(canvas.get_global_mouse_position()) and not game.pad_mode
	panel(rect,Color("ddbd89") if primary and hovered else (Color("c6a574") if primary else (Color("294955") if hovered else Color("152936"))))
	if hovered:canvas.draw_line(rect.position+Vector2(8,rect.size.y-1),rect.end-Vector2(8,1),game.TEAL,1)
	var size=16 if rect.size.y>34 else 12
	var width=game.font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	text(rect.position+Vector2((rect.size.x-width)*.5,rect.size.y*.5+size*.36),label,size,Color("13232b") if primary else game.WHITE)
	if game.pad_mode and game.state!="playing" and buttons.size()==pad_focus:
		canvas.draw_rect(rect.grow(3),game.GOLD,false,2)
	buttons.append({"rect":rect,"action":action})
func bottle(at,full):
	var c=Color("9fd8c8") if full else Color("3a4a50")
	var shape=PackedVector2Array([Vector2(-2,-12),Vector2(2,-12),Vector2(2,-8),Vector2(6,-4),Vector2(6,4),Vector2(-6,4),Vector2(-6,-4),Vector2(-2,-8)])
	for i in shape.size():shape[i]+=at
	canvas.draw_colored_polygon(shape,c)
	canvas.draw_line(at+Vector2(-3,-12),at+Vector2(3,-12),Color("c4bd95") if full else Color("4d5a5c"),2)
func gourd(at,color):
	canvas.draw_circle(at+Vector2(0,-5),4.5,color);canvas.draw_circle(at+Vector2(0,4),7,color)
	canvas.draw_line(at+Vector2(0,-10),at+Vector2(2,-13),Color("6b4f33"),2)
func meter(p,w,value,color):
	canvas.draw_rect(Rect2(p,Vector2(w,5)),Color("283c49"));canvas.draw_rect(Rect2(p,Vector2(w*clampf(value,0,1),5)),color)
func render():
	if pad_state!=game.state:pad_state=game.state;pad_focus=0
	buttons.clear()
	match game.state:
		"title":title_screen()
		"new_confirm":new_confirm_screen()
		"settings":settings_screen()
		"controls":controls_screen()
		"stage_select":stage_select_screen()
		"relic_journal":relic_journal_screen()
		"journey_records":journey_records_screen()
		"story":story_screen()
		"upgrade":upgrade_screen()
		"animation_lab":animation_screen()
		_:
			if game.player and game.state=="playing":playing_hud()
			if game.state in ["paused","dead","stage_clear","win"]:overlay()
func title_screen():
	canvas.draw_rect(Rect2(0,0,960,540),Color(.02,.04,.07,.65))
	canvas.draw_line(Vector2(70,89),Vector2(115,89),game.GOLD,2)
	text(Vector2(130,94),"月 下 同 行",14,game.GOLD)
	text(Vector2(64,179),"羊小侠",64)
	button(Rect2(70,239,250,46),"继续连战","continue",true)
	button(Rect2(70,300,250,40),"四境连战","new")
	button(Rect2(70,356,120,34),"选择关卡","stage_select")
	button(Rect2(200,356,120,34),"设置","settings")
	panel(Rect2(70,413,250,66),Color(.025,.045,.065,.75))
	text(Vector2(85,436),"断誓骑场",12,game.GOLD)
	button(Rect2(85,446,101,25),"马战","challenge")
	button(Rect2(200,446,105,25),"步战","challenge_foot")
	portrait(niu,niu_region,Vector2(713,453),190)
	portrait(hero,Rect2(0,0,181,208),Vector2(550,453),166)
	# Bottom row is right-aligned so hiding the moon journal leaves no gap.
	var row=[["旅途簿","journey_records",90],["操作","controls",90],["参数 · F2","debug",110]]
	if game.relic_count()>0:row.push_front(["月痕札记","relic_journal",110])
	var x=860.0
	for i in range(row.size()-1,-1,-1):
		x-=row[i][2];button(Rect2(x,486,row[i][2],28),row[i][0],row[i][1]);x-=10
	if game.developer_mode:button(Rect2(818,20,122,28),"动画对比","animation_lab")

func new_confirm_screen():
	canvas.draw_rect(Rect2(0,0,960,540),Color(.012,.026,.042,.94))
	panel(Rect2(200,150,560,245))
	centered(211,"重新出发？",30,game.GOLD)
	centered(258,"当前旅途进度将被覆盖。",16)
	centered(287,"月痕、纪录与设置会保留。",13,game.TEAL)
	button(Rect2(235,328,230,42),"返回","new_confirm_back",true)
	button(Rect2(495,328,230,42),"重新出发","new_confirm_start")

func portrait(texture,source,feet,height):
	var size=Vector2(source.size.x/source.size.y*height,height)
	canvas.draw_texture_rect_region(texture,Rect2(feet-Vector2(size.x*.5,size.y),size),source)
func playing_hud():
	var p=game.player
	# Combat HUD is read from shapes and colour, not labels: bars, bottles, a gourd.
	panel(Rect2(18,15,236,32),Color(.03,.055,.085,.62))
	meter(Vector2(30,24),212,p.health/100,Color("d8927f"))
	meter(Vector2(30,35),212,p.rage/100,game.GOLD)
	if game.relaxed_journey():canvas.draw_circle(Vector2(248,20),2.5,game.TEAL)
	button(Rect2(264,15,58,32),"","tonic")
	for i in game.TONIC_MAX:
		bottle(Vector2(281+i*22,32),i<game.tonic_count())
	if resource_feedback>0:
		var tint=Color(1,.62,.35,resource_feedback*.8)
		canvas.draw_rect(Rect2(264,15,58,32).grow(2),tint,false,2)
		canvas.draw_rect(Rect2(18,15,236,32).grow(2),tint,false,1)
	if p.hurt_anim>0:
		var hit_alpha=(1-smoothstep(0,.22,.22-p.hurt_anim))*.65
		for edge in [Rect2(0,0,960,4),Rect2(0,536,960,4),Rect2(0,0,4,540),Rect2(956,0,4,540)]:canvas.draw_rect(edge,Color(1,.38,.24,hit_alpha))
	# The stage name appears briefly when a fight starts, instead of a fixed panel.
	var banner=game.clock-game.stage_banner
	if banner>=0 and banner<2.4:
		var fade=smoothstep(0,.3,banner)*(1-smoothstep(1.7,2.4,banner))
		# Mid-screen title card between two thin rules, clear of the boss bar.
		var rise=(1-smoothstep(0,.4,banner))*8
		var half=60+smoothstep(0,.5,banner)*70
		canvas.draw_line(Vector2(480-half,214+rise),Vector2(480-28,214+rise),Color(game.GOLD,fade*.55),1)
		canvas.draw_line(Vector2(480+28,214+rise),Vector2(480+half,214+rise),Color(game.GOLD,fade*.55),1)
		canvas.draw_circle(Vector2(480,214+rise),2,Color(game.GOLD,fade*.8))
		centered(200+rise,game.level.title,30,Color(game.GOLD,fade))
		if game.boss_rush:centered(240+rise,"第 "+str(game.level.number)+" / 4 战",13,Color(game.TEAL,fade*.85))
	button(Rect2(785,15,33,25),"跳","stage_select")
	button(Rect2(826,15,33,25),"调","debug")
	button(Rect2(867,15,33,25),"音","settings")
	button(Rect2(908,15,33,25),"Ⅱ","pause")
	if game.summon.unlocked:
		var summon=game.summon;var ally=summon.brother
		var icon=Vector2(37,66);var ready=summon.phase=="ready" and not summon.is_sealed()
		gourd(icon,Color("d8c08a") if ready else (Color("6c6a62") if summon.is_sealed() else Color("8f8a74")))
		if summon.is_sealed():
			canvas.draw_line(icon+Vector2(-8,-9),icon+Vector2(8,9),Color("d39283"),2)
			text(icon+Vector2(16,5),str(ceili(summon.seal_left())),12,Color("a7a39a"))
		elif summon.phase=="cooldown":text(icon+Vector2(16,5),str(ceili(summon.remaining)),12,Color("aab0a6"))
		elif ready:canvas.draw_arc(icon,13+sin(game.clock*3)*1.2,0,TAU,24,Color(game.GOLD,.45),1.2,true)
		if is_instance_valid(ally):
			meter(Vector2(56,64),120,ally.health/ally.max_health,Color("aeaa85"))
			meter(Vector2(56,71),120,summon.remaining/maxf(1,game.tuning.get_value("assist_duration")+game.upgrade_level("brother")*4) if summon.phase=="active" else 0.0,Color(game.TEAL,.7))
	if game.subtitle_time>0:
		panel(Rect2(200,493,560,30),Color(.025,.04,.055,.72));centered(513,game.subtitle,14,game.GOLD)
	elif game.hint_time>0 and game.hint in ["获得月痕","出口已开启 →","闸门已开启","获得弓箭 · K 射击"]:
		centered(490,game.hint.replace(" · K 射击",""),13,game.GOLD)
	if game.boss.active_battle and not game.boss.dead:
		centered(136,game.boss.spec.title,14,game.GOLD)
		var ratio=clampf(game.boss.hp/game.boss.max_hp,0,1)
		meter(Vector2(305,147),350,ratio,Color("ce8e83"))
		if boss_lag>ratio:canvas.draw_rect(Rect2(305+350*ratio,147,350*(boss_lag-ratio),5),Color(1,.93,.82,.75))
	if game.boss.spec.id=="knight" and game.boss.active_battle and not game.boss.dead:
		for i in 3:
			var box=Rect2(414+i*46,158,34,8)
			canvas.draw_rect(box,Color(.08,.065,.12,.96))
			var fill=clampf(game.boss.soul.rage-i,0,1)
			if fill>0:canvas.draw_rect(Rect2(box.position,Vector2(box.size.x*fill,box.size.y)),Color("ca9ef0"))
			canvas.draw_rect(box,Color("9d7ab8",.82),false,1.2)
	if p.soul_slow>0:meter(Vector2(30,50),212,minf(p.soul_slow/7.0,1.0),Color("c8a3ef"))
	if game.is_touch and game.active():
		for b in touch_layout():panel(b.rect,Color(.04,.08,.12,.75));text(b.rect.position+Vector2(14,29),b.label,16,game.GOLD)
func upgrade_screen():
	canvas.draw_rect(Rect2(0,0,960,540),Color(.015,.03,.05,.88))
	centered(66,"山 灯 共 鸣",14,game.TEAL)
	centered(105,"选择一式武学",31,game.GOLD)
	var cards=[
		{"id":"blade","name":"破锋","mark":"刃","color":Color("d99b80"),"lines":["连斩与羊灵近战","伤害提高 15%"]},
		{"id":"spirit","name":"灵火","mark":"焰","color":Color("d6bc72"),"lines":["羊灵延长 2 秒","幽焰更快，伤害 +4"]},
		{"id":"brother","name":"同心","mark":"契","color":Color("82c6b2"),"lines":["牛大侠助战 +4 秒","冲撞伤害 +12%"]}
	]
	for i in cards.size():
		var card=cards[i];var rect=Rect2(55+i*295,158,260,292);var current=game.upgrade_level(card.id)
		panel(rect,Color(.035,.07,.095,.97))
		canvas.draw_circle(Vector2(rect.get_center().x,207),27,Color(card.color,.15))
		centered_card(rect,216,card.mark,24,card.color)
		centered_card(rect,266,card.name,25,card.color)
		centered_card(rect,302,str(current)+" → "+str(current+1),12,game.TEAL)
		centered_card(rect,344,card.lines[0],14)
		centered_card(rect,370,card.lines[1],14)
		button(Rect2(rect.position.x+30,394,200,38),"领悟","upgrade_"+card.id,i==0)
func centered_card(rect,y,message,size,color=Color("eeeade")):
	var w=game.font.get_string_size(message,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	text(Vector2(rect.get_center().x-w*.5,y),message,size,color)
func overlay():
	buttons.clear()
	if game.state in ["stage_clear","win"]:
		result_overlay();return
	canvas.draw_rect(Rect2(0,0,960,540),Color(.015,.035,.055,.9))
	var titles={"paused":"稍作歇息","dead":"再走一程"}
	centered(148 if game.state=="dead" else 162,titles[game.state],34,game.GOLD)
	if game.state=="dead":
		var guide=game.death_guide()
		centered(187,"败因 · "+guide.title,17)
		if game.relaxed_journey():centered(270,"从容同行 · 承受伤害 70%",11,Color("8fbfb5"))
	else:
		canvas.draw_line(Vector2(440,202),Vector2(520,202),game.TEAL,1)
		if game.relaxed_journey():centered(232,"从容同行 · 承受伤害 70%",12,game.TEAL)
	var action={"paused":"resume","dead":"retry"}[game.state]
	button(Rect2(350,283,260,45),{"paused":"继续战斗" if game.boss_rush else "继续旅途","dead":("重试步战" if game.challenge_entry_phase==2 else "重试马战") if game.is_challenge() else (("从步战继续" if game.level.boss_id=="knight" and game.rush_knight_foot() else "重试当前 BOSS") if game.boss_rush else "从山灯重试")}[game.state],action,true)
	if game.is_challenge():
		button(Rect2(350,338,260,38),"重新挑战马战" if game.challenge_entry_phase==2 else "挑战步战","challenge" if game.challenge_entry_phase==2 else "challenge_foot")
		button(Rect2(282,398,125,36),"设置","settings")
		button(Rect2(417,398,125,36),"自由跳关","stage_select")
		button(Rect2(552,398,125,36),"回到标题","title")
		if game.state=="paused":button(Rect2(35,472,260,34),"切换旧版 2D" if game.use_skeletal else "切换新版骨骼","hero_animation")
		return
	# Secondary actions stack evenly below the primary button; optional rows leave no gap.
	var rows=[["设置","settings"]]
	if game.state=="dead" and game.boss_rush and game.level.boss_id=="knight" and game.rush_knight_foot():rows.push_front(["重新挑战马战","rush_mounted"])
	if game.state=="paused" and game.relic_count()>0:rows.append(["月痕札记 · "+str(game.relic_count())+" / 6","relic_journal"])
	rows.append(["自由跳关","stage_select"]);rows.append(["回到标题","title"])
	var step=46.0 if rows.size()>3 else 52.0
	for i in rows.size():button(Rect2(350,343+i*step,260,38),rows[i][0],rows[i][1])
	if game.state=="paused":button(Rect2(35,472,260,34),"切换旧版 2D" if game.use_skeletal else "切换新版骨骼","hero_animation")
func result_overlay():
	canvas.draw_rect(Rect2(0,0,960,540),Color(.012,.028,.045,.94))
	var won=game.state=="win";var result=game.stage_result
	if game.boss_rush:rush_result();return
	if game.is_challenge():challenge_result(result);return
	centered(75,"此行，有你同行" if won else "山门已开",34,game.GOLD)
	centered(107,"三关旅途已经完成。" if won else "第 "+str(result.get("level",game.level.number))+" 关已经走完。",14,game.TEAL)
	panel(Rect2(105,132,750,190),Color(.025,.055,.075,.97))
	var labels=["旅途用时","总击败","区域肃清","武学层数"] if won else ["本次用时","本次击败","区域肃清","武学精进"]
	var values=[format_time(game.elapsed),str(game.kills),str(game.journey_clears.size())+" / 12",str(game.progress.get("upgrades",[]).size())] if won else [format_time(result.get("seconds",0)),str(result.get("kills",0)),str(result.get("clears",0))+" / 4","+"+str(result.get("upgrades",0))]
	for i in 4:
		var x=135+i*185
		text(Vector2(x,174),labels[i],12,Color("aebdc0"))
		text(Vector2(x,219),values[i],26,game.GOLD if i in [0,2] else game.WHITE)
		if i<3:canvas.draw_line(Vector2(x+145,158),Vector2(x+145,246),Color(.35,.5,.52,.25),1)
	var martial="破锋 "+str(game.upgrade_level("blade"))+" 层   ·   灵火 "+str(game.upgrade_level("spirit"))+" 层   ·   同心 "+str(game.upgrade_level("brother"))+" 层   ·   月痕 "+str(game.relic_count())+" / 6"
	centered(287,martial,14,game.TEAL)
	button(Rect2(350,350,260,45),"重新启程" if won else "前往下一关", "new" if won else "next",true)
	button(Rect2(282,409,125,36),"设置","settings")
	button(Rect2(417,409,125,36),"旅途簿","journey_records")
	button(Rect2(552,409,125,36),"回到标题","title")
	button(Rect2(350,459,260,34),"自由跳关","stage_select")
func rush_result():
	if game.state=="stage_clear":
		# Between bosses: show the automatic reward and the restored tonic, then continue.
		var next=load("res://data/arenas/boss_"+str(game.level.number+1)+".tres")
		centered(118,game.level.title+" · 已破",34,game.GOLD)
		centered(160,"第 "+str(game.level.number)+" / 4 战",14,game.TEAL)
		panel(Rect2(230,188,500,110),Color(.025,.055,.075,.97))
		if game.rush_reward!="":
			centered(230,"自动习得「"+game.UPGRADE_NAMES[game.rush_reward]+"」· 第 "+str(game.upgrade_level(game.rush_reward))+" 层",18,game.WHITE)
		centered(268,"月露已补满 ×"+str(game.TONIC_MAX)+"   ·   生命恢复",15,game.TEAL)
		next_boss_silhouette(next.boss_id,Vector2(812,452),178)
		button(Rect2(350,330,260,45),"下一战 · "+next.title,"next",true)
		button(Rect2(350,395,260,38),"回到标题","title")
		return
	centered(138,"四境皆破",38,game.GOLD)
	centered(186,"守灯 · 渡影 · 噬月 · 断誓",17,game.TEAL)
	centered(244,format_time(game.elapsed)+"   ·   四战告捷",22)
	button(Rect2(350,320,260,45),"再战四境","new",true)
	button(Rect2(350,385,260,38),"回到标题","title")
# A dark silhouette of the coming boss teases the next fight without spelling it out.
func next_boss_silhouette(id,feet,height):
	var texture;var source
	if id=="knight":
		texture=load("res://assets/art/knight_frames/mounted/00.png");source=Rect2(Vector2.ZERO,texture.get_size())
	else:
		# Per-frame boss art has a transparent background (frames 0/6/12 are each idle pose).
		texture=load("res://assets/art/boss_frames/%02d.png"%(["lantern","duelist","priest"].find(id)*6))
		source=Rect2(Vector2.ZERO,texture.get_size())
	var size=Vector2(source.size.x/source.size.y*height,height)
	var rect=Rect2(feet-Vector2(size.x*.5,size.y),size)
	var pulse=.5+.5*sin(game.clock*1.6)
	canvas.draw_texture_rect_region(texture,rect.grow(2),source,Color(.55,.85,.8,.10+.06*pulse))
	canvas.draw_texture_rect_region(texture,rect,source,Color(.02,.035,.05,.96))
	var boss=load("res://data/bosses/"+id+".tres")
	var w=game.font.get_string_size(boss.title,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
	text(Vector2(feet.x-w*.5,feet.y+22),boss.title,13,Color(game.TEAL,.8))
func challenge_result(result):
	centered(75,"步战已破" if result.get("practice",false) else "断誓已了",34,game.GOLD)
	centered(107,game.boss.spec.title+(" · 步战演武完成" if result.get("practice",false) else " · 马战与步战均已击破"),14,game.TEAL)
	panel(Rect2(185,132,590,170),Color(.025,.055,.075,.97))
	var record=game.stage_record(game.CHALLENGE_LEVEL,game.progress.get("journey_mode","standard"))
	var labels=["本次用时","最快用时","挑战完成"]
	var values=[format_time(result.get("seconds",0)),format_time(record.get("best_seconds",0)),str(record.get("completions",0))+" 次"]
	for i in 3:
		var x=215+i*190
		text(Vector2(x,174),labels[i],12,Color("aebdc0"))
		text(Vector2(x,219),values[i],26,game.GOLD if i==0 else game.WHITE)
		if i<2:canvas.draw_line(Vector2(x+160,158),Vector2(x+160,246),Color(.35,.5,.52,.25),1)
	centered(277,"步战演武 · 不计完整双阶段纪录" if result.get("practice",false) else "独立挑战 · 不影响旅途进度",12,Color("aebdc0"))
	button(Rect2(350,330,260,45),"再战一次","next",true)
	button(Rect2(282,389,125,36),"设置","settings")
	button(Rect2(417,389,125,36),"旅途簿","journey_records")
	button(Rect2(552,389,125,36),"回到标题","title")
	button(Rect2(350,439,260,34),"自由跳关","stage_select")
func format_time(seconds):
	var whole=maxi(0,int(seconds))
	return "%02d:%02d" % [whole/60,whole%60]
func relic_journal_rows():
	var rows=[];var collected=game.progress.get("relics",[])
	for i in game.RELIC_IDS.size():
		var id=game.RELIC_IDS[i];var parts=game.RELIC_TEXT[id].split(" · ")
		rows.append({"id":id,"number":i+1,"stage":int(id.get_slice("_",1)),"collected":id in collected,"name":parts[0],"body":parts[1]})
	return rows
func relic_journal_screen():
	canvas.draw_rect(Rect2(0,0,960,540),Color(.018,.038,.058,.99))
	centered(58,"月 痕 札 记",30,game.GOLD)
	centered(88,"已寻得 "+str(game.relic_count())+" / 6 · 月色会记住走过的路",13,game.TEAL)
	var rows=relic_journal_rows()
	for i in rows.size():
		var row=rows[i];var rect=Rect2(55+(i%2)*430,112+(i/2)*112,410,92)
		panel(rect,Color(.035,.072,.092,.98) if row.collected else Color(.025,.045,.06,.92))
		var icon=rect.position+Vector2(31,45);var color=game.GOLD if row.collected else Color("52636a")
		canvas.draw_arc(icon,14,-PI*.72,PI*.72,18,color,3)
		text(rect.position+Vector2(58,29),row.name if row.collected else "月痕之"+str(row.number),17,color)
		text(rect.position+Vector2(314,28),"第 "+str(row.stage)+" 关",11,game.TEAL if row.collected else Color("68777b"))
		text(rect.position+Vector2(58,61),row.body if row.collected else "尚未寻得",12,game.WHITE if row.collected else Color("77868a"))
	button(Rect2(380,468,200,38),"返回","relic_journal_back",true)
func journey_record_rows():
	var rows=[]
	# The book follows the four-boss journey; records share the stage numbers 1–4.
	for number in [1,2,3,4]:
		var stage=load("res://data/arenas/boss_"+str(number)+".tres")
		var boss=load("res://data/bosses/"+stage.boss_id+".tres")
		rows.append({"number":number,"title":stage.title,"boss":boss.title,"record":game.stage_record(number,journey_records_mode)})
	return rows
func journey_records_screen():
	canvas.draw_rect(Rect2(0,0,960,540),Color(.018,.038,.058,.99))
	centered(55,"旅 途 簿",30,game.GOLD)
	button(Rect2(340,97,135,34),"标准记录","records_standard",journey_records_mode=="standard")
	button(Rect2(485,97,135,34),"从容记录","records_relaxed",journey_records_mode=="relaxed")
	var rows=journey_record_rows()
	for i in rows.size():
		var row=rows[i];var rect=Rect2(40+i*222,151,214,273);var record=row.record
		var done=not record.is_empty()
		panel(rect,Color(.035,.072,.092,.98) if done else Color(.025,.045,.06,.92))
		centered_card(rect,185,"第 "+str(row.number)+" 战",12,game.TEAL)
		centered_card(rect,220,row.title,21,game.GOLD if done else Color("8a8f86"))
		canvas.draw_line(rect.position+Vector2(20,88),rect.position+Vector2(rect.size.x-20,88),Color(.35,.55,.55,.3),1)
		centered_card(rect,262,row.boss,14,game.WHITE if done else Color("6f7d80"))
		if done:
			centered_card(rect,306,"最快  "+format_time(record.best_seconds),20,game.GOLD)
			centered_card(rect,340,"击破 "+str(record.completions)+" 次",13)
			# A simple seal marks a defeated boss.
			var seal=rect.position+Vector2(rect.size.x*.5,392)
			canvas.draw_arc(seal,14,0,TAU,28,Color(game.GOLD,.7),2,true)
			canvas.draw_line(seal+Vector2(-6,0),seal+Vector2(-1,5),game.GOLD,2);canvas.draw_line(seal+Vector2(-1,5),seal+Vector2(7,-5),game.GOLD,2)
		else:
			centered_card(rect,320,"尚未击破",17,Color("7f9295"))
	button(Rect2(380,466,200,38),"返回","journey_records_back",true)
func stage_select_screen():
	canvas.draw_rect(Rect2(0,0,960,540),Color(.025,.045,.07,.98))
	centered(76,"自由跳关",30,game.GOLD)
	for i in 4:
		var stage=load("res://data/arenas/boss_"+str(i+1)+".tres")
		var boss=load("res://data/bosses/"+stage.boss_id+".tres")
		var y=118+i*82
		# A cropped band of the arena's own vista identifies each fight at a glance.
		var index=[0,1,2,3][i]
		var source=Rect2((index%2)*768,(index/2)*512+150,768,240)
		var thumb=Rect2(150,y,150,62)
		canvas.draw_texture_rect_region(vistas,thumb,source,Color(.8,.86,.92))
		canvas.draw_rect(thumb,Color(.45,.62,.61,.5),false,1)
		var cleared=i+1 in game.progress.get("rush_clears",[])
		text(Vector2(322,y+28),str(i+1)+" · "+stage.title,20,game.GOLD)
		text(Vector2(322,y+52),boss.title+("   · 已击破" if cleared else ""),13,game.TEAL if cleared else Color("9aa8aa"))
		button(Rect2(600,y+11,200,40),"进入战场","jump_"+str(i+1)+"_0")
	button(Rect2(380,473,200,38),"返回","stage_select_back")
func settings_screen():
	canvas.draw_rect(Rect2(0,0,960,540),Color(.025,.045,.07,.98))
	centered(65,"设置",30,game.GOLD)
	panel(Rect2(70,100,390,325));panel(Rect2(490,100,400,325))
	text(Vector2(100,137),"声音",18,game.GOLD)
	var labels={"music":"音乐","sfx":"音效","ambience":"环境"}
	var index=0
	for key in labels:
		var y=160+index*57;text(Vector2(100,y+24),labels[key],16)
		button(Rect2(235,y,36,34),"−","volume_"+key+"_-1")
		text(Vector2(292,y+24),str(int(game.progress[key]*100))+"%",16)
		button(Rect2(390,y,36,34),"＋","volume_"+key+"_1");index+=1
	button(Rect2(100,347,145,34),"声音：关" if game.progress.muted else "声音：开","mute")
	button(Rect2(265,347,160,34),"试听","melee_audition")
	button(Rect2(100,393,145,25),"AI 配音","voice_ai",game.progress.get("boss_voice","ai")=="ai")
	button(Rect2(265,393,160,25),"经典配音","voice_classic",game.progress.get("boss_voice","ai")=="classic")
	text(Vector2(520,137),"旅途",18,game.GOLD)
	button(Rect2(520,161,340,38),"难度 · "+("从容" if game.relaxed_journey() else "标准"),"journey_mode")
	button(Rect2(520,214,340,34),"震动 · "+("开" if game.progress.screen_shake else "关"),"screen_shake")
	text(Vector2(520,286),"角色外观",14,game.TEAL)
	button(Rect2(520,303,160,34),"骨骼动画","hero_modern",game.use_skeletal)
	button(Rect2(700,303,160,34),"经典 2D","hero_legacy",not game.use_skeletal)
	button(Rect2(520,360,340,34),"操作与按键","controls")
	button(Rect2(380,465,200,40),"返回","back",true)

func story_screen():
	canvas.draw_rect(Rect2(0,0,960,540),Color(.025,.045,.075,.9))
	portrait(niu,niu_region,Vector2(630,315),130)
	portrait(hero,Rect2(0,0,181,208),Vector2(350,315),120)
	var lines=["牛大侠：前面的路更险了。把这个葫芦带上。","牛大侠：需要帮忙就唤我一声，我的牛角会替你开路。","羊小侠：那就一起走。哥，下一关见！"]
	panel(Rect2(155,340,650,95));text(Vector2(180,377),lines[game.story_page],16)
	button(Rect2(590,459,215,38),"继续  →","story_next",true);button(Rect2(155,459,145,38),"跳过剧情","story_skip")
func touch_layout():
	return [{"rect":Rect2(18,440,48,48),"label":"←","action":"left"},{"rect":Rect2(74,440,48,48),"label":"→","action":"right"},{"rect":Rect2(130,440,48,48),"label":"↓","action":"down"},{"rect":Rect2(876,441,60,60),"label":"剑","action":"attack"},{"rect":Rect2(817,445,48,48),"label":"跳","action":"jump"},{"rect":Rect2(758,445,48,48),"label":"闪","action":"dash"},{"rect":Rect2(878,382,48,48),"label":"弓","action":"bow"},{"rect":Rect2(819,382,48,48),"label":"蓄","action":"charge"},{"rect":Rect2(760,382,48,48),"label":"羊","action":"transform"},{"rect":Rect2(701,445,48,48),"label":"兄","action":"summon"},{"rect":Rect2(701,382,48,48),"label":"露","action":"item"}]
func handle_click(at):
	for b in buttons:
		if b.rect.has_point(at):action(b.action);return true
	return false
func action(id):
	game.audio.play("ui_back" if id in ["back","title","resume","new_confirm_back"] or id.ends_with("_back") else "ui_confirm",-5)
	if id.begins_with("bind_"):game.gamepad.rebinding=id.substr(5);return
	if id.begins_with("upgrade_"):game.choose_upgrade(id.substr(8));return
	if id.begins_with("jump_"):
		var parts=id.split("_");game.call_deferred("jump_to_stage",int(parts[1]),int(parts[2]));return
	if id.begins_with("volume_"):
		var parts=id.split("_");var key=parts[1];game.progress[key]=clampf(game.progress[key]+float(parts[2])*.1,0,1);game.audio.apply_volumes();game.save_progress();return
	match id:
		"relic_journal":relic_journal_return=game.state;game.state="relic_journal";game.release_inputs()
		"relic_journal_back":game.state=relic_journal_return
		"journey_records":journey_records_return=game.state;journey_records_mode=game.progress.get("journey_mode","standard");game.state="journey_records";game.release_inputs()
		"journey_records_back":game.state=journey_records_return
		"records_standard":journey_records_mode="standard"
		"records_relaxed":journey_records_mode="relaxed"
		"stage_select":stage_select_return=game.state;game.state="stage_select";game.release_inputs()
		"challenge":game.call_deferred("start_challenge")
		"challenge_foot":game.call_deferred("start_challenge",game.CHALLENGE_LEVEL,2)
		"stage_select_back":game.state=stage_select_return
		"debug":game.debug_panel.toggle()
		"animation_lab":game.open_animation_lab()
		"lab_back":game.state=game.animation_lab.previous
		"lab_pause":game.animation_lab.playing=not game.animation_lab.playing
		"lab_speed":game.animation_lab.speed=.5 if game.animation_lab.speed==1.0 else 1.0
		"lab_restart":game.animation_lab.restart()
		"lab_switch","hero_animation":
			game.set_hero_animation(not game.use_skeletal)
		"hero_modern":game.set_hero_animation(true)
		"hero_legacy":game.set_hero_animation(false)
		"new":
			if game.state=="title" and game.has_journey_progress():new_confirm_return="title";game.state="new_confirm";game.release_inputs()
			else:game.start_new()
		"new_confirm_start":game.start_new()
		"new_confirm_back":game.state=new_confirm_return;game.release_inputs()
		"continue":game.continue_game()
		"resume":game.state="playing"
		"pause":game.state="paused";game.release_inputs()
		"retry":game.retry()
		"rush_mounted":game.retry_mounted()
		"next":game.next_level()
		"title":game.return_title()
		"settings":settings_return=game.state;game.state="settings";game.release_inputs()
		"controls":controls_return=game.state;game.state="controls";game.release_inputs()
		"controls_back":game.gamepad.rebinding="";game.state=controls_return
		"pad_reset":game.gamepad.reset_bindings()
		"pad_glyphs":
			var types=["auto","xbox","ps","switch"];game.gamepad.glyphs=types[(types.find(game.gamepad.glyphs)+1)%4];game.gamepad.save_bindings()
		"back":game.state=settings_return
		"mute":game.audio.toggle_mute()
		"voice_ai","voice_classic":
			game.progress.boss_voice="ai" if id=="voice_ai" else "classic";game.save_progress()
			game.audio.voice("knight_intro",true)
		"screen_shake":game.progress.screen_shake=not game.progress.screen_shake;game.save_progress()
		"journey_mode":game.progress.journey_mode="standard" if game.relaxed_journey() else "relaxed";game.save_progress()
		"melee_audition":game.audio.start_audition()
		"tonic":game.use_tonic()
		"story_next":game.advance_story()
		"story_skip":game.complete_story()

func pad_move(direction):
	if buttons.is_empty():return
	pad_focus=clampi(pad_focus,0,buttons.size()-1)
	var origin=buttons[pad_focus].rect.get_center()
	var best=-1;var score=INF
	for i in buttons.size():
		if i==pad_focus:continue
		var delta=buttons[i].rect.get_center()-origin
		var forward=delta.dot(direction)
		if forward<=1:continue
		var sideways=absf(delta.cross(direction))
		var value=forward+sideways*3
		if value<score:score=value;best=i
	if best<0:best=posmod(pad_focus+(1 if direction.x+direction.y>0 else -1),buttons.size())
	pad_focus=best;game.audio.play("ui_focus",-12)
func pad_activate():
	if buttons.is_empty():return
	var selected=buttons[clampi(pad_focus,0,buttons.size()-1)].action
	action(selected)

func animation_screen():
	canvas.draw_rect(Rect2(0,0,960,540),Color("111f2c"))
	centered(55,"羊小侠 · 连续动作样片",27,game.GOLD)
	centered(86,"同一原画，左侧切换姿势，右侧二维网格补间",13,game.TEAL)
	panel(Rect2(35,115,430,285));panel(Rect2(495,115,430,285))
	text(Vector2(60,146),"原版 · 姿势切帧",17)
	text(Vector2(520,146),"新版 · 二维网格 / 连续补间",17,game.GOLD)
	for x in [55,515]:canvas.draw_line(Vector2(x,375),Vector2(x+385,375),Color("638680"),2)
	centered(427,game.animation_lab.title(),17,game.GOLD)
	button(Rect2(55,451,110,36),"暂停" if game.animation_lab.playing else "播放","lab_pause")
	button(Rect2(180,451,125,36),"速度 ×"+str(game.animation_lab.speed),"lab_speed")
	button(Rect2(320,451,110,36),"重播","lab_restart")
	button(Rect2(470,451,235,36),"游戏：原画优化" if game.use_skeletal else "游戏：旧版图集","lab_switch")
	button(Rect2(765,451,130,36),"返回","lab_back")
	centered(518,"头颈完整 · 身体补间 · 挥剑有效时间与伤害同步",12,game.TEAL)

func controls_screen():
	canvas.draw_rect(Rect2(0,0,960,540),Color("111f2c"));centered(54,"手柄键位",28,game.GOLD)
	centered(85,"Switch：A跳跃 · X冲刺 · B召唤 · Y变身 · ZR翻滚",14,game.TEAL)
	var labels=["跳跃","近战 / 长按蓄力","远程攻击","翻滚","冲刺","羊灵觉醒","召唤牛大侠"]
	for i in game.gamepad.ACTIONS.size():
		var action_name=game.gamepad.ACTIONS[i];var x=80+(i%2)*420;var y=111+(i/2)*58
		text(Vector2(x,y+25),labels[i],16)
		button(Rect2(x+190,y,175,36),"等待按键…" if game.gamepad.rebinding==action_name else game.gamepad.binding_label(action_name),"bind_"+action_name)
	centered(380,"点选后按新键 · 长按近战蓄力",13)
	centered(410,"↓→ 斩 踏月剑气   ↓← 斩 回风斩   →↓→ 斩 升龙斩",12,game.GOLD)
	button(Rect2(75,455,260,38),"按键图标："+{"auto":"自动","xbox":"Xbox","ps":"PlayStation","switch":"Switch"}.get(game.gamepad.glyphs,"自动"),"pad_glyphs")
	button(Rect2(365,455,220,38),"恢复推荐键位","pad_reset")
	button(Rect2(650,455,235,38),"返回","controls_back",true)

extends RefCounted
# Short physical trails sit behind the painted actor, never persistent danger zones.
static func draw(knight):
	var gold=Color("e8c88d")
	if knight.action in ["lunge","spin_rush","triple_dash","spear_slam","charge","rein"]:
		var release=knight.prep_for(knight.action)
		if knight.action=="triple_dash":
			for at in knight.pursuit_times():
				if at>knight.t:release=at;break
		var before=release-knight.t
		if before>0 and before<.45:
			var weight=(1-before/.45)*.22
			var start=Vector2(knight.facing*8,-44)
			var end=Vector2(knight.facing*89,-40)
			knight.draw_line(start,end,Color(.82,.73,.53,weight),4,true)
			knight.draw_line(start,end,Color(.96,.88,.69,weight),1.2,true)
	for trail in knight.motion_trail:
		var u=1-trail.age/.20
		var art=trail.art;var index=trail.frame;var info=art.frame_info[index]
		knight.draw_set_transform(Vector2(trail.x-knight.position.x,0),0,Vector2(-trail.dir,1))
		var size=art.isolated[index].get_size()*art.frame_unit(index)
		var offset=Vector2(-float(info.anchor),-float(info.baseline))*art.frame_unit(index)
		knight.draw_texture_rect(art.isolated[index],Rect2(offset,size),false,Color(1,.84,.59,u*.20))
	knight.draw_set_transform(Vector2.ZERO)
	if knight.action=="spin_rush":
		var at=knight.t-knight.prep_for("spin_rush")
		if at>=0 and at<.66:
			var center=Vector2(knight.facing*18,-51)
			for j in 5:
				var points=PackedVector2Array()
				for i in 19:
					var angle=at*25-j*.23+i*.105
					points.append(center+Vector2(cos(angle)*82,sin(angle)*49))
				knight.draw_polyline(points,Color(gold,.60-j*.09),3.5-j*.45,true)
			knight.draw_line(Vector2(-knight.facing*70,-9),Vector2(-knight.facing*8,-9),Color(gold,.3),3,true)
	for fx in knight.strike_fx:
		var u=clampf(fx.age/fx.life,0,1);var c=Color(Color("b2deed") if knight.action=="lunge" else gold,(1-u)*.8)
		var origin=Vector2(fx.x-knight.position.x,0);var dir=fx.dir
		match fx.kind:
			"rush":
				for i in 3:
					var y=-25-i*12
					knight.draw_line(origin+Vector2(-dir*(25+i*12),y),Vector2(dir*(65+i*16),y),Color(c,c.a*(.5-i*.1)),3-i*.7,true)
			"sweep":
				var points=PackedVector2Array()
				for i in 24:
					var a=-1.4+float(i)/23*2.6
					points.append(origin+Vector2(dir*(25+cos(a)*124),-62+sin(a)*62))
				knight.draw_polyline(points,c,5*(1-u)+1,true)
				knight.draw_polyline(points,Color(1,.98,.87,c.a),1.5,true)
			"throw","catch":
				var center=origin+Vector2(dir*42,-36)
				knight.draw_arc(center,14+u*24,-1.8+u*4,1.8+u*4,22,c,2.5*(1-u),true)
			"bow":
				for i in 3:knight.draw_line(origin+Vector2(dir*22,-77),origin+Vector2(dir*(90+u*28),-77+(i-1)*16),c,1.8,true)

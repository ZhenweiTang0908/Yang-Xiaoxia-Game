extends SceneTree
# Deterministic sheet extraction only. Anatomy/support acceptance remains manual.
const STUDY=preload("res://tools/prepare_lion_frames.gd")
const ROOT="res://assets/art/lion_elder_frames/"
const SHEETS={"M01":[5,2],"M02":[5,2],"M03":[4,4],"M04":[7,2],"M05":[5,2],"M06":[5,2],"M07":[4,3],"M08":[4,4],"M09":[5,2],"M10":[7,2],"M11":[4,3],"M12":[4,4],"M13":[7,2],"M14":[4,3],"M15":[4,3],"M16":[5,2],"M17":[4,3],"M18":[7,2],"M19":[4,4],"M20":[6,3],"common_elder":[4,3],"common_lion":[4,3],"reactions":[7,2],"transition":[3,3]}
const SOURCE_ORDERS={"M07":[0,1,2,3,4,8,5,6,7,9,10,11],"M13":[0,1,2,3,4,5,6,8,7,9,10,11,12,13],"M14":[0,1,2,3,4,5,7,8,6,9,10,11]}
# Floor-contact frames whose lowest pixels are a palm or the set-down lion head.
# Support goes back to the shoes so the body does not slide when he plants a
# hand. Values come from tools/lion_foot_anchor.gd and were checked on the
# anchor-aligned contact sheets. M13 is a handstand: hands are its real support.
const SUPPORT_OVERRIDES={
	"M03":{10:Vector2(288.6,144),11:Vector2(248.4,156),13:Vector2(116.1,228)},
	"M12":{1:Vector2(277.9,198),2:Vector2(243.2,181),3:Vector2(245.9,175),12:Vector2(174.7,156)},
	"M16":{7:Vector2(193.4,296),8:Vector2(165.8,355)},
	"M18":{7:Vector2(289.6,181),8:Vector2(221.8,158)},
	"M20":{6:Vector2(222,202),7:Vector2(200,209),8:Vector2(161.7,181),9:Vector2(83.6,186),10:Vector2(155.0,185)},
	"transition":{2:Vector2(224.4,215),3:Vector2(290,244),4:Vector2(231.4,251),5:Vector2(228.5,287),6:Vector2(158.4,263),7:Vector2(151.8,252),8:Vector2(175.3,170)}}
const ONE_PROP_BANKS=["M15"]
const REFERENCES={"M05":9,"M12":15,"M18":13,"M19":14,"reactions":9}
const ROW_CUTS={"transition":[0,430,740,1024]}
# Reviewed gutters in this source sheet; its generated columns are unequal.
const COLUMN_CUTS={"M10":[[0,300,600,885,1145,1400,1700,2048],[0,360,640,925,1215,1500,1780,2048]]}
const POUNCE_CUTS=[[0,340,718,1060,1410,1774],[0,340,726,1114,1455,1774]]
func _initialize():call_deferred("run")
# Equal division cuts through hands and cloth whenever a generated sheet does not
# space its poses evenly. Find the emptiest gutter near each ideal line instead.
static func gutter(profile:PackedInt32Array,ideal:int,span:int) -> int:
	var lo=maxi(1,ideal-span);var hi=mini(profile.size()-2,ideal+span)
	var best=clampi(ideal,lo,hi);var best_value=profile[best]
	for x in range(lo,hi+1):
		if profile[x]<best_value or (profile[x]==best_value and absi(x-ideal)<absi(best-ideal)):
			best=x;best_value=profile[x]
	return best
static func column_profile(image:Image,from_y:int,to_y:int) -> PackedInt32Array:
	var profile=PackedInt32Array();profile.resize(image.get_width())
	for x in image.get_width():
		var count=0
		for y in range(from_y,to_y):
			if image.get_pixel(x,y).a>.35:count+=1
		profile[x]=count
	return profile
static func row_profile(image:Image,from_x:int,to_x:int) -> PackedInt32Array:
	var profile=PackedInt32Array();profile.resize(image.get_height())
	for y in image.get_height():
		var count=0
		for x in range(from_x,to_x):
			if image.get_pixel(x,y).a>.35:count+=1
		profile[y]=count
	return profile

# Each saved frame is its own PNG, so cells never have to form a strict grid.
# Label every painted component once, then give each pose only its own pixels.
# This keeps wide poses whole and stops a neighbour's cloth or gourd leaking in.
class Components:
	var labels:PackedInt32Array
	var boxes:Array
	var counts:Array
static func components(image:Image) -> Components:
	var w=image.get_width();var h=image.get_height()
	var result=Components.new()
	result.labels=PackedInt32Array();result.labels.resize(w*h);result.labels.fill(-1)
	result.boxes=[];result.counts=[]
	for y in h:
		for x in w:
			var index=y*w+x
			if result.labels[index]!=-1 or image.get_pixel(x,y).a<=.30:continue
			var label=result.boxes.size()
			var stack=PackedInt32Array([index]);var at=0
			var lo=Vector2i(x,y);var hi=lo
			result.labels[index]=label
			while at<stack.size():
				var cell=stack[at];at+=1
				var px=cell%w;var py=int(cell/w)
				lo=lo.min(Vector2i(px,py));hi=hi.max(Vector2i(px,py))
				for delta in [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1)]:
					var q=Vector2i(px,py)+delta
					if q.x<0 or q.y<0 or q.x>=w or q.y>=h:continue
					var next=q.y*w+q.x
					if result.labels[next]!=-1 or image.get_pixel(q.x,q.y).a<=.30:continue
					result.labels[next]=label;stack.append(next)
			result.boxes.append(Rect2i(lo,hi-lo+Vector2i.ONE));result.counts.append(stack.size())
	return result
func run():
	var total=0
	for id in SHEETS:
		var source_path="res://art_source/lion_elder/production/"+id+"-v1.png"
		var revised="res://art_source/lion_elder/production/"+id+"-v2.png"
		if FileAccess.file_exists(revised):source_path=revised
		if id=="M01":source_path="res://art_source/lion_elder/production/M01-v3.png"
		var image=Image.load_from_file(source_path)
		if image==null:push_error("Missing authored source "+source_path);quit(1);return
		if id=="M01" and image.get_size()!=Vector2i(1774,887):push_error("Pounce source size changed: review authored crop/support coordinates");quit(1);return
		var cols=SHEETS[id][0];var rows=SHEETS[id][1];var folder=ROOT+id
		if DirAccess.make_dir_recursive_absolute(folder)!=OK:quit(1);return
		var xs=[]
		for c in cols+1:xs.append(int(c*image.get_width()/float(cols)))
		var ys=[]
		for r in rows+1:ys.append(int(r*image.get_height()/float(rows)))
		var cuts_moved=0
		if not ROW_CUTS.has(id) and not COLUMN_CUTS.has(id) and id!="M01":
			for r in rows:
				var profile=column_profile(image,ys[r]+2,ys[r+1]-2)
				for c in range(1,cols):
					var at=gutter(profile,xs[c],int(image.get_width()/float(cols)*.45))
					if at!=xs[c]:cuts_moved+=1
					xs[c]=at
			var horizontal=row_profile(image,0,image.get_width())
			for r in range(1,rows):ys[r]=gutter(horizontal,ys[r],int(image.get_height()/float(rows)*.42))
		if ROW_CUTS.has(id):
			for r in rows+1:ys[r]=ROW_CUTS[id][r]
		var row_xs=[]
		for r in rows:row_xs.append(xs.duplicate())
		if COLUMN_CUTS.has(id):
			for r in rows:
				for c in cols+1:row_xs[r][c]=int(COLUMN_CUTS[id][r][c]*image.get_width()/2048.0)
		if id=="M01":
			for r in rows:
				for c in cols+1:row_xs[r][c]=POUNCE_CUTS[r][c]
		if cuts_moved>0:print("REVIEWED_CUTS ",id," gutters_moved=",cuts_moved," xs=",xs," ys=",ys)
		var parsed=components(image)
		var labels=parsed.labels;var boxes=parsed.boxes;var counts=parsed.counts
		var width=image.get_width()
		var band_of=[];var col_of=[]
		var peak=1
		for count in counts:peak=maxi(peak,count)
		var is_body=[]
		for i in counts.size():is_body.append(counts[i]>=maxi(60,int(peak*.35)))
		for i in boxes.size():
			band_of.append(-1);col_of.append(-1)
			if not is_body[i]:continue
			var centre=boxes[i].get_center()
			var band=rows-1
			for r in rows:
				if centre.y<ys[r+1]:band=r;break
			band_of[i]=band
			col_of[i]=clampi(int(floor(centre.x/float(width)*cols)),0,cols-1)
		# Loose props such as the tossed gourd sit far from their owner's support.
		# Give them to the nearest body so a throw stays with the throwing pose.
		for i in boxes.size():
			if is_body[i]:continue
			var best=-1;var best_cost=INF
			for j in boxes.size():
				if not is_body[j]:continue
				var a=boxes[i];var b=boxes[j]
				var gap_x=maxf(0,maxf(a.position.x-b.end.x,b.position.x-a.end.x))
				var gap_y=maxf(0,maxf(a.position.y-b.end.y,b.position.y-a.end.y))
				var cost=Vector2(gap_x,gap_y).length()
				# Everyone stands on the ground, so nothing he holds or tosses hangs
				# below his feet. A gourd floating in the gutter between two rows is
				# over the head of the pose beneath it, not under the pose above.
				if a.position.y>=b.end.y-4:cost+=10000.0
				if cost<best_cost:best_cost=cost;best=j
			if best>=0:band_of[i]=band_of[best];col_of[i]=col_of[best]
		for r in rows:
			for c in cols:
				var found=0
				for i in boxes.size():
					if is_body[i] and band_of[i]==r and col_of[i]==c:found+=1
				if found==0:push_error("No pose detected "+id+" row="+str(r)+" col="+str(c)+" (uneven sheet?)");quit(1);return
				if found>1:print("MULTI_BODY ",id," row=",r," col=",c," bodies=",found)
		var frames=[]
		for index in cols*rows:
			var source_index=SOURCE_ORDERS[id][index] if SOURCE_ORDERS.has(id) else index
			var col=source_index%cols;var row=int(source_index/cols)
			var members=[]
			var body=-1
			for i in boxes.size():
				if band_of[i]!=row or col_of[i]!=col:continue
				members.append(i)
				if body<0 or counts[i]>counts[body]:body=i
			# He owns exactly one gourd. When two loose props land in the same
			# crop, keep the one nearest his hand so no frame shows a spare.
			if ONE_PROP_BANKS.has(id):
				var props=members.filter(func(i):return i!=body)
				if props.size()>1:
					var best=props[0]
					for i in props:
						var da=boxes[i].get_center().distance_to(boxes[body].get_center())
						var db=boxes[best].get_center().distance_to(boxes[body].get_center())
						if da<db or (is_equal_approx(da,db) and counts[i]>counts[best]):best=i
					members=members.filter(func(i):return i==body or i==best)
			var keep={};var lo=Vector2i(width,image.get_height());var hi=Vector2i(-1,-1)
			for i in members:
				keep[i]=true;lo=lo.min(boxes[i].position);hi=hi.max(boxes[i].end)
			lo=Vector2i(maxi(0,lo.x-2),maxi(0,lo.y-2));hi=Vector2i(mini(width,hi.x+2),mini(image.get_height(),hi.y+2))
			var rect=Rect2i(lo,hi-lo)
			var cell=Image.create(rect.size.x,rect.size.y,false,Image.FORMAT_RGBA8)
			cell.fill(Color(0,0,0,0))
			for y in rect.size.y:
				for x in rect.size.x:
					var sx=lo.x+x;var sy=lo.y+y
					var label=labels[sy*width+sx]
					if label!=-1 and keep.has(label):cell.set_pixel(x,y,image.get_pixel(sx,sy))
			# Keep the soft outline of the same pose without importing a neighbour.
			for y in rect.size.y:
				for x in rect.size.x:
					if cell.get_pixel(x,y).a>0:continue
					var sx=lo.x+x;var sy=lo.y+y
					if image.get_pixel(sx,sy).a<=0:continue
					var touches=false
					for delta in [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1)]:
						var q=Vector2i(sx,sy)+delta
						if q.x<0 or q.y<0 or q.x>=width or q.y>=image.get_height():continue
						var near_label=labels[q.y*width+q.x]
						if near_label!=-1 and keep.has(near_label):touches=true;break
					if touches:cell.set_pixel(x,y,image.get_pixel(sx,sy))
			var used=cell.get_used_rect()
			if not used.has_area():push_error("Empty production cell "+id+str(index));quit(1);return
			var ground=maxi(used.position.y,int(boxes[body].end.y)-lo.y-1)
			# Support stays under the standing foot, matching how the tuned hit caps
			# were authored: the origin is the ground contact, the body reaches out.
			var sum=0.0;var weight=0.0
			for y in range(maxi(used.position.y,ground-3),mini(used.end.y,ground+2)):
				for x in range(used.position.x,used.end.x):
					var a=cell.get_pixel(x,y).a
					if a>.4:sum+=x*a;weight+=a
			var support=Vector2(sum/weight if weight>0 else used.get_center().x,ground+1)
			if SUPPORT_OVERRIDES.get(id,{}).has(index):support=SUPPORT_OVERRIDES[id][index]
			var clipped=boxes[body].position.y<=ys[row]+1 or boxes[body].end.y>=ys[row+1]-1 or boxes[body].position.x<=1 or boxes[body].end.x>=width-1
			var filename="%02d.png"%index
			if cell.save_png(folder+"/"+filename)!=OK:quit(1);return
			frames.append({"frame":index,"source_frame":source_index,"file":filename,"anchor":support.x,"baseline":support.y,"source_rect":[lo.x,lo.y,rect.size.x,rect.size.y],"approved":false,"anchor_status":"AUTHORED_SUPPORT_PENDING_RENDER_REVIEW" if SUPPORT_OVERRIDES.get(id,{}).has(index) else "PROVISIONAL_NEEDS_ANATOMICAL_REVIEW","edge_contact":clipped})
		var info={"schema":1,"bank":id,"status":"DRAFT_REQUIRES_REVIEW","source":source_path,"source_facing":-1,"study_frame_count":0,"draft_frame_count":frames.size(),"approved_production_count":0,"production_target_total":272,"reference_frame":REFERENCES.get(id,0),"reference_height":86 if id in ["common_elder","reactions"] or (id.begins_with("M") and int(id.substr(1))>=9) else 120,"warnings":["Generated frames require per-frame support, crop, identity and action-contact review. No fluency acceptance."],"frames":frames}
		var file=FileAccess.open(folder+"/frames.json",FileAccess.WRITE)
		if file==null:quit(1);return
		file.store_string(JSON.stringify(info,"\t")+"\n");total+=frames.size()
	print("LION_PRODUCTION_IMPORT_RESULT draft=",total," approved=0")
	quit(0)

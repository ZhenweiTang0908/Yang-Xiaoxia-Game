extends SceneTree
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(1200,720)
 root.content_scale_size=Vector2i(1200,720)
 var canvas=Node2D.new();root.add_child(canvas)
 var bg=ColorRect.new();bg.color=Color("1b2933");bg.size=Vector2(1440,720);canvas.add_child(bg)
 var species=["niu","sheep","bull"]
 var rigs=[]
 for i in species.size():
  var kind=species[i];var ref=load("res://scripts/actors/atlas_actor.gd").new();canvas.add_child(ref);ref.hide()
  var path="res://assets/art/v2/mobs.png";var cols=6;var rows=8
  if kind=="niu":path="res://assets/art/v3/niu_human.png";rows=4
  elif kind=="sheep":path="res://assets/art/v2/sheep.png";rows=4
  elif kind=="bull":path="res://assets/art/v3/bull.png";cols=4;rows=2
  elif i>=11:path="res://assets/art/v2/bosses.png";rows=3
  ref.configure(path,cols,rows,66)
  var rig=load("res://scripts/animation/brother_visual.gd" if kind=="niu" else "res://scripts/animation/cast_visual.gd").new();rig.preview=true;rig.source_art=ref;
  if kind!="niu":rig.species=kind
  rig.height=180;rig.position=Vector2(210+i*380,450);rig.preview_state="run";canvas.add_child(rig);rigs.append(rig)
  var label=Label.new();label.text=kind;label.position=rig.position+Vector2(-40,20);canvas.add_child(label)
 for action in ["idle","run","cast","charge","dash","idle"]:
  for rig in rigs:rig.preview_state=action;rig.preview_speed=150 if action in ["run","dash"] else 0
  for i in 60:await process_frame
 quit()

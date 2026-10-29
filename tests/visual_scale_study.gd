extends SceneTree
var page=[]
var canvas
var font
const OUT="res://builds/qa/visual-stability/"
func _initialize():root.unfocusable=true;root.size=Vector2i(1280,960);root.content_scale_size=root.size;call_deferred("run")
func paint():
 canvas.draw_rect(Rect2(0,0,1280,960),Color("1a1d27"))
 for item in page:
  var cell=item.cell;var texture=item.texture;var u=minf(290.0/texture.get_width(),205.0/texture.get_height());var at=cell+Vector2((320-texture.get_width()*u)*.5,28)
  canvas.draw_texture_rect(texture,Rect2(at,texture.get_size()*u),false)
  canvas.draw_string(font,cell+Vector2(12,18),item.label,HORIZONTAL_ALIGNMENT_LEFT,-1,14)
  if item.head!=null:canvas.draw_rect(Rect2(at+Vector2(item.head[0],item.head[1])*u,Vector2(item.head[2],item.head[3])*u),Color.CYAN,false,1)
func run():
 font=load("res://assets/art/ui_font.ttf");canvas=Node2D.new();root.add_child(canvas);canvas.draw.connect(paint)
 var all=JSON.parse_string(FileAccess.get_file_as_string(OUT+"landmark-candidates.json"))
 for bank in all:
  var folder="res://assets/art/knight_frames/"+bank.substr(7) if bank.begins_with("knight/") else "res://assets/art/boss_reset/"+bank.substr(6)
  var entries=all[bank]
  for chunk in ceili(entries.size()/16.0):
   page=[]
   for k in range(chunk*16,mini((chunk+1)*16,entries.size())):
    var i=k%16;var data=entries[k]
    page.append({"cell":Vector2((i%4)*320,(i/4)*240),"texture":load(folder+"/%02d.png"%k),"head":data.head if data!=null else null,"label":bank+" %02d"%k})
   canvas.queue_redraw();await process_frame;await process_frame;RenderingServer.force_draw(false)
   root.get_texture().get_image().save_png(OUT+"study-"+bank.replace("/","-")+"-%02d.png"%chunk)
 print("VISUAL_SCALE_STUDY_RESULT done");quit()

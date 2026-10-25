extends SceneTree
func _initialize():
 var img=Image.load_from_file("res://art_source/run-studies/unarmed-candidate.png")
 var clear=0;var partial=0
 for y in img.get_height():
  for x in img.get_width():
   var a=img.get_pixel(x,y).a
   if a<.01:clear+=1
   elif a<.99:partial+=1
 print("UNARMED_ALPHA size=",img.get_size()," format=",img.get_format()," clear=",clear," partial=",partial," bounds=",img.get_used_rect())
 quit()

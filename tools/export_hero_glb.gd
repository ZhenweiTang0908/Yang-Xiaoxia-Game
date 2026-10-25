extends SceneTree
func _initialize():call_deferred("run")
func run():
 var model=load("res://scenes/animation/hero_rig.tscn").instantiate();root.add_child(model)
 var document=GLTFDocument.new();var state=GLTFState.new()
 var result=document.append_from_scene(model,state)
 if result==OK:result=document.write_to_filesystem(state,"res://art_source/hero/yang_xiaoxia.glb")
 print("GLB_EXPORT ",result);model.queue_free();await process_frame;quit(result)

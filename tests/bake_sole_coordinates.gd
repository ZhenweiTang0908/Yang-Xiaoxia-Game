extends SceneTree
func _initialize():
 var skin=load("res://tests/sole_calibration_skin.gd").new()
 var values=[]
 for frame in 40:values.append(skin.sole_positions(frame))
 var out=FileAccess.open("res://assets/animation/hero_sole_coordinates.json",FileAccess.WRITE)
 out.store_string(JSON.stringify(values));out.close();skin.free();quit()

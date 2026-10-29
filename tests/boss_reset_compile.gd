extends SceneTree
func _initialize():
 var ok=true
 for path in ["res://scripts/actors/boss_reset/base.gd","res://scripts/actors/knight.gd"]:
  var script=load(path)
  if script==null or (not Engine.is_editor_hint() and not script.can_instantiate()):ok=false
 print("BOSS_RESET_COMPILE_RESULT valid=",ok)
 quit(0 if ok else 1)

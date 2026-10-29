extends SceneTree
# An exported pack loads the lion's frames through the import cache only. A new
# or regenerated PNG that never went through an import pass would leave the boss
# invisible in a release build while still looking fine in the editor.
const ROOT="res://assets/art/lion_elder_frames/"
var checks=0
var failures=[]
func verify(ok,label):
	checks+=1
	if not ok:failures.append(label);print("FAIL ",label)
func _initialize():
	var banks=DirAccess.get_directories_at(ROOT)
	verify(banks.size()>=20,"lion banks present, got "+str(banks.size()))
	var frames=0
	for bank in banks:
		var manifest=ROOT+bank+"/frames.json"
		var folder=ROOT+bank
		var pngs=Array(DirAccess.get_files_at(folder)).filter(func(f):return f.ends_with(".png"))
		if pngs.is_empty():continue
		verify(FileAccess.file_exists(manifest),bank+" manifest exists")
		for file in pngs:
			frames+=1
			var source=folder+"/"+file
			var meta=FileAccess.get_file_as_string(source+".import")
			verify(not meta.is_empty(),bank+"/"+file+" has an .import file")
			if meta.is_empty():continue
			var dest=""
			for line in meta.split("\n"):
				if line.begins_with("path=\"res://"):dest=line.split("\"")[1];break
			verify(not dest.is_empty() and FileAccess.file_exists(dest.replace("res://","")),bank+"/"+file+" imported texture exists")
			verify(ResourceLoader.exists(source),bank+"/"+file+" loads as a resource")
	print("LION_IMPORT_READY_RESULT frames=",frames," checks=",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)

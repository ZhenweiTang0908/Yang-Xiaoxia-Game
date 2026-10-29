extends SceneTree
var checks=0
var failures=[]
func verify(ok,label):
 checks+=1
 if not ok:failures.append(label);print("FAIL ",label)
func _initialize():
 var counts={"lantern":98,"duelist":108,"priest":156,"knight":28}
 for id in counts:
  var root_path="res://assets/art/boss_reset/"+id+"/"
  var meta=JSON.parse_string(FileAccess.get_file_as_string(root_path+"frames.json"))
  if not meta is Dictionary:verify(false,id+" metadata");continue
  var active={}
  for clip in meta.clips:
   for frame in meta.clips[clip]:active[frame]=true
  verify(active.size()>=counts[id],id+" actual authored frames in clips")
  if id=="priest" and not meta.clips.death.is_empty() and not meta.clips.recall.is_empty():
   verify(meta.clips.death.back()==meta.clips.recall.front(),"lying defeat pose joins recall without standing up")
  var hashes={}
  for i in meta.count:
   var file=root_path+"%02d.png"%i
   verify(ResourceLoader.exists(file),id+" import "+str(i))
   var hash=FileAccess.get_sha256(file);verify(not hashes.has(hash),id+" distinct image "+str(i));hashes[hash]=true
  for clip in meta.clips:
   verify(not meta.clips[clip].is_empty(),id+" "+clip)
 var catalog=preload("res://scripts/core/reset_audio_catalog.gd").PROFILES
 for id in catalog:
  for stage in ["warning","charge","release","impact","landing","recover"]:verify(ResourceLoader.exists("res://assets/audio/"+catalog[id][stage]+".wav"),id+" "+stage+" audio")
 var dialogue=preload("res://scripts/core/boss_dialogue.gd").BOSSES
 for boss in ["lantern","duelist","priest"]:
  for event in dialogue[boss].groups:
   for key in dialogue[boss].groups[event]:verify(ResourceLoader.exists("res://assets/voice/"+boss+"_"+key+".wav"),boss+" "+event+" voice")
 verify(ResourceLoader.exists("res://assets/art/boss_reset/moon.png"),"moon surface imported")
 print("BOSS_RESET_ASSETS_RESULT checks=",checks," failures=",failures);quit(0 if failures.is_empty() else 1)

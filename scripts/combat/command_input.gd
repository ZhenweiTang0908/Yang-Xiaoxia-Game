extends RefCounted
const WINDOW=.75
const FINISH_WINDOW=.30
var clock=0.0
var history=[]
var last_direction=Vector2.ZERO
func clear():
	history.clear();last_direction=Vector2.ZERO
func tick(dt):
	clock+=dt
	history=history.filter(func(step):return clock-step.time<=WINDOW)
func sample(direction,face):
	var next=Vector2(signf(direction.x),1 if direction.y>.25 else 0)
	if next==last_direction:return
	last_direction=next
	if next==Vector2.ZERO:return
	history.append({"direction":next,"face":face,"time":clock})
	if history.size()>12:history.pop_front()
func take():
	if history.is_empty() or clock-history.back().time>FINISH_WINDOW:return {}
	# Test the longest motion first so forward/down/forward cannot become a wave.
	for recipe in [{"id":"rising","steps":[6,2,6]},{"id":"wave","steps":[2,6]},{"id":"spin","steps":[2,4]}]:
		for start in range(history.size()):
			var face=history[start].face
			var tokens=[]
			for i in range(start,history.size()):
				var direction=history[i].direction
				var token=2 if direction.x==0 else (6 if direction.x*face>0 else 4)
				if tokens.is_empty() or tokens.back()!=token:tokens.append(token)
			if tokens==recipe.steps:
				clear();return {"id":recipe.id,"face":face}
	return {}

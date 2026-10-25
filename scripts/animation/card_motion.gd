extends RefCounted
# Hold the draw, snap through release, then give the hand time to settle.
# Frame 14 remains the authored hand socket used by the projectile system.
const RELEASE=.14
const DURATION=.42
const TIMES=[0.0,.09,RELEASE,.18,.24,.32]
static func frame_at(elapsed):
 var frame=12
 for i in TIMES.size():
  if elapsed>=TIMES[i]-.000001:frame=12+i
 return frame

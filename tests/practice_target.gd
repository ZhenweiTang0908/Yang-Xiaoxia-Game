extends Node2D
var flash=0.0
var health=100
var hits=0
func strike(damage):
 health=maxi(0,health-damage);hits+=1;flash=.09;queue_redraw()
func step(dt):flash=maxf(0,flash-dt);queue_redraw()
func _draw():
 var tint=Color("718078").lerp(Color("ded9b8"),clampf(flash/.09,0,1)*.4)
 draw_rect(Rect2(-4,12,8,52),Color("46544f"))
 draw_rect(Rect2(-14,60,28,4),Color("3e4b48"))
 draw_circle(Vector2.ZERO,18,tint)
 draw_line(Vector2(-9,-3),Vector2(9,-3),Color("46544f"),2)
 draw_line(Vector2(-7,4),Vector2(7,4),Color("46544f"),2)
 if flash>0:
  var u=1-flash/.09
  draw_line(Vector2(-16,0)+Vector2(-7,-4)*u,Vector2(-23,-6)+Vector2(-7,-4)*u,Color(1,.87,.58,1-u),1)
  draw_line(Vector2(-16,1)+Vector2(-5,5)*u,Vector2(-22,8)+Vector2(-5,5)*u,Color(1,.87,.58,1-u),1)

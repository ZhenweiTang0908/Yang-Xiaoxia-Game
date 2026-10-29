extends RefCounted
# Source-order timing for each move's own authored draft sheet. No generic
# study poses counted as production completion. Refine after rendered review.
const TIMES={
 "M01":[0.0,.13,.26,.40,.60,.72,.78,1.02,1.18,1.75],
 "M02":[0.0,.15,.30,.44,.57,.72,.86,1.03,1.28,1.60],
 "M03":[0.0,.10,.22,.34,.44,.55,.66,.75,.83,.91,.98,1.08,1.25,1.45,1.65,1.95],
 "M04":[0.0,.13,.26,.40,.55,.72,.86,.96,1.08,1.22,1.40,1.60,1.80,2.08],
 "M05":[0.0,.16,.32,.48,.66,.82,.96,1.12,1.35,1.65],
 "M06":[0.0,.16,.32,.50,.72,.92,1.04,1.22,1.48,1.82],
 "M07":[0.0,.20,.40,.60,.80,1.0,1.17,1.38,1.60,1.90,2.20,2.55],
 "M08":[0.0,.40,.75,1.0,1.18,1.38,1.55,1.80,2.0,2.20,2.40,2.55,2.75,2.95,3.20,3.55],
 "M09":[0.0,.12,.25,.40,.60,.82,.92,1.03,1.18,1.45],
 "M10":[0.0,.12,.24,.37,.51,.64,.80,.94,1.05,1.20,1.36,1.55,1.76,2.05],
 "M11":[0.0,.14,.28,.42,.58,.74,.89,1.04,1.20,1.42,1.70,2.05],
 "M12":[0.0,.14,.30,.48,.65,.85,1.06,1.23,1.40,1.55,1.68,1.82,2.03,2.28,2.58,2.95],
 "M13":[0.0,.15,.32,.50,.70,.88,1.02,1.12,1.25,1.62,1.82,2.04,2.26,2.50],
 "M14":[0.0,.10,.20,.34,.48,.61,.74,.87,.98,1.52,1.78,2.10],
 "M15":[0.0,.12,.27,.42,.58,.73,.88,1.0,1.16,1.34,1.52,1.90],
 "M16":[0.0,.16,.32,.50,.72,.92,1.08,1.27,1.56,1.95],
 "M17":[0.0,.20,.55,.82,1.00,1.17,1.37,1.56,1.74,1.97,2.22,2.55],
 "M18":[0.0,.16,.34,.54,.80,1.06,1.22,1.39,1.56,1.72,1.85,2.10,2.49,3.00],
 "M19":[0.0,.20,.44,.73,1.0,1.15,1.35,1.55,1.73,1.92,2.10,2.28,2.50,2.78,3.12,3.48],
 "M20":[0.0,.28,.70,1.10,1.28,1.47,1.62,1.77,1.89,2.0,2.20,2.43,2.65,2.80,2.97,3.10,3.36,4.45]
}
static func sequence(id,beats,definition,recovery):
 if not TIMES.has(id):return []
 var authored=[0.0];var tuned=[0.0]
 for index in beats.size():
  authored.append(float(definition.beats[index][0]));tuned.append(beats[index].time)
 authored.append(authored[-1]+definition.window+definition.recovery)
 tuned.append(tuned[-1]+beats[-1].window+recovery)
 var result=[]
 for index in TIMES[id].size():
  var at=float(TIMES[id][index]);var segment=authored.size()-2
  for knot in authored.size()-1:
   if at<=authored[knot+1]:segment=knot;break
  var u=clampf((at-authored[segment])/maxf(.001,authored[segment+1]-authored[segment]),0,1)
  var snap=false
  for beat in definition.beats:
   if is_equal_approx(at,float(beat[0])):snap=true
  result.append({"time":lerpf(tuned[segment],tuned[segment+1],u),"index":index,"snap":snap})
 return result

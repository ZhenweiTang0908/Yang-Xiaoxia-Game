"""Rebuild release-only weapon air from original CC0 swishes (no hit thumps)."""
from pathlib import Path
import wave
import numpy as np
from make_enemy_audio import read, pitched, RATE, ROOT
OUT=ROOT/'assets/audio'
GROUPS={
 'swish-3':(['knight_thrust','knight_lance','knight_lunge_release','knight_triple_dash_release','knight_kick_thrust_release'],1.03),
 'swish-9':(['knight_spin_rush_release','knight_dragon_break_release','knight_dragon_sweep_release'],.77),
 'swish-6':(['knight_uppercut_release','knight_spear_slam_release','knight_advance_release','knight_spear_chain_release','knight_dragon_rise_release'],.88),
 'swish-4':(['knight_spear_return_release'],.95),
 'swish-1':(['enemy_duelist_flash_release','enemy_duelist_triple_release','enemy_duelist_low_sweep_release'],1.12),
 'swish-13':(['enemy_priest_four_slash_release'],.92),
}
for source,(keys,speed) in GROUPS.items():
 raw=pitched(read(source,0),speed)
 for variant,key in enumerate(keys):
  # Distinct weight for each move, with a readable air tail even for short source clips.
  size=max(int(.21*RATE)+variant*379,int(len(raw)*(1+variant*.07)))
  shaped=np.interp(np.linspace(0,len(raw)-1,size),np.arange(len(raw)),raw)
  repeats=3 if 'spin_rush' in key or 'spear_return' in key else 1
  s=np.zeros(min(len(shaped),int(.30*RATE))+int((repeats-1)*.085*RATE))
  for i in range(repeats):
   start=int(i*.085*RATE);clip=shaped[:min(len(shaped),int(.30*RATE))].copy()
   clip[:min(240,len(clip))]*=np.linspace(0,1,min(240,len(clip)));clip[-480:]*=np.linspace(1,0,480)
   s[start:start+len(clip)]+=clip*(.72**i)
  s-=s.mean();s*=min(.79/max(abs(s).max(),1e-8),.145/max(np.sqrt(np.mean(s*s)),1e-8))
  with wave.open(str(OUT/(key+'.wav')),'wb') as f:
   f.setparams((1,2,RATE,0,'NONE',''));f.writeframes((s*32767).astype('<i2').tobytes())
  print(key,round(len(s)/RATE,3))

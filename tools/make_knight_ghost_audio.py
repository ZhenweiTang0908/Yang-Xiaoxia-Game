"""Soft ghost-regiment cues plus the knight's armour steps and horse snorts, all procedural.

Ghost cues stay in one A-minor pentatonic so overlapping units sound like a chord, not noise.
Run with the project venv: .venv/bin/python tools/make_knight_ghost_audio.py
"""
from pathlib import Path
import wave
import numpy as np
ROOT=Path(__file__).resolve().parents[1]/'assets/audio'
RATE=48000
rng=np.random.default_rng(261026)
def save(name,s,rms=.10):
 s=s.astype(float)
 s*=min(.85/max(1e-8,np.max(np.abs(s))),rms/max(1e-8,np.sqrt(np.mean(s*s))))
 s[:240]*=np.linspace(0,1,240);s[-960:]*=np.linspace(1,0,960)
 with wave.open(str(ROOT/(name+'.wav')),'wb') as f:
  f.setparams((1,2,RATE,0,'NONE',''));f.writeframes((s*32767).astype('<i2').tobytes())
def times(seconds):return np.arange(int(seconds*RATE))/RATE
def smooth(s,width):return np.convolve(s,np.ones(width)/width,'same')
def bell(freq,t,decay):
 # Soft glass bell: fundamental, a quiet octave and a slightly sharp fifth partial.
 return (np.sin(2*np.pi*freq*t)+.35*np.sin(2*np.pi*freq*2.0*t)*np.exp(-t*3)+.12*np.sin(2*np.pi*freq*3.01*t)*np.exp(-t*6))*np.exp(-t*decay)
def place(out,s,at):
 i=int(at*RATE);n=min(len(s),len(out)-i);out[i:i+n]+=s[:n];return out
def room(s,amount=.32):
 out=s.copy()
 for delay,gain in [(.043,.55),(.071,.42),(.109,.30),(.157,.20)]:
  d=int(delay*RATE);out[d:]+=amount*gain*s[:-d]
 return out
A3,C4,E4,G4,A4,C5,E5,G5,A5=220.0,261.63,329.63,392.0,440.0,523.25,659.25,783.99,880.0
# Regiment summon: a slow pentatonic swell with a breath of air underneath.
t=times(1.6)
swell=np.minimum(1,t/.45)*np.exp(-np.maximum(0,t-.5)*2.2)
chord=sum(g*np.sin(2*np.pi*f*t+p) for f,g,p in [(A3,.8,0),(E4,.6,.4),(A4,.5,1.1),(C5,.35,.7),(E5,.22,2.0)])
chord*=1+.12*np.sin(2*np.pi*5.5*t)
air=smooth(rng.normal(0,1,len(t)),40)*.18
summon=room((chord+air)*swell,.4)
summon=place(summon,bell(A5,times(.9),4.5)*.25,.42)
save('knight_ghost_summon',summon,.09)
# One unit taking shape: two rising bell notes.
rise=np.zeros(int(.7*RATE))
rise=place(rise,bell(E5,times(.6),7),0)
rise=place(rise,bell(A5,times(.55),8)*.8,.09)
save('knight_ghost_rise',room(rise,.3),.07)
# Spear ghost gliding forward: breathy whoosh with a faint upward tone.
t=times(.6)
env=np.sin(np.pi*np.clip(t/.6,0,1))**1.5
noise=rng.normal(0,1,len(t))
whoosh=smooth(noise,6)-smooth(noise,60)
tone=np.sin(2*np.pi*np.cumsum(520+340*t/.6)/RATE)*.25
save('knight_ghost_glide',room((whoosh*.8+tone)*env,.25),.08)
# A unit dissolving: falling three-note chime.
fade=np.zeros(int(1.0*RATE))
for k,f in enumerate([A5,E5,C5]):fade=place(fade,bell(f,times(.6),6)*(1-k*.18),k*.11)
save('knight_ghost_fade',room(fade,.38),.06)
# Armour on foot: a short metal clink over a soft boot thud, two variants.
for name,base in [('knight_armor_step_a',2150.0),('knight_armor_step_b',2380.0)]:
 t=times(.22)
 clink=sum(np.sin(2*np.pi*base*r*t)*np.exp(-t*d) for r,d in [(1.0,38),(1.59,52),(2.43,70)])
 thud=np.sin(2*np.pi*(95-40*t)*t)*np.exp(-t*30)*1.6
 grit=smooth(rng.normal(0,1,len(t)),3)*np.exp(-t*60)*.4
 save(name,clink*.5+thud+grit,.09)
# Horse snort: two fluttering breaths through the nose.
t=times(.75)
breath=smooth(rng.normal(0,1,len(t)),14)
flutter=.55+.45*np.sin(2*np.pi*31*t)
env=np.exp(-((t-.12)/.07)**2)+.8*np.exp(-((t-.42)/.11)**2)
save('knight_snort',breath*flutter*env,.10)
print('KNIGHT_GHOST_AUDIO ok')

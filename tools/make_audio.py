"""Original offline-synthesized PCM sound assets; reproducible, no dependencies."""
import math, random, wave, struct
from pathlib import Path
random.seed(41)
OUT=Path('assets/audio'); OUT.mkdir(parents=True,exist_ok=True)
SR=22050

def save(name,duration,fn):
    data=[]
    for i in range(int(duration*SR)):
        t=i/SR
        v=max(-.95,min(.95,fn(t)))
        data.append(int(v*32767))
    with wave.open(str(OUT/(name+'.wav')),'wb') as f:
        f.setparams((1,2,SR,0,'NONE','not compressed'));f.writeframes(struct.pack('<'+'h'*len(data),*data))

def tone(t,f):return math.sin(math.tau*f*t)
for name,dur,freq in [('jump',.23,360),('dash',.19,160),('swing',.19,240),('hit',.23,90),('hurt',.3,130),('bow',.25,680),('land',.13,65),('step',.09,120),('enemy',.5,110)]:
    def effect(t,d=dur,f=freq,n=name):
        e=(1-t/d)**2
        noise=random.uniform(-1,1)
        sweep=f*(1+2*t/d) if n=='jump' else f*(1-.7*t/d)
        return e*(tone(t,sweep)*.22+noise*(.38 if n in ('swing','dash','hit','land','step') else .09))
    save(name,dur,effect)
for name,notes in [('pickup',[523,659,784,1046]),('transform',[130,196,261,392,523,784]),('win',[392,523,659,784,1046]),('ui',[523,784]),('death',[392,330,261,196])]:
    dur=len(notes)*.14+.6
    def chime(t,ns=notes):
        v=0
        for k,f in enumerate(ns):
            u=t-k*.14
            if u>=0:v+=(tone(u,f)+.3*tone(u,f*2))*math.exp(-u*5)*.15*min(1,u*100)
        return v
    save(name,dur,chime)
save('charge',1.1,lambda t:(tone(t,150+220*t)+tone(t,152+220*t))*.11*min(1,t*15)*(1-t/1.1))
save('blast',.8,lambda t:(random.uniform(-1,1)*.3+tone(t,65-30*t)*.4)*math.exp(-t*6)*min(1,t*100))
# A 16-second pentatonic loop: bell melody, soft low strings, subtle wind.
notes=[293.66,349.23,440,523.25,587.33,523.25,440,349.23,261.63,349.23,392,523.25,440,392,349.23,293.66]
def music(t):
    v=0
    for k,f in enumerate(notes):
        for start in (k,k-16):
            u=t-start
            if 0<=u<5:v+=(tone(u,f)+.28*tone(u,f*2.001))*.055*math.exp(-u*1.45)*min(1,u*35)
    v+=(tone(t,73.41625)+.35*tone(t,110))*.025*(.75+.25*math.sin(math.tau*t/16))
    return v
save('music',16,music)
save('ambience',8,lambda t:random.uniform(-1,1)*.014*(.5+.4*math.sin(math.tau*t/8)) + tone(t,880)*.003*(.5+.5*math.sin(math.tau*t/2)))
print('Created',len(list(OUT.glob('*.wav'))),'audio assets')

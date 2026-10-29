"""Measure anatomical landmarks; does not alter source PNGs."""
from pathlib import Path
import json,subprocess
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
def rgba(p):
 meta=json.loads(subprocess.check_output(['ffprobe','-v','quiet','-show_streams','-of','json',str(p)]))['streams'][0]
 return np.frombuffer(subprocess.check_output(['ffmpeg','-v','error','-i',str(p),'-f','rawvideo','-pix_fmt','rgba','-']),np.uint8).reshape(meta['height'],meta['width'],4)
def groups(mask):
 h,w=mask.shape;seen=np.zeros_like(mask);result=[]
 for y,x in zip(*np.where(mask)):
  if seen[y,x]:continue
  stack=[(int(x),int(y))];seen[y,x]=True;xs=[];ys=[]
  while stack:
   xx,yy=stack.pop();xs.append(xx);ys.append(yy)
   for dx,dy in [(1,0),(-1,0),(0,1),(0,-1),(1,1),(1,-1),(-1,1),(-1,-1)]:
    nx,ny=xx+dx,yy+dy
    if 0<=nx<w and 0<=ny<h and mask[ny,nx] and not seen[ny,nx]:seen[ny,nx]=True;stack.append((nx,ny))
  if len(xs)>=12:result.append([min(xs),min(ys),max(xs)-min(xs)+1,max(ys)-min(ys)+1,len(xs)])
 return result

def measure(p,kind):
 a=rgba(p);r,g,b=[a[:,:,i].astype(float) for i in range(3)];solid=a[:,:,3]>170
 yy,xx=np.where(solid);top,bottom=min(yy),max(yy);height=bottom-top+1
 if kind=='priest':
  body=solid&(b>g*1.15)&(b>r*1.05)
  rows=np.where(body.sum(axis=1)>max(5,a.shape[1]*.07))[0]
  body_top=rows[0] if len(rows) else top
  upper=body & (np.arange(a.shape[0])[:,None]<body_top+height*.25)
  ys,xs=np.where(upper);center=float(np.median(xs)) if len(xs) else float(np.median(xx))
  mask=solid&(r>125)&(g>110)&(b>65)&(r>g*.95)&(r>b*1.03)
  candidates=[c for c in groups(mask) if c[4]>=80 and .45<c[2]/c[3]<1.7 and c[1]<body_top+height*.25]
  score=lambda c:abs(c[0]+c[2]*.5-center)+abs(c[1]+c[3]*.5-body_top)*.35-c[4]**.5*.3
 else:
  mask=solid&(r>100)&(g>90)&(b>65)&(abs(r-g)<40)&(abs(g-b)<45)
  candidates=[c for c in groups(mask) if .48<c[2]/c[3]<1.9 and c[3]>=8 and c[1]<top+height*.65]
  score=lambda c:c[1]*.7-c[4]**.5*.5
 if not candidates:return None
 c=min(candidates,key=score)
 return {'head':[int(v) for v in c[:4]],'area':int(c[4]),'alternatives':len(candidates)}
def main():
 result={}
 for bank in ['foot','mounted','extra','arsenal','pressure']:
  folder=ROOT/'assets/art/knight_frames'/bank
  result['knight/'+bank]=[measure(folder/f'{i:02}.png','knight') for i in range(12)]
 for bank in ['priest','knight']:
  folder=ROOT/'assets/art/boss_reset'/bank;meta=json.loads((folder/'frames.json').read_text())
  result['reset/'+bank]=[measure(folder/f'{i:02}.png','priest' if bank=='priest' else 'knight') for i in range(meta['count'])]
 out=ROOT/'builds/qa/visual-stability';out.mkdir(parents=True,exist_ok=True);(out/'.gdignore').touch()
 (out/'landmark-candidates.json').write_text(json.dumps(result,indent=2))
 for bank,items in result.items():print(bank,[(i,x['head'] if x else None) for i,x in enumerate(items) if bank!='reset/priest' or i<12])
if __name__=='__main__':main()

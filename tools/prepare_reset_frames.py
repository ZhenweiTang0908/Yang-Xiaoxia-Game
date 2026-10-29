"""Extract opaque authored characters, never count synthesized/interpolated frames."""
from pathlib import Path
import subprocess,json,zlib,struct,sys
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
def read(p):
 dims=json.loads(subprocess.check_output(['ffprobe','-v','quiet','-show_streams','-of','json',str(p)]))['streams'][0]
 w,h=dims['width'],dims['height']
 a=np.frombuffer(subprocess.check_output(['ffmpeg','-v','error','-i',str(p),'-f','rawvideo','-pix_fmt','rgba','-']),dtype=np.uint8).reshape(h,w,4).copy()
 # Generated sheets contain translucent atmospheric residue. Only character paint survives.
 a[:,:,3]=np.where(a[:,:,3]>=170,a[:,:,3],0)
 return a
def png(p,a):
 h,w=a.shape[:2]
 def chunk(t,b):return struct.pack('>I',len(b))+t+b+struct.pack('>I',zlib.crc32(t+b)&0xffffffff)
 p.parent.mkdir(parents=True,exist_ok=True)
 p.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(b''.join(b'\0'+r.tobytes() for r in a),6))+chunk(b'IEND',b''))
def components(a):
 mask=a[:,:,3]>0;h,w=mask.shape
 # Eight-neighbour connectivity, discard atmospheric flecks.
 seen=np.zeros((h,w),bool);boxes=[]
 for y,x in zip(*np.where(mask)):
  if seen[y,x]:continue
  stack=[(int(y),int(x))];seen[y,x]=1;xs=[];ys=[]
  while stack:
   yy,xx=stack.pop();xs.append(xx);ys.append(yy)
   for dy,dx in [(0,1),(0,-1),(1,0),(-1,0),(1,1),(1,-1),(-1,1),(-1,-1)]:
    ny,nx=yy+dy,xx+dx
    if 0<=ny<h and 0<=nx<w and mask[ny,nx] and not seen[ny,nx]:seen[ny,nx]=1;stack.append((ny,nx))
  if len(xs)>650:boxes.append([min(xs),min(ys),max(xs)+1,max(ys)+1,len(xs)])
 # Sort into rows by centers, robust to sheets with an extra column.
 rows=[]
 for b in sorted(boxes,key=lambda b:(b[1]+b[3])/2):
  cy=(b[1]+b[3])/2
  row=next((r for r in rows if abs(cy-np.mean([(c[1]+c[3])/2 for c in r]))<h*.05),None)
  if row is None:rows.append([b])
  else:row.append(b)
 return [b for row in rows for b in sorted(row)]
def isolate_character(a):
 # A crop can overlap a neighbouring spear. Retain the selected connected paint.
 mask=a[:,:,3]>0;h,w=mask.shape;seen=np.zeros_like(mask);largest=[]
 for y,x in zip(*np.where(mask)):
  if seen[y,x]:continue
  stack=[(int(y),int(x))];seen[y,x]=True;part=[]
  while stack:
   yy,xx=stack.pop();part.append((yy,xx))
   for dy,dx in [(0,1),(0,-1),(1,0),(-1,0),(1,1),(1,-1),(-1,1),(-1,-1)]:
    ny,nx=yy+dy,xx+dx
    if 0<=ny<h and 0<=nx<w and mask[ny,nx] and not seen[ny,nx]:
     seen[ny,nx]=True;stack.append((ny,nx))
  if len(part)>len(largest):largest=part
 keep=np.zeros_like(mask)
 for y,x in largest:keep[y,x]=True
 a[:,:,3]=np.where(keep,a[:,:,3],0)
 return a
CLIPS={
 'lantern':{'a':[('pounce',10),('sweep',10),('ground_wave',10),('idle',6)],'b':[('stone_lift',10),('stone_throw',10),('stone_roll',10),('walk',6)],'c':[('stone_combo',10),('walk',8),('turn',6),('hurt',3),('stagger',3),('death',4),('idle',2)]},
 'duelist':{'a':[('flash',10),('triple',10),('low_sweep',10),('idle',6)],'b':[('leap',10),('fan',10),('boomerang',10),('turn',6)],'c':[('feint',10),('shadow',10),('idle',4),('hurt',3),('stagger',3),('death',4),('turn',2)]},
 'priest':{'a':[('horn',10),('four_slash',10),('ground_wave',10),('idle',4),('walk',4),('turn',4)],'b':[('moonfall',10),('ring',10),('homing',10),('hurt',4),('stagger',4),('death',4)],'c':[('beam',10),('rain',10),('rift',10),('transform',12)],'d':[('ritual',10),('discard',20),('walk',8),('turn',6),('idle',2)],'melee':[('four_slash',10)],'recall':[('recall',16)],'turn':[('turn',8)]},
 'knight':{'extra':[('turn',7),('advance',6),('load',6),('recover',7)],'repair':[('turn',2),('advance',1),('recover',1)]}}
def main():
 for identity,groups in CLIPS.items():
  if "--only" in sys.argv and identity!=sys.argv[sys.argv.index("--only")+1]:continue
  clips={};metadata=[];reference=[]
  folder=ROOT/'assets/art/boss_reset'/identity
  for letter,layout in groups.items():
   source=ROOT/'art_source/boss_reset'/f'{dict(lantern="stone").get(identity,identity)}-{letter}.png'
   if not source.exists():continue
   a=read(source);boxes=components(a)
   if identity=='priest' and letter=='d':
    boxes=[]
    edges=[0,160,322,468,608,736,881,1024]
    for row in range(7):
     cols=6 if row<5 else 8
     for col in range(cols):
      l,r=round(col*a.shape[1]/cols),round((col+1)*a.shape[1]/cols)
      y,b=edges[row],edges[row+1]
      yy,xx=np.where(a[y:b,l:r,3]>0)
      if len(xx):boxes.append([int(l+min(xx)),int(y+min(yy)),int(l+max(xx)+1),int(y+max(yy)+1),len(xx)])
   if identity=='priest' and letter=='recall':
    boxes=[]
    for row in range(4):
     for col in range(4):
      l,r=round(col*a.shape[1]/4),round((col+1)*a.shape[1]/4)
      y,b=round(row*a.shape[0]/4),round((row+1)*a.shape[0]/4)
      yy,xx=np.where(a[y:b,l:r,3]>0)
      if len(xx):boxes.append([int(l+min(xx)),int(y+min(yy)),int(l+max(xx)+1),int(y+max(yy)+1),len(xx)])
   expected=sum(c for _,c in layout)
   print(identity,letter,'components',len(boxes),'expected',expected,flush=True)
   (source.with_suffix('.boxes.json')).write_text(json.dumps(boxes))
   # Preserve actual generated reading order and record source rectangles for audit.
   sheet_reference=float(np.median([b[3]-b[1] for b in boxes[:min(24,len(boxes))]]))
   if letter=='recall':sheet_reference=220.0
   if identity=='priest' and letter=='turn':sheet_reference/=1.08
   index=0
   for clip,count in layout:
    for k in range(count):
     if clip=='discard':index+=1;continue
     if index>=len(boxes):break
     x,y,r,b,_=boxes[index];index+=1
     crop=a[max(0,y-2):min(a.shape[0],b+2),max(0,x-2):min(a.shape[1],r+2)].copy()
     if identity=="knight":crop=isolate_character(crop)
     # A per-sheet scale preserves authored crouch/raised-staff height within a sequence.
     ratio=128/sheet_reference
     oh,ow=crop.shape[:2];nh,nw=max(1,round(oh*ratio)),max(1,round(ow*ratio))
     crop=crop[np.minimum((np.arange(nh)/ratio).astype(int),oh-1)[:,None],np.minimum((np.arange(nw)/ratio).astype(int),ow-1)[None,:]]
     num=len(metadata);png(folder/f'{num:02}.png',crop)
     clips.setdefault(clip,[]).append(num)
     metadata.append({'source':str(source.relative_to(ROOT)),'rect':[x,y,r-x,b-y],'clip':clip,'order':k,'sheet_scale':ratio})
     if clip=='idle':reference.append(b-y)
  if metadata:
   data={'count':len(metadata),'reference_height':128.0,'clips':clips,'frames':metadata}
   # Last dedicated sheets replace the earlier generic combo/recall mappings.
   if identity=='priest' and 'four_slash' in clips and len(clips['four_slash'])>10:clips['four_slash']=clips['four_slash'][-10:]
   if identity=='priest' and 'turn' in clips:
    clips['turn']=clips['turn'][-8:]
    clips['idle']=[20,21,23,24]
    clips['walk']=[28,29,30,39]+clips['walk'][4:]
    clips['ground_wave']=list(range(13,23))
    clips['death']=clips['recall'][:4];clips['recall']=clips['recall'][3:]
   (folder/'frames.json').write_text(json.dumps(data,indent=2))
if __name__=='__main__':main()

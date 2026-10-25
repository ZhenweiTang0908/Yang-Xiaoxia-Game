"""Fetch only selected members of the official Godot template ZIP (default: Mac and Web; pass names to choose)."""
import subprocess, struct, zipfile, os, zlib, sys
from pathlib import Path
URL='https://github.com/godotengine/godot-builds/releases/download/4.7-stable/Godot_v4.7-stable_export_templates.tpz'
wanted=sys.argv[1:] or ['macos.zip','web_nothreads_release.zip','web_nothreads_debug.zip','version.txt']
out=Path('builds/templates');out.mkdir(parents=True,exist_ok=True)
def fetch(rng,dest):
 subprocess.run(['curl','--proxy','http://127.0.0.1:7897','-fsSL','--retry','2','--max-time','600','-r',rng,URL,'-o',str(dest)],check=True)
# GitHub's asset store rejects suffix ranges such as -65536, so ask for the size first.
head=subprocess.run(['curl','--proxy','http://127.0.0.1:7897','-fsSLI',URL],check=True,capture_output=True,text=True).stdout
size=int([l.split(':')[1] for l in head.lower().splitlines() if l.startswith('content-length:')][-1])
tail=out/'tail';fetch(f'{size-65536}-{size-1}',tail)
data=tail.read_bytes();i=data.rfind(b'PK\x05\x06');e=struct.unpack_from('<4s4H2LH',data,i);cd_size,cd_offset=e[5],e[6]
cd=out/'cd';fetch(f'{cd_offset}-{cd_offset+cd_size-1}',cd)
data=cd.read_bytes();p=0
while p<len(data):
 h=struct.unpack_from('<4s6H3L5H2L',data,p)
 name=data[p+46:p+46+h[10]].decode();p+=46+h[10]+h[11]+h[12]
 if name.split('/')[-1] not in wanted:continue
 dest=out/name.split('/')[-1]
 if dest.exists():continue
 print('Fetching',name,h[8],flush=True)
 raw=out/'member';fetch(f'{h[16]}-{h[16]+30+len(name.encode())+256+h[8]-1}',raw)
 b=raw.read_bytes();head=struct.unpack_from('<4s5H3L2H',b);start=30+head[9]+head[10];blob=b[start:start+h[8]]
 dest.write_bytes(zlib.decompress(blob,-15) if h[4]==8 else blob)
 print('Saved',dest,dest.stat().st_size,flush=True)

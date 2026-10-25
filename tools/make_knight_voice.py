"""Offline Mandarin performance using the local macOS Reed voice, shipped as PCM."""
import json, subprocess, wave
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
LINES={
 'intro':'止步。此地，由我的枪守着。',
 'foot':'不必试马了。你我，凭本事决胜。',
 'dismount':'马可退，人不退。来，接我这一枪！',
 'spin_rush':'枪锋所向，破阵！',
 'spear_return':'躲得过来枪，躲得过回锋吗？',
 'triple_dash':'一枪未尽，再接两枪！',
 'bow_volley':'你逃跑的路，我看得清。',
 'wave':'看清楚，第三枪！',
 'pursuit':'只会逃，可赢不了我。',
 'seal':'葫芦救不了你。',
 'low':'铠甲可碎，誓言不折！',
 'death':'好身手。这条路，归你了。',
 'intro_b':'这道山门，不曾向逃兵敞开。',
 'foot_b':'下了马，才是我的真本事。',
 'dismount_b':'坐骑歇了，我的枪还没歇！',
 'spear_chain':'枪有三节，看清每一节。',
 'spear_chain_b':'先刺，再进，最后这一挑！',
 'dragon_sweep':'枪走下盘，你站稳了吗？',
 'dragon_sweep_b':'躲过低锋，再看回枪！',
 'dragon_rise':'旋枪聚势，起！',
 'dragon_rise_b':'天上，也在枪锋之内！',
 'dragon_break':'乱枪归一，破阵开山！',
 'dragon_break_b':'这一枪，敬我未归的同袍！',
 'lunge':'收枪，是为下一刺。',
 'lunge_b':'一线枪锋，穿甲而过！',
 'counter':'你的破绽，我看见了。',
 'guard':'来，试试谁先露出破绽。',
 'stagger':'好！你破得开我的枪架。',
 'soul_legion':'旧日的同袍，再随我冲阵！',
 'soul_legion_b':'战旗未倒，众将随我！',
 'wave_b':'抬枪之时，便是你起跳之时。',
 'spin_rush_b':'人随枪进，休想拉开！',
 'spear_return_b':'枪去有归，莫急着追。',
 'bow_volley_b':'风过弓弦，箭不落空。',
 'low_b':'还未倒下，就还守得住！',
 'death_b':'枪已尽。你，走吧。',
}
VARIANT_EVENTS=[
    'intro','foot','dismount','spear_chain','dragon_sweep','dragon_rise',
    'dragon_break','lunge','soul_legion','wave','spin_rush','spear_return',
    'bow_volley','low','death',
]
GROUPS={event:[event,event+'_b'] for event in VARIANT_EVENTS}

def main():
    source=ROOT/'art_source/audio/knight_voice';source.mkdir(parents=True,exist_ok=True)
    out=ROOT/'assets/voice';out.mkdir(parents=True,exist_ok=True)
    manifest={}
    manifest_path=ROOT/'builds/qa/knight/voice-manifest.json'
    previous=json.loads(manifest_path.read_text()) if manifest_path.exists() else {}
    for key,line in LINES.items():
        raw=source/(key+'.aiff')
        if not raw.exists() or previous.get(key,{}).get('line')!=line:
            subprocess.run(['say','-v','Reed (Chinese (China mainland))','-r','188','-o',str(raw),line],check=True)
        meta=json.loads(subprocess.check_output(['/opt/homebrew/bin/ffprobe','-v','error','-show_entries','stream=sample_rate,duration','-of','json',str(raw)]))['streams'][0]
        assert float(meta['duration'])>.4, 'Speech service produced empty audio'
        rate=int(meta['sample_rate'])
        data=subprocess.check_output(['/opt/homebrew/bin/ffmpeg','-v','error','-i',str(raw),'-af',f'asetrate={rate*.88},aresample=48000,atempo=1.1,highpass=f=100,lowpass=f=6500','-ac','1','-f','f32le','pipe:1'])
        audio=np.frombuffer(data,dtype='<f4').copy()
        # A very short reflection suggests a closed helmet without obscuring consonants.
        delay=int(.032*48000);audio[delay:]+=.10*audio[:-delay].copy()
        audio*=min(.72/max(1e-8,float(abs(audio).max())),.12/max(1e-8,float(np.sqrt(np.mean(audio*audio)))))
        assert np.isfinite(audio).all() and abs(audio).max()>.1
        with wave.open(str(out/('knight_'+key+'.wav')),'wb') as f:
            f.setparams((1,2,48000,0,'NONE',''));f.writeframes((audio*32767).astype('<i2').tobytes())
        manifest[key]={'line':line,'duration':round(len(audio)/48000,3),'peak':round(float(abs(audio).max()),3)}
    (ROOT/'builds/qa/knight/voice-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
    print('KNIGHT_VOICE',len(manifest),'real Mandarin lines')
if __name__=='__main__':main()

# 프레임 PNG를 펫별 가로 띠 1장으로 묶는다. 이동 모션이 실패한 펫은 임시로 기존 대기 모션(anim)을 쓴다.
from PIL import Image
import glob
PETS="d_chick d_frog d_mouse c_mushroom c_puffbird c_slime b_hamster b_hedgehog b_sparrow a_fennec a_otter a_owl s_fairy s_tome s_wisp ss_golem ss_knight ss_storm sss_apostle sss_demon sss_lunar sss_seraph".split()
MOVE_BAD={'d_frog','d_mouse','c_slime','a_fennec','a_otter','s_fairy','s_tome','a_owl'}
def strip(paths,out):
    fr=[Image.open(p).convert('RGBA') for p in paths]
    w,h=fr[0].size
    s=Image.new('RGBA',(w*len(fr),h),(0,0,0,0))
    for i,f in enumerate(fr): s.paste(f,(i*w,0))
    s.save(out)
import os,sys
redo=os.path.exists('move_redo')
for k in PETS:
    strip(['work/%s_%02d.png'%(k,i) for i in range(9)],'assets/pets/%s_work.png'%k)
    src='move_redo' if (redo and k in MOVE_BAD and os.path.exists('move_redo/%s_00.png'%k)) else ('../pet-newstyle-20261122/anim' if k in MOVE_BAD else 'move')
    strip([src+'/%s_%02d.png'%(k,i) if src!='../pet-newstyle-20261122/anim' else src+'/%s_%02d.png'%(k,i) for i in range(9)],'assets/pets/%s_move.png'%k)
for k in ['coral','star','pearls','chest']:
    src={'star':'star'}.get(k,k)
    strip(['prop/%s_a%02d.png'%(k,i) for i in range(9)],'assets/prop_%s.png'%k)
print('ok',len(glob.glob('assets/pets/*.png')))

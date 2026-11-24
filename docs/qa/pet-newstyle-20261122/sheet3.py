import sys
from PIL import Image, ImageDraw
exec(open('run3.py').read().split('def gen')[0].split("R='../")[0])
R='../pet-roster-20261118/';C=R+'cd-pixellab-right/'
import re
src=open('run3.py').read(); P=eval(src[src.index('P={')+2:src.index('\n}\n')+2].join(['{','']) if False else '{'+src[src.index('P={')+3:src.index('\n}\n')+1]+'}')
ids=sys.argv[2:];S=3;c=96*S
W=Image.new('RGBA',(4*(c+8)+8,len(ids)*(c+22)+8),(200,215,225,255));d=ImageDraw.Draw(W)
for r,pid in enumerate(ids):
    fs=[P[pid][0]]+[f'final/{pid}3/step{i}.png' for i in (1,2,3)]
    y=8+r*(c+22);d.text((8,y),f'{pid}: original | step1 | step2 face | step3 final',fill=(0,0,0,255))
    for i,f in enumerate(fs): W.alpha_composite(Image.open(f).convert('RGBA').resize((c,c),Image.NEAREST),(8+i*(c+8),y+16))
W.save(sys.argv[1])

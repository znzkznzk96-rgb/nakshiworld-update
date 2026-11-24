import sys,os
sys.argv=['x']
os.chdir('../pet-newstyle-20261122')
exec(open('gen5.py').read().split("if __name__")[0])
from concurrent.futures import ThreadPoolExecutor
OUT='../pet-hut-ui-20261124/icon/'
COL={'d':'gray','c':'green','b':'blue','a':'purple','s':'golden yellow','ss':'pink red','sss':'white and rainbow'}
M={'d_chick':'a tiny chick feather','d_frog':'a frog eye','d_mouse':'a round mouse ear','c_mushroom':'a mushroom cap','c_puffbird':'a fluffy bird feather','c_slime':'a water drop',
'b_hamster':'a sunflower seed','b_hedgehog':'a sharp spike','b_sparrow':'a small wing','a_fennec':'a big pointed fox ear','a_otter':'a spiral shell','a_owl':'a round owl eye',
's_fairy':'a sparkling fairy wing','s_tome':'an open spell book','s_wisp':'a small flame','ss_golem':'a glowing stone rune','ss_knight':'a sword hilt','ss_storm':'a lightning bolt',
'sss_apostle':'a crown with a star','sss_demon':'a flaming horn','sss_lunar':'a crescent moon','sss_seraph':'a golden halo and wing'}
jobs=[]
for k,m in M.items():
    c=COL[k.split('_')[0]]
    jobs.append(('frag_'+k,"pixel art item icon: a faceted %s crystal shard fragment glowing softly, with %s carved on it, centered, front view, game loot item"%(c,m)))
    if k.split('_')[0] in('a','s','ss','sss'):
        jobs.append(('bp_'+k,"pixel art item icon: a rolled blueprint paper scroll, blue technical drawing lines showing %s, tied with a %s ribbon, centered, front view, game loot item"%(m,c)))
def run(j):
    n,d=j
    gen5(d,20261420,OUT+n,{"image_size":{"width":32,"height":32},"view":"low top-down","direction":"south"})
b0=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
with ThreadPoolExecutor(4) as ex: list(ex.map(run,jobs))
print(len(jobs),b0,'->',call('https://api.pixellab.ai/v2/balance')['subscription']['generations'])

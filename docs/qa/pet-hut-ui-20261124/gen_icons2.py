import sys,os
only=sys.argv[1:] 
sys.argv=['x']
os.chdir('../pet-newstyle-20261122')
exec(open('gen5.py').read().split("if __name__")[0])
from concurrent.futures import ThreadPoolExecutor
OUT='../pet-hut-ui-20261124/icon2/'
COL={'d':'gray','c':'green','b':'blue','a':'purple','s':'golden yellow','ss':'red','sss':'white'}
M={'d_chick':'a feather','d_frog':'an eye','d_mouse':'a round ear','c_mushroom':'a mushroom','c_puffbird':'a bird wing','c_slime':'a water drop',
'b_hamster':'a seed','b_hedgehog':'a spike','b_sparrow':'a small wing','a_fennec':'a pointed ear','a_otter':'a shell','a_owl':'an owl eye',
's_fairy':'a butterfly wing','s_tome':'an open book','s_wisp':'a flame','ss_golem':'a rune','ss_knight':'a sword','ss_storm':'a lightning bolt',
'sss_apostle':'a crown','sss_demon':'a horn','sss_lunar':'a crescent moon','sss_seraph':'a halo'}
jobs=[('frag',"pixel art game item icon, a plain pale cyan diamond-shaped crystal shard fragment, upright, flat shading, black outline, nothing else")]
for k,m in M.items():
    c=COL[k.split('_')[0]]
    if 0: jobs.append(('frag_'+k,"pixel art game item icon, the same plain %s diamond-shaped crystal shard, upright, flat shading, black outline, with a tiny white symbol of %s in its center, nothing else"%(c,m)))
    if k.split('_')[0] in('a','s','ss','sss'):
        jobs.append(('bp_'+k,"pixel art game item icon, the same rolled blue paper blueprint scroll tied with a %s ribbon, upright, flat shading, black outline, with a tiny white sketch of %s on the paper, nothing else"%(c,m)))
if only: jobs=[j for j in jobs if j[0] in only]
def run(j):
    n,d=j
    gen5(d,20261430,OUT+n,{"image_size":{"width":32,"height":32},"view":"low top-down","direction":"south"})
b0=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
with ThreadPoolExecutor(4) as ex: list(ex.map(run,jobs))
print(len(jobs),b0,'->',call('https://api.pixellab.ai/v2/balance')['subscription']['generations'])

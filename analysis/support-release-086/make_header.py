import json,pathlib
c=json.loads(pathlib.Path('source085/game/addons/expedition/catalog.json').read_text())
skills=['drain','bolt','thorns','shield','curse','flurry','regen','heal','mend','weaken','pierce','counter','ward','poison','reflect']
f=pathlib.Path('analysis/support-release-086/catalog.h').open('w')
f.write('const int stats[15][3][3]={\n')
for s in c['soldiers']:f.write('{'+','.join('{'+','.join(str(s['stars'][str(k)][v]) for v in ['hp','atk','def'])+'}' for k in [1,2,3])+'},\n')
f.write('};\nconst int enemies[10][3][3]={\n')
es={str(e['id']):e for e in c['enemies']};factors=[3,3.5,3.2,5,2.5,4.5,1.5,3.5,3.5,1]
for r,seq in enumerate(c['rounds']):f.write('{'+','.join('{%s,%s,%s}'%(es[str(i)]['hp'],int(es[str(i)]['atk']*factors[r]+.5),es[str(i)]['defense']) for i in seq)+'},\n')
f.write('};\n')

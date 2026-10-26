import pathlib,json
p=pathlib.Path(__file__).parent
r=json.loads((p/'results.json').read_text())
lines=[json.loads(x) for x in (p/'trials.jsonl').read_text().splitlines()];(p/'trials.jsonl').write_text(''.join(json.dumps(x,ensure_ascii=False)+'\n' for x in lines))
# Paired deltas and per-player aquarium share; these complement population-total ratios.
by={}
for x in lines:by.setdefault(x['scenario'],{})[x['seed']]=x
summary={}
import numpy as np
for name,group in by.items():
 shares=[x['passive']/max(1,x['sales']+x['rewards']+x['passive']) for x in group.values()]
 summary[name]={'median_individual_aquarium_share':float(np.median(shares)),'day_counts':r[name]['day_counts']}
for name,a,b in [('doubling_six','current_104000_six','current_52000_six'),('aquarium_vs_sell','current_104000_six','current_104000_none')]:
 delta=[by[a][i]['day']-by[b][i]['day'] for i in by[a]];summary[name]={'mean_day_difference':float(np.mean(delta)),'median_day_difference':float(np.median(delta)),'earlier':sum(x<0 for x in delta),'same_day':sum(x==0 for x in delta),'later':sum(x>0 for x in delta)}
(p/'paired.json').write_text(json.dumps(summary,indent=2)+'\n')
# Compact all 8000 trial outcomes (days and money) preserve auditability without large logs.
import csv
with (p/'trials.csv').open('w') as f:
 cols=['scenario','seed','done','day','active_h','elapsed_h','sales','rewards','online_income','offline_income','gold','bait_spent','upgrades_and_region','casts','aqua_capacity','aqua_value'];w=csv.DictWriter(f,fieldnames=cols);w.writeheader()
 for x in lines:w.writerow({k:round(x[k],6) if isinstance(x[k],float) else x[k] for k in cols})
# JSONL is reproducible intermediate; CSV is the retained trial evidence.
(p/'trials.jsonl').unlink()
print('8000 trial outcomes retained as CSV')

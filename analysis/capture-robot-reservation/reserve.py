"""Compare reserve10, upfront-only, and priority escrow; no game edits."""
import pathlib,sys,json,time
import numpy as np
OUT=pathlib.Path(__file__).resolve().parent
sys.path.insert(0,str(OUT.parent/'capture-robot-early'))
from early import value

def run(mode,rate=12,cap=40,regen=30,profile='continuous',region=0,storage=20,collect=0,hours=1,n=512,dt=1,fixed=True):
 rng=np.random.default_rng(20261030);stock=np.full(n,float(cap));escrow=np.zeros(n);rt=np.zeros(n);mt=np.zeros(n);pending=np.zeros(n);rvpending=np.zeros(n)
 bag=np.zeros(n);robot=np.zeros(n);manual=np.zeros(n);rval=np.zeros(n);mval=np.zeros(n);bite=np.zeros(n);casts=np.zeros(n);empty=np.zeros(n)
 supplied=np.zeros(n);overflow=np.zeros(n);debit=np.zeros(n);reserved=np.zeros(n);busy=np.zeros(n,bool);snap=[]
 g=min(region,1)
 for k in range(int(hours*3600/dt)):
  t=k*dt;growth=regen*dt/3600;supplied+=growth
  stock+=growth;overflow+=np.maximum(0,stock-cap);stock=np.minimum(stock,cap)
  if collect and k and abs(t%(collect*3600))<dt/2:bag[:]=0
  # True priority requires protecting partial recovery, not just checking >=1 first.
  if mode in ['upfront','priority'] and rate:
   seeking=(~busy)&(bag<storage)
   if mode=='priority':
    moved=np.where(seeking,np.minimum(stock,1-escrow),0);stock-=moved;escrow+=moved
    begin=seeking&(escrow>=1-1e-8);escrow[begin]=0
   else:
    begin=seeking&(stock>=1);stock[begin]-=1
   reserved+=begin;busy[begin]=True;rt[begin]=0
   rvpending[begin]=value(region,g,g,stock[begin]/cap)
  active=profile=='continuous' or (profile=='mixed' and int(t//600)%2==0)
  running=mt>0;mt[running]-=dt;done=running&(mt<=0)
  manual+=done&(pending>0);mval[done]+=pending[done];pending[done]=0
  if active:
   ix=np.where(mt<=0)[0]
   if len(ix):
    lack=stock[ix]<1;empty[ix]+=lack;casts[ix]+=1
    debit[ix]+=np.minimum(1,stock[ix]);stock[ix]=np.maximum(0,stock[ix]-1)
    ratio=np.minimum(1,(stock[ix]+regen*1.46/3600)/cap)
    wait=rng.uniform(2.5,5,len(ix))*np.where(lack & fixed,3.5,1+.6*(1-ratio));bite[ix]+=wait
    mt[ix]=1.46+wait+rng.uniform(.8,1.2,len(ix))*(30-5.21)
    pending[ix]=value(region,g,4,ratio)*(rng.random(len(ix))<.9)
  if rate:
   if mode=='old':
    eligible=(stock>=11)&(bag<storage);rt+=eligible*dt
    caught=(rt>=3600/rate-1e-8)&eligible
    stock[caught]-=1;reserved+=caught;rvpending[caught]=value(region,g,g,stock[caught]/cap)
   else:
    rt+=busy*dt;caught=busy&(rt>=3600/rate-1e-8)
   robot+=caught;bag+=caught;rval[caught]+=rvpending[caught];busy[caught]=False;rt[caught]=0
  if k+1 in [round(s/dt) for s in [1800,3600,14400,28800]]:
   snap.append(dict(minutes=(k+1)*dt/60,robot=float(robot.mean()),robot_p10=float(np.quantile(robot,.1)),robot_p90=float(np.quantile(robot,.9)),manual=float(manual.mean()),
    manual_p10=float(np.quantile(manual,.1)),manual_p90=float(np.quantile(manual,.9)),robot_sale=float(rval.mean()),manual_sale=float(mval.mean()),
    mean_bite_seconds=float(np.mean(bite/np.maximum(casts,1))),empty_casts=float(empty.mean()),stock=float(stock.mean()),escrow=float(escrow.mean()),working_fraction=float(busy.mean())))
 error=np.max(np.abs(cap+supplied-stock-escrow-overflow-debit-reserved))
 assert error<1e-6,error
 assert np.all(robot<=rate*hours+1e-6) and np.all(bag<=storage) and np.all(stock>=-1e-8)
 assert np.all(reserved-robot<=1+1e-8)
 return dict(mode=mode,rate=rate,cap=cap,regen=regen,profile=profile,region=region,storage=storage,collect=collect,hours=hours,n=n,dt=dt,fixed=fixed,snapshots=snap,conservation_error=float(error))

def main():
 start=time.time();rows=[]
 for region,rate,cap,regen in [(0,12,40,30),(0,24,40,30),(1,36,40,30),(1,36,80,50)]:
  for profile in ['idle','mixed','continuous']:
   for mode in ['none','old','upfront','priority']:
    rows.append(run(mode,rate=0 if mode=='none' else rate,cap=cap,regen=regen,profile=profile,region=region,n=512))
 print('1h grid done',flush=True)
 for rate,cap,regen,region in [(12,40,30,0),(24,40,30,0),(36,80,50,1),(72,140,80,1)]:
  for mode in ['none','old','priority']:
   rows.append(run(mode,rate=0 if mode=='none' else rate,cap=cap,regen=regen,region=region,storage=60,collect=.5,hours=8,n=512))
 print('8h grid done',flush=True)
 for fixed in [False,True]:
  for dt in [.5,2]:rows.append(run('priority',dt=dt,fixed=fixed,n=1024))
 out=dict(rows=rows,trials=sum(x['n'] for x in rows),elapsed_seconds=time.time()-start,game_applied=False)
 (OUT/'results.json').write_text(json.dumps(out,indent=2)+'\n');print('DONE',out['trials'],out['elapsed_seconds'],flush=True)
if __name__=='__main__':main()

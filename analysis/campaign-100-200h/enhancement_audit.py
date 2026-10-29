import numpy as np,json,pathlib
P=pathlib.Path(__file__).resolve().parent
rows=[]
for rod,limit in enumerate([5,8,10,13,16,20]):
 for target in sorted(set([3,(limit+1)//2,limit])):
  for protected in [False,True]:
   Q=np.zeros((target,target));rewards=np.zeros((target,4))
   for lv in range(target):
    p=max(.3,.95-.05*lv*20/limit);risk=lv>=(limit+1)//2
    if lv+1<target:Q[lv,lv+1]+=p
    fail=lv-1 if risk and not protected else lv
    Q[lv,fail]+=1-p
    rewards[lv]=[1,np.floor([90,300,1080,3600,12000,39000][rod]*1.2**lv+.5),np.ceil([1,2,4,8,16,32][rod]*3*1.2**lv),int(risk and protected)]
   answer=np.linalg.solve(np.eye(target)-Q,rewards)
   assert np.allclose((np.eye(target)-Q)@answer,rewards,rtol=1e-7,atol=1e-5)
   assert (answer>=0).all()
   rows.append(dict(rod=rod,target=target,protected=protected,expected_attempts=answer[0,0],expected_gold=answer[0,1],expected_souls=answer[0,2],expected_pearls=answer[0,3]))
(P/'enhancement.json').write_text(json.dumps(rows,indent=2))
for r in rows:
 if r['target']==[5,8,10,13,16,20][r['rod']]:print(r)
# Hypothetical checkpoint floors: failure can never drop below latest +5/+10/+15.
checkpoint_rows=[]
for rod,limit in enumerate([5,8,10,13,16,20]):
 Q=np.zeros((limit,limit));reward=np.zeros((limit,3))
 for lv in range(limit):
  p=max(.3,.95-.05*lv*20/limit)
  if lv+1<limit:Q[lv,lv+1]+=p
  fail=max(lv//5*5,lv-1) if lv>=(limit+1)//2 else lv
  Q[lv,fail]+=1-p
  reward[lv]=[1,np.floor([90,300,1080,3600,12000,39000][rod]*1.2**lv+.5),np.ceil([1,2,4,8,16,32][rod]*3*1.2**lv)]
 answer=np.linalg.solve(np.eye(limit)-Q,reward)
 assert np.allclose((np.eye(limit)-Q)@answer,reward,rtol=1e-7,atol=1e-5)
 checkpoint_rows.append(dict(rod=rod,target=limit,expected_attempts=answer[0,0],expected_gold=answer[0,1],expected_souls=answer[0,2]))
(P/'enhancement_checkpoints.json').write_text(json.dumps(checkpoint_rows,indent=2))
print('checkpoint proposal',checkpoint_rows[-1])
options=[]
for floor in [.3,.45,.5,.6]:
 Q=np.zeros((20,20));R=np.zeros((20,3))
 for lv in range(20):
  p=max(floor,.95-.05*lv)
  if lv+1<20:Q[lv,lv+1]+=p
  Q[lv,max(lv//5*5,lv-1) if lv>=10 else lv]+=1-p
  R[lv]=[1,np.floor(39000*1.2**lv+.5),np.ceil(96*1.2**lv)]
 e=np.linalg.solve(np.eye(20)-Q,R)[0]
 options.append(dict(chance_floor=floor,attempts=e[0],gold=e[1],souls=e[2]))
(P/'enhancement_options.json').write_text(json.dumps(options,indent=2))

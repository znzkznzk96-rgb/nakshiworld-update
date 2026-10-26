#include <algorithm>
#include <array>
#include <cmath>
#include <fstream>
#include <iostream>
#include <sstream>
#include <vector>
#include <string>
#include "catalog.h"
using namespace std;
double utility_scale=1.;
int rnd(double x){return int(floor(x+0.5));}
struct U {int id,hp,mh,atk,def,shield=0,hits=0;};
U unit(int id,int star,int level,int rare,int h=4,int a=4,int d=4){double b=(star==3?1.0+rare*.04:1.0)*(array<double,4>{.7,.8,.9,1.0}[level]);return {id,rnd(stats[id][star-1][0]*(1+h/100.)*b),rnd(stats[id][star-1][0]*(1+h/100.)*b),rnd(stats[id][star-1][1]*(1+a/100.)*b),rnd(stats[id][star-1][2]*(1+d/100.)*b)};}
int dmg(double a,double d){return max(1,rnd(a*.2*100./(100.+max(0.,d))));}
double growth(U const&u){return double(u.mh)/stats[u.id][0][0];}
double ub(U const&t,U const&s){return t.mh*min(1.,growth(s)/growth(t));}
struct Result {bool win;int ticks;array<U,3> u;int ehp;};
Result fight(array<U,3> u,int room,bool modern){int total=0,rescue=0,ward=0,ehp=0;
 for(int encounter=0;encounter<3;encounter++){
  ehp=enemies[room][encounter][0];int ea=enemies[room][encounter][1],ed=enemies[room][encounter][2],poison=0;
  for(auto &f:u)if(f.hp>0&&f.id==3)f.shield=rnd(f.mh*.044);
  for(int tick=1;tick<=600;tick++){
   int front=-1,src[15];fill(src,src+15,-1);
   for(int i=0;i<3;i++)if(u[i].hp>0){if(front<0)front=i;int id=u[i].id;if(src[id]<0||growth(u[i])>growth(u[src[id]]))src[id]=i;}
   if(front<0)return {false,total,u,ehp};total++;U &f=u[front];double enemydef=ed,enemyatk=ea;
   if(src[4]>=0&&!modern)enemydef*=.7;if(src[9]>=0)enemyatk*=.8;
   int attack=rnd(poison*.2);vector<pair<int,int>> heals;
   for(int i=0;i<3;i++)if(u[i].hp>0){U &x=u[i];int sk=x.id;
    if(!modern&&tick%3==0&&(sk==6||sk==7||sk==12)){heals.push_back({sk,i});continue;}
    if(modern&&total%2==0&&sk==6&&src[6]==i)heals.push_back({sk,i});
    double power=x.atk;if(tick%3==0&&sk==1)power*=1.75;if(tick%3==0&&sk==5)power*=1.5;
    int dealt=dmg(power,sk==10?enemydef*.5:enemydef);if(modern&&src[4]>=0)dealt=rnd(dealt*1.15);attack+=dealt;
    if(sk==0)x.hp=min(x.mh,x.hp+rnd(power*.18*.2));if(sk==13)poison=min(18,poison+max(1,rnd(power*.08)));
   }
   int incoming=dmg(enemyatk,f.def);
   if(modern){
    if(total>=ward&&(incoming>=f.mh*.08||f.hp<=f.mh*.5)&&src[12]>=0){f.shield=min(rnd(f.mh*.25),f.shield+rnd(ub(f,u[src[12]])*.075*utility_scale));ward=total+3;}
    if(total>=rescue&&f.hp-max(0,incoming-f.shield)<=f.mh*.35&&src[7]>=0){f.hp=min(f.mh,f.hp+rnd(ub(f,u[src[7]])*.15*utility_scale));rescue=total+5;}
   }
   int blocked=min(f.shield,incoming);f.shield-=blocked;f.hp=max(0,f.hp-incoming+blocked);f.hits++;
   if(f.id==2)poison=min(18,poison+3);if(f.id==14)attack+=rnd(incoming*.25);if(f.id==11&&f.hits%3==0)attack+=dmg(f.atk*1.5,enemydef);if(f.id==8&&f.hp>0)f.hp=min(f.mh,f.hp+rnd(incoming*.15*utility_scale));
   for(auto [sk,s]:heals){int t=-1;for(int i=0;i<3;i++)if(u[i].hp>0&&(t<0||(sk==7&&double(u[i].hp)/u[i].mh<double(u[t].hp)/u[t].mh)))t=i;if(t<0)break;
    if(sk==12)u[t].shield=min(rnd(u[t].mh*.25),u[t].shield+rnd(u[s].atk*.2));else u[t].hp=min(u[t].mh,u[t].hp+(modern?rnd(ub(u[t],u[s])*.035*utility_scale):rnd(u[s].atk*.2*(sk==7?1.:.85))));
   }
   ehp=max(0,ehp-attack);bool alive=false;for(auto x:u)alive|=x.hp>0;
   if(!alive)return {false,total,u,ehp};if(ehp<=0)break;if(tick==600)return {false,total,u,ehp};
  }
 }
 return {true,total,u,ehp};}
int main(int argc,char**argv){string mode=argv[1];
 if(mode=="sample"){for(double sc:{.4,.45,.5,1.}){utility_scale=sc;for(array<int,3> cfg:{array<int,3>{1,0,3},{1,3,5},{1,3,8},{2,0,9},{2,3,10}}){int w=0;double hp=0;long t=0;for(int a:{2,3,8,11,14})for(int b:{0,1,5,10,13})for(int c:{4,6,7,9,12}){auto z=fight({unit(a,cfg[0],cfg[1],0),unit(b,cfg[0],cfg[1],0),unit(c,cfg[0],cfg[1],0)},cfg[2]-1,true);if(z.win){w++;t+=z.ticks;int h=0,m=0;for(auto u:z.u){h+=u.hp;m+=u.mh;}hp+=double(h)/m;}}cout<<sc<<","<<cfg[0]<<","<<cfg[1]<<","<<cfg[2]<<","<<w<<","<<double(t)*1.5/max(1,w)<<","<<hp*100/max(1,w)<<"\n";}}return 0;}
 if(mode=="gate"){
 for(double scale: {0.,.1,.2,.3,.4,.5,.6,.7,.8,1.}){utility_scale=scale;cout<<scale;for(array<int,3> ss: {array<int,3>{1,1,1},{2,1,1},{1,2,1},{1,1,2},{2,2,1},{2,2,2}}){int w=0;for(int a:{2,3,8,11,14})for(int b:{0,1,5,10,13})for(int c:{4,6,7,9,12})w+=fight({unit(a,ss[0],3,0,0,0,0),unit(b,ss[1],3,0,0,0,0),unit(c,ss[2],3,0,0,0,0)},9,true).win;cout<<","<<w;}cout<<"\n";}return 0;}
 if(mode=="cases"){ifstream in(argv[2]);ofstream out(argv[3]);int room,modern;while(in>>room>>modern){array<U,3>us;for(int i=0;i<3;i++){int id,s,l,r,h,a,d;in>>id>>s>>l>>r>>h>>a>>d;us[i]=unit(id,s,l,r,h,a,d);}auto z=fight(us,room-1,modern);out<<int(z.win)<<','<<z.ticks;for(auto u:z.u)out<<','<<u.hp<<','<<u.shield;out<<','<<z.ehp<<'\n';}return 0;}
 int room=stoi(argv[2])-1;ofstream out(argv[3]);vector<U>pools[3];int roles[3][5]={{2,3,8,11,14},{0,1,5,10,13},{4,6,7,9,12}};
 for(int role=0;role<3;role++)for(int id:roles[role])for(int s=1;s<=3;s++)for(int rare=0;rare<(s==3?3:1);rare++)for(int l=0;l<4;l++)pools[role].push_back(unit(id,s,l,rare));
 int comp[4][3]={{0,1,1},{0,1,2},{0,2,2},{2,2,2}};out<<"room,formation,modern,cases,wins,total_win_ticks,total_win_HP_ratio\n";
 for(int k=0;k<4;k++)for(int modern=(k==1?0:1);modern<=1;modern++){
 long long n=0,w=0,t=0;double hp=0;
 for(auto a:pools[comp[k][0]])for(auto b:pools[comp[k][1]])for(auto c:pools[comp[k][2]]){auto z=fight({a,b,c},room,modern);n++;if(z.win){w++;t+=z.ticks;int h=0,m=0;for(auto u:z.u){h+=u.hp;m+=u.mh;}hp+=double(h)/m;}}
 out<<room+1<<','<<k<<','<<modern<<','<<n<<','<<w<<','<<t<<','<<hp<<'\n';out.flush();cerr<<"room "<<room+1<<" comp "<<k<<" modern "<<modern<<" n="<<n<<'\n';}
}

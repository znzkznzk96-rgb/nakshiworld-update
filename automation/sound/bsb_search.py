import re,sys,html,subprocess,urllib.parse
def get(u): return subprocess.run(['curl','-sS','-m','30',u],capture_output=True,text=True).stdout
def search(q):
    s=get("https://bigsoundbank.com/search?q="+urllib.parse.quote(q))
    res=[]
    for blk in re.split(r"<div class='resultat_\d+'>",s)[1:]:
        m=re.search(r"href='/[^']*-s(\d+)\.html'>([^<]+)</a>",blk)
        if not m:continue
        L=re.search(r'Length: (\d+):(\d+)',blk)
        d=re.search(r"</div><div>([^<]{5,140})",blk)
        res.append((m.group(1),html.unescape(m.group(2)),(int(L.group(1))*60+int(L.group(2))) if L else 0,html.unescape(d.group(1)) if d else ''))
    return res
if __name__=='__main__':
    for q in sys.argv[1:]:
        print('##',q)
        for r in search(q)[:12]:print(' ',r[0],r[1],str(r[2])+'s',r[3][:70])

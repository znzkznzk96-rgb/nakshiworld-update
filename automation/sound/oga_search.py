# OpenGameArt CC0 검색: python3 automation/sound/oga_search.py music "calm loop"   (종류: music | sfx)
import re,sys,subprocess,urllib.parse
kind,qs=sys.argv[1],sys.argv[2:]
tid={"music":"12","sfx":"13"}[kind]
for q in qs:
    u=("https://opengameart.org/art-search-advanced?keys="+urllib.parse.quote_plus(q)+
       "&field_art_type_tid%5B%5D="+tid+"&field_art_licenses_tid%5B%5D=4&sort_by=count&sort_order=DESC")
    s=subprocess.run(['curl','-sL','-m','30',u],capture_output=True,text=True).stdout
    print('##',q)
    for m in sorted(set(re.findall(r'href="/content/([^"]+)"[^>]*>([^<]+)',s)))[:12]:
        if 'faq' not in m[0]:print('  ',m[0],'-',m[1])

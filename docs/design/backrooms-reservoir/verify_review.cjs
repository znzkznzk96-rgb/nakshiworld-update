// Verifies the offline gallery's calculation replay against Python results.
const fs=require('fs'),vm=require('vm'),assert=require('assert');
const path=require('path');const dir=__dirname;
const results=JSON.parse(fs.readFileSync(path.join(dir,'model-results.json'),'utf8'));
const elements={};const get=id=>elements[id]??=( {style:{},addEventListener(k,fn){this[k]=fn},showModal(){this.open=true},close(){this.open=false}} );
get('team').value=Object.keys(results.cases)[0];let callback=null;
const zoom=Array.from({length:6},(_,i)=>({addEventListener(k,fn){this[k]=fn},querySelector(){return {src:`image${i}`,alt:`screen${i}`}}}));
const context=vm.createContext({document:{getElementById:get,querySelectorAll:()=>zoom},setInterval(fn){callback=fn;return 1},clearInterval(){callback=null}});
vm.runInContext(fs.readFileSync(path.join(dir,'review-script.js'),'utf8'),context);
for(const [name,c] of Object.entries(results.cases)){
 get('team').value=name;get('team').change();
 assert.equal((get('stages').innerHTML.match(/돌파/g)||[]).length,c.stages.filter(x=>x.win).length);
 get('play').click();let ticks=0;while(callback&&ticks<50){callback();ticks++}
 const end=c.stages[9];assert.equal(ticks,end.ticks,name);
 assert(Math.abs(parseFloat(get('progressbar').style.width)-end.progress)<0.06,name);
 assert(Math.abs(parseFloat(get('hpbar').style.width)-end.hp_pct)<0.06,name);
 assert.equal(get('play').disabled,false);
}
zoom.forEach((z,i)=>{z.click();assert.equal(get('large').src,`image${i}`);assert(get('dialog').open);get('close').click();assert(!get('dialog').open)});
console.log('PASS: 8 replay cases match Python; 6 zoom actions open/close. DOM stub, not browser layout test.');

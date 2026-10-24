"""Patch kv_push_fn in a Node-RED flows JSON: per-detection snapshot history in Firebase (/snaphist/<id>/<key>)."""
import json, sys
src, dst = sys.argv[1], sys.argv[2]
flows = json.load(open(src))
n = [x for x in flows if x.get('id') == 'kv_push_fn']
assert len(n) == 1, 'kv_push_fn not found'
f = n[0]['func']
if 'snaphist' in f:
    print('already patched'); json.dump(flows, open(dst, 'w'), indent=1); sys.exit(0)
a = "const ev=st.last;"
assert a in f
f = f.replace(a, "const key=t=>String(t).replace(/[.:#$\\[\\]\\/]/g,'-');\n" + a)
b = "source:ev.source||'camera'})"
assert b in f
f = f.replace(b, "source:ev.source||'camera',snapshot:'/snaphist/'+id+'/'+key(ev.time)+'.json'})")
c = "body.history=body.history.map(fix);"
assert c in f
f = f.replace(c, "body.history=body.history.map(d=>d&&{...d,snapshot:'/snaphist/'+id+'/'+String(d.time).replace(/[.:#$\\[\\]\\/]/g,'-')+'.json'});")
tail = "return [out];"
assert f.rstrip().endswith(tail)
f = f.rstrip()[:-len(tail)] + """// per-detection snapshot -> /snaphist/<id>/<key> (keep last 30)
const img2=flow.get('kvSnap')||flow.get('kvImage');
if(ev&&ev.time&&img2&&ev.time!==flow.get('kvPushedSnapEvt')&&new Date(ev.time).getFullYear()>2020){
  flow.set('kvPushedSnapEvt',ev.time);
  const k=key(ev.time);
  out.push({url:DB+'/snaphist/'+id+'/'+k+'.json',method:'PUT',headers:{'Content-Type':'application/json'},payload:JSON.stringify(String(img2).replace(/^data:image\\/\\w+;base64,/,'')),kind:'snaphist'});
  const keys=flow.get('kvSnapKeys')||[]; keys.push(k);
  while(keys.length>30){ const old=keys.shift(); out.push({url:DB+'/snaphist/'+id+'/'+old+'.json',method:'DELETE',headers:{},payload:'',kind:'snapdel'}); }
  flow.set('kvSnapKeys',keys);
}
return [out];"""
n[0]['func'] = f
json.dump(flows, open(dst, 'w'), indent=1)
print('patched', len(flows), 'nodes ->', dst)

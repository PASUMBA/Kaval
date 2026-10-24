"""Add Firebase relay push nodes to the Kaval Node-RED flow JSON (idempotent)."""
import json, sys
src = sys.argv[1]; dst = sys.argv[2] if len(sys.argv) > 2 else src
DB = 'https://kaval-ab7b2-default-rtdb.asia-southeast1.firebasedatabase.app'
nodes = json.load(open(src))
nodes = [n for n in nodes if not str(n.get('id','')).startswith('kv_push') and n.get('id') not in ('kv_relay_in','kv_relay_fn','kv_relay_res')]
tab = next(n['z'] for n in nodes if n['id'] == 'kv_api_fn')

push_fn = r"""
// Push post state (and snapshot when it changes) to the cloud relay (Firebase RTDB REST).
const DB=(env.get('KV_RELAY')||'%s').replace(/\/+$/,'');
const id=env.get('KV_ID')||'KDN-01';
const st=flow.get('kv')||{history:[],alertUntil:0,pan:90,tilt:90,tracking:false};
const au=flow.get('kvAudio')||{};
const alert=Date.now()<(st.alertUntil||0);
let battery=Number(env.get('KV_BATTERY')||100);
const body={
  id, name:env.get('KV_NAME')||'Vadakkumbhagam Post',
  battery, alert, issue: battery<15?'Low battery':'',
  pan:st.pan, tilt:st.tilt, tracking:!!st.tracking,
  last_detection: st.last||null,
  history:(st.history||[]).slice(0,10),
  audio:{level:au.level||0, loud:!!au.loud},
  labels: flow.get('kvLastLabels')||[],
  uptime_s: Math.round((Date.now()-(flow.get('kvStart')||Date.now()))/1000),
  pushed: new Date().toISOString(),
  snapshot:'/snaps/'+id+'.json'
};
// relay snapshots are served from the relay, not the camera
const fix=d=>d&&{...d, snapshot:'/snaps/'+id+'.json'};
body.last_detection=fix(body.last_detection); body.history=body.history.map(fix);
const out=[{url:DB+'/posts/'+id+'.json', method:'PUT', headers:{'Content-Type':'application/json'}, payload:JSON.stringify(body), kind:'state'}];
const img=flow.get('kvSnap')||flow.get('kvImage');
if(img && img!==flow.get('kvPushedSnap')){
  flow.set('kvPushedSnap',img);
  const b64=String(img).replace(/^data:image\/\w+;base64,/,'');
  out.push({url:DB+'/snaps/'+id+'.json', method:'PUT', headers:{'Content-Type':'application/json'}, payload:JSON.stringify(b64), kind:'snap'});
}
return [out];
""" % DB

res_fn = r"""
const s=flow.get('kvPushStat')||{};
s.last={kind:msg.kind, code:msg.statusCode, time:new Date().toISOString()};
if(msg.statusCode===200){ s.ok=s.last.time; s.okCount=(s.okCount||0)+1; } else { s.err=s.last; s.errCount=(s.errCount||0)+1; }
flow.set('kvPushStat',s);
return null;
"""

relay_fn = r"""
msg.headers={'Content-Type':'application/json','Access-Control-Allow-Origin':'*'};
msg.payload=flow.get('kvPushStat')||{note:'no push yet'};
return msg;
"""

X, Y = 120, 1500
nodes += [
 {"id":"kv_push_tick","type":"inject","z":tab,"name":"every 3s","props":[{"p":"payload"}],"repeat":"3","crontab":"","once":True,"onceDelay":"5","topic":"","payload":"","payloadType":"date","x":X,"y":Y,"wires":[["kv_push_fn"]]},
 {"id":"kv_push_fn","type":"function","z":tab,"name":"state -> relay (Firebase)","func":push_fn,"outputs":1,"timeout":0,"noerr":0,"initialize":"","finalize":"","libs":[],"x":X+220,"y":Y,"wires":[["kv_push_req"]]},
 {"id":"kv_push_req","type":"http request","z":tab,"name":"PUT relay","method":"use","ret":"txt","paytoqs":"ignore","url":"","tls":"","persist":True,"proxy":"","insecureHTTPParser":False,"authType":"","senderr":True,"headers":[],"x":X+460,"y":Y,"wires":[["kv_push_res"]]},
 {"id":"kv_push_res","type":"function","z":tab,"name":"push status","func":res_fn,"outputs":1,"timeout":0,"noerr":0,"initialize":"","finalize":"","libs":[],"x":X+640,"y":Y,"wires":[[]]},
 {"id":"kv_relay_in","type":"http in","z":tab,"name":"GET /api/relay","url":"/api/relay","method":"get","upload":False,"swaggerDoc":"","x":X,"y":Y+60,"wires":[["kv_relay_fn"]]},
 {"id":"kv_relay_fn","type":"function","z":tab,"name":"push stats","func":relay_fn,"outputs":1,"timeout":0,"noerr":0,"initialize":"","finalize":"","libs":[],"x":X+220,"y":Y+60,"wires":[["kv_relay_res"]]},
 {"id":"kv_relay_res","type":"http response","z":tab,"name":"","statusCode":"","headers":{},"x":X+420,"y":Y+60,"wires":[]},
]
json.dump(nodes, open(dst,'w'), indent=1)
print(len(nodes),'nodes written to',dst)

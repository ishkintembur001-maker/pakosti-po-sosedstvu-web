import struct,json,os,re
p=os.path.join(os.path.dirname(__file__),'../assets/models/apartment_cast.glb')
data=open(p,'rb').read();n=struct.unpack_from('<I',data,12)[0];doc=json.loads(data[20:20+n]);tail=data[20+n:]
script=open(os.path.join(os.path.dirname(__file__),'build_assets.py')).read()
def linear(v):return v/12.92 if v<.04045 else ((v+.055)/1.055)**2.4
colors={name:[linear(int(h[i:i+2],16)/255) for i in (0,2,4)]+[1] for name,h in re.findall(r"mat\('([^']+)','([0-9a-fA-F]{6})'",script)}
for m in doc['materials']:
 pbr=m.setdefault('pbrMetallicRoughness',{})
 if 'baseColorTexture' not in pbr:
  pbr['baseColorFactor']=colors[m['name']]
new=json.dumps(doc,separators=(',',':')).encode();new+=b' '*((-len(new))%4)
out=struct.pack('<III',0x46546c67,2,20+len(new)+len(tail))+struct.pack('<II',len(new),0x4e4f534a)+new+tail
open(p,'wb').write(out)
print('GLTF_BASE_COLOR_FACTORS_FIXED')

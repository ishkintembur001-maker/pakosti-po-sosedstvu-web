from PIL import Image,ImageDraw,ImageFilter
import random,math,os
random.seed(77);D=os.path.join(os.path.dirname(__file__),'textures');os.makedirs(D,exist_ok=True)
N=512
for name,base in [('oak',(128,86,54)),('walnut',(76,48,33)),('hoodie',(31,99,110)),('denim',(48,65,87)),('cap',(162,54,44)),('wallpaper',(94,115,91)),('upholstery',(122,62,52)),('plaid',(124,47,43)),('shorts',(55,77,104)),('tile',(106,142,133))]:
 im=Image.new('RGB',(N,N));pix=im.load()
 for y in range(N):
  for x in range(N):
   noise=random.uniform(-3.5,3.5);v=0
   if name in ('oak','walnut'):
    v=9*math.sin(x*.12+4*math.sin(y*.012))+4*math.sin(x*.9+1.5*math.sin(y*.03))+2*math.sin(x*2.3+y*.01)
    if x%128<2:v-=22
   elif name in ('plaid','shorts','upholstery'):
    period=96 if name=='plaid' else 80
    xx=x%period;yy=y%period
    if xx<30:v-=20
    if yy<30:v-=20
    if 35<xx<39 or 35<yy<39:v+=38
    if 43<xx<46 or 43<yy<46:v+=15
    v+=2 if (x+y)%3==0 else -1
   elif name=='tile':
    v=3*math.sin(x*.035)*math.cos(y*.04)
    if x%128<3 or y%128<3:v=-35
   elif name in ('hoodie','denim','cap'):
    v=(4 if (x+y*2)%5<2 else -3)+2*math.sin(y*2)
   else:v=2*math.sin(x*2)+2*math.cos(y*2)
   pix[x,y]=tuple(max(0,min(255,int(c+v+noise))) for c in base)
 if name=='wallpaper':
  d=ImageDraw.Draw(im)
  for y in range(-64,576,96):
   for x in range(-64,576,64):
    xx=x+(32 if (y//96)%2 else 0)
    d.line([(xx,y),(xx-18,y+25),(xx,y+48),(xx+18,y+25),(xx,y)],fill=(128,143,109),width=2)
    d.ellipse((xx-5,y+15,xx+5,y+33),outline=(134,145,112),width=2)
    for s in [-1,1]:d.arc((xx+s*8-10,y+25,xx+s*8+10,y+48),0,280,fill=(126,140,108),width=2)
 im.save(os.path.join(D,name+'.png'),optimize=True)
# Ornamental rug: exact UVs, muted red field, medallion, borders, wool grain.
im=Image.new('RGB',(768,512),(112,44,43));d=ImageDraw.Draw(im)
for inset,color,width in [(8,(181,135,83),5),(20,(53,76,75),16),(40,(197,157,106),4),(49,(145,91,63),10),(65,(189,145,90),2)]:d.rectangle((inset,inset,767-inset,511-inset),outline=color,width=width)
for x in range(36,740,28):
 for y in [30,482]:d.polygon([(x,y-9),(x+9,y),(x,y+9),(x-9,y)],fill=(194,151,94))
for y in range(50,480,28):
 for x in [30,738]:d.polygon([(x,y-9),(x+9,y),(x,y+9),(x-9,y)],fill=(194,151,94))
for x in range(99,700,54):
 for y in range(96,450,54):
  d.polygon([(x,y-7),(x+8,y),(x,y+7),(x-8,y)],outline=(178,117,73))
for sz,col in [(164,(190,143,86)),(142,(44,73,70)),(115,(182,126,72)),(96,(113,50,44)),(58,(200,162,106)),(31,(49,76,70))]:
 d.polygon([(384,256-sz),(384+sz*1.1,256),(384,256+sz),(384-sz*1.1,256)],fill=col)
p=im.load()
for y in range(512):
 for x in range(768):
  v=random.randint(-5,5)+(2 if y%2 else -2);p[x,y]=tuple(max(0,min(255,c+v)) for c in p[x,y])
im.save(os.path.join(D,'rug.png'),optimize=True)
print('TEXTURES_OK')

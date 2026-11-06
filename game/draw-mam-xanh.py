"""Build the original Mầm Xanh terrain sprites. Requires Pillow."""
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[1] / 'assets' / 'mam-xanh'
OUT.mkdir(exist_ok=True)
fall=Image.new('RGBA',(96,32))
for f in range(6):
    tile=Image.new('RGBA',(16,32),'#62bfcb')
    d=ImageDraw.Draw(tile)
    d.rectangle((0,0,2,31),fill='#3e91a8')
    d.rectangle((13,0,15,31),fill='#3c93ab')
    for x,offset,length in [(3,0,8),(6,13,10),(9,20,6),(11,7,9)]:
        for j in range(length):
            y=(offset+f*5+j)%32
            d.point((x,y),fill='#c7f3e3' if j<length-2 else '#8cdbd6')
    fall.paste(tile,(f*16,0))
fall.save(OUT/'fall.png')
foam=Image.new('RGBA',(192,16))
for f in range(4):
    tile=Image.new('RGBA',(48,16))
    d=ImageDraw.Draw(tile)
    d.ellipse((2-f//2,5,45+f//2,12+f),outline='#a4e3dd')
    for x,y,w in [(5,8,5),(12,5,8),(23,6,9),(34,7,7),(40,10,4)]:
        d.rectangle((x,y+(f+x)%3,x+w,y+(f+x)%3+2),fill='#e7f6df')
    foam.paste(tile,(f*48,0))
foam.save(OUT/'foam.png')

soil=Image.new('RGBA',(144,32))
for wet in range(2):
    base, shine, groove = (('#81523e','#a57452','#5a3d35') if wet else ('#b67750','#dda36a','#895538'))
    for i in range(9):
        col,row=i%3,i//3
        tile=Image.new('RGBA',(16,16))
        d=ImageDraw.Draw(tile)
        l,t,r,b= (2 if col==0 else 0,2 if row==0 else 0,13 if col==2 else 15,13 if row==2 else 15)
        d.rectangle((l,t,r,b),fill=base)
        for y in range(3,14,4):
            if t<=y<b:
                d.line((l,y,r,y),fill=shine)
                d.line((l,y+1,r,y+1),fill=groove)
        soil.paste(tile,(16*i,16*wet))
soil.save(OUT/'soil.png')

fences = Image.new('RGBA',(112,16))
for i, dirs in enumerate(['ew','ns','es','ws','en','wn','']):
    tile=Image.new('RGBA',(16,16))
    d=ImageDraw.Draw(tile)
    for way in dirs:
        if way in 'ew':
            x0,x1=(0,8) if way=='w' else (8,15)
            for y in (5,10):
                d.rectangle((x0,y,x1,y+2),fill='#84513b')
                d.line((x0,y,x1,y),fill='#e5b77a')
        else:
            y0,y1=(0,8) if way=='n' else (8,15)
            d.rectangle((6,y0,9,y1),fill='#84513b')
            d.line((7,y0,7,y1),fill='#e5b77a')
    posts = [3,12] if not dirs else [8]
    for x in posts:
        d.rectangle((x-1,3,x+1,13),fill='#925a43')
        d.line((x-1,3,x+1,3),fill='#f2c38a')
    fences.paste(tile,(16*i,0))
fences.save(OUT/'fences.png')



ground=Image.new('RGBA',(64,32))
for i,(green,shade,path,chip) in enumerate([
    ('#9abf72','#799d5b','#ddb37e','#c19366'),
    ('#91b65c','#719548','#e5c08b','#c89e65'),
    ('#b3b173','#93915d','#d8af77','#b98558'),
    ('#dce6de','#b5cac1','#c9c2a9','#afa892'),
]):
    for row,(base,detail) in enumerate([(green,shade),(path,chip)]):
        tile=Image.new('RGBA',(16,16),base)
        d=ImageDraw.Draw(tile)
        d.point([(1,9),(7,2),(13,11)],fill=detail)
        d.line((9,6,11,6),fill=detail)
        ground.paste(tile,(i*16,row*16))
ground.save(OUT/'ground.png')
for kind,fruit in [('apple','#c85751'),('cherry','#ce668e'),('orange','#ec963b')]:
    sheet=Image.new('RGBA',(128,48))
    for f,(dark,leaf,light) in enumerate([
        ('#526e4f','#88ae67','#bfd68a'),('#436c4d','#74a659','#a9c66a'),
        ('#806047','#c38b54','#e9b574'),('#758a82','#a5b8a7','#e3ebd4'),
    ]):
        tree=Image.new('RGBA',(32,48))
        d=ImageDraw.Draw(tree)
        d.polygon([(12,44),(14,28),(18,27),(19,43),(22,46),(10,46)],fill='#684738')
        d.line((16,31,16,44),fill='#aa7852',width=2)
        for x,y,w,h in [(1,15,19,17),(11,13,19,18),(6,5,21,19),(5,20,24,14)]:
            d.ellipse((x,y,x+w,y+h),fill=dark)
            d.ellipse((x+1,y+1,x+w-2,y+h-3),fill=leaf)
            d.line((x+4,y+4,x+9,y+2),fill=light,width=2)
        for x,y in [(8,19),(15,12),(22,21),(13,26),(25,26)]:
            color='#f4b7c2' if f==0 and kind=='cherry' else light if f!=1 else fruit
            d.rectangle((x,y,x+2,y+2),fill=color)
        sheet.paste(tree,(32*f,0))
    sheet.save(OUT/f'{kind}.png')


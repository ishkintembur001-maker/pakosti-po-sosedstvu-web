from pathlib import Path
import shutil,re
root=Path(__file__).resolve().parents[1];dist=root/'dist'
p=dist/'index.html';s=p.read_text()
s=s.replace('<html lang="en">','<html lang="ru">')
s=re.sub(r'<title>.*?</title>','<title>Пакости по соседству — Tembur Games</title>',s)
s=s.replace('width=device-width, user-scalable=no, initial-scale=1.0','width=device-width, user-scalable=no, initial-scale=1.0, viewport-fit=cover')
s=s.replace('</style>','''
body { overscroll-behavior: none; background:#242c32; }
#rotate-hint { display:none; position:fixed; top:max(18px,env(safe-area-inset-top)); left:20px;right:20px; text-align:center; color:#e6d6b5;font:14px system-ui;pointer-events:none;z-index:3; }
@media (orientation:portrait) and (max-width:700px) { #rotate-hint {display:block;} }
</style>''',1)
s=s.replace('<body>','<body><div id="rotate-hint">Для удобной игры поверни телефон горизонтально ↻</div>')
preview=root/'evidence'/'gameplay.png'
if preview.exists():
 shutil.copy2(preview,dist/'preview.png');s=s.replace('src="index.png"','src="preview.png"')
p.write_text(s)
(dist/'.nojekyll').touch()
print('WEB_SHELL_OK')

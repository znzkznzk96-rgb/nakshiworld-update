import sys;sys.path.insert(0,'/tmp/cut1');from gen import *
run('researcher',{"description":"back view of a young female researcher standing still, seen from behind, full body, wearing a yellow hard hat with a small teal headlamp on the front, brown hair under the helmet, mustard yellow work vest over dark clothes, holding a small notebook in front of her, dark boots, pixel art character, centered, no background",
 "image_size":{"width":96,"height":96},"no_background":True,"seed":2211,
 "reference_images":[ref('/tmp/cut1/ref/idle_128.png',128,128,"same character: yellow hard hat with teal headlamp, brown hair, mustard vest; show her from behind")],
 "style_image":ref('/tmp/cut1/out/corridor_0.png',384,688),"style_options":{"color_palette":False,"outline":True,"detail":True,"shading":True}})

extends RefCounted
# Render-time backing: restore enclosed black body pixels without changing source art.
# Exterior transparency remains untouched; sheets are processed frame by frame.
static func prepare(texture: Texture2D,frame_size: int) -> Texture2D:
	var image: Image=texture.get_image()
	if image.is_compressed(): image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	var bytes: PackedByteArray=image.get_data()
	var width: int=image.get_width();var height: int=image.get_height()
	for sy in range(0,height,frame_size):
		for sx in range(0,width,frame_size):
			var w: int=mini(frame_size,width-sx);var h: int=mini(frame_size,height-sy)
			var exterior=PackedByteArray();exterior.resize(w*h)
			var queue=PackedInt32Array()
			for y in h:
				for x in w:
					if x!=0 and y!=0 and x!=w-1 and y!=h-1: continue
					if bytes[((sy+y)*width+sx+x)*4+3]==0:
						exterior[y*w+x]=1;queue.append(y*w+x)
			var cursor: int=0
			while cursor<queue.size():
				var pos: int=queue[cursor];cursor+=1
				var x: int=pos%w;var y: int=pos/w
				for step in [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1)]:
					var nx: int=x+step.x;var ny: int=y+step.y
					if nx<0 or ny<0 or nx>=w or ny>=h: continue
					var n: int=ny*w+nx
					if exterior[n]==0 and bytes[((sy+ny)*width+sx+nx)*4+3]==0:
						exterior[n]=1;queue.append(n)
			for y in h:
				for x in w:
					var i: int=((sy+y)*width+sx+x)*4
					if exterior[y*w+x]==0 and bytes[i+3]==0:
						bytes[i]=9;bytes[i+1]=12;bytes[i+2]=20;bytes[i+3]=255
	return ImageTexture.create_from_image(Image.create_from_data(width,height,false,Image.FORMAT_RGBA8,bytes))

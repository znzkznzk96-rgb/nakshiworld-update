extends SceneTree

# Offline sprite rig: only samples approved original texture pixels.
# No AI-generated frame, inferred background, palette replacement or random effects.
func _initialize():
	var report = {"method":"approved-original texture inverse-mapped rig", "frames":16, "fps":16, "paid_requests":0, "engine":Engine.get_version_info().string, "species":[]}
	for id in ["14", "17", "18"]:
		var src = Image.load_from_file("res://"+id+".png")
		src.convert(Image.FORMAT_RGBA8)
		var center = {"14":100.0,"17":76.0,"18":87.0}[id]
		var bend_start = {"14":68.0,"17":71.0,"18":100.0}[id]
		var amp = {"14":19.0,"17":24.0,"18":29.0}[id]
		var width = src.get_width()+64
		var height = src.get_height()+80
		DirAccess.make_dir_recursive_absolute("res://output/"+id)
		var atlas = Image.create(width*4,height*4,false,Image.FORMAT_RGBA8)
		atlas.fill(Color.TRANSPARENT)
		var bboxes = []
		for frame in range(16):
			var phase = TAU*frame/16.0
			var img = Image.create(width,height,false,Image.FORMAT_RGBA8)
			img.fill(Color.TRANSPARENT)
			for x in range(width):
				var sx = x-32
				if sx<0 or sx>=src.get_width(): continue
				var t = clampf((sx-bend_start)/(215.0-bend_start),0.0,1.0)
				# Travelling wave: front stays anchored, rear has progressively larger bends.
				var offset = amp*pow(t,1.6)*sin(phase-2.1*(1.0-t))
				# Fin spread is controlled around a fixed body axis, preserving fin topology.
				var fin_scale = 1.0
				if id=="14":fin_scale=0.74+0.26*cos(phase)
				elif id=="18":fin_scale=0.91+0.09*cos(phase-0.65)
				for y in range(height):
					var syf = float(y-40)-offset
					var dist = syf-center
					# Do not compress the body when flapping long fins.
					if absf(dist)>18.0:
						syf=center+signf(dist)*(18.0+(absf(dist)-18.0)/fin_scale)
					var sy = roundi(syf)
					if sy>=0 and sy<src.get_height():img.set_pixel(x,y,src.get_pixel(sx,sy))
			var box=img.get_used_rect()
			assert(box.position.x>0 and box.position.y>0 and box.end.x<width and box.end.y<height)
			bboxes.append([box.position.x,box.position.y,box.size.x,box.size.y])
			img.save_png("res://output/%s/frame-%02d.png" % [id,frame])
			atlas.blit_rect(img,Rect2i(0,0,width,height),Vector2i((frame%4)*width,(frame/4)*height))
		atlas.save_png("res://output/"+id+"/atlas.png")
		# Four extreme poses at native scale plus exact integer enlargement.
		var contact=Image.create(width*4,height,false,Image.FORMAT_RGBA8)
		contact.fill(Color("202d41"))
		for j in range(4):
			var f=Image.load_from_file("res://output/%s/frame-%02d.png" % [id,j*4])
			contact.blend_rect(f,Rect2i(0,0,width,height),Vector2i(j*width,0))
		contact.save_png("res://output/"+id+"/native.png")
		contact.resize(contact.get_width()*2,contact.get_height()*2,Image.INTERPOLATE_NEAREST)
		contact.save_png("res://output/"+id+"/nearest2.png")
		var original_box=src.get_used_rect()
		var scale=156.0/original_box.size.x
		var fw=roundi(width*scale)
		var fh=roundi(height*scale)
		for frame in range(16):
			var f=Image.load_from_file("res://output/%s/frame-%02d.png" % [id,frame])
			f.resize(fw,fh,Image.INTERPOLATE_NEAREST)
			f.save_png("res://output/%s/fight-%02d.png" % [id,frame])
		report.species.append({"id":id,"source_canvas":[src.get_width(),src.get_height()],"output_canvas":[width,height],"anchor":[32,40],"bend_start":bend_start,"tail_amplitude_px":amp,"body_center":center,"frame_bboxes":bboxes,"fight_scale":scale,"fight_canvas":[fw,fh],"source_colors_only":true,"game_applied":false})
	var f=FileAccess.open("res://output/RIG_REPORT.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"\t"))
	print("RIG_COMPLETE 3 species 48 frames, original texture only")
	quit()

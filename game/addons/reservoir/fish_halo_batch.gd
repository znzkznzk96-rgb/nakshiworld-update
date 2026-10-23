extends RefCounted
# Preserve triangle order and blend layers; only batch submission work.
const DIRECTIONS = [Vector2(1,0), Vector2(1,1), Vector2(0,1), Vector2(-1,1), Vector2(-1,0), Vector2(-1,-1), Vector2(0,-1), Vector2(1,-1)]
static func queue(m, quads: Array, tex: Texture2D, grade: int, t: float) -> void:
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	points.resize(quads.size()*4)
	uvs.resize(quads.size()*4)
	for q in quads.size():
		var v: PackedVector2Array = quads[q][0]
		for j in 4:
			points[q*4+j]=v[j]
			uvs[q*4+j]=quads[q][1][j]
		if absf((v[1]-v[0]).cross(v[2]-v[0])) >= 0.001:
			indices.append_array(PackedInt32Array([q*4,q*4+1,q*4+2]))
		if absf((v[2]-v[0]).cross(v[3]-v[0])) >= 0.001:
			indices.append_array(PackedInt32Array([q*4,q*4+2,q*4+3]))
	if indices.is_empty(): return
	var pulse := fposmod(t/1500.0,1.0)
	for layer in range(3,0,-1):
		var radius := roundf(1.0+(layer-1+pulse)*(1.0+grade*0.45))
		var opacity := (0.27 if layer==1 else 0.11 if layer==2 else 0.035)*(1.0-pulse*0.35)
		for i in 8:
			var offset: Vector2 = DIRECTIONS[i]*radius
			var shifted := points.duplicate()
			for j in shifted.size():
				shifted[j] += offset
				if not m.ui_demo: shifted[j] += Vector2(0,m.oy)
			m.ui_commands.append(["triangles",indices,shifted,PackedColorArray([m._aura_col(grade,t,opacity,i)]),uvs,tex])

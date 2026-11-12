extends RefCounted
const STRIDE=[20,20,28,27,27,26,23,22]
func update(r: Dictionary, dt: float) -> void :
	var old: float = r.x
	if r.wait > 0: r.wait = maxf(0, r.wait - dt);r.velocity = 0
	elif r.state == 1: r.state = 2;r.velocity = 0
	elif r.state == 3:
		var dir: float = float(r.local_dir)
		r.velocity = move_toward(float(r.velocity), float(r.speed) * dir, float(r.speed) * 4 * dt)
		r.x += r.velocity * dt
		if r.x < r.local_min or r.x > r.local_max:
			r.x = clampf(r.x, float(r.local_min), float(r.local_max));r.local_dir = - dir;r.wait = randf_range(1.2, 2.8);r.velocity = 0
	else:
		var signum: = 1.0 if r.state == 0 else -1.0
		r.velocity = move_toward(float(r.velocity), float(r.speed) * signum, float(r.speed) * 4 * dt)
		r.x += r.velocity * dt
		if r.state == 0 and not r.paused and r.x >= r.pause_at:
			r.paused = true
			if randf() < 0.3: r.wait = randf_range(0.8, 2.2);r.velocity = 0
		if r.state == 0 and r.x >= 1140: r.x = 1140.0;r.state = 1;r.wait = randf_range(7, 12);r.velocity = 0
	r.reward_t = maxf(0.0, float(r.reward_t) - dt)
	r.step += absf(r.x - old) / STRIDE[r.group] * 8.0

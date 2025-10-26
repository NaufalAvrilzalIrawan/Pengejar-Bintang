extends Area2D

signal collected(body, self_ref)

var is_collected = false

func _on_body_entered(body):
	if is_collected:
		return
	if body.name == "Player":
		is_collected = true
		emit_signal("collected", body, self)

		# 🔹 Hentikan animasi idle kalau ada
		if has_node("AnimationPlayer"):
			var anim_player = $AnimationPlayer
			if anim_player.is_playing():
				anim_player.stop()
		
		# 🔹 Mainkan efek partikel
		if has_node("ExplosionParticles"):
			var p = $ExplosionParticles
			p.emitting = true
		
		# 🔹 Sembunyikan sprite biar koin seolah meledak
		if has_node("AnimatedSprite2D"):
			$AnimatedSprite2D.hide()
		
		# 🔹 Tunggu efek partikel selesai baru hapus
		await get_tree().create_timer(1).timeout
		queue_free()

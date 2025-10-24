extends Area2D

@export var speed: float = 400.0  # kecepatan proyektil
@export var direction: Vector2 = Vector2.LEFT  # arah default (ke kiri)

var deflected := false

func _ready() -> void:
	direction = direction.normalized()

func _physics_process(delta: float) -> void:
	if not deflected:
		position += direction * speed * delta

func _on_area_entered(area: Area2D) -> void:
	if deflected:
		return
	
	if area.name == "Barrier":
		deflected = true
		
		# 🔹 Beri tahu barrier bahwa proyektil berhasil ditangkis
		if area.has_method("on_projectile_blocked"):
			area.on_projectile_blocked()
		
		# 🔹 Hentikan pergerakan & deteksi tabrakan
		set_physics_process(false)
		set_deferred("monitorable", false)
		set_deferred("monitoring", false)

		var collision = find_child("CollisionPolygon2D")
		if collision:
			collision.disabled = true
		
		# 🔹 Sembunyikan sprite proyektil
		if has_node("AnimatedSprite2D"):
			$AnimatedSprite2D.hide()
		
		# 🔹 Aktifkan efek partikel defleksi
		if has_node("DeflectedParticles"):
			var particles = $DeflectedParticles
			particles.emitting = true
		
		# 🔹 Tunggu efek partikel selesai (misal 1 detik), lalu hapus
		await get_tree().create_timer(1).timeout
		queue_free()

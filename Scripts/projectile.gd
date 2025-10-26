extends Area2D

@export var speed: float = 400.0  # kecepatan proyektil
@export var direction: Vector2 = Vector2.LEFT  # arah default (ke kiri)
@onready var Block: AudioStreamPlayer2D = $Block
@onready var DeflectedParticles: CPUParticles2D = $DeflectedParticles
@onready var TrailParticles: CPUParticles2D = $TrailParticles

var deflected := false

func _ready() -> void:
	direction = direction.normalized()
	add_to_group("projectiles")

func _physics_process(delta: float) -> void:
	if not deflected:
		position += direction * speed * delta

func _on_area_entered(area: Area2D) -> void:
	if deflected:
		return
	
	if area.name == "Barrier":
		deflected = true
		
		# Beri tahu barrier bahwa proyektil berhasil ditangkis
		if area.has_method("on_projectile_blocked"):
			area.on_projectile_blocked()
			Block.play()
		
		# Hentikan pergerakan & deteksi tabrakan
		set_physics_process(false)
		set_deferred("monitorable", false)
		set_deferred("monitoring", false)

		var collision = find_child("CollisionShape2D")
		if collision:
			collision.disabled = true
		
		# Sembunyikan sprite proyektil
		if has_node("AnimatedSprite2D"):
			$AnimatedSprite2D.hide()
			DeflectedParticles.emitting = true
			TrailParticles.emitting = false
		
		# Tunggu efek partikel selesai (misal 1 detik), lalu hapus
		await get_tree().create_timer(1).timeout
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		get_tree().root.get_node("Main").game_over()
		queue_free() # Destroy the projectile

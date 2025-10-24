extends Node2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
signal projectile_blocked  # sinyal ke scene utama

func _ready() -> void:
	if anim:
		anim.play("active")

# Fungsi dipanggil dari scene utama saat durasi habis
func play_end_animation() -> void:
	if anim:
		anim.stop()
		anim.play("end")
		await anim.animation_finished
	queue_free()

# Dipanggil oleh projectile saat barrier menangkis serangan
func on_projectile_blocked() -> void:
	emit_signal("projectile_blocked")

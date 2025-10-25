extends Node2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx_activate: AudioStreamPlayer2D = $SFX_Activate
@onready var sfx_deactivate: AudioStreamPlayer2D = $SFX_Deactivate
signal projectile_blocked  # sinyal ke scene utama

func _ready() -> void:
	if anim:
		anim.play("active")
	if sfx_activate:
		sfx_activate.play()

# Fungsi dipanggil dari scene utama saat durasi habis
func play_end_animation() -> void:
	if anim:
		anim.stop()
		anim.play("end")
	if sfx_deactivate:
		sfx_deactivate.play()
	await sfx_deactivate.finished
	queue_free()

# Dipanggil oleh projectile saat barrier menangkis serangan
func on_projectile_blocked() -> void:
	emit_signal("projectile_blocked")

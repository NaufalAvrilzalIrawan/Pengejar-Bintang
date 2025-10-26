extends Node2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx_activate: AudioStreamPlayer2D = $SFX_Activate
@onready var sfx_deactivate: AudioStreamPlayer2D = $SFX_Deactivate
signal projectile_blocked  # sinyal ke scene utama
signal enemy_destroyed

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

func _on_area_entered(area):
	# If the area that entered is "destroyable"
	if area.is_in_group("destroyable"):
		# If it's an enemy, tell the main script
		if area.is_in_group("enemy"):
			emit_signal("enemy_destroyed")
		# DUARRR MERDEKA!!!!
		area.queue_free()

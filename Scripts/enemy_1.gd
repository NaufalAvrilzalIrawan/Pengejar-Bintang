extends Area2D

const PROJECTILE_SCENE := preload("res://Scenes/projectile.tscn")

@onready var muzzle: Marker2D = $Muzzle
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var player_in_range: bool = false
var is_shooting: bool = false


func _ready():
	# Pastikan sinyal animation_finished terhubung
	if not anim.is_connected("animation_finished", Callable(self, "_on_AnimatedSprite2D_animation_finished")):
		anim.animation_finished.connect(_on_AnimatedSprite2D_animation_finished)

func _on_detection_zone_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		if not is_shooting:
			start_shoot_cycle()

func _on_detection_zone_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false

func start_shoot_cycle():
	anim.frame = 0
	is_shooting = true
	anim.play("shoot") # dimainkan sekali karena looping sudah dimatikan di _ready()

func _on_AnimatedSprite2D_animation_finished():
	if anim.animation == "shoot":
		shoot()
		is_shooting = false
		anim.play("reform") 

func shoot():
	var projectile = PROJECTILE_SCENE.instantiate()
	projectile.global_position = muzzle.global_position
	get_tree().root.add_child(projectile)
	print_debug("Projectile fired at:", muzzle.global_position)

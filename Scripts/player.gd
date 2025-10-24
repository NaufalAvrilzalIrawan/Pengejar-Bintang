extends CharacterBody2D

const GRAVITY : int = 2800
const JUMP_SPEED : int = -1200
const DIVE_SPEED : int = 1000

var barrier_scene = preload("res://Scenes/barrier.tscn")
var barrier_instance = null
var has_barrier: bool = false

var q_just_pressed = false
var q_just_released := true

@onready var collision_running: CollisionShape2D = $CollisionShapeRunning
@onready var collision_jumping: CollisionShape2D = $CollisionShapeJumping
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var RunParticle: CPUParticles2D = $Particles

var last_frame := -1
var last_anim := ""

func _physics_process(delta):
	velocity.y += GRAVITY * delta

	if is_on_floor():
		collision_running.disabled = false
		collision_jumping.disabled = true

		if Input.is_action_pressed("jump"):
			velocity.y = JUMP_SPEED
			$JumpAudio.play()
			anim.play("Jump")
		else:
			anim.play("Run")
	else:
		collision_running.disabled = true
		collision_jumping.disabled = false

		if Input.is_action_just_pressed("dive"):
			velocity.y = DIVE_SPEED
			anim.play("Dive") # pastikan animasi Dive ada

	move_and_slide()

	_check_particle_activation()


func _check_particle_activation():
	var current_anim = anim.animation
	var current_frame = anim.frame

	# Deteksi perubahan animasi
	if current_anim != last_anim:
		# Matikan semua partikel saat animasi berganti
		RunParticle.emitting = false
		last_frame = -1
		last_anim = current_anim

	# Cek frame pertama animasi tertentu
	if current_anim == "Run" :
		if current_frame == 0 and last_frame != 0:
			RunParticle.emitting = true
		elif current_frame == 5 and last_frame != 0:
			RunParticle.emitting = true 
		elif current_frame != 0:
			RunParticle.emitting = false
	last_frame = current_frame

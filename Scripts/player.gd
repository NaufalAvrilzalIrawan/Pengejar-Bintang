extends CharacterBody2D

# ======== KONSTANTA GERAK =========
const GRAVITY : int = 2800
const JUMP_SPEED : int = -1050
const DIVE_SPEED : int = 900

# ======== BARRIER =========
var barrier_scene = preload("res://Scenes/barrier.tscn")
var barrier_instance = null
var has_barrier: bool = false
var is_dead: bool = false

# ======== NODE REF =========
@onready var collision_running: CollisionShape2D = $CollisionShapeRunning
@onready var collision_jumping: CollisionPolygon2D = $CollisionShapeJumping
@onready var collision_falling: CollisionPolygon2D = $CollisionShapeJumping
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var JumpDust: CPUParticles2D = $JumpDust
@onready var StepDust_Left1: CPUParticles2D = $StepDust_Left1
@onready var StepDust_Right1: CPUParticles2D = $StepDust_Right1
@onready var StepDust_Left2: CPUParticles2D = $StepDust_Left2
@onready var StepDust_Right2: CPUParticles2D = $StepDust_Right2
@onready var JumpAudio: AudioStreamPlayer2D = $JumpAudio

# ======== STATUS =========
var was_on_floor := false
var last_step_frame := -1  # untuk deteksi frame langkah sebelumnya


func _physics_process(delta):
	velocity.y += GRAVITY * delta
	if is_dead:
		move_and_slide()  # biar bisa jatuh sedikit sebelum freeze
		return

	if is_on_floor():
		# Jika baru mendarat, mainkan debu mendarat
		collision_running.disabled = false
		collision_jumping.disabled = true
		collision_falling.disabled = true

		if Input.is_action_pressed("jump"):
			velocity.y = JUMP_SPEED
			if JumpAudio:
				JumpAudio.play()
			anim.play("Jump")
			play_jump_dust()
		else:
			anim.play("Run")
			play_run_dust()
	else:
		collision_running.disabled = true
		collision_jumping.disabled = false
		collision_falling.disabled = true

		if Input.is_action_just_pressed("dive"):
			velocity.y = DIVE_SPEED
			anim.play("Dive")  # pastikan animasi Dive ada

	move_and_slide()
	was_on_floor = is_on_floor()


# =========================
#     EFEK DEBU
# =========================

# 💨 Efek debu saat melompat
func play_jump_dust():
	if JumpDust:
		JumpDust.restart()
		JumpDust.emitting = true
# 💨 Efek debu sinkron dengan animasi langkah kaki
func play_run_dust():
	if not is_on_floor():
		if StepDust_Left1:
			StepDust_Left1.disabled = true
		if StepDust_Right1:
			StepDust_Right1.disabled = true
		if StepDust_Left2:
			StepDust_Left2.disabled = true
		if StepDust_Right2:
			StepDust_Right2.disabled = true
		return
	if anim.animation != "Run":
		return
	
	# Frame langkah — sesuaikan dengan animasi kamu
	var left_step_frames1 = [0]   # kaki kiri injak tanah
	var right_step_frames1 = [3]  # kaki kanan injak tanah
	var left_step_frames2 = [5]
	var right_step_frames2 = [8]
	
	# Saat frame kaki kiri menyentuh tanah
	if anim.frame in left_step_frames1 and anim.frame != last_step_frame:
		if StepDust_Left1:
			StepDust_Left1.restart()
			StepDust_Left1.emitting = true
		last_step_frame = anim.frame
	# Saat frame kaki kanan menyentuh tanah
	elif anim.frame in right_step_frames1 and anim.frame != last_step_frame:
		if StepDust_Right1:
			StepDust_Right1.restart()
			StepDust_Right1.emitting = true
		last_step_frame = anim.frame
	elif anim.frame in left_step_frames2 and anim.frame != last_step_frame:
		if StepDust_Left2:
			StepDust_Left2.restart()
			StepDust_Left2.emitting = true
		last_step_frame = anim.frame
	elif anim.frame in right_step_frames2 and anim.frame != last_step_frame:
		if StepDust_Right2:
			StepDust_Right2.restart()
			StepDust_Right2.emitting = true
		last_step_frame = anim.frame

	elif anim.frame not in left_step_frames1 and anim.frame not in right_step_frames1 and anim.frame not in left_step_frames2 and anim.frame not in right_step_frames2:
		last_step_frame = -1

func play_game_over_anim():
	# Aktifkan gravitasi normal supaya jatuh
	is_dead = true 
	velocity = Vector2.ZERO  # reset gerak horizontal
	# Mainkan animasi
	if anim:
		anim.play("Fall")

	collision_running.disabled = true
	collision_jumping.disabled = true
	collision_falling.disabled = false
	# Matikan partikel debu
	if JumpDust: JumpDust.emitting = false
	if StepDust_Left1: StepDust_Left1.emitting = false
	if StepDust_Right1: StepDust_Right1.emitting = false
	if StepDust_Left2: StepDust_Left2.emitting = false
	if StepDust_Right2: StepDust_Right2.emitting = false

	# Putar animasi "Death" (pastikan ada di AnimatedSprite2D)
	if anim:
		anim.play("Fall")

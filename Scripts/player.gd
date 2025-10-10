extends CharacterBody2D

const GRAVITY : int = 2800
const JUMP_SPEED : int = -1200
const DIVE_SPEED : int = 1000
var barrier_scene = preload("res://Scenes/barrier.tscn")
var barrier_instance = null
var has_barrier: bool = false
#@onready var barrier = $Barrier
var q_just_pressed = false
var q_just_released := true
@onready var collision_running: CollisionShape2D = $CollisionShapeRunning
@onready var collision_jumping: CollisionShape2D = $CollisionShapeJumping

func _physics_process(delta):
	velocity.y += GRAVITY*delta
	if is_on_floor():
		collision_running.disabled = false
		collision_jumping.disabled = true
		if Input.is_action_pressed("jump"):
			velocity.y = JUMP_SPEED
			$JumpAudio.play()
			$AnimatedSprite2D.play("Jump")
		else:
			$AnimatedSprite2D.play("Run")
	else:
		collision_running.disabled = true
		collision_jumping.disabled = false
		# --- ADD THIS DIVE CHECK ---
		if Input.is_action_just_pressed("dive"):
			# Immediately set downward velocity for a fast dive
			velocity.y = DIVE_SPEED
			# Optional: Play a dive animation and sound
			$AnimatedSprite2D.play("Dive") # Assumes you create a "Dive" animation
		else:
			# If not diving, just do the regular float/fall animation
			$AnimatedSprite2D.play("Float")
	
	move_and_slide()

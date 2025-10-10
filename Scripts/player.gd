extends CharacterBody2D

const GRAVITY : int = 2800
const JUMP_SPEED : int = -1200
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
		$AnimatedSprite2D.play("Float")
	move_and_slide()

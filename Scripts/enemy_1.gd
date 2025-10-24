extends Area2D


# Preload
const PROJECTILE_SCENE := preload("res://Scenes/projectile.tscn")

const MAX_SHOOT_WAIT_TIME: float = 2.2 # Wait time at slowest player speed
const MIN_SHOOT_WAIT_TIME: float = 0.8 # Wait time at fastest player speed

@onready var shoot_timer: Timer = $ShootTimer
@onready var muzzle: Marker2D = $Muzzle

var player_in_range: bool = false

func init_enemy(current_player_speed: float, min_player_speed: float, max_player_speed: float):
	# Calculate the new wait time based on player speed
	# remap() scales one range of numbers to another
	var new_wait_time = remap(
		current_player_speed,
		min_player_speed,
		max_player_speed,
		MAX_SHOOT_WAIT_TIME,
		MIN_SHOOT_WAIT_TIME
	)
	
	# Set the timer's wait time to our new calculated value
	shoot_timer.wait_time = new_wait_time
	print_debug("New enemy spawned. Shoot timer set to: ", new_wait_time)
	
func _on_detection_zone_body_entered(body):
	# If the player enters detection range, start shooting
	if body.is_in_group("player"):
		player_in_range = true

func _on_detection_zone_body_exited(body):
	# If the player leaves, stop shooting
	if body.is_in_group("player"):
		player_in_range = false

func _on_shoot_timer_timeout():
	# When the timer goes off, shoot if the player is in range
	if player_in_range:
		shoot()

func shoot():
	var projectile = PROJECTILE_SCENE.instantiate()
	# Spawn the projectile at the muzzle's global position
	projectile.global_position = muzzle.global_position
	# Add the projectile to the main scene, not this enemy
	get_tree().root.add_child(projectile)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Get the main scene and call game_over
		get_tree().root.get_node("Main").game_over()

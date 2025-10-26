extends Node2D

@onready var platforms := [
	$PlatformA,
	$PlatformB,
	$PlatformC
]

func _ready():
	# Matikan semua platform dulu
	for p in platforms:
		p.hide()
		for shape in p.get_children():
			if shape is CollisionShape2D:
				shape.disabled = true
	
	# Pilih satu secara acak
	var chosen = platforms[randi() % platforms.size()]
	chosen.show()
	for shape in chosen.get_children():
		if shape is CollisionShape2D:
			shape.disabled = false
			
func get_spawn_points() -> Dictionary:
	var spawns = {
		"coin": [],
		"enemy": [],
		"stone": [],
		"projectile": []
	}
	
	for child in get_children():
		if child.name.begins_with("CoinSpawn"):
			spawns["coin"].append(child.global_position)
		elif child.name.begins_with("EnemySpawn"):
			spawns["enemy"].append(child.global_position)
		elif child.name.begins_with("StoneSpawn"):
			spawns["stone"].append(child.global_position)
		elif child.name.begins_with("ProjectileSpawn"):
			spawns["projectile"].append(child.global_position)
	
	return spawns

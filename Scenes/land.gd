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

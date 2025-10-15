extends Node

#Set Variables
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var moon: Sprite2D = $BG/Moon
@onready var score_label: Label = $BG/Control/LabelScore
@onready var high_score_label: Label = $BG/Control2/LabelHigh
@onready var coin_label: Label = $BG/Control5/LabelCoin
@onready var restart_button: Button = $BG/Control3/Restart
@onready var start_label: Label = $BG/Control4/Start

#Preload Scenes
const STONE_1_SCENE := preload("res://Scenes/stone_1.tscn")
const STONE_2_SCENE := preload("res://Scenes/stone_2.tscn")
const PROJECTILE_SCENE := preload("res://Scenes/projectile.tscn")
const BARRIER_SCENE := preload("res://Scenes/barrier.tscn")
const COIN_SCENE := preload("res://Scenes/coin.tscn")
const LAND_SCENE := preload("res://Scenes/land.tscn")


#Game Configuration
@export var START_POS := Vector2(150, 485)
@export var CAM_START := Vector2(576, 324)
@export var MOON_START := Vector2(698, 330)
@export var START_SPEED : float = 250.0
@export var MAX_SPEED : float = 3000
@export var MAX_DIFFICULTY : int = 2
@export var SPEED_INCREASE_FACTOR : float = 4
@export var LAND_Y_POSITION : float = 580.0
@export var GAP_SIZE : float = 180.0
@export var SAFE_ZONE_PERCENT: float = 0.3
@export var PROJECTILE_HEIGHTS: Array[int] = [200, 300, 400]
@export var COIN_AIR_HEIGHTS: Array[int] = [300, 400]
@export var COIN_GROUND_FLOAT : float = 60.0 # How high coins float above the ground

#Land Variables
var LAND_SEGMENT_WIDTH: float = 0.0
var land_segments: Array[Node2D] = []
var last_land_segment: Node2D = null

#State Variables
var stone_type := [STONE_1_SCENE, STONE_2_SCENE]
var stones : Array
var coins: Array = []
var coin_count: int = 0
var _next_stone_spawn_x: float = 0.0
var _next_projectile_spawn_x: float = 0.0
var _next_coin_spawn_x: float = 0.0
var land_height : int
var obstacles: Array[Node2D] = []
var current_barrier: Node2D = null
var speed: float = 0.0
var score: float = 0.0
var high_score: float = 0.0
var game_running: bool = false
var difficulty: int = 0
var screen_size: Vector2i
var generate := true

#Camera untuk generate
var _camera_cleanup_threshold: float = 0.0
var _last_spawn_x: float = -INF


func _ready():
	# Load the high score from the singleton
	high_score = GameData.high_score
	high_score_label.text = "HIGH SCORE: %d" % int(high_score)
	
	screen_size = get_window().size
	restart_button.pressed.connect(reload_game)
	
	#Set Land Width
	var temp_land = LAND_SCENE.instantiate()
	land_height = temp_land.get_node("Sprite2D").texture.get_height()
	if temp_land.get_child_count() > 0:
		var child = temp_land.get_child(0)
		if child is Sprite2D:
			LAND_SEGMENT_WIDTH = child.texture.get_width() * child.scale.x
		elif child is CollisionShape2D and child.shape is RectangleShape2D:
			LAND_SEGMENT_WIDTH = child.shape.size.x
	temp_land.queue_free()
	
	#Clean se t
	_camera_cleanup_threshold = screen_size.x / 2 + 200

	new_game()

func reload_game() -> void:
	get_tree().reload_current_scene()
	
func new_game() -> void:
	#Reset state
	game_running = false
	get_tree().paused = false
	score = 0.0
	coin_count = 0
	speed = START_SPEED
	difficulty = 0
	_last_spawn_x = -INF

	#Reset UI
	score_label.text = "SCORE: 0"
	coin_label.text = "KOIN: 0"
	start_label.show()
	restart_button.hide()
	
	_next_stone_spawn_x = player.position.x + screen_size.x
	_next_projectile_spawn_x = player.position.x + screen_size.x + 400
	_next_coin_spawn_x = player.position.x + screen_size.x + 200
	
	#Cleanup
	for obstacle in obstacles:
		obstacle.queue_free()
	obstacles.clear()
	
	for coin in coins:
		coin.queue_free()
	coins.clear()
	
	for segment in land_segments:
		segment.queue_free()
	land_segments.clear()
	
	#Reset positions
	player.position = START_POS
	player.velocity = Vector2.ZERO
	camera.position = CAM_START
	moon.position = MOON_START
	
	#Generate first floor
	spawn_land_segment(Vector2(START_POS.x, LAND_Y_POSITION))
	
	#Generate initial land segments
	for i in range(4):
		generate_next_land_segment()
	$BGM.play()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("barrier"):
		toggle_barrier()

func _process(delta: float) -> void:
	if not game_running:
		if Input.is_action_just_pressed("jump"):
			start_game()
		return
	
	generate_stones()
	generate_projectiles()
	generate_coins()

	update_game_state(delta)
	generate_land()
	cleanup_nodes()
	
	if player.position.y > 700:
		game_over()


func start_game() -> void:
	game_running = true
	start_label.hide()
	

func update_game_state(delta: float) -> void:
	#Update speed and difficulty
	speed = min(START_SPEED + (score / SPEED_INCREASE_FACTOR), MAX_SPEED)
	difficulty = mini(int(score / 1000), MAX_DIFFICULTY)
	
	#Move player and camera
	player.position.x += speed * delta
	camera.position.x += speed * delta
	
	#Update score
	score += speed * delta * 0.1
	score_label.text = "SCORE: %d" % int(score)
	
	#Moon Ascends
	if moon.position.y > 80:
		moon.position.y -= speed * delta * 0.005

func generate_land() -> void:
	var spawn_threshold = camera.position.x + screen_size.x
	
	#Prevent Spawn at same place
	if _last_spawn_x < spawn_threshold:
		if last_land_segment.position.x + LAND_SEGMENT_WIDTH < spawn_threshold:
			generate_next_land_segment()
			_last_spawn_x = last_land_segment.position.x
		

func generate_next_land_segment() -> void:
	var new_pos_x = last_land_segment.position.x + LAND_SEGMENT_WIDTH + GAP_SIZE
	spawn_land_segment(Vector2(new_pos_x, LAND_Y_POSITION))

func spawn_land_segment(pos: Vector2) -> void:
	var new_land = LAND_SCENE.instantiate()
	new_land.position = pos
	add_child(new_land)
	land_segments.append(new_land)
	last_land_segment = new_land

func is_in_safe_zone(pos_x: float) -> bool:
	for segment in land_segments:
		var seg_start = segment.position.x
		var seg_end = seg_start + LAND_SEGMENT_WIDTH
		var safe_margin = LAND_SEGMENT_WIDTH * SAFE_ZONE_PERCENT

		if (pos_x >= seg_start && pos_x <= seg_start + safe_margin) || \
			(pos_x >= seg_end - safe_margin && pos_x <= seg_end):
			return true
	return false

func generate_stones():
	var camera_right_edge = camera.position.x + (screen_size.x / 2)
	if camera_right_edge > _next_stone_spawn_x:
		var st_type = stone_type[randi() % stone_type.size()]
		var max_st = difficulty + 1
		var last_spawned_stone_pos_x = _next_stone_spawn_x

		for i in range(randi() % max_st + 1):
			var st_x : float = last_spawned_stone_pos_x + (i * 100)
			if is_in_safe_zone(st_x):
				continue
			var st = st_type.instantiate()
			var st_height = st.get_node("Sprite2D").texture.get_height()
			var st_scale = st.get_node("Sprite2D").scale
			var st_y : int = screen_size.y - land_height - (st_height * st_scale.y / 2) + 5 

			add_stones(st, st_x, st_y)
		_next_stone_spawn_x = last_spawned_stone_pos_x + randi_range(400, 800)
		

func generate_projectiles():
	var camera_right_edge = camera.position.x + (screen_size.x / 2)
	
	#Check Projectile on screen
	if camera_right_edge > _next_projectile_spawn_x:
		var st = PROJECTILE_SCENE.instantiate()
		
		#position to camera
		var st_x = camera_right_edge + 200
		var st_y = PROJECTILE_HEIGHTS[randi() % PROJECTILE_HEIGHTS.size()]

		add_projectile(st, st_x, st_y)
		
		#Next spawn position
		_next_projectile_spawn_x = st_x + randi_range(800, 1200)

func generate_coins():
	var camera_right_edge = camera.position.x + (screen_size.x / 2)
	
	# Check if it's time to spawn a new coin cluster
	if camera_right_edge > _next_coin_spawn_x:
		var spawn_x_start = camera_right_edge + 150 # Start spawning ahead of camera
		
		# Use our new function to make sure we don't spawn over a deadly gap
		if not is_on_land(spawn_x_start):
			_next_coin_spawn_x = camera_right_edge + 100 # Try again soon
			return

		var spawn_y: float
		# Decide randomly: 0 for ground, 1 for air
		var spawn_type = randi() % 2
		
		if spawn_type == 0:
			# Spawn on the ground
			var temp_coin = COIN_SCENE.instantiate()
			# Safely get the sprite node
			var coin_sprite = temp_coin.get_node_or_null("Sprite2D") as Sprite2D
			
			# Check if the sprite was actually found before using it
			if coin_sprite and coin_sprite.texture:
				var coin_height = coin_sprite.texture.get_height() * coin_sprite.scale.y
				spawn_y = LAND_Y_POSITION - (coin_height / 2) - COIN_GROUND_FLOAT
			else:
				# If no sprite is found, fall back to a default height to prevent a crash
				spawn_y = LAND_Y_POSITION - 20 - COIN_GROUND_FLOAT
				print_debug("ERROR: Could not find a 'Sprite2D' node in coin.tscn!")
			
			temp_coin.queue_free()
		else:
			# Spawn in the air
			spawn_y = COIN_AIR_HEIGHTS[randi() % COIN_AIR_HEIGHTS.size()]

		# Now, spawn a line of 5 coins at the calculated position
		for i in range(5):
			var coin_instance = COIN_SCENE.instantiate()
			var coin_x = spawn_x_start + (i * 60) # Space them out
			
			coin_instance.position = Vector2(coin_x, spawn_y)
			coin_instance.body_entered.connect(_on_coin_collected.bind(coin_instance))
			
			add_child(coin_instance)
			coins.append(coin_instance)
		
		# Set the position for the next coin spawn
		_next_coin_spawn_x = spawn_x_start + randi_range(500, 900)

func _on_coin_collected(body, coin_instance):
	if body.name == "Player":
		score += 10
		score_label.text = "SCORE: %d" % int(score)
		coin_count += 1
		coin_label.text = "KOIN: %d" % coin_count
		
		print("Coin collected by:", body.name)
		# $CoinSound.play()

		# Remove the coin
		if coins.has(coin_instance):
			coins.erase(coin_instance)
		coin_instance.queue_free()

func add_stones(st, x, y):
	st.position = Vector2 (x,y)
	st.body_entered.connect(hit_stone)
	add_child(st)
	stones.append(st)
	obstacles.append(st)

func add_projectile(projectile, x, y):
	projectile.position = Vector2 (x,y)
	projectile.body_entered.connect(hit_stone)
	add_child(projectile)
	stones.append(projectile)

func hit_stone(body):
	if body.name == "Player":
		game_over() 

func cleanup_nodes() -> void:
	var cleanup_threshold = camera.position.x - _camera_cleanup_threshold
	#Cleanup land segments
	for i in range(land_segments.size() - 1, -1, -1):
		var segment = land_segments[i]
		if segment != last_land_segment:
			if segment.position.x + LAND_SEGMENT_WIDTH < cleanup_threshold:
				segment.queue_free()
				land_segments.remove_at(i)
	
	# Cleanup coins
	for i in range(coins.size() - 1, -1, -1):
		var coin = coins[i]
		if coin.position.x < cleanup_threshold:
			coin.queue_free()
			coins.remove_at(i)

func toggle_barrier() -> void:
	if current_barrier:
		current_barrier.queue_free()
		current_barrier = null
	else:
		current_barrier = BARRIER_SCENE.instantiate()
		player.add_child(current_barrier)
		current_barrier.position = Vector2.ZERO

		await get_tree().create_timer(0.3).timeout
		if current_barrier:
			current_barrier.queue_free()
			current_barrier = null

# This function checks if a given x-coordinate is over any land segment
func is_on_land(pos_x: float) -> bool:
	for segment in land_segments:
		var seg_start = segment.position.x
		var seg_end = seg_start + LAND_SEGMENT_WIDTH
		if pos_x >= seg_start and pos_x <= seg_end:
			return true
	return false

func game_over() -> void:
	if score > GameData.high_score:
		GameData.high_score = score
		# Now, call the save function to write it to the file!
		GameData.save_data()

	get_tree().paused = true
	game_running = false
	restart_button.show()

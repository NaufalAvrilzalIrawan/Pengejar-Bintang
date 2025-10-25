extends Node

#Set Variables
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var moon: Sprite2D = $BG/Moon
@export var moon_speed: float = 30.0        # kecepatan naik (pixel per detik)
@export var moon_travel_distance: float = 200.0  # jarak maksimum sebelum reset
var moon_start_y: float
@onready var score_label: Label = $BG/Control/LabelScore
@onready var high_score_label: Label = $BG/Control2/LabelHigh
@onready var coin_label: Label = $BG/Control5/LabelCoin
@onready var kills_label: Label = $BG/Control6/LabelKills
@onready var high_coin_label: Label = $BG/Control7/LabelHighCoin
@onready var high_kill_label: Label = $BG/Control8/LabelHighKill
@onready var restart_button: Button = $BG/Control3/Restart
@onready var Game_Over: Label = $BG/Control3/Game_Over
@onready var title_label: Label = $BG/Control4/Title
@onready var start_button: Button = $BG/Control4/StartButton
@onready var Game_Finished: AudioStreamPlayer2D = $Game_Finished

#Preload Scenes
const ENEMY_SCENE := preload("res://Scenes/enemy_1.tscn")
const STONE_1_SCENE := preload("res://Scenes/stone_1.tscn")
const STONE_2_SCENE := preload("res://Scenes/stone_2.tscn")
const PROJECTILE_SCENE := preload("res://Scenes/projectile.tscn")
const BARRIER_SCENE := preload("res://Scenes/barrier.tscn")
const COIN_SCENE := preload("res://Scenes/coin.tscn")
const LAND_SCENE := preload("res://Scenes/land.tscn")


#Game Configuration
@export var START_POS := Vector2(150, 500)
@export var MOON_START := Vector2(698, 330)
@export var START_SPEED : float = 300.0
@export var MAX_SPEED : float = 2500
@export var MAX_DIFFICULTY : int = 2
@export var SPEED_INCREASE_FACTOR : float = 4
@export var LAND_Y_POSITION : float = 580.0
@export var GAP_SIZE : float = 180.0
@export var SAFE_ZONE_PERCENT: float = 0.3
@export var PROJECTILE_HEIGHTS: Array[int] = [200, 300, 400]
@export var COIN_AIR_HEIGHTS: Array[int] = [300, 400]
@export var COIN_GROUND_FLOAT : float = 60.0 # How high coins float above the ground
@export var BARRIER_DURATION : float = 1 # How high coins float above the ground
@export var barrier_cooldown: float = 2.0 # durasi cooldown (detik)
var barrier_ready: bool = true


#Land Variables
var LAND_SEGMENT_WIDTH: float = 0.0
var land_segments: Array[Node2D] = []
var last_land_segment: Node2D = null

#State Variables
var enemies: Array = []
var stone_type := [STONE_1_SCENE, STONE_2_SCENE]
var stones : Array
var coins: Array = []
var coin_count: int = 0
var enemies_killed_count: int = 0
var _next_enemy_spawn_x: float = 0.0
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
	player.add_to_group("player")
	# Load the high score from the singleton
	moon_start_y = moon.position.y
	high_score = GameData.high_score
	high_score_label.text = "HIGH SCORE: %d" % int(high_score)
	high_coin_label.text = "HIGH COINS: %d" % GameData.high_coin_count
	high_kill_label.text = "HIGH KILLS: %d" % GameData.high_kill_count
	
	screen_size = get_window().size
	start_button.pressed.connect(on_start_button_pressed)
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
func on_start_button_pressed() -> void:
	start_button.hide()  # sembunyikan tombol start
	start_game()         # panggil animasi masuk kamera

func reload_game() -> void:
	get_tree().reload_current_scene()
	
func new_game() -> void:
	#Reset state
	game_running = false
	get_tree().paused = false
	score = 0.0
	coin_count = 0
	enemies_killed_count = 0
	speed = START_SPEED
	difficulty = 0
	_last_spawn_x = -INF
<<<<<<< HEAD

	start_button.show()
=======
	
	score_label.text = "SCORE: 0"
	coin_label.text = "COINS: 0"
	kills_label.text = "KILLS: 0"
	start_label.show()
>>>>>>> 31fcbd003e1a06c32a571e3b311ba00ee5b2957b
	title_label.show()
	restart_button.hide()
	Game_Over.hide()
	player.hide()
	
	camera.position = Vector2(player.position.x, camera.position.y)
	_next_stone_spawn_x = camera.position.x + screen_size.x
	_next_projectile_spawn_x = camera.position.x + screen_size.x
	_next_coin_spawn_x = camera.position.x + screen_size.x
	_next_enemy_spawn_x = player.position.x + screen_size.x * 2.0
	
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
	
	for enemy in enemies:
		enemy.queue_free()
	enemies.clear()
	
	for st in stones:
		st.queue_free()
	stones.clear()
	
	#Reset positions
	player.position = START_POS
	player.velocity = Vector2.ZERO
	
	#Generate first floor
	spawn_land_segment(Vector2(START_POS.x, LAND_Y_POSITION))
	
	#Generate initial land segments
	for i in range(4):
		generate_next_land_segment()
	$BGM.play()

func _input(event: InputEvent) -> void:
	# Hanya izinkan input jika game sedang berjalan
	if not game_running:
		return

	if event.is_action_pressed("barrier"):
		toggle_barrier()


func _process(delta: float) -> void:
	if not game_running:
		return
	
	generate_stones()
	generate_projectiles()
	generate_coins()
	generate_enemies()

	update_game_state(delta)
	generate_land()
	cleanup_nodes()
	
	# Gerakkan bulan naik ke atas
	moon.position.y -= moon_speed * delta

	# Jika sudah melewati batas jarak, reset ke posisi awal
	if moon.position.y <= moon_start_y - moon_travel_distance:
		moon.position.y = moon_start_y
	if player.position.y > 700:
		game_over()


func start_game() -> void:
	
	start_button.hide()
	title_label.hide()
	player.show()

	# Mulai animasi karakter masuk ke layar
	var tween = create_tween()
	var target_pos = START_POS
	var start_pos = START_POS - Vector2(150,0) # mulai dari luar layar kiri
	
	player.position = start_pos
	player.velocity = Vector2.ZERO
	game_running = false # jangan mulai dulu gameplay-nya

	# Tween untuk memindahkan karakter ke posisi START_POS
	tween.tween_property(player, "position", target_pos, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Setelah animasi selesai, baru mulai game
	await tween.finished
	game_running = true

	

func update_game_state(delta: float) -> void:
	#Update speed and difficulty
	speed = min(START_SPEED + (score / SPEED_INCREASE_FACTOR), MAX_SPEED)
	difficulty = min(int(score / 1000), MAX_DIFFICULTY)
	
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
	var spawn_threshold = camera.position.x + screen_size.x + 50
	
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

func get_land_y_at_x(x: float) -> Variant:
	for seg in land_segments:
		var seg_start = seg.position.x
		var seg_end = seg_start + LAND_SEGMENT_WIDTH
		if x >= seg_start and x <= seg_end:
			return seg.position.y
	return null


func generate_stones():
	var camera_right_edge = camera.position.x + (screen_size.x / 2) + 750 
	if camera_right_edge <= _next_stone_spawn_x:
		return

	var st_type = stone_type[randi() % stone_type.size()]
	var max_st = difficulty + 1
	var base_x = _next_stone_spawn_x

	var spawned_any = false
	for i in range(randi() % max_st + 1):
		var st_x = base_x + (i * 100)

		# Jika tidak ada tanah di posisi st_x, skip (atau cari nearest land jika mau)
		var land_y = get_land_y_at_x(st_x)
		if land_y == null:
			continue

		# Hindari spawn terlalu dekat tepian (safe zone)
		if is_in_safe_zone(st_x):
			continue

		var st = st_type.instantiate()
		var sprite_node = st.get_node_or_null("Sprite2D") as Sprite2D
		var st_height = (sprite_node.texture.get_height() * sprite_node.scale.y) if sprite_node and sprite_node.texture else 32
		var st_y = land_y - (st_height / 2)

		add_stones(st, st_x, st_y)
		spawned_any = true

	# Set next spawn (jika tidak spawn apapun, coba sedikit maju agar tidak stuck)
	if spawned_any:
		_next_stone_spawn_x = base_x + randi_range(400, 800)
	else:
		_next_stone_spawn_x = camera_right_edge + 200

func generate_projectiles():
	var camera_right_edge = camera.position.x + (screen_size.x / 2)
	
	#Check Projectile on screen
	if camera_right_edge > _next_projectile_spawn_x:
		var st = PROJECTILE_SCENE.instantiate()
		
		#position to camera
		var st_x = camera_right_edge + 750
		var st_y = PROJECTILE_HEIGHTS[randi() % PROJECTILE_HEIGHTS.size()]

		add_projectile(st, st_x, st_y)
		
		#Next spawn position
		_next_projectile_spawn_x = st_x + randi_range(800, 1200)

func generate_coins():
	var camera_right_edge = camera.position.x + (screen_size.x / 2)
	
	# Check if it's time to spawn a new coin cluster
	if camera_right_edge > _next_coin_spawn_x:
		var spawn_x_start = camera_right_edge + 750 # Start spawning ahead of camera
		
		# Use our new function to make sure we don't spawn over a deadly gap
		if not is_on_land(spawn_x_start):
			_next_coin_spawn_x = camera_right_edge + 750 # Try again soon
			return

		var spawn_y: float
		# Decide randomly: 0 for ground, 1 for air
		var spawn_type = randi() % 2
		
		if spawn_type == 0:
			# Spawn on the ground
			var temp_coin = COIN_SCENE.instantiate()
			# Safely get the sprite node
			var coin_sprite = temp_coin.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
			
			# Check if the sprite was actually found before using it
			if coin_sprite and coin_sprite.sprite_frames:
				# Get the texture of the first frame of the "default" animation
				var frame_texture = coin_sprite.sprite_frames.get_frame_texture("default", 0)
				var coin_height = frame_texture.get_height() * coin_sprite.scale.y
				spawn_y = LAND_Y_POSITION - (coin_height / 2) - COIN_GROUND_FLOAT
			else:
				# Fallback if we can't find it
				spawn_y = LAND_Y_POSITION - 20 - COIN_GROUND_FLOAT
				print_debug("ERROR: Could not find 'AnimatedSprite2D' node in coin.tscn!")
			
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

func generate_enemies():
	var camera_right_edge = camera.position.x + (screen_size.x / 2)
	
	# Check if it's time to spawn a new enemy
	if camera_right_edge > _next_enemy_spawn_x:
		var spawn_x = camera_right_edge + 750
		
		# Don't spawn over a gap
		var land_y = get_land_y_at_x(spawn_x)
		if land_y == null:
			# No land here (it's a gap), so skip spawning
			_next_enemy_spawn_x = camera_right_edge + 200 # Try again soon
			return
		
		if is_in_safe_zone(spawn_x):
			_next_enemy_spawn_x = camera_right_edge + 200 # Try again soon
			return
		
		var enemy = ENEMY_SCENE.instantiate()
		
		# Get its height to place it correctly on the ground
		var enemy_sprite = enemy.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		var spawn_y_final: float
		
		if enemy_sprite and enemy_sprite.sprite_frames:
			# Get the texture of the first frame of the "default" animation
			var frame_texture = enemy_sprite.sprite_frames.get_frame_texture("default", 0)
			var enemy_height = frame_texture.get_height() * enemy_sprite.scale.y
			spawn_y_final = land_y - (enemy_height / 2)
		else:
			spawn_y_final = LAND_Y_POSITION - 30 # Fallback
			print_debug("ERROR: Could not find 'AnimatedSprite2D' in Enemy_1.tscn")

		enemy.position = Vector2(spawn_x, spawn_y_final)
		add_child(enemy)
		enemies.append(enemy)
		
		# Pass the current speed to the enemy
		enemy.init_enemy(speed, START_SPEED, MAX_SPEED)
		
		# Set the next trigger relative to THIS spawn's position
		_next_enemy_spawn_x = spawn_x + randi_range(3000, 5000)
	
func _on_coin_collected(body, coin_instance):
	if body.name != "Player":
		return
	
	score += 10
	score_label.text = "SCORE: %d" % int(score)
	coin_count += 1
	coin_label.text = "COINS: %d" % coin_count
	
	if has_node("CoinSound"):
		$CoinSound.play()
	
	if coin_instance == null or not is_instance_valid(coin_instance):
		return
	
	if coins.has(coin_instance):
		coins.erase(coin_instance)



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
			
	# Cleanup enemies
	for i in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[i]
		if not is_instance_valid(enemy):
			enemies.remove_at(i) # Clean up the "ghost" reference
			continue
		
		if enemy.position.x < cleanup_threshold:
			enemy.queue_free()
			enemies.remove_at(i)

func toggle_barrier() -> void:
	if not barrier_ready:
		return # masih cooldown, jangan aktifkan lagi

	if current_barrier:
		current_barrier.queue_free()
		current_barrier = null
	else:
		current_barrier = BARRIER_SCENE.instantiate()
		player.add_child(current_barrier)
		current_barrier.position = Vector2.ZERO

		# Hubungkan sinyal saat menangkis proyektil
		current_barrier.projectile_blocked.connect(_on_barrier_blocked)
		current_barrier.enemy_destroyed.connect(_on_enemy_destroyed)
		
		# Jalankan durasi & cooldown dari sini
		run_barrier_duration()
		start_barrier_cooldown()

func _on_enemy_destroyed():
	enemies_killed_count += 1
	kills_label.text = "KILLS: %d" % enemies_killed_count
	
# Fungsi durasi utama (pakai BARRIER_DURATION dari scene utama)
func run_barrier_duration() -> void:
	await get_tree().create_timer(BARRIER_DURATION).timeout
	if current_barrier:
		await current_barrier.play_end_animation()
		current_barrier = null

<<<<<<< HEAD
# ⏱️ Jalankan cooldown setelah barrier diaktifkan
=======

# Jalankan cooldown setelah barrier diaktifkan
>>>>>>> 31fcbd003e1a06c32a571e3b311ba00ee5b2957b
func start_barrier_cooldown() -> void:
	barrier_ready = false
	await get_tree().create_timer(barrier_cooldown).timeout
	barrier_ready = true

# ⚡ Kalau projectile kena barrier, reset cooldown (langsung bisa aktif lagi)
func _on_barrier_blocked() -> void:
	barrier_ready = true

# This function checks if a given x-coordinate is over any land segment
func is_on_land(pos_x: float) -> bool:
	for segment in land_segments:
		var seg_start = segment.position.x
		var seg_end = seg_start + LAND_SEGMENT_WIDTH
		if pos_x >= seg_start and pos_x <= seg_end:
			return true
	return false

func game_over() -> void:
	var new_high_score_set = false # Flag to see if save is needed
	
	if score > GameData.high_score:
		GameData.high_score = score
		# Now, call the save function to write it to the file!
		GameData.save_data()
<<<<<<< HEAD
		
	if Game_Finished:
		$Game_Finished.play()
		$BGM.stop()
		
	if player and is_instance_valid(player):
		player.play_game_over_anim()
	await get_tree().create_timer(1).timeout
=======
	if coin_count > GameData.high_coin_count:
		GameData.high_coin_count = coin_count
		new_high_score_set = true
		
	if enemies_killed_count > GameData.high_kill_count:
		GameData.high_kill_count = enemies_killed_count
		new_high_score_set = true
	
	# Only save the file if a new record was set
	if new_high_score_set:
		GameData.save_data()
	
>>>>>>> 31fcbd003e1a06c32a571e3b311ba00ee5b2957b
	get_tree().paused = true
	game_running = false
	restart_button.show()
	Game_Over.show()

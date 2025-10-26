extends Node

# For storing the game data even when the game is closed
const SAVE_PATH = "user://savegame.dat"
var high_score: float = 0.0
var high_coin_count: int = 0
var high_kill_count: int = 0

# This function runs automatically once when the singleton is first loaded.
func _ready():
	load_data()

func save_data():
	var data_dict = {
		"high_score": high_score,
		"high_coin_count": high_coin_count,
		"high_kill_count": high_kill_count
	}
	
	# Open the save file for writing.
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	# Store the high_score variable directly into the file.
	file.store_var(data_dict)
	print("Game data saved: ", data_dict)

func load_data():
	# Check if a save file actually exists
	if FileAccess.file_exists(SAVE_PATH):
		# If it exists, open it for reading
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		# Load the data
		var loaded_data = file.get_var()
		
		# Check if the loaded data is our new dictionary format
		if loaded_data is Dictionary:
			# Safely load each value, using a default if the key is missing
			high_score = loaded_data.get("high_score", 0.0)
			high_coin_count = loaded_data.get("high_coin_count", 0)
			high_kill_count = loaded_data.get("high_kill_count", 0)
			print("Save data loaded.")
		# Check if it's the OLD save format (just a float)
		elif loaded_data is float:
			high_score = loaded_data
			print("Old save file format detected and loaded. New stats will be added on next save.")
	else:
		print("No save file found. Starting with a fresh game.")

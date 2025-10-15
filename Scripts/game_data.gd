extends Node

# For storing the game data even when the game is closed
const SAVE_PATH = "user://savegame.dat"
var high_score: float = 0.0

# This function runs automatically once when the singleton is first loaded.
func _ready():
	load_data()

func save_data():
	# Open the save file for writing.
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	# Store the high_score variable directly into the file.
	file.store_var(high_score)
	print("Game data saved. High score is now: ", high_score)

func load_data():
	# Check if a save file actually exists.
	if FileAccess.file_exists(SAVE_PATH):
		# If it exists, open it for reading.
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		# Load the variable from the file and put it into our high_score variable.
		high_score = file.get_var()
		print("Save data loaded. High score is: ", high_score)
	else:
		print("No save file found. Starting with a fresh game.")

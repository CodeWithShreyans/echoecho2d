extends Node

signal score_updated(score)
signal achievement_unlocked(achievement_name, description)
signal lives_updated(lives)

var current_score = 0
var enemies_killed = 0
var lives = 3
var high_score = 0

var achievements = {
	"Rookie": {
		"kills_required": 5,
		"description": "Kill 5 enemies",
		"unlocked": false
	},
	"Hunter": {
		"kills_required": 15,
		"description": "Kill 15 enemies",
		"unlocked": false
	},
	"Exterminator": {
		"kills_required": 30,
		"description": "Kill 30 enemies",
		"unlocked": false
	},
	"Destroyer": {
		"kills_required": 50,
		"description": "Kill 50 enemies",
		"unlocked": false
	},
	"Legend": {
		"kills_required": 100,
		"description": "Kill 100 enemies",
		"unlocked": false
	}
}

const POINTS_PER_KILL = 100

func _ready():
	print("ScoreManager initialized")

func enemy_killed():
	current_score += POINTS_PER_KILL
	enemies_killed += 1
	
	score_updated.emit(current_score)
	
	check_achievements()
	
	print("Enemy killed! Score: ", current_score, ", Enemies killed: ", enemies_killed)

func reset():
	if current_score > high_score:
		high_score = current_score
	
	current_score = 0
	enemies_killed = 0
	lives = 3
	
	for achievement in achievements:
		achievements[achievement]["unlocked"] = false
	
	score_updated.emit(current_score)
	lives_updated.emit(lives)

func partial_reset():
	score_updated.emit(current_score)
	lives_updated.emit(lives)

func check_achievements():
	for achievement_name in achievements:
		var achievement = achievements[achievement_name]
		if !achievement["unlocked"] and enemies_killed >= achievement["kills_required"]:
			achievement["unlocked"] = true
			
			achievement_unlocked.emit(achievement_name, achievement["description"])
			
			print("Achievement unlocked: ", achievement_name, " - ", achievement["description"])

func get_score():
	return current_score

func lose_life():
	lives -= 1
	lives_updated.emit(lives)
	
	if lives > 0:
		partial_reset()
		return true
	else:
		if current_score > high_score:
			high_score = current_score
			print("New high score: ", high_score)
		
		return false

# Get current lives
func get_lives():
	return lives
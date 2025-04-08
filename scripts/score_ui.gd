extends CanvasLayer

@onready var score_label = $ScoreContainer/ScoreLabel
@onready var lives_label = $ScoreContainer/LivesLabel
@onready var achievement_container = $AchievementContainer
@onready var achievement_name_label = $AchievementContainer/AchievementNameLabel
@onready var achievement_desc_label = $AchievementContainer/AchievementDescLabel
@onready var achievement_timer = $AchievementTimer

const ACHIEVEMENT_DISPLAY_TIME = 3.0

func _ready():
	var score_manager = get_node("/root/ScoreManager")
	score_manager.score_updated.connect(_on_score_updated)
	score_manager.achievement_unlocked.connect(_on_achievement_unlocked)
	score_manager.lives_updated.connect(_on_lives_updated)
	
	score_label.text = "Score: 0"
	lives_label.text = "Lives: 3"
	
	achievement_container.visible = false

func _on_score_updated(score):
	score_label.text = "Score: " + str(score)

func _on_lives_updated(lives):
	lives_label.text = "Lives: " + str(lives)

func _on_achievement_unlocked(achievement_name, description):
	achievement_name_label.text = achievement_name
	achievement_desc_label.text = description
	
	achievement_container.visible = true
	
	if achievement_container.has_node("AnimationPlayer"):
		achievement_container.get_node("AnimationPlayer").play("achievement_popup")
	
	achievement_timer.start(ACHIEVEMENT_DISPLAY_TIME)

func _on_achievement_timer_timeout():
	if achievement_container.has_node("AnimationPlayer"):
		achievement_container.get_node("AnimationPlayer").play("achievement_fade")
	else:
		achievement_container.visible = false

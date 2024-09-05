extends Control

signal retry()

func _ready() -> void:
	$VboxContainer/PlayAgain.grab_focus()

func _on_play_again_pressed() -> void:
	emit_signal("retry")
	queue_free()

func _on_quit_pressed() -> void:
	get_tree().quit()

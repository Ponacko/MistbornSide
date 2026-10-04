class_name MusicZone
extends Node
## Starts this area's music loop when the level loads.

@export var track := "night_city"


func _ready() -> void:
	Audio.play_music(track)

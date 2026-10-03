class_name MistRepeller
extends Node2D
## Marks a spiked being: the mists part around it (Inquisitors, koloss).

@export var radius := 70.0


func _enter_tree() -> void:
	MistField.add_repeller(self)


func _exit_tree() -> void:
	MistField.remove_repeller(self)

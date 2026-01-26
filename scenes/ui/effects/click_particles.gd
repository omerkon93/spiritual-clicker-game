extends Node2D

@onready var particles: CPUParticles2D = $CPUParticles2D

func _ready():
	particles.emitting = true
	# Wait for particles to finish, then delete this object
	await get_tree().create_timer(particles.lifetime).timeout
	queue_free()

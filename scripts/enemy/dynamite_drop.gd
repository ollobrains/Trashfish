extends Node2D

func _ready() -> void:
	$AnimatedSprite2D.play("idle")
	$drop_component.timer_length += randi() % 4
	$drop_component.fall_speed += randi() % 55

func timer_timeout_event():
	self.rotation_degrees = 0
	get_node("explosion_hitbox/CollisionPolygon2D").set_deferred("disabled", false)
	$AnimatedSprite2D.play("explosion")
	get_node("StaticBody2D/CollisionPolygon2D").set_deferred("disabled", true)
	$CPUParticles2D.emitting = true


func _on_explosion_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.decrease_health()

# When the player attacks this object
func attacked():
	self.get_parent().get_parent().get_parent().score += 1
	$drop_component.delete_timer.start()
	$drop_component.isActive = false
	$drop_component.active_timer.stop()
	$drop_component.active_timer.emit_signal("timeout")
	

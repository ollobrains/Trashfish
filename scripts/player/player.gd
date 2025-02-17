extends CharacterBody2D
var speed : float = 250
const acceleration : float = 22
var starve : int = 100
@export var health : int = 6
@export var max_starve : int = 100
@export var max_health : int = 10
@export var world_id : int = 3
@export var honey_speed : int = 2.5
@export var ice_speed : int = 5

var isAttacking : bool = false
var isDead : bool = false
var isHoneyd : bool = false
var isIced : bool = false
var isRolling : bool = false

var drop
var direction : Vector2
const trash_can = preload("res://scenes/player/trash_can.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$debuff_master/honey.play("default")
	$debuff_master/ice.play("default")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if (Input.is_action_just_pressed("restart")):
		get_tree().change_scene_to_file("res://scenes/world/world.tscn")
	if (Input.is_action_just_pressed("revive")):
		self.set_health(10)
		self.isDead = false
	if isDead:
		return
	if Input.is_action_just_pressed("attack") and not isAttacking and not isRolling:
		self.attack()
	if Input.is_action_just_pressed("roll") and not isRolling and $debuff_master/roll_cooldown_timer.is_stopped():
		self.roll()
	if self.health == 0:
		player_death()
		return
	handle_player_input(delta)
	handle_player_animation()
	move_and_slide()
# Handles basic player movement
func handle_player_input(delta):
	if not isRolling:
		direction = Input.get_vector("move_left","move_right","move_up","move_down")
	#print(self.velocity.x, ":", self.velocity.y)
	
	self.velocity.x = lerp(velocity.x, speed * direction.x, acceleration * delta)
	self.velocity.y = lerp(velocity.y, speed * direction.y * 0.65, acceleration * delta)
	self.rotation_degrees = 5 if not (abs(self.velocity.y) <= 10) else 0
	self.rotation_degrees *= -1 if self.velocity.x < 0 else 1
	self.rotation_degrees *= -1 if self.velocity.y < 0 else 1

	
# Handles basic player animations using bools/state machine
func handle_player_animation():
	if abs(velocity.x) > 0.001:
		flip(velocity.x < 0)
	if isDead:
		$body.play("death")
		return
	$debuff_master/honey.visible = isHoneyd
	$debuff_master/ice.visible = isIced
	match isAttacking:
		true:
			$head.play("attack")
		false:
			$head.play("idle")
	match isRolling:
		true:
			$body.play("roll")
			return
		false:
			$body.play("idle")
	$body.play("idle")
	
# Flip the animations and hitboxes
func flip(value: bool):
	if value != $body.flip_h:
		$body.flip_h = value
		$head.flip_h = value
		$attack_hitbox/CollisionShape2D.position.x *= -1
		$debuff_master/honey.flip_h = value
		$debuff_master/ice.flip_h = value
		
# Handles the Player rolling logic
func roll():
	self.starve -= self.max_starve / 2
	isRolling = true
	self.speed *= 1.8
	self.velocity = speed * direction
	
	$head.visible = false
	$debuff_master/roll_timer.start()

# Getter for health
func get_health():
	return self.health;

# Variables to mess with player health
func set_health(change : int):
	self.health = change

func decrease_health() :
	if self.world_id == 0 or self.world_id == 1 or (isRolling and not starve <= 0):
		return
	self.health -= 1;
	self.damage_flash_body();

func increase_health():
	self.health += 1;
	if health > max_health:
		health = max_health
	self.heal_flash_body()
	
func player_death():
	self.get_parent().update_hud_when_dead()
	self.health = 0
	self.isDead = true
	$body.play("death")
	$head.visible = false
	drop = trash_can.instantiate()
	self.add_child(drop)
	
# If we attack, then we should turn on attack hitboxes
func attack():
	get_node("attack_hitbox/CollisionShape2D").set_deferred("disabled", false)
	isAttacking = true
	$attack_hitbox/attack_timer.start()
	
# Sets the player's debuff 
func set_debuff(debuff : String) -> void:
	match debuff:
		"honey":
			if isHoneyd:
				$debuff_master/honey_timer.start()
				return
			isHoneyd = true
			self.speed /= honey_speed
			$debuff_master/honey_timer.start()
		"ice":
			if isIced:
				$debuff_master/ice_timer.start()
				return
			isIced = true
			self.speed /= ice_speed
			$debuff_master/ice_timer.start()

# Flashes the player body when damaged
func damage_flash_body():
	if health <= 0:
		return
	$body.material.set_shader_parameter("flash_color",Color(0.76,0,0,1.0))
	$body.material.set_shader_parameter("flash_modifer", 0.7)
	$head.material.set_shader_parameter("flash_color",Color(0.76,0,0,1.0))
	$head.material.set_shader_parameter("flash_modifer", 0.7)
	$body/flash_timer.start()
# flashes player body green when healed
func heal_flash_body():
	if health <= 0 or health > max_health:
		return
	$body.material.set_shader_parameter("flash_color",Color(0.13,0.86,0.14,1.0))
	$body.material.set_shader_parameter("flash_modifer", 0.7)
	$head.material.set_shader_parameter("flash_color",Color(0.13,0.86,0.14,1.0))
	$head.material.set_shader_parameter("flash_modifer", 0.7)
	$body/flash_timer.start()

# When the attack timer resets (CD), we should turn off hitboxes
func _on_attack_timer_timeout() -> void:
	get_node("attack_hitbox/CollisionShape2D").set_deferred("disabled", true)
	isAttacking = false

# handles what the attack hitbox calls on whatever it is attacking
func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		return
	if body.is_in_group("drop"):
		self.reset_starvation()
		body.get_parent().attacked()
		return
	if body.is_in_group("main_menu_block"):
		body.get_parent().attacked()
		return
		


func _on_honey_timer_timeout() -> void:
	self.speed = speed * honey_speed
	isHoneyd = false


func _on_ice_timer_timeout() -> void:
	self.speed = speed * ice_speed
	isIced = false


func _on_flash_timer_timeout() -> void:
	$body.material.set_shader_parameter("flash_modifer", 0)
	$head.material.set_shader_parameter("flash_modifer", 0)
	
func _on_roll_timer_timeout():
	$head.visible = true
	self.speed /= 1.8
	isRolling = false
	$debuff_master/roll_cooldown_timer.start()

# lets player know they can roll again
func _on_roll_cooldown_timer_timeout():
	$body.material.set_shader_parameter("flash_color",Color(0.66,0.51,0.17,1.0))
	$body.material.set_shader_parameter("flash_modifer", 0.7)
	$head.material.set_shader_parameter("flash_color",Color(0.66,0.51,0.17,1.0))
	$head.material.set_shader_parameter("flash_modifer", 0.7)
	$body/flash_timer.start(0.5)

# every second we will take a bit of starvation
# default is you take a hit every 20 seconds of not eating
func _on_starve_timer_timeout():
	starve -= 5
	if starve <= 0:
		self.decrease_health()
		self.reset_starvation()
		
# Resets starvation whenever called
func reset_starvation():
	self.starve = max_starve

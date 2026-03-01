extends CharacterBody2D
func win():
	get_tree().change_scene_to_file("res://Scenes/end_screen.tscn")
func death():
	position = respawn_point
var gravity: float
var move_velocity: float
var is_jumping: bool
var is_on_ground: bool
var on_ladder: bool
var respawn_point: Vector2
var keys_collected: int
var can_wall_jump: bool = false
const move_speed: float = 35
const deceleration: float = 0.75
const gravity_strength: float = 1800
const falling_multiplier: float = 2
const jump_strength: float = -800
const short_jump_multiplier: float = 0.45
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gravity = 0
	move_velocity = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if get_tree().current_scene.name == "level2":
		can_wall_jump = true
	if on_ladder:
		is_on_ground = false
		if Input.is_action_pressed("jump"):
			velocity.y = -150
			gravity = -450
		if Input.is_action_pressed("down"):
			velocity.y = 150
			gravity = 450
		if not (Input.is_action_pressed("down") or Input.is_action_pressed("jump")):
			velocity.y = 0
			gravity = 0
	else:
		#Detecting if the player just left the ground
		if not is_on_floor() and is_on_ground and not is_jumping:
			$"Coyote Time".start()
		#Jumping
		if Input.is_action_just_pressed("jump"):
			$"Jump Buffering".start()
		
		#Floor Detection
		if is_on_floor():
			is_on_ground = true
			velocity.y = 0
			gravity = 0
			if is_jumping:
				is_jumping = false
		else:
			is_on_ground = false
		
		#Adding velocity from jump
		if $"Jump Buffering".time_left > 0 and (is_on_ground or $"Coyote Time".time_left > 0):
			gravity = jump_strength
			is_jumping = true
			$"Jump Buffering".stop()
		#Do wall jump
		if Input.is_action_just_pressed("jump") and can_wall_jump and is_on_wall_only() and (Input.is_action_pressed("left") or Input.is_action_pressed("right")):
			gravity = jump_strength * 0.8
			move_velocity = 600 * -(abs(move_velocity) / move_velocity)
		#Do Gravity
		if gravity > 0:
			gravity += gravity_strength * falling_multiplier * _delta
		else:
			#Make the jump go higher if you hold the button
			if is_jumping and Input.is_action_pressed("jump"):
				gravity += gravity_strength * _delta
			else:
				gravity += gravity_strength * _delta / short_jump_multiplier
		velocity.y = gravity
		
			#Make the player not stick to ceilings
		if is_on_ceiling():
			velocity.y = 50
			gravity = 0
		
	#Moving
	if Input.is_action_pressed("left"):
		move_velocity += 0 - move_speed / (deceleration * deceleration)
		$AnimatedSprite2D.scale.x = -2
		$AnimatedSprite2D.play("walk")
	if Input.is_action_pressed("right"):
		move_velocity += move_speed / (deceleration * deceleration)
		$AnimatedSprite2D.scale.x = 2
		$AnimatedSprite2D.play("walk")
	if not (Input.is_action_pressed("left") or Input.is_action_pressed("right")):
		$AnimatedSprite2D.play("stand")
	velocity.x = move_velocity
	move_velocity = move_velocity * deceleration
	#Zeroing out velocity when it's low enough
	if abs(move_velocity) < 0:
		move_velocity = 0

	move_and_slide()

	print(can_wall_jump)


func _on_jump_buffering_timeout() -> void:
	$"Jump Buffering".stop()


func _on_coyote_time_timeout() -> void:
	is_on_ground = false
	$"Coyote Time".stop()
	


func _on_checkpoint_body_entered(body: Node2D) -> void:
	if body == $".":
		respawn_point = position


func _on_damage_hitbox_body_entered(_body: Node2D) -> void:
	death()


func _on_ladder_hitbox_body_entered(_body: Node2D) -> void:
	on_ladder = true


func _on_ladder_hitbox_body_exited(_body: Node2D) -> void:
	on_ladder = false


func _on_key_body_entered(body: Node2D) -> void:
	if body == $".":
		keys_collected += 1


func _on_door_body_entered(body: Node2D) -> void:
	if body == $"." and keys_collected >= 3:
		get_tree().change_scene_to_file("res://Scenes/level_2.tscn")
		can_wall_jump = true
		keys_collected = 0


func _on_door2_body_entered(body: Node2D) -> void:
	if body == $"." and keys_collected >= 3:
		win()

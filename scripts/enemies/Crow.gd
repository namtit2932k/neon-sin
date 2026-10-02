extends CharacterBody2D


# ==================================================
# SIGNAL
# ==================================================

signal health_changed(current_hp: float, max_hp: float)


# ==================================================
# EXPORTS
# ==================================================

@export_group("Movement")
@export var move_speed: float = 100.0
@export var gravity: float = 1200.0

@export_group("Combat")
@export var max_hp: float = 500.0
@export var attack_damage: float = 20.0
@export var attack_cooldown: float = 1.5


# ==================================================
# STATE
# ==================================================

var hp: float = 500.0
var can_attack: bool = true
var is_attacking: bool = false
var is_dead: bool = false
var has_hit_this_attack: bool = false
var is_getting_hit: bool = false

# Rest position of the attack hitbox, flipped with facing.
var attack_offset_x: float = 0.0


# ==================================================
# REFERENCES
# ==================================================

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var attack_collision: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var boss_hud: CanvasLayer = get_node_or_null("BossHUD")


# ==================================================
# LIFECYCLE
# ==================================================

func _ready() -> void:
	hp = max_hp
	attack_offset_x = attack_collision.position.x

	if boss_hud != null:
		health_changed.connect(boss_hud.set_boss_hp)

	health_changed.emit(hp, max_hp)

	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.play("idle")


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_apply_gravity(delta)

	var player := get_player()

	if player == null:
		_stand_still("idle")
		move_and_slide()
		return

	# Attacks lock movement, so the boss holds position.
	if is_attacking:
		velocity.x = 0.0
		move_and_slide()
		return

	# Close enough: hold ground and swing.
	if is_player_in_attack_range(player):
		velocity.x = 0.0

		if can_attack:
			face_player(player)
			start_attack()
		elif not is_getting_hit:
			animated_sprite.play("idle")

		move_and_slide()
		return

	if is_player_detected(player):
		_chase(player)
	else:
		_stand_still("idle")

	move_and_slide()


# ==================================================
# MOVEMENT
# ==================================================

func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y += gravity * delta


func _stand_still(animation: StringName) -> void:
	velocity.x = 0.0

	if not is_attacking and not is_getting_hit:
		animated_sprite.play(animation)


func _chase(player: Node2D) -> void:
	var direction := signf(player.global_position.x - global_position.x)

	velocity.x = direction * move_speed
	update_facing(direction)

	if not is_getting_hit:
		animated_sprite.play("move")


# ==================================================
# TARGET
# ==================================================

func get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D


func is_player_detected(player: Node2D) -> bool:
	return (
		detection_area != null
		and detection_area.overlaps_body(player)
	)


func is_player_in_attack_range(player: Node2D) -> bool:
	return (
		attack_area != null
		and attack_area.overlaps_body(player)
	)


# ==================================================
# FACING
# ==================================================

func face_player(player: Node2D) -> void:
	update_facing(signf(player.global_position.x - global_position.x))


func update_facing(direction: float) -> void:
	if direction == 0.0:
		return

	# The sprite art faces left by default.
	animated_sprite.flip_h = direction > 0.0

	# Mirror the hitbox to the side the boss faces.
	attack_collision.position.x = (
		-attack_offset_x if direction > 0.0 else attack_offset_x
	)


# ==================================================
# ATTACK
# ==================================================

func start_attack() -> void:
	if is_attacking or not can_attack:
		return

	is_attacking = true
	can_attack = false
	has_hit_this_attack = false
	velocity.x = 0.0

	animated_sprite.play("attack")

	# Damage lands shortly after the swing starts.
	await get_tree().create_timer(0.2).timeout

	if is_attacking and not is_dead:
		deal_attack_damage()


func deal_attack_damage() -> void:
	if has_hit_this_attack:
		return

	for target in attack_area.get_overlapping_bodies():
		if target == self or not target.is_in_group("player"):
			continue

		target.take_damage(attack_damage, global_position.x)
		has_hit_this_attack = true
		print("Boss hit Player for ", attack_damage, " damage")
		return


func _on_animation_finished() -> void:
	match animated_sprite.animation:
		"attack":
			_finish_attack()
		"gethit":
			is_getting_hit = false


func _finish_attack() -> void:
	is_attacking = false
	velocity.x = 0.0
	animated_sprite.play("idle")

	await get_tree().create_timer(attack_cooldown).timeout

	if not is_dead:
		can_attack = true


# ==================================================
# DAMAGE
# ==================================================

func take_damage(amount: float, attacker_x: float = NAN) -> void:
	if is_dead:
		return

	hp = clampf(hp - amount, 0.0, max_hp)
	health_changed.emit(hp, max_hp)

	print("Boss HP: ", hp, "/", max_hp)

	if hp <= 0.0:
		die()
		return

	start_gethit()


# Never flinches mid attack, so player hits cannot
# interrupt the boss swing.
func start_gethit() -> void:
	if is_attacking or is_dead:
		return

	is_getting_hit = true
	animated_sprite.play("gethit")


func die() -> void:
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO

	# Collision off so the player can walk over the corpse.
	$CollisionShape2D.set_deferred("disabled", true)
	detection_area.set_deferred("monitoring", false)
	attack_area.set_deferred("monitoring", false)

	animated_sprite.play("death")
	await animated_sprite.animation_finished

	# BossHUD is a child node, so it vanishes with the boss.
	await get_tree().create_timer(1.5).timeout
	queue_free()
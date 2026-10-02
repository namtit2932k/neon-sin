extends CharacterBody2D

# ==================================================
# CONSTANTS
# ==================================================

# Physics layers: 1 = world, 2 = enemy.
const MASK_WORLD: int = 1
const MASK_WORLD_ENEMY: int = 3

# The player moves to a "ghost" layer while dashing.
# No mask listens to it, so enemies neither collide
# with nor push the player mid dash.
const LAYER_PLAYER: int = 1
const LAYER_DASH_GHOST: int = 4


# ==================================================
# EXPORTS
# ==================================================

@export_group("Movement")
@export var move_speed: float = 230.0
@export var run_multiplier: float = 1.8
@export var jump_force: float = 520.0
@export var gravity: float = 1200.0

@export_group("Stamina")
@export var max_stamina: float = 100.0
@export var stamina_drain: float = 15.0
@export var stamina_regen: float = 20.0

@export_group("Dash")
@export var dash_speed: float = 620.0
@export var dash_duration: float = 0.55
@export var dash_cooldown: float = 0.4
@export var dash_stamina_cost: float = 8.0

# Collisions stay off this long after a dash so the
# player can fully exit an enemy body.
@export var dash_exit_grace: float = 0.15

@export var dash_invulnerable: bool = true

@export_group("Combat")
@export var max_hp: float = 100.0
@export var attack_damage: float = 50.0

@export_group("Knockback")
@export var knockback_force: float = 220.0
@export var knockback_up_force: float = 120.0
@export var knockback_decel: float = 900.0


# ==================================================
# STATE
# ==================================================

var hp: float = 100.0
var stamina: float = 100.0

var is_dead: bool = false
var is_running: bool = false

# Stays true while Shift is held on an empty bar,
# so the player cannot chain runs without releasing.
var run_locked: bool = false

var is_attacking: bool = false
var has_hit_this_attack: bool = false

var is_getting_hit: bool = false

var is_dashing: bool = false
var dash_direction: float = 1.0
var dash_timer: float = 0.0
var dash_cd: float = 0.0
var dash_grace_timer: float = 0.0

# Rest position of the attack hitbox, flipped with facing.
var attack_offset_x: float = 0.0


# ==================================================
# REFERENCES
# ==================================================

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_collision: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var attack_voice: AudioStreamPlayer = $AttackVoice
@onready var attack_hit: AudioStreamPlayer = $AttackHit
@onready var hud = get_node("../HUD")


# ==================================================
# LIFECYCLE
# ==================================================

func _ready() -> void:
	add_to_group("player")

	hp = max_hp
	stamina = max_stamina
	attack_offset_x = attack_collision.position.x

	animated_sprite.animation_finished.connect(_on_animation_finished)

	hud.update_hp(hp, max_hp)
	hud.update_stamina(stamina, max_stamina)


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)

	# Runs before the early returns so the grace timer
	# also ticks while stunned or dead.
	_update_dash_grace(delta)

	if is_dead:
		velocity.x = 0.0
		move_and_slide()
		return

	if is_getting_hit:
		velocity.x = move_toward(velocity.x, 0.0, knockback_decel * delta)
		move_and_slide()
		return

	var direction := Input.get_axis("move_left", "move_right")

	if Input.is_action_just_pressed("attack") and not is_attacking:
		start_attack()

	# Tap Shift to dash, hold Shift to run.
	dash_cd = maxf(dash_cd - delta, 0.0)

	if Input.is_action_just_pressed("run") and _can_dash():
		start_dash(direction)

	_update_stamina(delta, direction)
	_update_horizontal_speed(delta, direction)
	_update_facing(direction)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -jump_force

	_update_animation(direction)

	move_and_slide()


# ==================================================
# MOVEMENT
# ==================================================

func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y += gravity * delta


func _update_stamina(delta: float, direction: float) -> void:
	if not Input.is_action_pressed("run"):
		run_locked = false

	is_running = false

	var wants_to_run := (
		Input.is_action_pressed("run")
		and direction != 0.0
		and not run_locked
	)

	if wants_to_run and stamina > 0.0:
		var cost := stamina_drain * delta

		if stamina <= cost:
			stamina = 0.0
			run_locked = true
		else:
			stamina -= cost
			is_running = true
	else:
		stamina = minf(stamina + stamina_regen * delta, max_stamina)

	hud.update_stamina(stamina, max_stamina)


func _update_horizontal_speed(delta: float, direction: float) -> void:
	if is_dashing:
		dash_timer -= delta
		velocity.x = dash_direction * dash_speed

		# Also ends early when another state (attack,
		# gethit) takes over the animation.
		if dash_timer <= 0.0 or animated_sprite.animation != "dash":
			_stop_dash()

		return

	var speed := move_speed * (run_multiplier if is_running else 1.0)
	velocity.x = direction * speed


func _update_facing(direction: float) -> void:
	# A dash keeps its direction, so the sprite and the
	# hitbox stay locked until it ends.
	if direction == 0.0 or is_dashing:
		return

	animated_sprite.flip_h = direction < 0.0
	attack_collision.position.x = (
		-attack_offset_x if direction < 0.0 else attack_offset_x
	)


func _update_animation(direction: float) -> void:
	# Attack and dash own the sprite until they finish.
	if is_attacking or is_dashing:
		return

	if direction == 0.0:
		animated_sprite.play("idle")
	elif is_running:
		animated_sprite.play("run")
	else:
		animated_sprite.play("move")


func use_stamina(amount: float) -> void:
	stamina = clampf(stamina - amount, 0.0, max_stamina)
	hud.update_stamina(stamina, max_stamina)


# ==================================================
# DASH
# ==================================================

func _can_dash() -> bool:
	if is_dead or is_getting_hit or is_attacking or is_dashing:
		return false

	return dash_cd <= 0.0 and stamina >= dash_stamina_cost


func start_dash(direction: float) -> void:
	# Standing still dashes towards the current facing.
	dash_direction = (
		direction
		if direction != 0.0
		else (-1.0 if animated_sprite.flip_h else 1.0)
	)

	is_dashing = true
	dash_timer = dash_duration
	dash_cd = dash_cooldown
	dash_grace_timer = 0.0

	# Ghost layer + world only mask = phase through enemies.
	set_deferred("collision_layer", LAYER_DASH_GHOST)
	set_deferred("collision_mask", MASK_WORLD)

	use_stamina(dash_stamina_cost)
	animated_sprite.play("dash")


func _stop_dash() -> void:
	is_dashing = false
	dash_grace_timer = dash_exit_grace


func _update_dash_grace(delta: float) -> void:
	if dash_grace_timer <= 0.0:
		return

	dash_grace_timer -= delta

	if dash_grace_timer <= 0.0:
		set_deferred("collision_layer", LAYER_PLAYER)
		set_deferred("collision_mask", MASK_WORLD_ENEMY)


# ==================================================
# ATTACK
# ==================================================

func start_attack() -> void:
	if is_attacking:
		return

	is_attacking = true
	has_hit_this_attack = false
	_stop_dash()

	animated_sprite.play("attack")
	attack_voice.play()

	# Let the swing start before the hitbox is checked
	# so the hit lands in the middle of the animation.
	await get_tree().create_timer(0.15).timeout

	if is_attacking:
		deal_attack_damage()


func deal_attack_damage() -> void:
	if has_hit_this_attack:
		return

	for target in attack_area.get_overlapping_bodies():
		if target == self or not target.has_method("take_damage"):
			continue

		target.take_damage(attack_damage, global_position.x)
		has_hit_this_attack = true
		attack_hit.play()
		return


func _on_animation_finished() -> void:
	match animated_sprite.animation:
		"attack":
			is_attacking = false
		"gethit":
			is_getting_hit = false


# ==================================================
# DAMAGE
# ==================================================

func take_damage(amount: float, attacker_x: float = NAN) -> void:
	if is_dead:
		return

	# Dashing (plus the grace window) is invulnerable,
	# otherwise a hit would cancel the dash mid flight.
	if dash_invulnerable and (is_dashing or dash_grace_timer > 0.0):
		return

	hp = clampf(hp - amount, 0.0, max_hp)
	hud.update_hp(hp, max_hp)

	print("Player HP: ", hp)

	if hp <= 0.0:
		die()
		return

	start_gethit(attacker_x)


func start_gethit(attacker_x: float) -> void:
	is_attacking = false
	has_hit_this_attack = true
	is_getting_hit = true
	_stop_dash()

	animated_sprite.play("gethit")

	velocity.x = _knockback_direction(attacker_x) * knockback_force
	velocity.y = -knockback_up_force


func _knockback_direction(attacker_x: float) -> float:
	# Unknown attacker (NAN) pushes the player right.
	if is_nan(attacker_x):
		return 1.0

	var direction := signf(global_position.x - attacker_x)
	return 1.0 if direction == 0.0 else direction


func die() -> void:
	if is_dead:
		return

	is_dead = true
	is_attacking = false
	is_getting_hit = false
	_stop_dash()

	velocity = Vector2.ZERO
	print("Player died")

	animated_sprite.play("death")
	await animated_sprite.animation_finished

	get_tree().reload_current_scene()
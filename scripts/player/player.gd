extends CharacterBody2D

# =========================
# MOVEMENT
# =========================
@export var move_speed: float = 200.0
@export var run_multiplier: float = 1.5
@export var jump_force: float = 400.0
@export var gravity: float = 1200.0

# =========================
# STAMINA
# =========================
@export var max_stamina: float = 100.0
@export var stamina_drain: float = 25.0
@export var stamina_regen: float = 20.0

var stamina: float = 100.0
var is_running: bool = false

# Khi stamina hết, không thể chạy lại
# cho tới khi thả Shift.
var run_locked: bool = false

# =========================
# HP
# =========================
@export var max_hp: float = 100.0
var hp: float = 100.0

# Đã chết → không điều khiển,
# đợi animation die xong thì restart.
var is_dead: bool = false

# =========================
# ATTACK
# =========================
@export var attack_damage: float = 50.0

var is_attacking: bool = false
var has_hit_this_attack: bool = false

# Vị trí gốc của hitbox attack (bên phải).
# Dùng để lật hitbox khi quay mặt trái/phải.
var attack_offset_x: float = 0.0

# =========================
# GETHIT / KNOCKBACK
# =========================
@export var knockback_force: float = 220.0
@export var knockback_up_force: float = 120.0
@export var knockback_decel: float = 900.0

# Đang bị đánh (mất điều khiển ngắn)
var is_getting_hit: bool = false

# =========================
# REFERENCES
# =========================
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_collision: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var hud = get_node("../HUD")

# =========================
# AUDIO
# =========================
@onready var attack_voice: AudioStreamPlayer = $AttackVoice
@onready var attack_hit: AudioStreamPlayer = $AttackHit


func _ready() -> void:

	# Add Player vào group "player"
	add_to_group("player")

	# Initialize HP / stamina
	hp = max_hp
	stamina = max_stamina

	# Lưu vị trí gốc của hitbox attack
	attack_offset_x = attack_collision.position.x

	# Animation finished signal
	animated_sprite.animation_finished.connect(_on_animation_finished)

	# Update HUD
	hud.update_hp(hp, max_hp)
	hud.update_stamina(stamina, max_stamina)


func _physics_process(delta: float) -> void:

	# =========================
	# GRAVITY
	# =========================
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0


	# =========================
	# DEAD
	# =========================

	# Đã chết: chỉ rơi xuống đất,
	# không nhận input gì nữa.

	if is_dead:

		velocity.x = 0.0
		move_and_slide()
		return


	# =========================
	# GETHIT STUN
	# =========================

	# Trong lúc bị đánh:
	# - Không điều khiển được
	# - Trượt theo knockback rồi dừng lại

	if is_getting_hit:

		velocity.x = move_toward(
			velocity.x,
			0.0,
			knockback_decel * delta
		)

		move_and_slide()
		return


	# =========================
	# ATTACK INPUT
	# =========================
	if Input.is_action_just_pressed("attack") and not is_attacking:
		start_attack()


	# =========================
	# MOVEMENT INPUT
	# =========================
	var direction: float = Input.get_axis(
		"move_left",
		"move_right"
	)


	# =========================
	# RUN LOCK
	# =========================

	# Nếu đã hết stamina và đang giữ Shift,
	# không cho chạy lại.
	if not Input.is_action_pressed("run"):
		run_locked = false


	var wants_to_run: bool = (
		Input.is_action_pressed("run")
		and direction != 0.0
		and not run_locked
	)


	# =========================
	# STAMINA
	# =========================
	is_running = false

	if wants_to_run and stamina > 0.0:

		var stamina_cost: float = stamina_drain * delta

		if stamina <= stamina_cost:

			stamina = 0.0
			is_running = false
			run_locked = true

		else:

			stamina -= stamina_cost
			is_running = true

	else:

		# Regenerate stamina
		stamina += stamina_regen * delta
		stamina = min(stamina, max_stamina)


	# Update HUD
	hud.update_stamina(stamina, max_stamina)


	# =========================
	# SPEED
	# =========================

	var current_speed: float = move_speed

	if is_running:
		current_speed *= run_multiplier


	velocity.x = direction * current_speed


	# =========================
	# FLIP SPRITE
	# =========================

	if direction != 0.0:
		animated_sprite.flip_h = direction < 0.0

		# Lật hitbox attack theo hướng mặt
		attack_collision.position.x = (
			attack_offset_x * -1.0
			if direction < 0.0
			else attack_offset_x
		)


	# =========================
	# JUMP
	# =========================

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -jump_force


	# =========================
	# ANIMATION
	# =========================

	# Nếu đang attack:
	# KHÔNG đổi sang idle/move/run.
	# Nhưng vẫn cho phép movement + jump.
	if not is_attacking:

		if direction != 0.0:

			if is_running:
				animated_sprite.play("run")
			else:
				animated_sprite.play("move")

		else:

			animated_sprite.play("idle")


	# =========================
	# MOVE
	# =========================

	move_and_slide()


# ==================================================
# ATTACK
# ==================================================

func start_attack() -> void:

	if is_attacking:
		return

	is_attacking = true
	has_hit_this_attack = false

	animated_sprite.play("attack")

	# Tiếng hô khi tung đòn (bus Voice)
	attack_voice.play()

	# Chờ một chút để animation bắt đầu.
	# Sau đó kiểm tra hit.
	await get_tree().create_timer(0.15).timeout

	if is_attacking:
		deal_attack_damage()


func deal_attack_damage() -> void:

	if has_hit_this_attack:
		return

	var targets: Array[Node2D] = attack_area.get_overlapping_bodies()

	for target: Node2D in targets:

		if target == self:
			continue

		if target.has_method("take_damage"):

			target.take_damage(
				attack_damage,
				global_position.x
			)

			has_hit_this_attack = true

			# Tiếng trúng địch (bus SFX)
			attack_hit.play()

			break


func _on_animation_finished() -> void:

	if animated_sprite.animation == "attack":

		is_attacking = false

	elif animated_sprite.animation == "gethit":

		is_getting_hit = false


# ==================================================
# DAMAGE
# ==================================================

func take_damage(amount: float, attacker_x: float = NAN) -> void:

	if is_dead:
		return

	hp -= amount
	hp = clamp(hp, 0.0, max_hp)

	hud.update_hp(hp, max_hp)

	print("Player HP: ", hp)

	if hp <= 0.0:
		die()
		return

	start_gethit(attacker_x)


# ==================================================
# GETHIT
# ==================================================

# Bị đánh → phát animation gethit
# + knockback đẩy player ra xa kẻ đánh.

func start_gethit(attacker_x: float) -> void:

	# Hủy attack đang thực hiện (nếu có)
	is_attacking = false
	has_hit_this_attack = true

	# Phát animation gethit
	is_getting_hit = true
	animated_sprite.play("gethit")


	# =========================
	# KNOCKBACK
	# =========================

	# Đẩy player ra xa vị trí kẻ đánh.
	# Nếu không biết vị trí kẻ đánh
	# (attacker_x = NAN) → đẩy về bên phải.

	var knock_direction: float = 1.0

	if not is_nan(attacker_x):

		knock_direction = signf(
			global_position.x - attacker_x
		)

		if knock_direction == 0.0:
			knock_direction = 1.0

	velocity.x = knock_direction * knockback_force
	velocity.y = -knockback_up_force


func die() -> void:

	if is_dead:
		return

	is_dead = true

	# Hủy các trạng thái đang thực hiện
	is_attacking = false
	is_getting_hit = false

	velocity = Vector2.ZERO

	print("Player died")

	# =========================
	# DEATH ANIMATION
	# =========================

	animated_sprite.play("death")

	# Đợi animation chết chạy xong
	# rồi restart lại màn chơi từ đầu.

	await animated_sprite.animation_finished

	get_tree().reload_current_scene()


# ==================================================
# STAMINA
# ==================================================

func use_stamina(amount: float) -> void:

	stamina -= amount
	stamina = clamp(stamina, 0.0, max_stamina)

	hud.update_stamina(stamina, max_stamina)

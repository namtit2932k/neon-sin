extends CharacterBody2D


# ==================================================
# SIGNAL
# ==================================================

signal health_changed(current_hp: float, max_hp: float)


# ==================================================
# MOVEMENT
# ==================================================

@export var move_speed: float = 100.0
@export var gravity: float = 1200.0


# ==================================================
# HP
# ==================================================

@export var max_hp: float = 500.0
var hp: float = 500.0


# ==================================================
# ATTACK
# ==================================================

@export var attack_damage: float = 20.0
@export var attack_cooldown: float = 1.5

var can_attack: bool = true
var is_attacking: bool = false
var is_dead: bool = false
var has_hit_this_attack: bool = false
var is_getting_hit: bool = false

# Vị trí gốc của hitbox attack (bên trái).
# Dùng để lật hitbox khi quay mặt trái/phải.
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
# READY
# ==================================================

func _ready() -> void:

	# =========================
	# INITIALIZE HP
	# =========================

	hp = max_hp


	# =========================
	# SAVE ATTACK OFFSET
	# =========================

	# Lưu vị trí gốc của hitbox attack

	attack_offset_x = attack_collision.position.x


	# =========================
	# CONNECT BOSS HUD
	# =========================

	# Nối signal health_changed với BossHUD
	# để thanh máu boss cập nhật khi bị đánh.

	if boss_hud != null:

		health_changed.connect(boss_hud.set_boss_hp)


	# =========================
	# SEND INITIAL HP
	# =========================

	health_changed.emit(
		hp,
		max_hp
	)


	# =========================
	# ANIMATION SIGNAL
	# =========================

	animated_sprite.animation_finished.connect(
		_on_animation_finished
	)


	# =========================
	# START IDLE
	# =========================

	animated_sprite.play("idle")


# ==================================================
# PHYSICS PROCESS
# ==================================================

func _physics_process(delta: float) -> void:

	if is_dead:
		return


	# ==================================================
	# GRAVITY
	# ==================================================

	if not is_on_floor():

		velocity.y += gravity * delta

	else:

		velocity.y = 0.0


	# ==================================================
	# FIND PLAYER
	# ==================================================

	var player: Node2D = get_player()


	if player == null:

		velocity.x = 0.0

		if not is_attacking and not is_getting_hit:

			animated_sprite.play("idle")

		move_and_slide()

		return


	# ==================================================
	# ATTACKING
	# ==================================================

	# Trong lúc attack:
	# - Không di chuyển
	# - Không chase
	# - Không attack lần nữa

	if is_attacking:

		velocity.x = 0.0

		move_and_slide()

		return


	# ==================================================
	# ATTACK RANGE
	# ==================================================

	if is_player_in_attack_range(player):

		# Đứng yên khi player ở trong attack range

		velocity.x = 0.0


		# Nếu cooldown đã xong → attack

		if can_attack:

			face_player(player)

			start_attack()

		elif not is_getting_hit:

			# Đang cooldown → idle

			animated_sprite.play("idle")


		move_and_slide()

		return


	# ==================================================
	# CHASE PLAYER
	# ==================================================

	if is_player_detected(player):

		var direction: float = sign(
			player.global_position.x -
			global_position.x
		)


		# =========================
		# MOVE TOWARD PLAYER
		# =========================

		velocity.x = direction * move_speed


		# =========================
		# FACE PLAYER
		# =========================

		update_facing(direction)


		# =========================
		# MOVE ANIMATION
		# =========================

		if not is_getting_hit:

			animated_sprite.play("move")

	else:

		# Player ngoài DetectionArea

		velocity.x = 0.0

		if not is_getting_hit:

			animated_sprite.play("idle")


	# ==================================================
	# MOVE
	# ==================================================

	move_and_slide()


# ==================================================
# FIND PLAYER
# ==================================================

func get_player() -> Node2D:

	var player = get_tree().get_first_node_in_group("player")

	if player != null:

		return player

	return null


# ==================================================
# DETECTION
# ==================================================

func is_player_detected(player: Node2D) -> bool:

	if detection_area == null:

		return false

	return detection_area.overlaps_body(player)


func is_player_in_attack_range(player: Node2D) -> bool:

	if attack_area == null:

		return false

	return attack_area.overlaps_body(player)


# ==================================================
# FACE PLAYER
# ==================================================

func face_player(player: Node2D) -> void:

	var direction: float = sign(
		player.global_position.x -
		global_position.x
	)

	update_facing(direction)


# ==================================================
# FACE DIRECTION
# ==================================================

# Lật sprite và hitbox attack
# theo hướng di chuyển / hướng player.

func update_facing(direction: float) -> void:

	if direction == 0.0:
		return

	# Sprite mặc định quay trái,
	# nên flip_h = true khi sang phải.

	animated_sprite.flip_h = direction > 0.0

	# Hitbox gốc ở bên trái (attack_offset_x âm).
	# Quay sang phải → lật hitbox sang phải.

	if direction > 0.0:

		attack_collision.position.x = \
			-attack_offset_x

	else:

		attack_collision.position.x = \
			attack_offset_x


# ==================================================
# START ATTACK
# ==================================================

func start_attack() -> void:

	if is_attacking:
		return

	if not can_attack:
		return


	# =========================
	# ATTACK STATE
	# =========================

	is_attacking = true
	can_attack = false
	has_hit_this_attack = false

	velocity.x = 0.0


	# =========================
	# PLAY ATTACK ANIMATION
	# =========================

	animated_sprite.play("attack")


	# =========================
	# ATTACK HIT TIMING
	# =========================

	# 0.2 giây sau khi animation bắt đầu
	# Boss gây damage.

	await get_tree().create_timer(0.2).timeout


	if is_attacking and not is_dead:

		deal_attack_damage()


# ==================================================
# DEAL DAMAGE
# ==================================================

func deal_attack_damage() -> void:

	if has_hit_this_attack:
		return

	if attack_area == null:
		return


	var targets: Array[Node2D] = \
		attack_area.get_overlapping_bodies()


	for target: Node2D in targets:

		# =========================
		# DON'T HIT SELF
		# =========================

		if target == self:

			continue


		# =========================
		# ONLY HIT PLAYER
		# =========================

		if target.is_in_group("player"):

			# Truyền vị trí boss để player
			# bị knockback ra xa đúng hướng.

			target.take_damage(
				attack_damage,
				global_position.x
			)

			has_hit_this_attack = true


			print(
				"Boss hit Player for ",
				attack_damage,
				" damage"
			)

			break


# ==================================================
# ATTACK ANIMATION FINISHED
# ==================================================

func _on_animation_finished() -> void:

	if animated_sprite.animation == "attack":

		# =========================
		# ATTACK FINISHED
		# =========================

		is_attacking = false

		velocity.x = 0.0


		# =========================
		# GO BACK TO IDLE
		# =========================

		animated_sprite.play("idle")


		# =========================
		# COOLDOWN
		# =========================

		# Boss sẽ đứng idle trong khoảng
		# attack_cooldown giây.

		await get_tree().create_timer(
			attack_cooldown
		).timeout


		# =========================
		# READY TO ATTACK AGAIN
		# =========================

		if not is_dead:

			can_attack = true

	elif animated_sprite.animation == "gethit":

		# =========================
		# GETHIT FINISHED
		# =========================

		is_getting_hit = false


# ==================================================
# TAKE DAMAGE
# ==================================================

func take_damage(
	amount: float,
	attacker_x: float = NAN
) -> void:

	if is_dead:
		return

	# =========================
	# REDUCE HP
	# =========================

	hp -= amount


	# Không cho HP < 0 hoặc > max_hp

	hp = clampf(
		hp,
		0.0,
		max_hp
	)


	# =========================
	# UPDATE HP HUD
	# =========================

	health_changed.emit(
		hp,
		max_hp
	)


	# =========================
	# DEBUG HP
	# =========================

	print(
		"Boss HP: ",
		hp,
		"/",
		max_hp
	)


	# =========================
	# DEATH
	# =========================

	if hp <= 0.0:

		die()
		return


	# =========================
	# GETHIT
	# =========================

	start_gethit()


# ==================================================
# GETHIT
# ==================================================

# Bị player đánh → phát animation gethit.
#
# Lưu ý: nếu đang attack thì KHÔNG flinch,
# để đòn đánh của boss không bị gián đoạn.

func start_gethit() -> void:

	if is_attacking or is_dead:
		return

	is_getting_hit = true

	animated_sprite.play("gethit")


# ==================================================
# DEATH
# ==================================================

func die() -> void:

	if is_dead:

		return

	is_dead = true
	velocity = Vector2.ZERO


	# =========================
	# DISABLE COLLISION
	# =========================

	# Tắt va chạm để player có thể
	# đi qua xác boss tự do.

	$CollisionShape2D.set_deferred("disabled", true)

	detection_area.set_deferred("monitoring", false)
	attack_area.set_deferred("monitoring", false)


	# =========================
	# DEATH ANIMATION
	# =========================

	animated_sprite.play("death")


	await animated_sprite.animation_finished


	# =========================
	# DISAPPEAR AFTER 2 SECONDS
	# =========================

	# Xác boss nằm yên 1.5 giây rồi biến mất.
	# BossHUD là node con của Crow
	# nên sẽ biến mất cùng lúc.

	await get_tree().create_timer(1.5).timeout

	queue_free()

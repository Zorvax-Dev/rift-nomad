extends CharacterBody2D
class_name ArenaFighter

signal died(fighter: ArenaFighter)
signal health_changed(fighter: ArenaFighter)
signal attack_landed(attacker: ArenaFighter, victim: ArenaFighter, damage_amount: float, critical: bool)
signal request_shot(shooter: ArenaFighter, origin: Vector2, direction: Vector2, damage_amount: float, shot_color: Color, critical: bool)

const RADIUS: float = 22.0
const MELEE_HALF_ANGLE: float = 1.10
const MOVE_POSE_THRESHOLD_SQ: float = 256.0
const HERO_STRIDE_PIXELS: float = 88.0
const ENEMY_STRIDE_PIXELS: float = 92.0
const MELEE_ATTACK_VISUAL_DURATION: float = 0.24
const RANGED_ATTACK_VISUAL_DURATION: float = 0.20

const HERO_IDLE_TEXTURE: Texture2D = preload("res://assets/hero/nomad_idle.webp")
const HERO_MOVE_TEXTURE: Texture2D = preload("res://assets/hero/nomad_move_cycle_a.png")
const HERO_MOVE_ALT_TEXTURE: Texture2D = preload("res://assets/hero/nomad_move_cycle_b.png")
const HERO_ATTACK_TEXTURE: Texture2D = preload("res://assets/hero/nomad_attack.webp")
const HERO_HIT_TEXTURE: Texture2D = preload("res://assets/hero/nomad_hit.webp")
const ENEMY_BLADE_IDLE_TEXTURE: Texture2D = preload("res://assets/enemies/enemy_blade_idle.png")
const ENEMY_BLADE_MOVE_TEXTURE: Texture2D = preload("res://assets/enemies/enemy_blade_move_a.png")
const ENEMY_BLADE_MOVE_ALT_TEXTURE: Texture2D = preload("res://assets/enemies/enemy_blade_move_b.png")
const ENEMY_BLADE_ATTACK_TEXTURE: Texture2D = preload("res://assets/enemies/enemy_blade_attack.png")
const ENEMY_BLADE_HIT_TEXTURE: Texture2D = preload("res://assets/enemies/enemy_blade_hit.png")
const ENEMY_BLASTER_IDLE_TEXTURE: Texture2D = preload("res://assets/enemies/enemy_blaster_idle.png")
const ENEMY_BLASTER_MOVE_TEXTURE: Texture2D = preload("res://assets/enemies/enemy_blaster_move_a.png")
const ENEMY_BLASTER_MOVE_ALT_TEXTURE: Texture2D = preload("res://assets/enemies/enemy_blaster_move_b.png")
const ENEMY_BLASTER_ATTACK_TEXTURE: Texture2D = preload("res://assets/enemies/enemy_blaster_attack.png")
const ENEMY_BLASTER_HIT_TEXTURE: Texture2D = preload("res://assets/enemies/enemy_blaster_hit.png")

var display_name: String = "Nomad"
var team: int = 0
var is_player: bool = false
var elite: bool = false
var dead: bool = false
var combat_enabled: bool = true

var body_color: Color = Color("6f7d98")
var accent_color: Color = Color("cad2e0")
var cape_color: Color = Color("1a1e29")
var visor_color: Color = Color("42d3ff")
var skin_color: Color = Color("d5b08a")
var masked: bool = true
var mask_style: int = 0
var outfit_name: String = "Ranger"
var outfit_idx: int = 0
var weapon_type: String = "blade"
var weapon_name: String = "Lame cobalt"
var weapon_color: Color = Color("52d6ff")
var weapon_skin_idx: int = 0

var max_health: float = 120.0
var health: float = 120.0
var speed: float = 240.0
var damage: float = 24.0
var attack_range: float = 92.0
var attack_cooldown_base: float = 0.58
var ranged_range: float = 420.0
var projectile_speed: float = 760.0

var regeneration: float = 0.0
var lifesteal: float = 0.0
var armor: float = 0.0
var critical_chance: float = 0.08
var critical_multiplier: float = 1.70

var mobile_input_vector: Vector2 = Vector2.ZERO
var arena_rect: Rect2 = Rect2(40, 100, 1200, 580)
var room_top_y: float = 250.0
var room_bottom_y: float = 650.0
var room_left_top_x: float = 300.0
var room_right_top_x: float = 980.0
var room_left_bottom_x: float = 80.0
var room_right_bottom_x: float = 1200.0
var room_scale_min: float = 0.78
var room_scale_max: float = 1.12
var room_base_scale: float = 1.0
var room_free_movement: bool = false
var target: ArenaFighter
var facing: Vector2 = Vector2.RIGHT
var visual_facing_x: float = 1.0
var hit_radius: float = 20.0

var attack_timer: float = 0.0
var attack_cooldown: float = 0.0
var stagger_timer: float = 0.0
var hit_flash: float = 0.0
var aura_phase: float = 0.0
var walk_phase: float = 0.0
var ai_rethink: float = 0.0
var ai_side: float = 1.0
var knockback_velocity: Vector2 = Vector2.ZERO
var shot_flash: float = 0.0
var attack_swing_direction: float = 1.0
var hit_stop_timer: float = 0.0
var damage_grace_timer: float = 0.0

var hero_pose_current: String = "idle"
var hero_pose_previous: String = "idle"
var hero_pose_blend: float = 1.0
var hero_motion_tilt: float = 0.0
var hero_ground_glow: float = 0.0
var hero_stride_phase: float = 0.0
var hero_stride_strength: float = 0.0

var enemy_pose_current: String = "idle"
var enemy_pose_previous: String = "idle"
var enemy_pose_blend: float = 1.0
var enemy_motion_tilt: float = 0.0
var enemy_ground_glow: float = 0.0
var enemy_stride_phase: float = 0.0
var enemy_stride_strength: float = 0.0

func _ready() -> void:
	add_to_group("fighters")
	collision_layer = 1
	collision_mask = 1
	var collision_shape_node: CollisionShape2D = CollisionShape2D.new()
	var circle_shape: CircleShape2D = CircleShape2D.new()
	circle_shape.radius = 19.0
	collision_shape_node.shape = circle_shape
	add_child(collision_shape_node)
	scale = Vector2.ONE
	z_index = 0
	queue_redraw()

func setup_from_profile(data: Dictionary, player_flag: bool, assigned_team: int) -> void:
	display_name = String(data.get("name", "Nomad"))
	body_color = data.get("body", Color("6f7d98")) as Color
	accent_color = data.get("accent", Color("cad2e0")) as Color
	cape_color = data.get("cape", Color("1a1e29")) as Color
	visor_color = data.get("visor", Color("42d3ff")) as Color
	skin_color = data.get("skin", Color("d5b08a")) as Color
	masked = bool(data.get("mask_on", true))
	mask_style = int(data.get("mask_style", 0))
	outfit_name = String(data.get("outfit_name", "Ranger"))
	outfit_idx = int(data.get("outfit_idx", 0))
	weapon_type = String(data.get("weapon_type", "blade"))
	weapon_name = String(data.get("weapon_name", "Lame cobalt"))
	weapon_color = data.get("weapon_color", Color("52d6ff")) as Color
	weapon_skin_idx = int(data.get("weapon_skin_idx", 0))
	max_health = float(data.get("health", 120.0))
	health = max_health
	speed = float(data.get("speed", 240.0))
	damage = float(data.get("damage", 24.0))
	attack_range = float(data.get("range", 92.0))
	attack_cooldown_base = float(data.get("attack_speed", 0.58))
	ranged_range = float(data.get("ranged_range", 420.0))
	projectile_speed = float(data.get("projectile_speed", 760.0))
	regeneration = float(data.get("regeneration", 0.0))
	lifesteal = float(data.get("lifesteal", 0.0))
	armor = float(data.get("armor", 0.0))
	critical_chance = float(data.get("critical_chance", 0.08))
	critical_multiplier = float(data.get("critical_multiplier", 1.70))
	elite = bool(data.get("elite", false))
	is_player = player_flag
	team = assigned_team
	visual_facing_x = 1.0
	hit_stop_timer = 0.0
	damage_grace_timer = 0.0
	hero_pose_current = "idle"
	hero_pose_previous = "idle"
	hero_pose_blend = 1.0
	hero_motion_tilt = 0.0
	hero_ground_glow = 0.0
	hero_stride_phase = 0.0
	hero_stride_strength = 0.0
	enemy_pose_current = "idle"
	enemy_pose_previous = "idle"
	enemy_pose_blend = 1.0
	enemy_motion_tilt = 0.0
	enemy_ground_glow = 0.0
	enemy_stride_phase = 0.0
	enemy_stride_strength = 0.0
	queue_redraw()

func apply_room_profile(profile: Dictionary) -> void:
	room_top_y = float(profile.get("top_y", arena_rect.position.y + 150.0))
	room_bottom_y = float(profile.get("bottom_y", arena_rect.end.y - 18.0))
	room_left_top_x = float(profile.get("left_top_x", arena_rect.position.x + 80.0))
	room_right_top_x = float(profile.get("right_top_x", arena_rect.end.x - 80.0))
	room_left_bottom_x = float(profile.get("left_bottom_x", arena_rect.position.x + 8.0))
	room_right_bottom_x = float(profile.get("right_bottom_x", arena_rect.end.x - 8.0))
	room_scale_min = float(profile.get("scale_min", 0.90))
	room_scale_max = float(profile.get("scale_max", 1.04))
	room_free_movement = bool(profile.get("free_movement", false))
	_apply_room_projection()

func set_room_base_scale(multiplier: float) -> void:
	room_base_scale = multiplier
	_apply_room_projection()

func _room_depth_ratio() -> float:
	if room_bottom_y <= room_top_y:
		return 1.0
	return clampf((global_position.y - room_top_y) / (room_bottom_y - room_top_y), 0.0, 1.0)

func _room_x_bounds_at(y_pos: float) -> Vector2:
	if room_free_movement:
		return Vector2(room_left_bottom_x, room_right_bottom_x)
	var denom: float = maxf(room_bottom_y - room_top_y, 0.001)
	var ratio: float = clampf((y_pos - room_top_y) / denom, 0.0, 1.0)
	var left_x: float = lerpf(room_left_top_x, room_left_bottom_x, ratio)
	var right_x: float = lerpf(room_right_top_x, room_right_bottom_x, ratio)
	return Vector2(left_x, right_x)

func _apply_room_projection() -> void:
	var clamped_y: float = clampf(global_position.y, room_top_y, room_bottom_y)
	global_position.y = clamped_y
	var bounds: Vector2 = _room_x_bounds_at(clamped_y)
	global_position.x = clampf(global_position.x, bounds.x + RADIUS, bounds.y - RADIUS)
	var depth: float = _room_depth_ratio()
	var depth_scale: float = lerpf(room_scale_min, room_scale_max, depth) * room_base_scale
	scale = Vector2(depth_scale, depth_scale)
	z_index = int(round(global_position.y))

func _physics_process(delta: float) -> void:
	if dead:
		velocity = Vector2.ZERO
		return

	if hit_stop_timer > 0.0:
		hit_stop_timer = maxf(0.0, hit_stop_timer - delta)
		queue_redraw()
		return

	aura_phase += delta
	walk_phase += delta * (6.0 if velocity.length_squared() > 25.0 else 1.2)
	attack_timer = maxf(0.0, attack_timer - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	hit_flash = maxf(0.0, hit_flash - delta)
	damage_grace_timer = maxf(0.0, damage_grace_timer - delta)
	stagger_timer = maxf(0.0, stagger_timer - delta)
	shot_flash = maxf(0.0, shot_flash - delta)
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 980.0 * delta)

	if regeneration > 0.0 and health < max_health and combat_enabled:
		health = minf(max_health, health + regeneration * delta)

	if not combat_enabled:
		velocity = Vector2.ZERO
		queue_redraw()
		return

	if stagger_timer > 0.0:
		velocity = knockback_velocity
	else:
		if is_player:
			_player_movement()
			_auto_attack()
		else:
			_enemy_ai(delta)
		velocity += knockback_velocity

	_update_visual_facing()
	move_and_slide()
	_apply_room_projection()
	if is_player:
		_update_player_visual_state(delta)
	else:
		_update_enemy_visual_state(delta)
	queue_redraw()

func _update_visual_facing() -> void:
	# During an attack, the artwork must face the actual target/shot direction.
	# Outside attacks, the running artwork follows the real movement direction.
	if attack_timer > 0.0 or shot_flash > 0.0:
		if absf(facing.x) > 0.05:
			visual_facing_x = -1.0 if facing.x < 0.0 else 1.0
		return
	if absf(velocity.x) > 8.0:
		visual_facing_x = -1.0 if velocity.x < 0.0 else 1.0

func _movement_side_sign() -> float:
	return visual_facing_x

func _select_move_cycle_texture(primary: Texture2D, alternate: Texture2D, phase: float) -> Texture2D:
	var use_primary: bool = sin(phase) >= 0.0
	if _movement_side_sign() < 0.0:
		use_primary = not use_primary
	return primary if use_primary else alternate

func _player_movement() -> void:
	var move_dir: Vector2 = mobile_input_vector
	if move_dir.length_squared() < 0.01:
		move_dir = Vector2.ZERO
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_UP):
			move_dir.y -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			move_dir.y += 1.0
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_LEFT):
			move_dir.x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			move_dir.x += 1.0
	if move_dir.length_squared() > 1.0:
		move_dir = move_dir.normalized()
	if move_dir.length_squared() > 0.01:
		facing = move_dir.normalized()
	velocity = move_dir * speed

func _auto_attack() -> void:
	var nearest: ArenaFighter = _find_nearest_enemy()
	if nearest == null:
		return
	var offset: Vector2 = nearest.global_position - global_position
	var distance: float = offset.length()
	if distance > 0.1:
		facing = offset / distance
	if weapon_type == "blade":
		if distance <= attack_range and attack_cooldown <= 0.0:
			perform_melee_attack()
	else:
		if distance <= ranged_range and attack_cooldown <= 0.0:
			fire_shot(facing, nearest)

func _find_nearest_enemy() -> ArenaFighter:
	var nearest: ArenaFighter = null
	var nearest_distance: float = INF
	for node: Node in get_tree().get_nodes_in_group("fighters"):
		var other: ArenaFighter = node as ArenaFighter
		if other == null or other == self or other.dead or other.team == team:
			continue
		var distance: float = global_position.distance_squared_to(other.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = other
	return nearest

func _enemy_ai(delta: float) -> void:
	if not is_instance_valid(target) or target.dead:
		target = _find_nearest_enemy()
	if not is_instance_valid(target) or target.dead:
		velocity = Vector2.ZERO
		return

	ai_rethink -= delta
	if ai_rethink <= 0.0:
		ai_rethink = randf_range(0.25, 0.52)
		ai_side = -1.0 if randf() < 0.5 else 1.0

	var to_target: Vector2 = target.global_position - global_position
	var distance: float = to_target.length()
	if distance > 0.1:
		facing = to_target / distance
	var tangent: Vector2 = Vector2(-facing.y, facing.x) * ai_side

	if weapon_type == "blade":
		var desired_blade_range: float = attack_range * 0.78
		if distance > desired_blade_range + 16.0:
			velocity = (facing + tangent * 0.16).normalized() * speed * 0.86
		elif distance < desired_blade_range - 12.0:
			velocity = (-facing + tangent * 0.34).normalized() * speed * 0.56
		else:
			velocity = tangent * speed * 0.25
			if attack_cooldown <= 0.0:
				perform_melee_attack()
	else:
		var desired_gun_range: float = minf(ranged_range * 0.72, 285.0)
		if distance > desired_gun_range + 36.0:
			velocity = (facing + tangent * 0.22).normalized() * speed * 0.82
		elif distance < desired_gun_range - 40.0:
			velocity = (-facing + tangent * 0.40).normalized() * speed * 0.72
		else:
			velocity = tangent * speed * 0.35
			if attack_cooldown <= 0.0 and distance <= ranged_range:
				fire_shot(facing, target)

func perform_melee_attack() -> Array[ArenaFighter]:
	var victims: Array[ArenaFighter] = []
	if dead or attack_cooldown > 0.0 or not combat_enabled:
		return victims

	attack_timer = MELEE_ATTACK_VISUAL_DURATION
	attack_cooldown = attack_cooldown_base
	attack_swing_direction *= -1.0

	for node: Node in get_tree().get_nodes_in_group("fighters"):
		var other: ArenaFighter = node as ArenaFighter
		if other == null or other == self or other.dead or other.team == team:
			continue
		var offset: Vector2 = other.global_position - global_position
		var distance: float = offset.length()
		if distance > attack_range or distance < 0.1:
			continue
		var angle: float = absf(facing.angle_to(offset / distance))
		if angle > MELEE_HALF_ANGLE:
			continue
		var critical: bool = randf() < critical_chance
		var outgoing_damage: float = damage * (critical_multiplier if critical else 1.0)
		var knockback_strength: float = 310.0 if critical else 235.0
		var hit_stagger: float = 0.16 if critical else 0.11
		var actual_damage: float = other.take_damage(outgoing_damage, (offset / distance) * knockback_strength, hit_stagger)
		if lifesteal > 0.0 and actual_damage > 0.0:
			health = minf(max_health, health + actual_damage * lifesteal)
		attack_landed.emit(self, other, actual_damage, critical)
		victims.append(other)
	return victims

func fire_shot(direction: Vector2, intended_target: ArenaFighter = null) -> void:
	if dead or attack_cooldown > 0.0 or not combat_enabled:
		return
	attack_timer = RANGED_ATTACK_VISUAL_DURATION
	attack_cooldown = attack_cooldown_base
	shot_flash = 0.11
	var shoot_dir: Vector2 = direction
	if is_instance_valid(intended_target) and not intended_target.dead:
		var aim_offset: Vector2 = intended_target.global_position - global_position
		if aim_offset.length() > 0.1:
			shoot_dir = aim_offset.normalized()
	if not is_player:
		shoot_dir = shoot_dir.rotated(randf_range(-0.065, 0.065))
	var shot_side_sign: float = visual_facing_x
	if absf(shoot_dir.x) > 0.05:
		shot_side_sign = -1.0 if shoot_dir.x < 0.0 else 1.0
	visual_facing_x = shot_side_sign
	var local_muzzle: Vector2 = Vector2(shot_side_sign * (30.0 if is_player else 46.0), -44.0 if is_player else -56.0)
	var muzzle_origin: Vector2 = to_global(local_muzzle)
	request_shot.emit(self, muzzle_origin, shoot_dir, damage, weapon_color, randf() < critical_chance)

func take_damage(amount: float, knockback: Vector2 = Vector2.ZERO, stagger: float = 0.10) -> float:
	if dead:
		return 0.0
	# Courte fenêtre anti-burst pour éviter que plusieurs ennemis retirent la vie du joueur au même instant.
	if is_player and damage_grace_timer > 0.0:
		return 0.0
	var reduction: float = clampf(armor, 0.0, 0.65)
	var actual_damage: float = maxf(1.0, amount * (1.0 - reduction))
	health = maxf(0.0, health - actual_damage)
	if is_player:
		damage_grace_timer = 0.16
	knockback_velocity += knockback
	stagger_timer = maxf(stagger_timer, stagger)
	hit_flash = 0.14
	health_changed.emit(self)
	if health <= 0.0:
		dead = true
		velocity = Vector2.ZERO
		collision_layer = 0
		collision_mask = 0
		died.emit(self)
	queue_redraw()
	return actual_damage

func apply_hit_stop(duration: float) -> void:
	hit_stop_timer = maxf(hit_stop_timer, clampf(duration, 0.0, 0.08))

func health_ratio() -> float:
	if max_health <= 0.0:
		return 0.0
	return health / max_health

func _draw() -> void:
	if dead:
		_draw_shadow(0.18)
		draw_circle(Vector2.ZERO, 19.0, Color(0.07, 0.08, 0.10, 0.88))
		draw_line(Vector2(-14, -14), Vector2(14, 14), Color(0.92, 0.18, 0.28, 0.80), 3.2, true)
		draw_line(Vector2(14, -14), Vector2(-14, 14), Color(0.92, 0.18, 0.28, 0.80), 3.2, true)
		return

	if is_player:
		_draw_player_illustration()
		return

	_draw_shadow(0.34)
	if elite:
		var aura_alpha: float = 0.10 + sin(aura_phase * 4.0) * 0.03
		draw_circle(Vector2.ZERO, 36.0, Color(1.0, 0.38, 0.12, aura_alpha))
		draw_circle(Vector2.ZERO, 31.0, Color(1.0, 0.62, 0.18, 0.20), false, 2.0, true)

	var flash_mix: float = 0.82 if hit_flash > 0.0 else 0.0
	var current_body: Color = body_color.lerp(Color.WHITE, flash_mix)
	var current_accent: Color = accent_color.lerp(Color.WHITE, flash_mix * 0.45)
	var bob: float = sin(walk_phase * 1.45) * 1.3 if velocity.length_squared() > 40.0 else 0.0

	_draw_enemy_hd_illustration(current_body, current_accent, bob)
	_draw_enemy_health()

func _draw_player_illustration() -> void:
	var current_texture: Texture2D = _hero_texture_for_pose(hero_pose_current)
	var previous_texture: Texture2D = _hero_texture_for_pose(hero_pose_previous)
	if current_texture == null:
		return

	_draw_shadow(0.30)
	_draw_player_floor_fx()

	var current_rect: Rect2 = _hero_rect_for_texture(current_texture, hero_pose_current)
	var previous_rect: Rect2 = _hero_rect_for_texture(previous_texture, hero_pose_previous)
	var move_strength: float = hero_stride_strength
	var breathe: float = 1.0
	if combat_enabled and move_strength < 0.12 and attack_timer <= 0.0 and hit_flash <= 0.0:
		breathe = 1.0 + sin(aura_phase * 2.1) * 0.006
	var side_sign: float = _movement_side_sign()
	var stride_wave: float = sin(hero_stride_phase)
	var stride_bounce: float = absf(cos(hero_stride_phase))
	var horizontal_scale: float = side_sign * breathe
	var vertical_scale: float = breathe * (1.0 - stride_bounce * 0.006 * move_strength)
	var hover_y: float = sin(aura_phase * 2.0) * 0.4 * (1.0 - move_strength)
	var draw_origin: Vector2 = Vector2(0.0, hover_y - stride_bounce * 0.65 * move_strength)
	if attack_timer > 0.0:
		draw_origin += Vector2(side_sign * 4.0, -1.5)
	if hit_flash > 0.0:
		draw_origin += Vector2(-side_sign * 4.0, 1.5)
	var rotation: float = hero_motion_tilt
	if attack_timer > 0.0:
		rotation += attack_swing_direction * 0.06
	elif hit_flash > 0.0:
		rotation -= side_sign * 0.05

	_draw_player_afterimages(current_texture, current_rect, draw_origin, rotation, horizontal_scale, vertical_scale)
	_draw_player_backlight(draw_origin)

	var previous_alpha: float = 1.0 - hero_pose_blend
	if previous_alpha > 0.01 and previous_texture != null:
		var prev_tint: Color = Color(1.0, 1.0, 1.0, previous_alpha)
		if hit_flash > 0.0:
			prev_tint = Color(1.0, 0.82, 0.82, previous_alpha)
		draw_set_transform(draw_origin, rotation, Vector2(horizontal_scale, vertical_scale))
		draw_texture_rect(previous_texture, previous_rect, false, prev_tint, false)

	var current_tint: Color = Color.WHITE
	if hit_flash > 0.0:
		current_tint = Color(1.0, 0.78, 0.78, 1.0)
	else:
		current_tint = Color(1.0, 1.0, 1.0, maxf(hero_pose_blend, 0.18))
	draw_set_transform(draw_origin, rotation, Vector2(horizontal_scale, vertical_scale))
	draw_texture_rect(current_texture, current_rect, false, current_tint, false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if attack_timer > 0.0:
		_draw_player_slash_arc(draw_origin, side_sign)
	if shot_flash > 0.0:
		_draw_player_shot_flash(draw_origin, side_sign)
	if hit_flash > 0.0:
		_draw_player_hit_sparks(draw_origin, side_sign)

func _update_player_visual_state(delta: float) -> void:
	var desired_pose: String = _hero_pose_name()
	var entering_move: bool = desired_pose == "move" and hero_pose_current != "move"
	if desired_pose != hero_pose_current:
		hero_pose_previous = hero_pose_current
		hero_pose_current = desired_pose
		hero_pose_blend = 0.0
		if entering_move:
			hero_stride_phase = 0.0
	var blend_speed: float = 18.0 if desired_pose == "attack" or desired_pose == "hit" else 14.0
	hero_pose_blend = minf(1.0, hero_pose_blend + delta * blend_speed)
	var speed_ratio: float = minf(1.0, velocity.length() / maxf(speed, 1.0))
	hero_stride_strength = lerpf(hero_stride_strength, speed_ratio, minf(1.0, delta * 10.0))
	if desired_pose == "move":
		hero_stride_phase = fposmod(hero_stride_phase + (velocity.length() * delta / HERO_STRIDE_PIXELS) * TAU, TAU)
	var target_tilt: float = clampf(velocity.x / maxf(speed, 1.0), -1.0, 1.0) * 0.010
	if attack_timer > 0.0:
		target_tilt += attack_swing_direction * 0.035
	hero_motion_tilt = lerpf(hero_motion_tilt, target_tilt, minf(1.0, delta * 10.0))
	hero_ground_glow = lerpf(hero_ground_glow, 0.16 + hero_stride_strength * 0.22 + (0.08 if attack_timer > 0.0 else 0.0), minf(1.0, delta * 6.0))

func _hero_pose_name() -> String:
	if not combat_enabled:
		return "idle"
	if hit_flash > 0.0:
		return "hit"
	if attack_timer > 0.0:
		return "attack"
	if velocity.length_squared() > MOVE_POSE_THRESHOLD_SQ:
		return "move"
	return "idle"

func _hero_texture_for_pose(pose_name: String) -> Texture2D:
	match pose_name:
		"hit":
			return HERO_HIT_TEXTURE
		"attack":
			return HERO_ATTACK_TEXTURE
		"move":
			return _select_move_cycle_texture(HERO_MOVE_TEXTURE, HERO_MOVE_ALT_TEXTURE, hero_stride_phase)
		_:
			return HERO_IDLE_TEXTURE

func _enemy_pose_name() -> String:
	if not combat_enabled:
		return "idle"
	if hit_flash > 0.0:
		return "hit"
	if attack_timer > 0.0:
		return "attack"
	if velocity.length_squared() > MOVE_POSE_THRESHOLD_SQ:
		return "move"
	return "idle"

func _update_enemy_visual_state(delta: float) -> void:
	var desired_pose: String = _enemy_pose_name()
	var entering_move: bool = desired_pose == "move" and enemy_pose_current != "move"
	if desired_pose != enemy_pose_current:
		enemy_pose_previous = enemy_pose_current
		enemy_pose_current = desired_pose
		enemy_pose_blend = 0.0
		if entering_move:
			enemy_stride_phase = 0.0
	var blend_speed: float = 18.0 if desired_pose == "attack" or desired_pose == "hit" else 14.0
	enemy_pose_blend = minf(1.0, enemy_pose_blend + delta * blend_speed)
	var speed_ratio: float = minf(1.0, velocity.length() / maxf(speed, 1.0))
	enemy_stride_strength = lerpf(enemy_stride_strength, speed_ratio, minf(1.0, delta * 10.0))
	if desired_pose == "move":
		enemy_stride_phase = fposmod(enemy_stride_phase + (velocity.length() * delta / ENEMY_STRIDE_PIXELS) * TAU, TAU)
	var target_tilt: float = clampf(velocity.x / maxf(speed, 1.0), -1.0, 1.0) * 0.012
	if attack_timer > 0.0:
		target_tilt += attack_swing_direction * (0.032 if weapon_type == "blade" else 0.012)
	enemy_motion_tilt = lerpf(enemy_motion_tilt, target_tilt, minf(1.0, delta * 10.0))
	var action_glow: float = 0.08 if attack_timer > 0.0 or shot_flash > 0.0 else 0.0
	enemy_ground_glow = lerpf(enemy_ground_glow, 0.14 + enemy_stride_strength * 0.18 + action_glow, minf(1.0, delta * 6.0))

func _enemy_blade_texture_for_pose(pose_name: String) -> Texture2D:
	match pose_name:
		"hit":
			return ENEMY_BLADE_HIT_TEXTURE
		"attack":
			return ENEMY_BLADE_ATTACK_TEXTURE
		"move":
			return _select_move_cycle_texture(ENEMY_BLADE_MOVE_TEXTURE, ENEMY_BLADE_MOVE_ALT_TEXTURE, enemy_stride_phase)
		_:
			return ENEMY_BLADE_IDLE_TEXTURE

func _enemy_blaster_texture_for_pose(pose_name: String) -> Texture2D:
	match pose_name:
		"hit":
			return ENEMY_BLASTER_HIT_TEXTURE
		"attack":
			return ENEMY_BLASTER_ATTACK_TEXTURE
		"move":
			return _select_move_cycle_texture(ENEMY_BLASTER_MOVE_TEXTURE, ENEMY_BLASTER_MOVE_ALT_TEXTURE, enemy_stride_phase)
		_:
			return ENEMY_BLASTER_IDLE_TEXTURE

func _enemy_blade_rect_for_texture(texture: Texture2D, _pose_name: String) -> Rect2:
	var target_height: float = 130.0
	if display_name.find("Brute") != -1:
		target_height *= 1.04
	elif display_name.find("Stalker") != -1:
		target_height *= 0.98
	var source_size: Vector2 = texture.get_size()
	if source_size.y <= 0.0:
		return Rect2(-32, -96, 64, 96)
	var ratio: float = target_height / source_size.y
	var target_width: float = source_size.x * ratio
	var bottom_y: float = 27.0
	return Rect2(-target_width * 0.5, bottom_y - target_height, target_width, target_height)

func _enemy_blaster_rect_for_texture(texture: Texture2D, _pose_name: String) -> Rect2:
	var target_height: float = 130.0
	if display_name.find("Sentinel") != -1:
		target_height *= 1.03
	var source_size: Vector2 = texture.get_size()
	if source_size.y <= 0.0:
		return Rect2(-32, -96, 64, 96)
	var ratio: float = target_height / source_size.y
	var target_width: float = source_size.x * ratio
	var bottom_y: float = 28.0
	return Rect2(-target_width * 0.5, bottom_y - target_height, target_width, target_height)

func _hero_rect_for_texture(texture: Texture2D, _pose_name: String) -> Rect2:
	var target_height: float = 130.0
	if not combat_enabled:
		target_height = 330.0
	var source_size: Vector2 = texture.get_size()
	if source_size.y <= 0.0:
		return Rect2(-32, -96, 64, 96)
	var ratio: float = target_height / source_size.y
	var target_width: float = source_size.x * ratio
	var bottom_y: float = 28.0
	return Rect2(-target_width * 0.5, bottom_y - target_height, target_width, target_height)

func _draw_player_floor_fx() -> void:
	var pulse: float = 0.04 + sin(aura_phase * 2.2) * 0.010
	var ring_alpha: float = pulse + hero_ground_glow * 0.18
	draw_custom_ellipse(Vector2(0, 22), Vector2(36, 12), Color(0.0, 0.0, 0.0, 0.15 + hero_stride_strength * 0.10))
	draw_custom_ellipse(Vector2(0, 22), Vector2(33, 11), Color(weapon_color.r, weapon_color.g, weapon_color.b, ring_alpha))
	draw_custom_ellipse(Vector2(0, 22), Vector2(22, 7), Color(1.0, 1.0, 1.0, ring_alpha * 0.08))
	if hero_stride_strength > 0.16:
		var streak_offset: float = sin(hero_stride_phase) * 8.0
		draw_line(Vector2(-18 - streak_offset, 23), Vector2(-5 - streak_offset * 0.45, 21), Color(1.0, 1.0, 1.0, 0.08 + hero_stride_strength * 0.06), 1.2, true)
		draw_line(Vector2(5 + streak_offset * 0.45, 21), Vector2(18 + streak_offset, 23), Color(1.0, 1.0, 1.0, 0.08 + hero_stride_strength * 0.06), 1.2, true)

func _draw_player_backlight(draw_origin: Vector2) -> void:
	var glow_alpha: float = 0.065 + sin(aura_phase * 3.0) * 0.015
	draw_circle(draw_origin + Vector2(0, -42), 24.0, Color(weapon_color.r, weapon_color.g, weapon_color.b, glow_alpha))
	draw_circle(draw_origin + Vector2(0, -16), 18.0, Color(weapon_color.r, weapon_color.g, weapon_color.b, glow_alpha * 0.55))

func _draw_player_afterimages(texture: Texture2D, sprite_rect: Rect2, draw_origin: Vector2, rotation: float, horizontal_scale: float, vertical_scale: float) -> void:
	var move_strength: float = minf(1.0, velocity.length() / maxf(speed, 1.0))
	var attack_strength: float = 1.0 if attack_timer > 0.0 else 0.0
	if move_strength < 0.18 and attack_strength <= 0.0:
		return
	var trail_dir: Vector2 = velocity.normalized()
	if trail_dir.length_squared() < 0.01:
		trail_dir = facing
	for i: int in range(4):
		var ratio: float = float(i + 1) / 4.0
		var offset: Vector2 = -trail_dir * (8.0 + ratio * (16.0 + move_strength * 16.0))
		if attack_strength > 0.0:
			offset += Vector2(-trail_dir.y, trail_dir.x) * attack_swing_direction * ratio * 5.0
		var alpha: float = 0.075 * move_strength * (1.0 - ratio * 0.20) + 0.06 * attack_strength * (1.0 - ratio * 0.18)
		draw_set_transform(draw_origin + offset, rotation, Vector2(horizontal_scale, vertical_scale))
		draw_texture_rect(texture, sprite_rect, false, Color(weapon_color.r, weapon_color.g, weapon_color.b, alpha), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_player_slash_arc(draw_origin: Vector2, side_sign: float) -> void:
	var facing_dir: Vector2 = facing if facing.length_squared() > 0.01 else Vector2.RIGHT
	var progress: float = 1.0 - attack_timer / MELEE_ATTACK_VISUAL_DURATION
	progress = clampf(progress, 0.0, 1.0)
	var center: Vector2 = draw_origin + Vector2(side_sign * 5.0, -36.0)
	var base_angle: float = facing_dir.angle()
	var start_angle: float = base_angle - attack_swing_direction * 1.15
	var end_angle: float = base_angle + attack_swing_direction * (0.28 + progress * 0.95)
	var outer_radius: float = 64.0 + progress * 10.0
	var inner_radius: float = outer_radius - 18.0
	var arc: PackedVector2Array = PackedVector2Array()
	for step: int in range(11):
		var t: float = float(step) / 10.0
		var angle: float = lerpf(start_angle, end_angle, t)
		arc.append(center + Vector2(cos(angle), sin(angle)) * outer_radius)
	for back_step: int in range(10, -1, -1):
		var t_back: float = float(back_step) / 10.0
		var angle_back: float = lerpf(start_angle, end_angle, t_back)
		arc.append(center + Vector2(cos(angle_back), sin(angle_back)) * inner_radius)
	draw_colored_polygon(arc, Color(weapon_color.r, weapon_color.g, weapon_color.b, 0.13))
	var stroke: PackedVector2Array = PackedVector2Array()
	for stroke_step: int in range(11):
		var ts: float = float(stroke_step) / 10.0
		var angle_s: float = lerpf(start_angle, end_angle, ts)
		stroke.append(center + Vector2(cos(angle_s), sin(angle_s)) * (outer_radius - 4.0))
	draw_polyline(stroke, Color(1.0, 1.0, 1.0, 0.34), 2.4, true)
	draw_circle(stroke[stroke.size() - 1], 3.4, weapon_color.lightened(0.30))

func _draw_player_shot_flash(draw_origin: Vector2, side_sign: float) -> void:
	var muzzle_pos: Vector2 = draw_origin + Vector2(side_sign * 30.0, -44.0)
	var flare_alpha: float = 0.16 + shot_flash * 0.42
	draw_circle(muzzle_pos, 5.0 + shot_flash * 16.0, Color(weapon_color.r, weapon_color.g, weapon_color.b, flare_alpha))
	draw_line(muzzle_pos + Vector2(0, -6), muzzle_pos + Vector2(0, 6), Color.WHITE, 1.5, true)
	draw_line(muzzle_pos + Vector2(-6, 0), muzzle_pos + Vector2(6, 0), Color.WHITE, 1.5, true)

func _draw_player_hit_sparks(draw_origin: Vector2, side_sign: float) -> void:
	var spark_center: Vector2 = draw_origin + Vector2(side_sign * 4.0, -52.0)
	var spark_alpha: float = 0.34 + hit_flash * 0.55
	for i: int in range(4):
		var angle: float = PI * 0.2 + float(i) * TAU / 4.0
		var direction: Vector2 = Vector2(cos(angle), sin(angle))
		draw_line(spark_center + direction * 3.0, spark_center + direction * 12.0, Color(1.0, 0.92, 0.80, spark_alpha), 1.8, true)

func _draw_shadow(alpha: float) -> void:
	draw_custom_ellipse(Vector2(0, 22), Vector2(31, 11), Color(0.0, 0.0, 0.0, alpha))
	draw_custom_ellipse(Vector2(0, 22), Vector2(20, 6), Color(1.0, 1.0, 1.0, alpha * 0.03))

func _draw_core_glow(bob: float) -> void:
	var glow_alpha: float = 0.045 + 0.02 * sin(aura_phase * 3.2)
	draw_circle(Vector2(0, -8 + bob), 16.0, Color(weapon_color.r, weapon_color.g, weapon_color.b, glow_alpha))

func _draw_legs(current_body: Color, bob: float) -> void:
	var step: float = sin(walk_phase * 1.45) * 3.5 if velocity.length_squared() > 40.0 else 0.0
	var leg_color: Color = current_body.darkened(0.28)
	var boot_color: Color = Color("0d1219")
	var left_knee: Vector2 = Vector2(-5, 12 + bob)
	var right_knee: Vector2 = Vector2(5, 12 + bob)
	var left_foot: Vector2 = Vector2(-7 + step, 28 + bob)
	var right_foot: Vector2 = Vector2(7 - step, 28 + bob)
	draw_line(Vector2(-6, 4 + bob), left_knee, leg_color, 7.0, true)
	draw_line(left_knee, left_foot, leg_color, 7.0, true)
	draw_line(Vector2(6, 4 + bob), right_knee, leg_color, 7.0, true)
	draw_line(right_knee, right_foot, leg_color, 7.0, true)
	draw_line(left_foot + Vector2(-2, 0), left_foot + Vector2(4, 0), boot_color, 5.2, true)
	draw_line(right_foot + Vector2(-4, 0), right_foot + Vector2(2, 0), boot_color, 5.2, true)

func _draw_cape(bob: float) -> void:
	var back: Vector2 = -facing * 13.0
	var side: Vector2 = Vector2(-facing.y, facing.x)
	var flutter: float = sin(walk_phase * 0.9 + aura_phase * 2.0) * 2.2
	var cape: PackedVector2Array = PackedVector2Array([
		back + side * 12.0 + Vector2(0, -12 + bob),
		back - side * 12.0 + Vector2(0, -12 + bob),
		back - side * 20.0 + Vector2(-2, 8 + bob + flutter),
		back - side * 15.0 + Vector2(-1, 28 + bob),
		back + side * 15.0 + Vector2(1, 28 + bob),
		back + side * 20.0 + Vector2(2, 8 + bob - flutter)
	])
	draw_colored_polygon(cape, cape_color)
	draw_polyline(PackedVector2Array([cape[0], cape[1], cape[2], cape[3], cape[4], cape[5], cape[0]]), Color(1.0, 1.0, 1.0, 0.05), 1.2, true)

func _draw_torso(current_body: Color, current_accent: Color, bob: float) -> void:
	var shoulder: float = 20.0
	var waist: float = 16.0
	if outfit_idx == 2:
		shoulder = 23.0
	elif outfit_idx == 3:
		waist = 18.0
	elif outfit_idx >= 4:
		shoulder = 21.5
	var torso: PackedVector2Array = PackedVector2Array([
		Vector2(-waist, 15 + bob), Vector2(-shoulder, -4 + bob), Vector2(-10, -20 + bob),
		Vector2(10, -20 + bob), Vector2(shoulder, -4 + bob), Vector2(waist, 15 + bob)
	])
	draw_colored_polygon(torso, current_body)
	draw_polyline(PackedVector2Array([torso[0], torso[1], torso[2], torso[3], torso[4], torso[5], torso[0]]), Color(0.02, 0.03, 0.05, 0.98), 2.0, true)
	var chest_plate: Rect2 = Rect2(-11, -11 + bob, 22, 16)
	draw_rect(chest_plate, current_accent.darkened(0.20), true)
	draw_rect(chest_plate.grow(-3), current_accent.lightened(0.04), false, 2.0, true)
	draw_line(Vector2(-10, 6 + bob), Vector2(10, 6 + bob), current_accent.lightened(0.20), 2.0, true)
	match outfit_idx:
		0:
			draw_line(Vector2(-8, -9 + bob), Vector2(8, -9 + bob), current_accent, 2.0, true)
		1:
			draw_line(Vector2(-13, -9 + bob), Vector2(12, 12 + bob), current_accent, 4.0, true)
			draw_circle(Vector2(-10, -6 + bob), 4.0, current_accent.darkened(0.25))
		2:
			draw_line(Vector2(-22, -6 + bob), Vector2(-14, -1 + bob), current_accent, 4.0, true)
			draw_line(Vector2(22, -6 + bob), Vector2(14, -1 + bob), current_accent, 4.0, true)
			draw_rect(Rect2(-15, -14 + bob, 30, 18), current_accent.darkened(0.38), false, 2.0, true)
		3:
			draw_line(Vector2(-12, -10 + bob), Vector2(12, 9 + bob), current_accent, 2.6, true)
			draw_line(Vector2(12, -10 + bob), Vector2(-12, 9 + bob), current_accent.darkened(0.16), 2.6, true)
		4:
			draw_circle(Vector2(0, -3 + bob), 4.0, visor_color)
			draw_line(Vector2(-13, 0 + bob), Vector2(13, 0 + bob), current_accent, 2.0, true)
		_:
			draw_line(Vector2(-13, -4 + bob), Vector2(13, -4 + bob), current_accent, 3.0, true)
			draw_line(Vector2(0, -13 + bob), Vector2(0, 9 + bob), current_accent.darkened(0.25), 2.0, true)
	var waist_rect: Rect2 = Rect2(-waist, 10 + bob, waist * 2.0, 6.0)
	draw_rect(waist_rect, Color("131821"), true)
	draw_rect(waist_rect.grow(-1), Color(1.0, 1.0, 1.0, 0.04), false, 1.0, true)

func _draw_skirt_and_belt(bob: float) -> void:
	var left_panel: PackedVector2Array = PackedVector2Array([
		Vector2(-12, 12 + bob), Vector2(-2, 12 + bob), Vector2(-4, 30 + bob), Vector2(-13, 28 + bob)
	])
	var right_panel: PackedVector2Array = PackedVector2Array([
		Vector2(2, 12 + bob), Vector2(12, 12 + bob), Vector2(13, 28 + bob), Vector2(4, 30 + bob)
	])
	draw_colored_polygon(left_panel, body_color.darkened(0.18))
	draw_colored_polygon(right_panel, body_color.darkened(0.18))
	draw_line(Vector2(-12, 12 + bob), Vector2(12, 12 + bob), accent_color, 2.0, true)
	draw_rect(Rect2(-5, 11 + bob, 10, 5), accent_color.darkened(0.22), true)

func _draw_arms(current_body: Color, current_accent: Color, bob: float) -> void:
	var side: Vector2 = Vector2(-facing.y, facing.x)
	var left_shoulder: Vector2 = Vector2(-12, -5 + bob) + side * 2.0
	var right_shoulder: Vector2 = Vector2(12, -5 + bob) - side * 2.0
	var left_elbow: Vector2 = left_shoulder + Vector2(-3, 8)
	var right_elbow: Vector2 = right_shoulder + facing * 6.0 + Vector2(0, 6)
	var left_hand: Vector2 = left_elbow + Vector2(-2, 8)
	var right_hand: Vector2 = right_elbow + facing * 9.0 + Vector2(0, 5)
	draw_line(left_shoulder, left_elbow, current_body.darkened(0.16), 6.4, true)
	draw_line(left_elbow, left_hand, current_body.darkened(0.16), 6.2, true)
	draw_line(right_shoulder, right_elbow, current_body.darkened(0.16), 6.4, true)
	draw_line(right_elbow, right_hand, current_body.darkened(0.16), 6.2, true)
	draw_line(left_elbow, left_hand, current_accent, 2.0, true)
	draw_line(right_elbow, right_hand, current_accent, 2.0, true)

func _draw_head(bob: float) -> void:
	var head_pos: Vector2 = Vector2(0, -32 + bob)
	if masked:
		var helmet_color: Color = Color("1a212d").lerp(Color.WHITE, 0.55 if hit_flash > 0.0 else 0.0)
		match mask_style:
			0:
				draw_circle(head_pos, 14.0, helmet_color)
				draw_rect(Rect2(head_pos.x - 9.0, head_pos.y - 3.5, 18.0, 6.5), visor_color, true)
				draw_arc(head_pos, 10.0, 0.55, PI - 0.55, 18, Color("5a6578"), 2.2, true)
				draw_line(head_pos + Vector2(0, 1), head_pos + Vector2(0, 8), accent_color.darkened(0.15), 1.6, true)
			1:
				var mask_poly: PackedVector2Array = PackedVector2Array([
					head_pos + Vector2(-12, -10), head_pos + Vector2(0, -15), head_pos + Vector2(12, -10),
					head_pos + Vector2(10, 8), head_pos + Vector2(0, 13), head_pos + Vector2(-10, 8)
				])
				draw_colored_polygon(mask_poly, helmet_color)
				draw_line(head_pos + Vector2(-7, -3), head_pos + Vector2(7, -3), visor_color, 4.0, true)
				draw_line(head_pos + Vector2(-5, 3), head_pos + Vector2(5, 3), accent_color, 2.0, true)
			2:
				draw_circle(head_pos, 14.0, helmet_color)
				draw_arc(head_pos, 12.0, PI, TAU, 18, cape_color.lightened(0.10), 5.0, true)
				draw_line(head_pos + Vector2(0, -6), head_pos + Vector2(0, 6), visor_color, 4.0, true)
				draw_circle(head_pos + Vector2(0, 7), 4.0, accent_color.darkened(0.20))
				draw_line(head_pos + Vector2(-6, 2), head_pos + Vector2(6, 2), accent_color.darkened(0.10), 2.0, true)
			_:
				draw_circle(head_pos, 13.5, helmet_color)
				draw_rect(Rect2(head_pos.x - 10.0, head_pos.y - 5.0, 20.0, 5.0), visor_color, true)
				draw_colored_polygon(PackedVector2Array([head_pos + Vector2(-7, 2), head_pos + Vector2(7, 2), head_pos + Vector2(5, 11), head_pos + Vector2(-5, 11)]), accent_color.darkened(0.28))
				draw_line(head_pos + Vector2(-7, -8), head_pos + Vector2(7, -8), accent_color, 2.0, true)
		if elite:
			draw_line(head_pos + Vector2(-5, 12), head_pos + Vector2(5, 12), Color("f4b64b"), 2.0, true)
	else:
		var skin: Color = skin_color.lerp(Color.WHITE, 0.50 if hit_flash > 0.0 else 0.0)
		draw_circle(head_pos, 13.0, skin)
		var hair_color: Color = body_color.darkened(0.24)
		match outfit_idx % 3:
			0:
				draw_rect(Rect2(head_pos.x - 9.5, head_pos.y - 13.0, 19.0, 7.0), hair_color, true)
			1:
				draw_arc(head_pos + Vector2(0, -2), 10.0, PI, TAU, 16, hair_color, 5.0, true)
			_:
				draw_line(head_pos + Vector2(-8, -9), head_pos + Vector2(8, -9), hair_color, 4.0, true)
		draw_arc(head_pos + Vector2(0, 1), 7.0, 0.20, PI - 0.20, 12, Color("2b231f"), 1.8, true)
		draw_circle(head_pos + Vector2(-4.2, -1.0), 1.3, Color.BLACK)
		draw_circle(head_pos + Vector2(4.2, -1.0), 1.3, Color.BLACK)
		draw_arc(head_pos + Vector2(0, 4.5), 4.0, 0.25, PI - 0.25, 10, Color("6a4432"), 1.4, true)

func _draw_weapon(bob: float) -> void:
	var side: Vector2 = Vector2(-facing.y, facing.x)
	var hand_pos: Vector2 = facing * 11.0 + Vector2(0, 5 + bob)
	if weapon_type == "blade":
		var swing_angle: float = attack_swing_direction * attack_timer * 3.5
		var blade_dir: Vector2 = facing.rotated(swing_angle)
		var hilt_a: Vector2 = hand_pos - blade_dir * 9.0
		var hilt_b: Vector2 = hand_pos + blade_dir * 5.0
		draw_line(hilt_a, hilt_b, Color("151a22"), 6.0, true)
		draw_line(hand_pos - side * 4.0, hand_pos + side * 4.0, Color("343c48"), 3.0, true)
		var blade_len: float = 37.0 + attack_timer * 18.0
		if weapon_skin_idx == 2:
			blade_len -= 3.0
		elif weapon_skin_idx >= 4:
			blade_len += 7.0
		var blade_end: Vector2 = hand_pos + blade_dir * blade_len
		draw_line(hand_pos, blade_end, Color(weapon_color.r, weapon_color.g, weapon_color.b, 0.20), 9.0, true)
		draw_line(hand_pos, blade_end, weapon_color.lightened(0.35), 5.0, true)
		draw_line(hand_pos, blade_end, Color.WHITE, 1.8, true)
		if weapon_skin_idx == 1:
			var tip_side: Vector2 = Vector2(-blade_dir.y, blade_dir.x)
			draw_line(blade_end - blade_dir * 7.0, blade_end + tip_side * 6.0, weapon_color, 2.0, true)
			draw_line(blade_end - blade_dir * 7.0, blade_end - tip_side * 6.0, weapon_color, 2.0, true)
		elif weapon_skin_idx == 3:
			for s: int in range(3):
				var offset_amount: float = float(s - 1) * 2.5
				draw_line(hand_pos + side * offset_amount, blade_end + side * offset_amount, Color(weapon_color.r, weapon_color.g, weapon_color.b, 0.45), 1.2, true)
		elif weapon_skin_idx >= 4:
			for seg: int in range(6):
				var a: float = float(seg) / 6.0
				var b: float = float(seg + 1) / 6.0 - 0.02
				draw_line(hand_pos.lerp(blade_end, a), hand_pos.lerp(blade_end, b), Color.WHITE, 1.2, true)
		draw_circle(blade_end, 3.0, weapon_color.lightened(0.25))
		if attack_timer > 0.0:
			var trail: PackedVector2Array = PackedVector2Array([
				hand_pos,
				hand_pos + blade_dir.rotated(attack_swing_direction * 0.28) * (blade_len * 0.55),
				hand_pos + blade_dir * blade_len,
				hand_pos + blade_dir.rotated(-attack_swing_direction * 0.25) * (blade_len * 0.62)
			])
			draw_colored_polygon(trail, Color(weapon_color.r, weapon_color.g, weapon_color.b, 0.14))
	else:
		var gun_pos: Vector2 = hand_pos + facing * 6.0
		var barrel_length: float = 19.0 + float(weapon_skin_idx % 3) * 3.0
		var gun_side: Vector2 = side * (4.2 + float(weapon_skin_idx % 2))
		var body_poly: PackedVector2Array = PackedVector2Array([
			gun_pos - gun_side - facing * 7.0,
			gun_pos + gun_side - facing * 7.0,
			gun_pos + gun_side + facing * 11.0,
			gun_pos - gun_side + facing * 11.0
		])
		draw_colored_polygon(body_poly, Color("2c3440"))
		draw_polyline(PackedVector2Array([body_poly[0], body_poly[1], body_poly[2], body_poly[3], body_poly[0]]), Color(1.0, 1.0, 1.0, 0.08), 1.4, true)
		draw_line(gun_pos + facing * 4.0, gun_pos + facing * barrel_length, weapon_color.lightened(0.20), 3.6, true)
		if weapon_skin_idx == 1:
			draw_line(gun_pos - gun_side, gun_pos - gun_side - side * 5.0 + facing * 4.0, accent_color, 2.0, true)
		elif weapon_skin_idx == 2:
			draw_circle(gun_pos - facing * 4.0, 4.0, weapon_color.darkened(0.25), false, 2.0, true)
		elif weapon_skin_idx >= 3:
			draw_line(gun_pos + side * 5.0, gun_pos + side * 8.0 + facing * 8.0, accent_color, 2.0, true)
		if shot_flash > 0.0:
			var muzzle_pos: Vector2 = gun_pos + facing * (barrel_length + 1.0)
			draw_circle(muzzle_pos, 5.0 + shot_flash * 12.0, Color(weapon_color.r, weapon_color.g, weapon_color.b, 0.24 + shot_flash * 0.55))
			draw_line(muzzle_pos, muzzle_pos + facing * 12.0, Color.WHITE, 2.0, true)

func _draw_enemy_hd_illustration(current_body: Color, current_accent: Color, bob: float) -> void:
	if weapon_type == "blade":
		_draw_enemy_blade_illustration(current_body, current_accent, bob)
		return
	_draw_enemy_blaster_illustration(current_body, current_accent, bob)

func _draw_enemy_blade_illustration(current_body: Color, current_accent: Color, bob: float) -> void:
	var current_texture: Texture2D = _enemy_blade_texture_for_pose(enemy_pose_current)
	var previous_texture: Texture2D = _enemy_blade_texture_for_pose(enemy_pose_previous)
	if current_texture == null:
		_draw_enemy_blade_design(current_body, current_accent, bob)
		return

	_draw_enemy_floor_fx(enemy_stride_strength, sin(enemy_stride_phase))

	var current_rect: Rect2 = _enemy_blade_rect_for_texture(current_texture, enemy_pose_current)
	var previous_rect: Rect2 = _enemy_blade_rect_for_texture(previous_texture, enemy_pose_previous)
	var move_strength: float = enemy_stride_strength
	var breathe: float = 1.0
	if combat_enabled and move_strength < 0.12 and attack_timer <= 0.0 and hit_flash <= 0.0:
		breathe = 1.0 + sin(aura_phase * 2.0) * 0.005
	var side_sign: float = _movement_side_sign()
	var stride_bounce: float = absf(cos(enemy_stride_phase))
	var horizontal_scale: float = side_sign * breathe
	var vertical_scale: float = breathe * (1.0 - stride_bounce * 0.006 * move_strength)
	var hover_y: float = sin(aura_phase * 2.0) * 0.35 * (1.0 - move_strength)
	var draw_origin: Vector2 = Vector2(0.0, hover_y - stride_bounce * 0.60 * move_strength)
	if attack_timer > 0.0:
		draw_origin += Vector2(side_sign * 3.0, -1.2)
	if hit_flash > 0.0:
		draw_origin += Vector2(-side_sign * 4.0, 1.5)
	var rotation: float = enemy_motion_tilt
	if hit_flash > 0.0:
		rotation -= side_sign * 0.05

	_draw_enemy_hd_afterimages(current_texture, current_rect, draw_origin, rotation, horizontal_scale, vertical_scale, move_strength, true)
	_draw_enemy_backlight(draw_origin, true)

	var previous_alpha: float = 1.0 - enemy_pose_blend
	if previous_alpha > 0.01 and previous_texture != null:
		var prev_tint: Color = Color(1.0, 1.0, 1.0, previous_alpha)
		if hit_flash > 0.0:
			prev_tint = Color(1.0, 0.82, 0.82, previous_alpha)
		draw_set_transform(draw_origin, rotation, Vector2(horizontal_scale, vertical_scale))
		draw_texture_rect(previous_texture, previous_rect, false, prev_tint, false)

	var current_tint: Color = Color.WHITE
	if hit_flash > 0.0:
		current_tint = Color(1.0, 0.78, 0.78, 1.0)
	else:
		current_tint = Color(1.0, 1.0, 1.0, maxf(enemy_pose_blend, 0.18))
	draw_set_transform(draw_origin, rotation, Vector2(horizontal_scale, vertical_scale))
	draw_texture_rect(current_texture, current_rect, false, current_tint, false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if attack_timer > 0.0:
		_draw_enemy_blade_slash_arc(draw_origin, side_sign)
	if hit_flash > 0.0:
		_draw_enemy_hit_sparks(draw_origin, side_sign)

func _draw_enemy_blaster_illustration(current_body: Color, current_accent: Color, bob: float) -> void:
	var current_texture: Texture2D = _enemy_blaster_texture_for_pose(enemy_pose_current)
	var previous_texture: Texture2D = _enemy_blaster_texture_for_pose(enemy_pose_previous)
	if current_texture == null:
		_draw_enemy_blaster_design(current_body, current_accent, bob)
		return

	_draw_enemy_floor_fx(enemy_stride_strength, sin(enemy_stride_phase))

	var current_rect: Rect2 = _enemy_blaster_rect_for_texture(current_texture, enemy_pose_current)
	var previous_rect: Rect2 = _enemy_blaster_rect_for_texture(previous_texture, enemy_pose_previous)
	var move_strength: float = enemy_stride_strength
	var breathe: float = 1.0
	if combat_enabled and move_strength < 0.12 and attack_timer <= 0.0 and hit_flash <= 0.0:
		breathe = 1.0 + sin(aura_phase * 2.1) * 0.005
	var side_sign: float = _movement_side_sign()
	var stride_bounce: float = absf(cos(enemy_stride_phase))
	var horizontal_scale: float = side_sign * breathe
	var vertical_scale: float = breathe * (1.0 - stride_bounce * 0.006 * move_strength)
	var hover_y: float = sin(aura_phase * 2.0) * 0.35 * (1.0 - move_strength)
	var draw_origin: Vector2 = Vector2(0.0, hover_y - stride_bounce * 0.60 * move_strength)
	if attack_timer > 0.0:
		draw_origin += Vector2(side_sign * 3.0, -1.0)
	if hit_flash > 0.0:
		draw_origin += Vector2(-side_sign * 4.0, 1.5)
	var rotation: float = enemy_motion_tilt
	if hit_flash > 0.0:
		rotation -= side_sign * 0.045

	_draw_enemy_hd_afterimages(current_texture, current_rect, draw_origin, rotation, horizontal_scale, vertical_scale, move_strength, false)
	_draw_enemy_backlight(draw_origin, false)

	var previous_alpha: float = 1.0 - enemy_pose_blend
	if previous_alpha > 0.01 and previous_texture != null:
		var prev_tint: Color = Color(1.0, 1.0, 1.0, previous_alpha)
		if hit_flash > 0.0:
			prev_tint = Color(1.0, 0.82, 0.82, previous_alpha)
		draw_set_transform(draw_origin, rotation, Vector2(horizontal_scale, vertical_scale))
		draw_texture_rect(previous_texture, previous_rect, false, prev_tint, false)

	var current_tint: Color = Color.WHITE
	if hit_flash > 0.0:
		current_tint = Color(1.0, 0.80, 0.80, 1.0)
	else:
		current_tint = Color(1.0, 1.0, 1.0, maxf(enemy_pose_blend, 0.18))
	draw_set_transform(draw_origin, rotation, Vector2(horizontal_scale, vertical_scale))
	draw_texture_rect(current_texture, current_rect, false, current_tint, false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_enemy_hd_blaster_fx(draw_origin, side_sign)
	if hit_flash > 0.0:
		_draw_enemy_hit_sparks(draw_origin, side_sign)
func _draw_enemy_floor_fx(move_strength: float, stride_wave: float) -> void:
	var pulse: float = 0.04 + sin(aura_phase * 2.1) * 0.010
	var ring_alpha: float = pulse + enemy_ground_glow * 0.18
	draw_custom_ellipse(Vector2(0, 22), Vector2(36, 12), Color(0.0, 0.0, 0.0, 0.15 + move_strength * 0.10))
	draw_custom_ellipse(Vector2(0, 22), Vector2(33, 11), Color(weapon_color.r, weapon_color.g, weapon_color.b, ring_alpha))
	draw_custom_ellipse(Vector2(0, 22), Vector2(22, 7), Color(1.0, 1.0, 1.0, ring_alpha * 0.08))
	if move_strength > 0.16:
		var streak_offset: float = stride_wave * 8.0
		draw_line(Vector2(-18 - streak_offset, 23), Vector2(-5 - streak_offset * 0.45, 21), Color(1.0, 1.0, 1.0, 0.08 + move_strength * 0.06), 1.2, true)
		draw_line(Vector2(5 + streak_offset * 0.45, 21), Vector2(18 + streak_offset, 23), Color(1.0, 1.0, 1.0, 0.08 + move_strength * 0.06), 1.2, true)

func _draw_enemy_backlight(draw_origin: Vector2, blade_mode: bool) -> void:
	var glow_alpha: float = 0.060 + sin(aura_phase * 3.0) * 0.014
	var upper_offset: float = -40.0 if blade_mode else -34.0
	draw_circle(draw_origin + Vector2(0, upper_offset), 22.0 if blade_mode else 17.0, Color(weapon_color.r, weapon_color.g, weapon_color.b, glow_alpha))
	draw_circle(draw_origin + Vector2(0, -16), 17.0, Color(weapon_color.r, weapon_color.g, weapon_color.b, glow_alpha * 0.55))

func _draw_enemy_hd_afterimages(texture: Texture2D, sprite_rect: Rect2, draw_origin: Vector2, rotation: float, horizontal_scale: float, vertical_scale: float, move_strength: float, blade_mode: bool) -> void:
	var attack_strength: float = 1.0 if attack_timer > 0.0 else 0.0
	if move_strength < 0.18 and attack_strength <= 0.0:
		return
	var trail_dir: Vector2 = velocity.normalized()
	if trail_dir.length_squared() < 0.01:
		trail_dir = facing
	for i: int in range(4 if blade_mode else 2):
		var count: float = float(4 if blade_mode else 2)
		var ratio: float = float(i + 1) / count
		var offset: Vector2 = -trail_dir * (8.0 + ratio * (16.0 + move_strength * 16.0))
		if attack_strength > 0.0 and blade_mode:
			offset += Vector2(-trail_dir.y, trail_dir.x) * attack_swing_direction * ratio * 5.0
		var alpha: float = 0.075 * move_strength * (1.0 - ratio * 0.20) + 0.06 * attack_strength * (1.0 - ratio * 0.18)
		if not blade_mode:
			alpha *= 0.65
		draw_set_transform(draw_origin + offset, rotation, Vector2(horizontal_scale, vertical_scale))
		draw_texture_rect(texture, sprite_rect, false, Color(weapon_color.r, weapon_color.g, weapon_color.b, alpha), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_enemy_blade_slash_arc(draw_origin: Vector2, side_sign: float) -> void:
	var facing_dir: Vector2 = facing if facing.length_squared() > 0.01 else Vector2.RIGHT
	var progress: float = 1.0 - attack_timer / MELEE_ATTACK_VISUAL_DURATION
	progress = clampf(progress, 0.0, 1.0)
	var center: Vector2 = draw_origin + Vector2(side_sign * 5.0, -36.0)
	var base_angle: float = facing_dir.angle()
	var start_angle: float = base_angle - attack_swing_direction * 1.10
	var end_angle: float = base_angle + attack_swing_direction * (0.24 + progress * 0.90)
	var outer_radius: float = 60.0 + progress * 10.0
	var inner_radius: float = outer_radius - 16.0
	var arc: PackedVector2Array = PackedVector2Array()
	for step: int in range(11):
		var t: float = float(step) / 10.0
		var angle: float = lerpf(start_angle, end_angle, t)
		arc.append(center + Vector2(cos(angle), sin(angle)) * outer_radius)
	for back_step: int in range(10, -1, -1):
		var t_back: float = float(back_step) / 10.0
		var angle_back: float = lerpf(start_angle, end_angle, t_back)
		arc.append(center + Vector2(cos(angle_back), sin(angle_back)) * inner_radius)
	draw_colored_polygon(arc, Color(weapon_color.r, weapon_color.g, weapon_color.b, 0.10))

func _draw_enemy_hit_sparks(draw_origin: Vector2, side_sign: float) -> void:
	var spark_origin: Vector2 = draw_origin + Vector2(side_sign * -2.0, -36.0)
	for i: int in range(5):
		var spread: float = -0.8 + float(i) * 0.4
		var dir: Vector2 = Vector2(cos(spread), sin(spread - 0.3 * side_sign)).normalized()
		draw_line(spark_origin, spark_origin + dir * (8.0 + float(i) * 2.4), Color(1.0, 0.85, 0.85, 0.6 - float(i) * 0.08), 1.7, true)

func _draw_enemy_hd_blaster_fx(draw_origin: Vector2, side_sign: float) -> void:
	var muzzle_pos: Vector2 = draw_origin + Vector2(side_sign * 46.0, -56.0)
	if shot_flash > 0.0:
		draw_circle(muzzle_pos, 5.0 + shot_flash * 11.0, Color(weapon_color.r, weapon_color.g, weapon_color.b, 0.20 + shot_flash * 0.40))
		draw_line(muzzle_pos, muzzle_pos + Vector2(side_sign * 18.0, 0.0), Color.WHITE, 2.0, true)
	draw_line(muzzle_pos + Vector2(side_sign * -8.0, 0.0), muzzle_pos + Vector2(side_sign * 7.0, 0.0), Color(weapon_color.r, weapon_color.g, weapon_color.b, 0.12), 2.8, true)

func _draw_enemy_blade_design(current_body: Color, current_accent: Color, bob: float) -> void:
	var move_strength: float = minf(1.0, velocity.length() / maxf(speed, 1.0))
	var stride: float = sin(walk_phase * 1.45) * 4.8 * move_strength
	var side_sign: float = _movement_side_sign()
	var is_brute: bool = display_name.find("Brute") != -1
	var is_stalker: bool = display_name.find("Stalker") != -1
	var body_w: float = 15.0
	var shoulder_w: float = 20.0
	var head_r: float = 12.5
	if is_brute:
		body_w = 18.0
		shoulder_w = 24.0
		head_r = 13.5
	elif is_stalker:
		body_w = 13.0
		shoulder_w = 17.0
		head_r = 11.5
	var glow_alpha: float = 0.06 + 0.04 * attack_timer + 0.02 * sin(aura_phase * 3.0)
	draw_custom_ellipse(Vector2(0, 22), Vector2(30, 10), Color(weapon_color.r, weapon_color.g, weapon_color.b, 0.04 + move_strength * 0.05))
	var cape_top: Vector2 = Vector2(-side_sign * 8.0, -22.0 + bob)
	var cape_back: float = 20.0 + move_strength * 6.0
	var cape_poly: PackedVector2Array = PackedVector2Array([
		cape_top + Vector2(-side_sign * 10.0, -1.0),
		cape_top + Vector2(side_sign * 10.0, -1.0),
		cape_top + Vector2(side_sign * (8.0 + stride * 0.18), 12.0),
		cape_top + Vector2(side_sign * (-cape_back), 30.0 + stride * 0.35),
		cape_top + Vector2(side_sign * (-cape_back * 0.86), 46.0),
		cape_top + Vector2(side_sign * (-4.0), 36.0)
	])
	draw_colored_polygon(cape_poly, cape_color)
	draw_polyline(PackedVector2Array([cape_poly[0], cape_poly[1], cape_poly[2], cape_poly[3], cape_poly[4], cape_poly[5], cape_poly[0]]), Color(1.0, 1.0, 1.0, 0.05), 1.2, true)
	var rear_leg_from: Vector2 = Vector2(-6.0, 7.0 + bob)
	var rear_knee: Vector2 = Vector2(-7.0 - stride * 0.45, 15.0 + bob)
	var rear_foot: Vector2 = Vector2(-10.0 - stride * 0.70, 28.0 + bob)
	var front_leg_from: Vector2 = Vector2(6.0, 7.0 + bob)
	var front_knee: Vector2 = Vector2(8.0 + stride * 0.55, 15.0 + bob)
	var front_foot: Vector2 = Vector2(12.0 + stride * 0.92, 28.0 + bob)
	var leg_color: Color = current_body.darkened(0.26)
	draw_line(rear_leg_from, rear_knee, leg_color, 6.8, true)
	draw_line(rear_knee, rear_foot, leg_color, 6.4, true)
	draw_line(front_leg_from, front_knee, leg_color, 7.4, true)
	draw_line(front_knee, front_foot, leg_color, 7.0, true)
	draw_line(rear_foot + Vector2(-3.0, 0.0), rear_foot + Vector2(3.0, 0.0), Color("131821"), 4.6, true)
	draw_line(front_foot + Vector2(-4.0, 0.0), front_foot + Vector2(4.0, 0.0), Color("131821"), 5.0, true)
	var torso_poly: PackedVector2Array = PackedVector2Array([
		Vector2(-body_w, 13.0 + bob),
		Vector2(-shoulder_w, -4.0 + bob),
		Vector2(-9.0, -22.0 + bob),
		Vector2(9.0, -22.0 + bob),
		Vector2(shoulder_w, -4.0 + bob),
		Vector2(body_w, 13.0 + bob)
	])
	draw_colored_polygon(torso_poly, current_body)
	draw_polyline(PackedVector2Array([torso_poly[0], torso_poly[1], torso_poly[2], torso_poly[3], torso_poly[4], torso_poly[5], torso_poly[0]]), Color(0.02, 0.03, 0.05, 0.98), 1.8, true)
	draw_rect(Rect2(-10.0, -11.0 + bob, 20.0, 16.0), current_accent.darkened(0.18), true)
	draw_line(Vector2(-11.0, 0.0 + bob), Vector2(11.0, 0.0 + bob), current_accent, 2.0, true)
	draw_line(Vector2(0.0, -12.0 + bob), Vector2(0.0, 9.0 + bob), current_accent.darkened(0.22), 1.4, true)
	if is_brute:
		draw_rect(Rect2(-18.0, -15.0 + bob, 8.0, 20.0), current_accent.darkened(0.35), true)
		draw_rect(Rect2(10.0, -15.0 + bob, 8.0, 20.0), current_accent.darkened(0.35), true)
	elif is_stalker:
		draw_line(Vector2(-12.0, -13.0 + bob), Vector2(11.0, 10.0 + bob), current_accent, 2.6, true)
		draw_circle(Vector2(-8.0, -8.0 + bob), 3.0, visor_color)
	var back_arm_from: Vector2 = Vector2(-12.0, -5.0 + bob)
	var back_elbow: Vector2 = back_arm_from + Vector2(-4.0 - stride * 0.20, 7.0)
	var back_hand: Vector2 = back_elbow + Vector2(-4.0 - stride * 0.12, 7.0)
	draw_line(back_arm_from, back_elbow, current_body.darkened(0.14), 5.8, true)
	draw_line(back_elbow, back_hand, current_body.darkened(0.14), 5.2, true)
	var head_pos: Vector2 = Vector2(0.0, -34.0 + bob)
	var helmet_color: Color = Color("171d28").lerp(Color.WHITE, 0.55 if hit_flash > 0.0 else 0.0)
	if masked:
		var helm_poly: PackedVector2Array = PackedVector2Array([
			head_pos + Vector2(-head_r, -8.0),
			head_pos + Vector2(0.0, -head_r - 3.0),
			head_pos + Vector2(head_r, -8.0),
			head_pos + Vector2(head_r - 2.0, 8.0),
			head_pos + Vector2(0.0, head_r),
			head_pos + Vector2(-head_r + 2.0, 8.0)
		])
		draw_colored_polygon(helm_poly, helmet_color)
		draw_line(head_pos + Vector2(-7.0, -2.0), head_pos + Vector2(7.0, -2.0), visor_color, 4.0, true)
		draw_line(head_pos + Vector2(-5.0, 4.0), head_pos + Vector2(5.0, 4.0), current_accent, 1.8, true)
	else:
		draw_circle(head_pos, head_r, skin_color)
		draw_arc(head_pos + Vector2(0.0, 1.0), 7.0, 0.2, PI - 0.2, 12, Color("2b231f"), 1.8, true)
	var blade_hand: Vector2 = Vector2(10.0, -2.0 + bob)
	var blade_arm_dir: Vector2 = facing if facing.length_squared() > 0.01 else Vector2.RIGHT
	var forward_arm_from: Vector2 = Vector2(10.0, -5.0 + bob)
	var forward_elbow: Vector2 = forward_arm_from + blade_arm_dir * 6.0 + Vector2(0.0, 6.0)
	draw_line(forward_arm_from, forward_elbow, current_body.darkened(0.14), 6.0, true)
	draw_line(forward_elbow, blade_hand, current_body.darkened(0.14), 5.4, true)
	var swing_angle: float = attack_swing_direction * attack_timer * 3.6
	var blade_dir: Vector2 = blade_arm_dir.rotated(swing_angle)
	var hilt_start: Vector2 = blade_hand - blade_dir * 10.0
	var hilt_end: Vector2 = blade_hand + blade_dir * 4.0
	draw_line(hilt_start, hilt_end, Color("161b22"), 5.5, true)
	draw_line(blade_hand + Vector2(-blade_dir.y, blade_dir.x) * 4.0, blade_hand - Vector2(-blade_dir.y, blade_dir.x) * 4.0, Color("343d48"), 2.8, true)
	var blade_len: float = 38.0 + attack_timer * 18.0 + (6.0 if is_stalker else 0.0)
	var blade_end: Vector2 = blade_hand + blade_dir * blade_len
	draw_line(blade_hand, blade_end, Color(weapon_color.r, weapon_color.g, weapon_color.b, 0.18 + glow_alpha), 8.0, true)
	draw_line(blade_hand, blade_end, weapon_color.lightened(0.35), 4.6, true)
	draw_line(blade_hand, blade_end, Color.WHITE, 1.5, true)
	draw_circle(blade_end, 2.8, weapon_color.lightened(0.30))
	if attack_timer > 0.0:
		var slash_poly: PackedVector2Array = PackedVector2Array([
			blade_hand,
			blade_hand + blade_dir.rotated(attack_swing_direction * 0.24) * (blade_len * 0.52),
			blade_end,
			blade_hand + blade_dir.rotated(-attack_swing_direction * 0.24) * (blade_len * 0.64)
		])
		draw_colored_polygon(slash_poly, Color(weapon_color.r, weapon_color.g, weapon_color.b, 0.12))
	draw_circle(Vector2(0.0, -8.0 + bob), 14.0, Color(weapon_color.r, weapon_color.g, weapon_color.b, 0.04 + glow_alpha * 0.4))

func _draw_enemy_blaster_design(current_body: Color, current_accent: Color, bob: float) -> void:
	var move_strength: float = minf(1.0, velocity.length() / maxf(speed, 1.0))
	var stride: float = sin(walk_phase * 1.40) * 3.2 * move_strength
	var side_sign: float = _movement_side_sign()
	var is_sentinel: bool = display_name.find("Sentinel") != -1
	var armor_w: float = 16.0 if not is_sentinel else 18.5
	var shoulder_w: float = 22.0 if not is_sentinel else 25.0
	draw_custom_ellipse(Vector2(0, 22), Vector2(31, 10), Color(weapon_color.r, weapon_color.g, weapon_color.b, 0.03 + move_strength * 0.03))
	var backpack: Rect2 = Rect2(-10.0, -18.0 + bob, 20.0, 24.0)
	if is_sentinel:
		backpack = Rect2(-12.0, -19.0 + bob, 24.0, 26.0)
	draw_rect(backpack, cape_color.darkened(0.05), true)
	draw_rect(backpack.grow(-2), Color(1.0, 1.0, 1.0, 0.04), false, 1.2, true)
	var rear_leg_from: Vector2 = Vector2(-6.0, 7.0 + bob)
	var rear_knee: Vector2 = Vector2(-7.0 - stride * 0.3, 15.0 + bob)
	var rear_foot: Vector2 = Vector2(-9.0 - stride * 0.55, 28.0 + bob)
	var front_leg_from: Vector2 = Vector2(6.0, 7.0 + bob)
	var front_knee: Vector2 = Vector2(8.0 + stride * 0.42, 15.0 + bob)
	var front_foot: Vector2 = Vector2(10.0 + stride * 0.72, 28.0 + bob)
	var leg_color: Color = current_body.darkened(0.22)
	draw_line(rear_leg_from, rear_knee, leg_color, 7.0, true)
	draw_line(rear_knee, rear_foot, leg_color, 6.4, true)
	draw_line(front_leg_from, front_knee, leg_color, 7.2, true)
	draw_line(front_knee, front_foot, leg_color, 6.8, true)
	draw_line(rear_foot + Vector2(-3.0, 0.0), rear_foot + Vector2(3.0, 0.0), Color("10151d"), 4.8, true)
	draw_line(front_foot + Vector2(-4.0, 0.0), front_foot + Vector2(4.0, 0.0), Color("10151d"), 5.0, true)
	var torso_poly: PackedVector2Array = PackedVector2Array([
		Vector2(-armor_w, 13.0 + bob),
		Vector2(-shoulder_w, -5.0 + bob),
		Vector2(-10.0, -22.0 + bob),
		Vector2(10.0, -22.0 + bob),
		Vector2(shoulder_w, -5.0 + bob),
		Vector2(armor_w, 13.0 + bob)
	])
	draw_colored_polygon(torso_poly, current_body)
	draw_polyline(PackedVector2Array([torso_poly[0], torso_poly[1], torso_poly[2], torso_poly[3], torso_poly[4], torso_poly[5], torso_poly[0]]), Color(0.02, 0.03, 0.05, 0.98), 1.8, true)
	draw_rect(Rect2(-13.0, -13.0 + bob, 26.0, 19.0), current_accent.darkened(0.28), true)
	draw_rect(Rect2(-9.0, -9.0 + bob, 18.0, 11.0), current_accent.lightened(0.05), true)
	draw_line(Vector2(-12.0, 0.0 + bob), Vector2(12.0, 0.0 + bob), Color(1.0, 1.0, 1.0, 0.12), 1.4, true)
	if is_sentinel:
		draw_rect(Rect2(-18.0, -16.0 + bob, 6.0, 22.0), current_accent.darkened(0.35), true)
		draw_rect(Rect2(12.0, -16.0 + bob, 6.0, 22.0), current_accent.darkened(0.35), true)
	var left_arm_from: Vector2 = Vector2(-13.0, -5.0 + bob)
	var left_elbow: Vector2 = left_arm_from + Vector2(-4.0 - stride * 0.18, 7.0)
	var left_hand: Vector2 = left_elbow + Vector2(-3.0, 7.0)
	draw_line(left_arm_from, left_elbow, current_body.darkened(0.14), 5.8, true)
	draw_line(left_elbow, left_hand, current_body.darkened(0.14), 5.0, true)
	var gun_dir: Vector2 = facing if facing.length_squared() > 0.01 else Vector2.RIGHT
	var right_arm_from: Vector2 = Vector2(12.0, -6.0 + bob)
	var right_elbow: Vector2 = right_arm_from + gun_dir * 7.0 + Vector2(0.0, 5.0)
	var gun_hand: Vector2 = right_elbow + gun_dir * 8.0
	draw_line(right_arm_from, right_elbow, current_body.darkened(0.14), 5.8, true)
	draw_line(right_elbow, gun_hand, current_body.darkened(0.14), 5.2, true)
	var head_pos: Vector2 = Vector2(0.0, -34.0 + bob)
	var helmet_color: Color = Color("1a222f").lerp(Color.WHITE, 0.55 if hit_flash > 0.0 else 0.0)
	draw_circle(head_pos, 13.0, helmet_color)
	draw_rect(Rect2(head_pos.x - 10.0, head_pos.y - 5.0, 20.0, 6.0), visor_color, true)
	draw_line(head_pos + Vector2(-6.0, 3.0), head_pos + Vector2(6.0, 3.0), current_accent, 2.0, true)
	draw_line(head_pos + Vector2(0.0, -8.0), head_pos + Vector2(0.0, 9.0), current_accent.darkened(0.18), 1.3, true)
	var gun_side: Vector2 = Vector2(-gun_dir.y, gun_dir.x)
	var barrel_length: float = 21.0 if not is_sentinel else 24.0
	var rifle_poly: PackedVector2Array = PackedVector2Array([
		gun_hand - gun_side * 4.0 - gun_dir * 8.0,
		gun_hand + gun_side * 4.0 - gun_dir * 8.0,
		gun_hand + gun_side * 3.8 + gun_dir * 12.0,
		gun_hand - gun_side * 3.8 + gun_dir * 12.0
	])
	draw_colored_polygon(rifle_poly, Color("29323e"))
	draw_polyline(PackedVector2Array([rifle_poly[0], rifle_poly[1], rifle_poly[2], rifle_poly[3], rifle_poly[0]]), Color(1.0, 1.0, 1.0, 0.07), 1.0, true)
	draw_line(gun_hand + gun_dir * 4.0, gun_hand + gun_dir * barrel_length, weapon_color.lightened(0.15), 3.2, true)
	draw_line(gun_hand - gun_side * 2.0, gun_hand - gun_side * 5.0 + gun_dir * 5.0, current_accent, 1.8, true)
	if is_sentinel:
		draw_circle(gun_hand - gun_dir * 3.0, 3.6, weapon_color.darkened(0.18), false, 2.0, true)
	if shot_flash > 0.0:
		var muzzle_pos: Vector2 = gun_hand + gun_dir * (barrel_length + 1.0)
		draw_circle(muzzle_pos, 5.0 + shot_flash * 12.0, Color(weapon_color.r, weapon_color.g, weapon_color.b, 0.22 + shot_flash * 0.50))
		draw_line(muzzle_pos, muzzle_pos + gun_dir * 13.0, Color.WHITE, 1.8, true)
	draw_circle(Vector2(0.0, -8.0 + bob), 12.0, Color(weapon_color.r, weapon_color.g, weapon_color.b, 0.03 + shot_flash * 0.18))

func _draw_enemy_health() -> void:
	var bg_rect: Rect2 = Rect2(-21, -49, 42, 5)
	draw_rect(bg_rect, Color(0.0, 0.0, 0.0, 0.55), true)
	draw_rect(Rect2(-21, -49, 42 * health_ratio(), 5), Color("50df84"), true)

func draw_custom_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(28):
		var angle: float = TAU * float(i) / 28.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)

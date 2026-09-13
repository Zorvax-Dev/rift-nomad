extends Node2D

const FighterScene = preload("res://fighter.gd")
const ProjectileScene = preload("res://projectile.gd")

const BG_FORGE: Texture2D = preload("res://assets/backgrounds/forge_base_hd.png")
const OVERLAY_FORGE: Texture2D = preload("res://assets/backgrounds/forge_overlay_hd.png")
const HERO_PREVIEW_IDLE: Texture2D = preload("res://assets/hero/nomad_idle.webp")
const UI_LOGO_MAIN: Texture2D = preload("res://assets/ui/rift_nomad_logo.png")
const UI_LOGO_EMBLEM: Texture2D = preload("res://assets/ui/rift_nomad_emblem.png")

const VIEW: Vector2 = Vector2(1280, 720)
const ARENA_RECT: Rect2 = Rect2(44, 100, 1192, 576)
const JOYSTICK_RADIUS: float = 84.0
const JOYSTICK_DEADZONE: float = 10.0
const HUD_MENU_TOUCH_RECT: Rect2 = Rect2(1132, 40, 108, 62)
const AUTOSAVE_INTERVAL: float = 6.0
const BALANCE_WAVE_HEAL_RATIO: float = 0.14
const BALANCE_WAVE_HEAL_MIN: float = 10.0
const BALANCE_ENEMY_HP_STEP: float = 0.045
const BALANCE_ENEMY_DAMAGE_STEP: float = 0.022
const BALANCE_VERSION: int = 41
const PLAYER_BASE_SPEED: float = 250.0

enum GameState { LOADING, MENU, CUSTOMIZE, MISSION, OPTIONS, PLAYING, LEVEL_UP, GAME_OVER }
var state: GameState = GameState.LOADING

var background_root: Node2D
var background_base_sprite: Sprite2D
var background_overlay_sprite: Sprite2D
var world_root: Node2D
var fighters_root: Node2D
var projectiles_root: Node2D
var ui_root: CanvasLayer

var menu_panel: Control
var customize_panel: Control
var mission_panel: Control
var options_panel: Control
var hud: Control
var level_panel: Control
var game_over_panel: Control
var loading_panel: Control
var loading_progress_bar: ProgressBar
var loading_status_label: Label
var loading_hint_label: Label
var loading_elapsed: float = 0.0

var preview_fighter: ArenaFighter
var player: ArenaFighter

var player_config: Dictionary = {
	"mask_on": true,
	"mask_style": 0,
	"outfit_idx": 0,
	"weapon_type": "blade",
	"blade_skin_idx": 0,
	"blaster_skin_idx": 0
}

var options_config: Dictionary = {
	"screen_shake": true,
	"low_fx": false
}

var outfit_styles: Array[Dictionary] = [
	{"name":"Nomad", "body":Color("61728e"), "accent":Color("dbe7ff"), "cape":Color("1d2431"), "visor":Color("6fe4ff"), "skin":Color("d7b08a"), "unlock":0},
	{"name":"Skin 02", "body":Color("61728e"), "accent":Color("dbe7ff"), "cape":Color("1d2431"), "visor":Color("6fe4ff"), "skin":Color("d7b08a"), "unlock":999999999},
	{"name":"Skin 03", "body":Color("61728e"), "accent":Color("dbe7ff"), "cape":Color("1d2431"), "visor":Color("6fe4ff"), "skin":Color("d7b08a"), "unlock":999999999},
	{"name":"Skin 04", "body":Color("61728e"), "accent":Color("dbe7ff"), "cape":Color("1d2431"), "visor":Color("6fe4ff"), "skin":Color("d7b08a"), "unlock":999999999},
	{"name":"Skin 05", "body":Color("61728e"), "accent":Color("dbe7ff"), "cape":Color("1d2431"), "visor":Color("6fe4ff"), "skin":Color("d7b08a"), "unlock":999999999},
	{"name":"Skin 06", "body":Color("61728e"), "accent":Color("dbe7ff"), "cape":Color("1d2431"), "visor":Color("6fe4ff"), "skin":Color("d7b08a"), "unlock":999999999}
]

var mask_styles: Array[Dictionary] = [
	{"name":"Scout", "unlock":0},
	{"name":"Warden", "unlock":180},
	{"name":"Veil", "unlock":460},
	{"name":"Breacher", "unlock":1050}
]

var blade_skins: Array[Dictionary] = [
	{"name":"Flux cobalt", "color":Color("56d8ff"), "unlock":0},
	{"name":"Arc émeraude", "color":Color("4fe178"), "unlock":160},
	{"name":"Prisme pourpre", "color":Color("bb72ff"), "unlock":380},
	{"name":"Solaris", "color":Color("ffbc53"), "unlock":700},
	{"name":"Ion blanc", "color":Color("e7fbff"), "unlock":1180}
]

var blaster_skins: Array[Dictionary] = [
	{"name":"Pulse cobalt", "color":Color("5fd6ff"), "unlock":0},
	{"name":"Pulse corail", "color":Color("ff7867"), "unlock":200},
	{"name":"Pulse citron", "color":Color("ffe05a"), "unlock":420},
	{"name":"Pulse violet", "color":Color("c87dff"), "unlock":760},
	{"name":"Pulse glacier", "color":Color("b8f8ff"), "unlock":1250}
]

var missions: Array[Dictionary] = [
	{"name":"Forge orbitale", "description":"Arène principale. Difficulté rééquilibrée avec une montée progressive et une récupération entre les vagues.", "accent":Color("5ac8ff"), "secondary":Color("f0c45b"), "enemy_hp":0.90, "enemy_damage":0.82, "reward":1.15}
]

var enemy_profiles: Array[Dictionary] = [
	{"name":"Raider", "weapon_type":"blade", "body":Color("6b2d35"), "accent":Color("f48f97"), "cape":Color("251217"), "visor":Color("ff8f8a"), "health":82.0, "speed":188.0, "damage":14.0, "range":84.0, "attack_speed":0.92, "armor":0.02},
	{"name":"Trooper", "weapon_type":"blaster", "body":Color("7b838f"), "accent":Color("dce3eb"), "cape":Color("242a33"), "visor":Color("55d0ff"), "health":72.0, "speed":176.0, "damage":11.0, "range":84.0, "attack_speed":0.98, "ranged_range":390.0, "projectile_speed":720.0, "armor":0.03},
	{"name":"Brute", "weapon_type":"blade", "body":Color("5e4437"), "accent":Color("f0b37c"), "cape":Color("231914"), "visor":Color("ffb066"), "health":108.0, "speed":164.0, "damage":16.0, "range":92.0, "attack_speed":1.10, "armor":0.07},
	{"name":"Stalker", "weapon_type":"blade", "body":Color("2f5b58"), "accent":Color("7bf1cf"), "cape":Color("102724"), "visor":Color("7bf1cf"), "health":62.0, "speed":214.0, "damage":11.0, "range":78.0, "attack_speed":0.72, "armor":0.0},
	{"name":"Sentinel", "weapon_type":"blaster", "body":Color("3e4659"), "accent":Color("9ba7c2"), "cape":Color("171b24"), "visor":Color("b488ff"), "health":98.0, "speed":158.0, "damage":14.0, "range":84.0, "attack_speed":1.18, "ranged_range":455.0, "projectile_speed":660.0, "armor":0.16}
]

var upgrade_pool: Array[Dictionary] = [
	{"id":"health", "title":"VITALITÉ", "description":"+25 PV max\nsoigne 25 PV"},
	{"id":"damage", "title":"PUISSANCE", "description":"+18 % dégâts"},
	{"id":"attack_speed", "title":"CÉLÉRITÉ", "description":"+12 % vitesse d'attaque"},
	{"id":"speed", "title":"MOBILITÉ", "description":"+10 % vitesse"},
	{"id":"range", "title":"ALLONGE", "description":"+12 portée d'attaque"},
	{"id":"crit", "title":"PRÉCISION", "description":"+8 % critique"},
	{"id":"lifesteal", "title":"DRAIN", "description":"+4 % vol de vie"},
	{"id":"regen", "title":"MÉDITATION", "description":"+1.5 PV/s"},
	{"id":"armor", "title":"RÉSILIENCE", "description":"+6 % réduction dégâts"}
]

var menu_meta_label: Label
var menu_title_label: Label
var menu_subtitle_label: Label
var menu_left_card: Panel
var menu_right_card: Panel
var menu_hero_preview: TextureRect
var menu_status_label: Label
var menu_best_wave_value: Label
var menu_kills_value: Label
var menu_credits_value: Label
var menu_arena_value: Label
var menu_play_button: Button
var menu_anim_time: float = 0.0
var menu_preview_timer: float = 0.0
var menu_preview_frame: int = 0
var mission_card_panels: Array[Panel] = []
var mission_select_buttons: Array[Button] = []
var options_shake_button: Button
var options_fx_button: Button
var custom_name_label: Label
var custom_look_label: Label
var custom_weapon_label: Label
var custom_legal_label: Label
var custom_progress_label: Label
var mission_title_label: Label
var mission_desc_label: Label
var mission_reward_label: Label
var options_summary_label: Label
var options_save_label: Label
var skin_slot_buttons: Array[Button] = []
var wave_label: Label
var score_label: Label
var hero_label: Label
var level_label: Label
var special_label: Label
var announcement_label: Label
var health_bar: ProgressBar
var health_value_label: Label
var xp_bar: ProgressBar
var xp_value_label: Label
var game_over_title: Label
var game_over_stats: Label
var level_buttons: Array[Button] = []
var current_upgrade_choices: Array[Dictionary] = []

var selected_mission: int = 0
var lifetime_credits: int = 0
var best_wave: int = 0
var lifetime_kills: int = 0
var total_runs: int = 0
var best_score: int = 0
var save_status_text: String = "Aucune sauvegarde locale"
var autosave_timer: float = 0.0
var saved_run_available: bool = false
var saved_run_data: Dictionary = {}
var run_credits: int = 0
var run_banked: bool = false
var special_timer: float = 0.0
var special_cooldown: float = 6.0
var special_fx_time: float = 0.0
var special_fx_radius: float = 0.0
var special_fx_color: Color = Color("70dfff")

var wave: int = 0
var score: int = 0
var kills: int = 0
var enemies_alive: int = 0
var next_wave_timer: float = -1.0
var player_level: int = 1
var player_xp: int = 0
var xp_to_next: int = 70
var total_upgrades: int = 0
var pulse_time: float = 0.0
var shake_time: float = 0.0
var shake_strength: float = 0.0
var shake_duration: float = 0.0

var star_points: PackedVector2Array = PackedVector2Array()
var star_brightness: PackedFloat32Array = PackedFloat32Array()
var ambient_particles: Array[Dictionary] = []
var impact_effects: Array[Dictionary] = []

var joystick_touch_id: int = -1
var joystick_origin: Vector2 = Vector2.ZERO
var joystick_knob: Vector2 = Vector2.ZERO
var joystick_active: bool = false

func _ready() -> void:
	randomize()
	_load_save()
	_generate_stars()
	_generate_ambient_particles()

	background_root = Node2D.new()
	background_root.name = "DynamicBackground"
	background_root.z_index = -100
	add_child(background_root)

	background_base_sprite = Sprite2D.new()
	background_base_sprite.name = "BackgroundBase"
	background_base_sprite.position = VIEW * 0.5
	background_base_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	background_root.add_child(background_base_sprite)

	background_overlay_sprite = Sprite2D.new()
	background_overlay_sprite.name = "BackgroundOverlay"
	background_overlay_sprite.position = VIEW * 0.5
	background_overlay_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	background_overlay_sprite.z_index = 1
	background_root.add_child(background_overlay_sprite)

	_update_background_assets()

	world_root = Node2D.new()
	world_root.name = "World"
	add_child(world_root)

	fighters_root = Node2D.new()
	fighters_root.name = "Fighters"
	world_root.add_child(fighters_root)

	projectiles_root = Node2D.new()
	projectiles_root.name = "Projectiles"
	world_root.add_child(projectiles_root)

	ui_root = CanvasLayer.new()
	ui_root.name = "UI"
	add_child(ui_root)

	_build_loading_panel()
	_build_menu_panel()
	_build_customize_panel()
	_build_mission_panel()
	_build_options_panel()
	_build_hud()
	_build_level_panel()
	_build_game_over_panel()

	_show_loading_screen()
	queue_redraw()

func _generate_stars() -> void:
	var total: int = 120 if bool(options_config["low_fx"]) else 180
	star_points = PackedVector2Array()
	star_brightness = PackedFloat32Array()
	for _i: int in range(total):
		star_points.append(Vector2(randf_range(0.0, VIEW.x), randf_range(0.0, VIEW.y)))
		star_brightness.append(randf_range(0.15, 0.95))

func _generate_ambient_particles() -> void:
	ambient_particles.clear()
	var total: int = 16 if bool(options_config["low_fx"]) else 32
	for _i: int in range(total):
		ambient_particles.append({
			"base": Vector2(randf_range(ARENA_RECT.position.x - 30.0, ARENA_RECT.end.x + 30.0), randf_range(ARENA_RECT.position.y - 36.0, ARENA_RECT.end.y + 24.0)),
			"phase": randf_range(0.0, TAU),
			"depth": randf_range(0.35, 1.0),
			"size": randf_range(1.8, 4.8),
			"speed": randf_range(0.35, 1.15),
			"drift": randf_range(-20.0, 20.0)
		})

func _update_impact_effects(delta: float) -> void:
	for i: int in range(impact_effects.size() - 1, -1, -1):
		var effect: Dictionary = impact_effects[i]
		effect["time"] = float(effect["time"]) - delta
		impact_effects[i] = effect
		if float(effect["time"]) <= 0.0:
			impact_effects.remove_at(i)

func _spawn_impact_effect(position: Vector2, base_color: Color, strong: bool) -> void:
	impact_effects.append({
		"pos": position,
		"time": 0.44 if strong else 0.24,
		"max_time": 0.44 if strong else 0.24,
		"radius": 18.0 if strong else 10.0,
		"growth": 64.0 if strong else 38.0,
		"color": base_color,
		"strong": strong,
		"angle": randf_range(0.0, TAU)
	})

func _spawn_muzzle_effect(position: Vector2, direction: Vector2, base_color: Color, critical: bool) -> void:
	impact_effects.append({
		"kind": "muzzle",
		"pos": position,
		"time": 0.11,
		"max_time": 0.11,
		"radius": 7.0 if critical else 5.0,
		"growth": 18.0,
		"color": base_color,
		"strong": critical,
		"direction": direction.normalized(),
		"angle": direction.angle()
	})

func _process(delta: float) -> void:
	pulse_time += delta
	_update_loading_motion(delta)
	_update_menu_motion(delta)
	if special_fx_time > 0.0:
		special_fx_time = maxf(0.0, special_fx_time - delta)
	_update_impact_effects(delta)
	if state == GameState.PLAYING:
		autosave_timer += delta
		if autosave_timer >= AUTOSAVE_INTERVAL:
			autosave_timer = 0.0
			_save_progress()
		if next_wave_timer >= 0.0:
			next_wave_timer -= delta
			if next_wave_timer <= 0.0:
				next_wave_timer = -1.0
				spawn_wave()
		_update_auto_special(delta)
		_update_hud()

	if bool(options_config["screen_shake"]) and shake_time > 0.0:
		shake_time = maxf(0.0, shake_time - delta)
		var shake_ratio: float = clampf(shake_time / maxf(shake_duration, 0.001), 0.0, 1.0)
		var shake_wave: Vector2 = Vector2(sin(pulse_time * 91.0), cos(pulse_time * 113.0))
		world_root.position = shake_wave * shake_strength * shake_ratio
	else:
		shake_time = 0.0
		shake_strength = 0.0
		shake_duration = 0.0
		world_root.position = Vector2.ZERO

	_update_dynamic_background()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if state != GameState.PLAYING or not is_instance_valid(player) or player.dead:
		return
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed:
			if joystick_touch_id == -1 and not HUD_MENU_TOUCH_RECT.has_point(touch.position):
				joystick_touch_id = touch.index
				joystick_origin = touch.position
				joystick_knob = touch.position
				joystick_active = true
				player.mobile_input_vector = Vector2.ZERO
				queue_redraw()
				get_viewport().set_input_as_handled()
		elif touch.index == joystick_touch_id:
			_reset_joystick()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		if drag.index == joystick_touch_id:
			_update_joystick(drag.position)
			get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventKey:
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if state == GameState.GAME_OVER:
		if key_event.keycode == KEY_ENTER or key_event.keycode == KEY_R:
			start_game()
	elif state == GameState.MENU:
		if key_event.keycode == KEY_ENTER:
			_start_or_continue_run()
	elif state == GameState.CUSTOMIZE or state == GameState.MISSION or state == GameState.OPTIONS:
		if key_event.keycode == KEY_ESCAPE:
			_show_main_menu()

func _update_joystick(touch_pos: Vector2) -> void:
	var delta: Vector2 = touch_pos - joystick_origin
	var distance: float = delta.length()
	if distance > JOYSTICK_RADIUS:
		delta = delta.normalized() * JOYSTICK_RADIUS
	joystick_knob = joystick_origin + delta
	if is_instance_valid(player):
		if distance <= JOYSTICK_DEADZONE:
			player.mobile_input_vector = Vector2.ZERO
		else:
			player.mobile_input_vector = delta / JOYSTICK_RADIUS
	queue_redraw()

func _reset_joystick() -> void:
	joystick_touch_id = -1
	joystick_active = false
	joystick_knob = joystick_origin
	if is_instance_valid(player):
		player.mobile_input_vector = Vector2.ZERO
	queue_redraw()

func _update_auto_special(delta: float) -> void:
	if not is_instance_valid(player) or player.dead:
		return
	special_timer = maxf(0.0, special_timer - delta)
	if special_timer > 0.0:
		return
	if String(player_config["weapon_type"]) == "blade":
		var victims: Array[ArenaFighter] = []
		for node: Node in get_tree().get_nodes_in_group("fighters"):
			var enemy: ArenaFighter = node as ArenaFighter
			if enemy == null or enemy == player or enemy.dead or enemy.team == player.team:
				continue
			if player.global_position.distance_to(enemy.global_position) <= 178.0:
				victims.append(enemy)
		if victims.is_empty():
			return
		var total_damage: float = 0.0
		for enemy: ArenaFighter in victims:
			var direction: Vector2 = enemy.global_position - player.global_position
			if direction.length() < 0.1:
				direction = Vector2.RIGHT
			var actual: float = enemy.take_damage(player.damage * 0.58, direction.normalized() * 310.0, 0.16)
			total_damage += actual
		if player.lifesteal > 0.0 and total_damage > 0.0:
			player.health = minf(player.max_health, player.health + total_damage * player.lifesteal)
			player.health_changed.emit(player)
		special_cooldown = 6.2
		special_timer = special_cooldown
		special_fx_time = 0.34
		special_fx_radius = 178.0
		special_fx_color = _current_weapon_skin()["color"] as Color
		_trigger_shake(5.0, 0.18)
	else:
		var targets: Array[ArenaFighter] = _nearest_enemies(4)
		if targets.is_empty():
			return
		var shot_color: Color = _current_weapon_skin()["color"] as Color
		for enemy: ArenaFighter in targets:
			var direction: Vector2 = enemy.global_position - player.global_position
			if direction.length() < 0.1:
				direction = Vector2.RIGHT
			_on_request_shot(player, player.global_position + direction.normalized() * 18.0, direction.normalized(), player.damage * 0.72, shot_color, false)
		special_cooldown = 5.4
		special_timer = special_cooldown
		special_fx_time = 0.26
		special_fx_radius = 70.0
		special_fx_color = shot_color
		_trigger_shake(3.5, 0.12)

func _nearest_enemies(limit: int) -> Array[ArenaFighter]:
	var result: Array[ArenaFighter] = []
	if not is_instance_valid(player):
		return result
	for _pick: int in range(limit):
		var nearest: ArenaFighter = null
		var nearest_distance: float = INF
		for node: Node in get_tree().get_nodes_in_group("fighters"):
			var enemy: ArenaFighter = node as ArenaFighter
			if enemy == null or enemy == player or enemy.dead or enemy.team == player.team or result.has(enemy):
				continue
			var distance: float = player.global_position.distance_squared_to(enemy.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = enemy
		if nearest == null:
			break
		result.append(nearest)
	return result

func _clear_world() -> void:
	for node: Node in fighters_root.get_children():
		node.queue_free()
	for node: Node in projectiles_root.get_children():
		node.queue_free()
	impact_effects.clear()
	preview_fighter = null
	player = null
	enemies_alive = 0
	_reset_joystick()

func _show_only(panel: Control) -> void:
	if loading_panel != null:
		loading_panel.visible = false
	menu_panel.visible = false
	customize_panel.visible = false
	mission_panel.visible = false
	options_panel.visible = false
	hud.visible = false
	level_panel.visible = false
	game_over_panel.visible = false
	panel.visible = true

func _show_loading_screen() -> void:
	state = GameState.LOADING
	_clear_world()
	_show_only(loading_panel)
	loading_elapsed = 0.0
	if loading_progress_bar != null:
		loading_progress_bar.value = 0.0
	if loading_status_label != null:
		loading_status_label.text = "Synchronisation de la faille"
	if loading_hint_label != null:
		loading_hint_label.text = "Préparation de l'arène orbitale"
	var timer: SceneTreeTimer = get_tree().create_timer(1.65)
	timer.timeout.connect(_finish_loading_screen)

func _finish_loading_screen() -> void:
	if state == GameState.LOADING:
		_show_main_menu()

func _show_main_menu() -> void:
	if (state == GameState.PLAYING or state == GameState.LEVEL_UP) and not run_banked and wave > 0:
		_bank_run_progress()
	state = GameState.MENU
	_clear_world()
	_show_only(menu_panel)
	_announcement_text("", Color.WHITE)
	_update_customize_panel()
	_update_mission_panel()
	_update_options_panel()
	_update_menu_meta()
	_update_menu_preview()
	_animate_menu_entry()

func _show_customize_menu() -> void:
	state = GameState.CUSTOMIZE
	_clear_world()
	_show_only(customize_panel)
	_update_customize_panel()
	_animate_panel_reveal(customize_panel)

func _show_mission_menu() -> void:
	state = GameState.MISSION
	_clear_world()
	_show_only(mission_panel)
	_update_mission_panel()
	_animate_panel_reveal(mission_panel)

func _show_options_menu() -> void:
	state = GameState.OPTIONS
	_clear_world()
	_show_only(options_panel)
	_update_options_panel()
	_animate_panel_reveal(options_panel)

func _spawn_preview_fighter() -> void:
	if is_instance_valid(preview_fighter):
		preview_fighter.queue_free()
	preview_fighter = FighterScene.new()
	preview_fighter.arena_rect = ARENA_RECT
	preview_fighter.global_position = Vector2(955, 400)
	preview_fighter.setup_from_profile(_build_player_profile(), true, 0)
	_apply_room_profile_to_fighter(preview_fighter)
	preview_fighter.combat_enabled = false
	fighters_root.add_child(preview_fighter)

func _mission_room_profile() -> Dictionary:
	return {
		"top_y": 286.0,
		"bottom_y": 646.0,
		"left_top_x": 54.0,
		"right_top_x": 1226.0,
		"left_bottom_x": 54.0,
		"right_bottom_x": 1226.0,
		"scale_min": 0.93,
		"scale_max": 1.02,
		"free_movement": true
	}
func _room_x_bounds_for_profile(profile: Dictionary, y_pos: float) -> Vector2:
	if bool(profile.get("free_movement", false)):
		return Vector2(
			float(profile.get("left_bottom_x", ARENA_RECT.position.x)),
			float(profile.get("right_bottom_x", ARENA_RECT.end.x))
		)
	var top_y: float = float(profile.get("top_y", ARENA_RECT.position.y + 150.0))
	var bottom_y: float = float(profile.get("bottom_y", ARENA_RECT.end.y - 18.0))
	var ratio: float = 1.0
	if bottom_y > top_y:
		ratio = clampf((y_pos - top_y) / (bottom_y - top_y), 0.0, 1.0)
	var left_x: float = lerpf(float(profile.get("left_top_x", ARENA_RECT.position.x + 80.0)), float(profile.get("left_bottom_x", ARENA_RECT.position.x + 8.0)), ratio)
	var right_x: float = lerpf(float(profile.get("right_top_x", ARENA_RECT.end.x - 80.0)), float(profile.get("right_bottom_x", ARENA_RECT.end.x - 8.0)), ratio)
	return Vector2(left_x, right_x)
func _apply_room_profile_to_fighter(fighter: ArenaFighter) -> void:
	if fighter == null:
		return
	fighter.apply_room_profile(_mission_room_profile())

func _build_player_profile() -> Dictionary:
	var outfit: Dictionary = outfit_styles[int(player_config["outfit_idx"])]
	var weapon_type: String = String(player_config["weapon_type"])
	var weapon_skin: Dictionary = blade_skins[int(player_config["blade_skin_idx"])]
	if weapon_type == "blaster":
		weapon_skin = blaster_skins[int(player_config["blaster_skin_idx"])]
	var profile: Dictionary = {
		"name": "Nomad",
		"body": outfit["body"],
		"accent": outfit["accent"],
		"cape": outfit["cape"],
		"visor": outfit["visor"],
		"skin": outfit["skin"],
		"mask_on": bool(player_config["mask_on"]),
		"mask_style": int(player_config["mask_style"]),
		"outfit_name": String(outfit["name"]),
		"outfit_idx": int(player_config["outfit_idx"]),
		"weapon_type": weapon_type,
		"weapon_name": String(weapon_skin["name"]),
		"weapon_color": weapon_skin["color"],
		"weapon_skin_idx": int(player_config["blade_skin_idx"] if weapon_type == "blade" else player_config["blaster_skin_idx"]),
		"health": 135.0,
		"speed": PLAYER_BASE_SPEED,
		"damage": 26.0,
		"range": 96.0,
		"attack_speed": 0.56,
		"ranged_range": 430.0,
		"projectile_speed": 780.0,
		"critical_chance": 0.08,
		"critical_multiplier": 1.7,
		"lifesteal": 0.0,
		"regeneration": 0.35,
		"armor": 0.05
	}
	return profile

func _start_or_continue_run() -> void:
	if saved_run_available:
		_resume_saved_run()
	else:
		start_game()

func _resume_saved_run() -> void:
	if not saved_run_available or saved_run_data.is_empty():
		start_game()
		return
	state = GameState.PLAYING
	projectiles_root.process_mode = Node.PROCESS_MODE_INHERIT
	_show_only(hud)
	level_panel.visible = false
	game_over_panel.visible = false
	_clear_world()
	wave = maxi(0, int(saved_run_data.get("wave", 1)) - 1)
	score = int(saved_run_data.get("score", 0))
	kills = int(saved_run_data.get("kills", 0))
	run_credits = int(saved_run_data.get("run_credits", 0))
	player_level = maxi(1, int(saved_run_data.get("player_level", 1)))
	player_xp = maxi(0, int(saved_run_data.get("player_xp", 0)))
	xp_to_next = maxi(40, int(saved_run_data.get("xp_to_next", 70)))
	total_upgrades = maxi(0, int(saved_run_data.get("total_upgrades", 0)))
	special_timer = maxf(0.0, float(saved_run_data.get("special_timer", 0.0)))
	run_banked = false
	autosave_timer = 0.0
	spawn_player()
	if is_instance_valid(player):
		# Migration douce des runs V36 : aucun ancien run ne repart avec des stats inférieures au nouvel équilibrage de base.
		var saved_max_health: float = float(saved_run_data.get("max_health", player.max_health))
		var saved_health: float = float(saved_run_data.get("health", saved_max_health))
		player.max_health = maxf(135.0, saved_max_health)
		player.health = clampf(saved_health + maxf(0.0, player.max_health - saved_max_health), 1.0, player.max_health)
		var saved_speed: float = float(saved_run_data.get("speed", PLAYER_BASE_SPEED))
		if int(saved_run_data.get("balance_version", 0)) < BALANCE_VERSION:
			saved_speed *= 0.90
		player.speed = maxf(PLAYER_BASE_SPEED, saved_speed)
		player.damage = maxf(26.0, float(saved_run_data.get("damage", player.damage)))
		player.attack_range = maxf(96.0, float(saved_run_data.get("attack_range", player.attack_range)))
		player.attack_cooldown_base = minf(0.56, maxf(0.20, float(saved_run_data.get("attack_cooldown", player.attack_cooldown_base))))
		player.critical_chance = clampf(float(saved_run_data.get("critical_chance", player.critical_chance)), 0.0, 0.85)
		player.lifesteal = clampf(float(saved_run_data.get("lifesteal", player.lifesteal)), 0.0, 0.60)
		player.regeneration = maxf(0.35, float(saved_run_data.get("regeneration", player.regeneration)))
		player.armor = clampf(maxf(0.05, float(saved_run_data.get("armor", player.armor))), 0.0, 0.65)
		player.health_changed.emit(player)
	spawn_wave()
	saved_run_available = false
	saved_run_data.clear()
	_update_hud()
	_announcement_text("Run repris  •  vague %d" % [wave], Color("7be3ff"))
	_save_progress()

func start_game() -> void:
	saved_run_available = false
	saved_run_data.clear()
	autosave_timer = 0.0
	state = GameState.PLAYING
	projectiles_root.process_mode = Node.PROCESS_MODE_INHERIT
	_show_only(hud)
	level_panel.visible = false
	game_over_panel.visible = false
	_clear_world()
	wave = 0
	score = 0
	kills = 0
	next_wave_timer = -1.0
	player_level = 1
	player_xp = 0
	xp_to_next = 70
	total_upgrades = 0
	run_credits = 0
	run_banked = false
	special_cooldown = 6.2 if String(player_config["weapon_type"]) == "blade" else 5.4
	special_timer = 2.2
	special_fx_time = 0.0
	spawn_player()
	spawn_wave()
	_update_hud()
	var mission: Dictionary = missions[selected_mission]
	_announcement_text(String(mission["name"]), mission["accent"] as Color)
	_save_progress()

func spawn_player() -> void:
	player = FighterScene.new()
	player.arena_rect = ARENA_RECT
	player.global_position = ARENA_RECT.get_center()
	player.setup_from_profile(_build_player_profile(), true, 0)
	_apply_room_profile_to_fighter(player)
	player.died.connect(_on_fighter_died)
	player.health_changed.connect(_on_health_changed)
	player.attack_landed.connect(_on_attack_landed)
	player.request_shot.connect(_on_request_shot)
	fighters_root.add_child(player)

func spawn_wave() -> void:
	if not is_instance_valid(player) or player.dead:
		return
	wave += 1
	enemies_alive = 0
	var champion_wave: bool = wave % 10 == 0
	# La V36 démarrait à 5 ennemis et montait presque immédiatement en surnombre.
	# La nouvelle courbe laisse respirer le joueur et plafonne le chaos à l'écran.
	var total_enemies: int = mini(3 + int(floor(float(wave - 1) * 0.60)), 12)
	if champion_wave:
		total_enemies = mini(total_enemies, 9)
	var elite_frequency: int = 6
	for i: int in range(total_enemies):
		var enemy: ArenaFighter = FighterScene.new()
		var elite: bool = (wave % elite_frequency == 0 and i == total_enemies - 1 and not champion_wave)
		var champion: bool = champion_wave and i == total_enemies - 1
		# Un champion n'empile plus les multiplicateurs d'élite + champion.
		var profile: Dictionary = _build_enemy_profile(randi_range(0, enemy_profiles.size() - 1), elite)
		if champion:
			profile["name"] = "Champion %s" % [String(profile["name"])]
			profile["health"] = float(profile["health"]) * 1.80
			profile["damage"] = float(profile["damage"]) * 1.15
			profile["speed"] = float(profile["speed"]) * 0.95
			profile["attack_speed"] = float(profile["attack_speed"]) * 1.04
			profile["armor"] = minf(0.38, float(profile["armor"]) + 0.08)
		enemy.arena_rect = ARENA_RECT
		enemy.setup_from_profile(profile, false, 1)
		enemy.global_position = _random_spawn_position()
		_apply_room_profile_to_fighter(enemy)
		enemy.target = player
		if champion:
			enemy.set_room_base_scale(1.04)
		elif elite:
			enemy.set_room_base_scale(1.01)
		enemy.died.connect(_on_fighter_died)
		enemy.health_changed.connect(_on_health_changed)
		enemy.attack_landed.connect(_on_attack_landed)
		enemy.request_shot.connect(_on_request_shot)
		fighters_root.add_child(enemy)
		enemies_alive += 1
	var mission: Dictionary = missions[selected_mission]
	if champion_wave:
		_announcement_text("Vague %d  •  CHAMPION" % [wave], Color("f1cf63"))
		_trigger_shake(3.0, 0.14)
	elif wave % elite_frequency == 0:
		_announcement_text("Vague %d  •  ÉLITE" % [wave], Color("ffb06a"))
	else:
		_announcement_text("Vague %d" % wave, mission["accent"] as Color)
	_save_progress()

func _build_enemy_profile(index: int, elite: bool) -> Dictionary:
	var base: Dictionary = enemy_profiles[index]
	var mission: Dictionary = missions[selected_mission]
	var wave_health_scale: float = 1.0 + maxf(0.0, float(wave - 1)) * BALANCE_ENEMY_HP_STEP
	var wave_damage_scale: float = 1.0 + maxf(0.0, float(wave - 1)) * BALANCE_ENEMY_DAMAGE_STEP
	var enemy_weapon_type: String = String(base["weapon_type"])
	var enemy_skin_idx: int = randi_range(0, 2)
	var profile: Dictionary = {
		"name": String(base["name"]),
		"body": base["body"],
		"accent": base["accent"],
		"cape": base["cape"],
		"visor": base["visor"],
		"skin": Color("bb8d6c"),
		"mask_on": true,
		"mask_style": randi_range(0, 3),
		"outfit_name": String(base["name"]),
		"outfit_idx": randi_range(0, 5),
		"weapon_type": enemy_weapon_type,
		"weapon_name": "Arme",
		"weapon_color": base["visor"],
		"weapon_skin_idx": enemy_skin_idx,
		"health": float(base["health"]) * float(mission["enemy_hp"]) * wave_health_scale,
		"speed": float(base["speed"]) * (1.0 + minf(float(wave) * 0.003, 0.06)),
		"damage": float(base["damage"]) * float(mission["enemy_damage"]) * wave_damage_scale,
		"range": float(base["range"]),
		"attack_speed": maxf(0.56, float(base["attack_speed"]) * (1.0 - minf(float(wave) * 0.003, 0.08))),
		"ranged_range": float(base.get("ranged_range", 400.0)),
		"projectile_speed": float(base.get("projectile_speed", 720.0)),
		"critical_chance": 0.03 + minf(float(wave) * 0.0015, 0.045),
		"critical_multiplier": 1.55,
		"armor": float(base.get("armor", 0.0)),
		"elite": elite
	}
	if elite:
		profile["name"] = "%s Élite" % String(base["name"])
		profile["health"] = float(profile["health"]) * 1.65
		profile["damage"] = float(profile["damage"]) * 1.20
		profile["speed"] = float(profile["speed"]) * 1.01
		profile["attack_speed"] = maxf(0.56, float(profile["attack_speed"]) * 0.93)
		profile["armor"] = minf(0.34, float(profile["armor"]) + 0.08)
	return profile

func _random_spawn_position() -> Vector2:
	var profile: Dictionary = _mission_room_profile()
	var top_y: float = float(profile.get("top_y", ARENA_RECT.position.y + 150.0))
	var bottom_y: float = float(profile.get("bottom_y", ARENA_RECT.end.y - 18.0))
	var edge: int = randi_range(0, 3)
	match edge:
		0:
			var spawn_y_top: float = top_y + 8.0
			var bounds_top: Vector2 = _room_x_bounds_for_profile(profile, spawn_y_top)
			return Vector2(randf_range(bounds_top.x + 28.0, bounds_top.y - 28.0), spawn_y_top)
		1:
			var spawn_y_bottom: float = bottom_y - 8.0
			var bounds_bottom: Vector2 = _room_x_bounds_for_profile(profile, spawn_y_bottom)
			return Vector2(randf_range(bounds_bottom.x + 28.0, bounds_bottom.y - 28.0), spawn_y_bottom)
		2:
			var side_y_left: float = randf_range(top_y + 12.0, bottom_y - 12.0)
			var left_bounds: Vector2 = _room_x_bounds_for_profile(profile, side_y_left)
			return Vector2(left_bounds.x + 28.0, side_y_left)
		_:
			var side_y_right: float = randf_range(top_y + 12.0, bottom_y - 12.0)
			var right_bounds: Vector2 = _room_x_bounds_for_profile(profile, side_y_right)
			return Vector2(right_bounds.y - 28.0, side_y_right)

func _on_request_shot(shooter: ArenaFighter, origin: Vector2, direction: Vector2, damage_amount: float, shot_color: Color, critical: bool) -> void:
	_spawn_muzzle_effect(origin, direction, shot_color, critical)
	var projectile: ArenaProjectile = ProjectileScene.new()
	projectile.global_position = origin
	projectile.velocity = direction.normalized() * shooter.projectile_speed
	projectile.team = shooter.team
	projectile.damage = damage_amount
	projectile.shot_color = shot_color
	projectile.critical = critical
	projectile.owner_fighter = shooter
	projectile.arena_rect = ARENA_RECT
	projectile.hit_target.connect(_on_projectile_hit)
	projectiles_root.add_child(projectile)

func _on_projectile_hit(shooter: ArenaFighter, victim: ArenaFighter, damage_amount: float, critical: bool) -> void:
	if is_instance_valid(shooter):
		_on_attack_landed(shooter, victim, damage_amount, critical)

func _on_health_changed(_fighter: ArenaFighter) -> void:
	_update_hud()

func _on_attack_landed(attacker: ArenaFighter, victim: ArenaFighter, _damage_amount: float, critical: bool) -> void:
	if is_instance_valid(victim):
		_spawn_impact_effect(victim.global_position, attacker.weapon_color, critical or attacker == player)
		var victim_stop: float = 0.048 if critical else 0.028
		victim.apply_hit_stop(victim_stop)
	if is_instance_valid(attacker) and attacker.weapon_type == "blade":
		attacker.apply_hit_stop(0.035 if critical else 0.018)
	if attacker == player and critical:
		_trigger_shake(5.0, 0.15)
	elif attacker == player:
		_trigger_shake(2.5, 0.085)
	elif victim == player:
		_trigger_shake(1.8, 0.07)

func _on_fighter_died(fighter: ArenaFighter) -> void:
	if fighter == player:
		state = GameState.GAME_OVER
		_bank_run_progress()
		_show_only(game_over_panel)
		game_over_title.text = "Défaite"
		game_over_stats.text = "Vague %d  •  Score %d\nEnnemis vaincus %d  •  Crédits de run +%d\nRéserve totale %d crédits" % [wave, score, kills, run_credits, lifetime_credits]
		return

	enemies_alive = max(0, enemies_alive - 1)
	_spawn_impact_effect(fighter.global_position, fighter.visor_color, true)
	var corpse_timer: SceneTreeTimer = get_tree().create_timer(0.55)
	corpse_timer.timeout.connect(fighter.queue_free)
	kills += 1
	var mission: Dictionary = missions[selected_mission]
	var base_credit: int = 7 + wave * 2 + (16 if fighter.elite else 0)
	var gained_credit: int = roundi(float(base_credit) * float(mission["reward"]))
	run_credits += gained_credit
	score += 12 + wave * 3 + (18 if fighter.elite else 0)
	gain_xp(18 + wave * 2 + (22 if fighter.elite else 0))
	if kills % 3 == 0:
		_save_progress()
	if enemies_alive <= 0:
		next_wave_timer = 2.15
		for shot_node: Node in projectiles_root.get_children():
			shot_node.queue_free()
		var recovered: float = 0.0
		if is_instance_valid(player) and not player.dead:
			var wanted_heal: float = maxf(BALANCE_WAVE_HEAL_MIN, player.max_health * BALANCE_WAVE_HEAL_RATIO)
			recovered = minf(wanted_heal, player.max_health - player.health)
			if recovered > 0.0:
				player.health += recovered
				player.health_changed.emit(player)
		if recovered > 0.5:
			_announcement_text("Zone sécurisée  •  récupération +%d PV" % roundi(recovered), Color("7be3a2"))
		else:
			_announcement_text("Zone sécurisée  •  prochaine vague", Color("7be3a2"))

func _bank_run_progress() -> void:
	if run_banked:
		return
	best_wave = max(best_wave, wave)
	best_score = max(best_score, score)
	total_runs += 1
	lifetime_kills += kills
	lifetime_credits += run_credits
	run_banked = true
	_save_progress()
func gain_xp(amount: int) -> void:
	if state != GameState.PLAYING and state != GameState.LEVEL_UP:
		return
	player_xp += amount
	if state == GameState.PLAYING and player_xp >= xp_to_next:
		player_xp -= xp_to_next
		player_level += 1
		xp_to_next = 70 + (player_level - 1) * 35
		_open_level_up()
	_update_hud()

func _open_level_up() -> void:
	state = GameState.LEVEL_UP
	projectiles_root.process_mode = Node.PROCESS_MODE_DISABLED
	for node: Node in fighters_root.get_children():
		var fighter: ArenaFighter = node as ArenaFighter
		if fighter != null:
			fighter.combat_enabled = false
	current_upgrade_choices = []
	var used_indices: Array[int] = []
	while current_upgrade_choices.size() < 3:
		var index: int = randi_range(0, upgrade_pool.size() - 1)
		if used_indices.has(index):
			continue
		used_indices.append(index)
		current_upgrade_choices.append(upgrade_pool[index])
	for i: int in range(level_buttons.size()):
		var button: Button = level_buttons[i]
		var choice: Dictionary = current_upgrade_choices[i]
		button.text = "%s\n\n%s" % [String(choice["title"]), String(choice["description"])]
	level_panel.visible = true
	announcement_label.text = "Choisis 1 amplification"
	_save_progress()

func _on_upgrade_choice(slot: int) -> void:
	if slot < 0 or slot >= current_upgrade_choices.size() or not is_instance_valid(player):
		return
	var upgrade_id: String = String(current_upgrade_choices[slot]["id"])
	_apply_upgrade(upgrade_id)
	total_upgrades += 1
	state = GameState.PLAYING
	projectiles_root.process_mode = Node.PROCESS_MODE_INHERIT
	level_panel.visible = false
	for node: Node in fighters_root.get_children():
		var fighter: ArenaFighter = node as ArenaFighter
		if fighter != null:
			fighter.combat_enabled = true
	_update_hud()
	_announcement_text("Amplification obtenue", Color("7be3ff"))
	_save_progress()
	if player_xp >= xp_to_next:
		player_xp -= xp_to_next
		player_level += 1
		xp_to_next = 70 + (player_level - 1) * 35
		_open_level_up()

func _apply_upgrade(upgrade_id: String) -> void:
	if not is_instance_valid(player):
		return
	match upgrade_id:
		"health":
			player.max_health += 25.0
			player.health = minf(player.max_health, player.health + 25.0)
		"damage":
			player.damage *= 1.18
		"attack_speed":
			player.attack_cooldown_base = maxf(0.18, player.attack_cooldown_base * 0.88)
		"speed":
			player.speed *= 1.10
		"range":
			player.attack_range += 12.0
			player.ranged_range += 26.0
		"crit":
			player.critical_chance = minf(0.65, player.critical_chance + 0.08)
		"lifesteal":
			player.lifesteal = minf(0.35, player.lifesteal + 0.04)
		"regen":
			player.regeneration += 1.5
		"armor":
			player.armor = minf(0.60, player.armor + 0.06)
	player.health_changed.emit(player)

func _trigger_shake(strength: float, duration: float) -> void:
	if not bool(options_config["screen_shake"]):
		return
	shake_strength = maxf(shake_strength, strength)
	shake_time = maxf(shake_time, duration)
	shake_duration = maxf(shake_duration, duration)

func _update_hud() -> void:
	if not hud.visible or not is_instance_valid(player):
		return
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	xp_bar.max_value = xp_to_next
	xp_bar.value = player_xp
	health_value_label.text = "%d / %d" % [roundi(player.health), roundi(player.max_health)]
	xp_value_label.text = "XP %d / %d" % [player_xp, xp_to_next]
	wave_label.text = "VAGUE %d" % wave
	score_label.text = "SCORE %d  •  KO %d  •  RUN %d CR" % [score, kills, run_credits]
	var hero_outfit: Dictionary = outfit_styles[int(player_config["outfit_idx"])]
	hero_label.text = "Nomad  •  %s" % [String(hero_outfit["name"])]
	level_label.text = "Niv. %d  •  Amplif. %d  •  Total %d cr." % [player_level, total_upgrades, lifetime_credits]
	var special_name: String = "Onde cinétique"
	special_label.text = "%s  •  %s" % [special_name, ("PRÊT" if special_timer <= 0.0 else "recharge %.1fs" % special_timer)]
func _announcement_text(text: String, color: Color) -> void:
	announcement_label.text = text
	announcement_label.add_theme_color_override("font_color", color)

func _current_weapon_skin() -> Dictionary:
	if String(player_config["weapon_type"]) == "blaster":
		return blaster_skins[int(player_config["blaster_skin_idx"])]
	return blade_skins[int(player_config["blade_skin_idx"])]

func _update_customize_panel() -> void:
	var skin_idx: int = int(player_config["outfit_idx"])
	var skin_data: Dictionary = outfit_styles[skin_idx]
	custom_name_label.text = "Skin active : %s" % [String(skin_data["name"])]
	custom_look_label.text = "Apparence actuelle du héros\nSlot %02d" % [skin_idx + 1]
	custom_weapon_label.text = "Les nouvelles skins seront ajoutées ici plus tard.\nLe menu est déjà prêt pour les accueillir."
	custom_progress_label.text = "Crédits : %d\n%s" % [lifetime_credits, _next_unlock_text()]
	custom_legal_label.text = "Le slot actif est sauvegardé automatiquement. Les slots marqués À VENIR seront activés lorsque leurs assets seront créés."
	_update_skin_slots()

func _next_unlock_text() -> String:
	return "Nouvelles skins à venir"

func _update_mission_panel() -> void:
	if mission_title_label == null:
		return
	var mission: Dictionary = missions[selected_mission]
	mission_title_label.text = String(mission["name"])
	mission_title_label.add_theme_color_override("font_color", mission["accent"] as Color)
	mission_desc_label.text = String(mission["description"])
	mission_reward_label.text = "Équilibrage ×%.2f PV  •  ×%.2f dégâts  •  ×%.2f crédits" % [float(mission["enemy_hp"]), float(mission["enemy_damage"]), float(mission["reward"])]
	for i: int in range(mission_select_buttons.size()):
		var button: Button = mission_select_buttons[i]
		button.text = "SÉLECTIONNÉE" if i == selected_mission else "Sélectionner"
		button.disabled = i == selected_mission
	for i: int in range(mission_card_panels.size()):
		var card: Panel = mission_card_panels[i]
		var style: StyleBoxFlat = card.get_theme_stylebox("panel") as StyleBoxFlat
		if style != null:
			var copy: StyleBoxFlat = style.duplicate() as StyleBoxFlat
			var card_mission: Dictionary = missions[i]
			var accent: Color = card_mission["accent"] as Color
			copy.border_color = Color(accent.r, accent.g, accent.b, 0.90 if i == selected_mission else 0.34)
			copy.border_width_left = 3 if i == selected_mission else 2
			copy.border_width_top = 3 if i == selected_mission else 2
			copy.border_width_right = 3 if i == selected_mission else 2
			copy.border_width_bottom = 3 if i == selected_mission else 2
			card.add_theme_stylebox_override("panel", copy)

func _update_options_panel() -> void:
	options_summary_label.text = "Secousse : %s\nJoystick : flottant\nEffets : %s" % [
		("ON" if bool(options_config["screen_shake"]) else "OFF"),
		("allégés" if bool(options_config["low_fx"]) else "normaux")
	]
	if options_shake_button != null:
		options_shake_button.text = "Secousse écran  •  %s" % [("ON" if bool(options_config["screen_shake"]) else "OFF")]
	if options_fx_button != null:
		options_fx_button.text = "Effets  •  %s" % [("ALLÉGÉS" if bool(options_config["low_fx"]) else "NORMAUX")]
	if options_save_label != null:
		options_save_label.text = "État : %s\nRuns : %d\nMeilleur score : %d" % [save_status_text, total_runs, best_score]

func _build_loading_panel() -> void:
	loading_panel = Control.new()
	loading_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(loading_panel)
	loading_panel.visible = false
	_add_screen_scrim(loading_panel, 0.56)

	var backdrop: ColorRect = ColorRect.new()
	backdrop.position = Vector2.ZERO
	backdrop.size = VIEW
	backdrop.color = Color(0.004, 0.010, 0.025, 0.88)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loading_panel.add_child(backdrop)

	var frame: Panel = _make_card_panel(Vector2(252, 88), Vector2(776, 544), Color(0.016, 0.028, 0.050, 0.78), Color(0.25, 0.58, 0.86, 0.22))
	loading_panel.add_child(frame)

	var emblem: TextureRect = _make_texture_preview(UI_LOGO_EMBLEM, Vector2(246, 36), Vector2(284, 284))
	emblem.modulate = Color(1.0, 1.0, 1.0, 0.96)
	frame.add_child(emblem)

	var logo: TextureRect = _make_texture_preview(UI_LOGO_MAIN, Vector2(118, 282), Vector2(540, 108))
	frame.add_child(logo)

	loading_status_label = _make_label("Synchronisation de la faille", Vector2(0, 400), Vector2(776, 28), 19, Color("e8f4ff"), HORIZONTAL_ALIGNMENT_CENTER)
	frame.add_child(loading_status_label)
	loading_hint_label = _make_label("Préparation de l'arène orbitale", Vector2(0, 430), Vector2(776, 22), 13, Color("79dfff"), HORIZONTAL_ALIGNMENT_CENTER)
	frame.add_child(loading_hint_label)

	loading_progress_bar = ProgressBar.new()
	loading_progress_bar.position = Vector2(138, 470)
	loading_progress_bar.size = Vector2(500, 16)
	loading_progress_bar.min_value = 0.0
	loading_progress_bar.max_value = 100.0
	loading_progress_bar.show_percentage = false
	_style_progress_bar(loading_progress_bar, Color("66cfff"))
	frame.add_child(loading_progress_bar)

	frame.add_child(_make_label("INITIALISATION DU PROTOCOLE", Vector2(0, 500), Vector2(776, 18), 10, Color("667f98"), HORIZONTAL_ALIGNMENT_CENTER))

func _build_menu_panel() -> void:
	menu_panel = Control.new()
	menu_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(menu_panel)
	_add_screen_scrim(menu_panel, 0.18)

	var left_fade: ColorRect = ColorRect.new()
	left_fade.position = Vector2.ZERO
	left_fade.size = VIEW
	left_fade.color = Color(0.004, 0.010, 0.025, 0.38)
	left_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_panel.add_child(left_fade)

	menu_left_card = _make_card_panel(Vector2(62, 54), Vector2(548, 612), Color(0.008, 0.014, 0.030, 0.78), Color(0.22, 0.58, 0.86, 0.18))
	menu_panel.add_child(menu_left_card)

	var menu_logo: TextureRect = _make_texture_preview(UI_LOGO_MAIN, Vector2(34, 26), Vector2(480, 154))
	menu_left_card.add_child(menu_logo)
	menu_title_label = _make_label("RIFT NOMAD", Vector2(30, 90), Vector2(488, 32), 1, Color(1, 1, 1, 0))
	menu_left_card.add_child(menu_title_label)
	menu_subtitle_label = _make_label("Traverse la faille. Nettoie l'arène. Reviens plus fort.", Vector2(30, 190), Vector2(488, 54), 20, Color("d3e2f2"), HORIZONTAL_ALIGNMENT_LEFT, true)
	menu_left_card.add_child(menu_subtitle_label)
	menu_left_card.add_child(_make_label("Action survival sci-fi • déplacement libre • combat automatique", Vector2(30, 248), Vector2(488, 22), 12, Color("7f95ab")))

	var mission_strip: Panel = _make_card_panel(Vector2(28, 292), Vector2(492, 72), Color(0.020, 0.030, 0.050, 0.94), Color(0.22, 0.58, 0.86, 0.24))
	menu_left_card.add_child(mission_strip)
	menu_status_label = _make_label("PRÊT À ENTRER DANS LA FAILLE", Vector2(18, 14), Vector2(300, 18), 12, Color("86f0c0"))
	mission_strip.add_child(menu_status_label)
	menu_arena_value = _make_label("FORGE ORBITALE  •  MODE SURVIE", Vector2(18, 38), Vector2(450, 18), 13, Color("a9b7ff"))
	mission_strip.add_child(menu_arena_value)

	menu_play_button = _make_big_button("JOUER", Vector2(28, 386), Vector2(492, 76), true)
	_style_home_primary_button(menu_play_button)
	menu_play_button.add_theme_font_size_override("font_size", 29)
	menu_play_button.pressed.connect(_start_or_continue_run)
	menu_left_card.add_child(menu_play_button)

	var skins_button: Button = _make_big_button("PERSONNALISER", Vector2(28, 480), Vector2(234, 56))
	skins_button.add_theme_font_size_override("font_size", 16)
	skins_button.pressed.connect(_show_customize_menu)
	menu_left_card.add_child(skins_button)
	var options_button: Button = _make_big_button("RÉGLAGES", Vector2(286, 480), Vector2(234, 56))
	options_button.add_theme_font_size_override("font_size", 16)
	options_button.pressed.connect(_show_options_menu)
	menu_left_card.add_child(options_button)

	menu_meta_label = _make_label("Progression locale • sauvegarde automatique", Vector2(30, 552), Vector2(488, 18), 11, Color("8ca0b7"))
	menu_left_card.add_child(menu_meta_label)

	var wave_tile: Panel = _make_metric_tile(Vector2(28, 570), Vector2(150, 72), "MEILLEURE VAGUE", Color("5bdcff"), 21)
	menu_best_wave_value = wave_tile.get_node("Value") as Label
	menu_left_card.add_child(wave_tile)
	var kills_tile: Panel = _make_metric_tile(Vector2(192, 570), Vector2(150, 72), "KO", Color("f1cf63"), 21)
	menu_kills_value = kills_tile.get_node("Value") as Label
	menu_left_card.add_child(kills_tile)
	var credits_tile: Panel = _make_metric_tile(Vector2(356, 570), Vector2(164, 72), "CRÉDITS", Color("86efc4"), 21)
	menu_credits_value = credits_tile.get_node("Value") as Label
	menu_left_card.add_child(credits_tile)

	menu_right_card = _make_card_panel(Vector2(650, 54), Vector2(568, 612), Color(0.006, 0.010, 0.020, 0.28), Color(0.18, 0.44, 0.68, 0.10))
	menu_panel.add_child(menu_right_card)
	var crest: TextureRect = _make_texture_preview(UI_LOGO_EMBLEM, Vector2(144, 18), Vector2(280, 280))
	crest.modulate = Color(1.0, 1.0, 1.0, 0.13)
	menu_right_card.add_child(crest)
	menu_hero_preview = _make_texture_preview(HERO_PREVIEW_IDLE, Vector2(0, 18), Vector2(568, 548))
	menu_right_card.add_child(menu_hero_preview)
	menu_right_card.add_child(_make_label("HÉROS PRINCIPAL", Vector2(26, 538), Vector2(170, 18), 11, Color("74dcff")))
	menu_right_card.add_child(_make_label("Nomad", Vector2(26, 556), Vector2(170, 28), 24, Color("eef7ff")))
	menu_right_card.add_child(_make_label("Éclaireur de faille • lame d'énergie", Vector2(26, 584), Vector2(300, 18), 12, Color("8ea2b8")))
	menu_right_card.add_child(_make_label("RIFT NOMAD", Vector2(350, 558), Vector2(190, 20), 13, Color("7ce3b5"), HORIZONTAL_ALIGNMENT_RIGHT))

	menu_panel.add_child(_make_chip_label("BUILD V47", Vector2(1086, 24), Vector2(132, 30), Color("67ddff")))

func _build_customize_panel() -> void:
	customize_panel = Control.new()
	customize_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(customize_panel)
	customize_panel.visible = false
	_add_screen_scrim(customize_panel, 0.34)

	customize_panel.add_child(_make_label("SKINS", Vector2(52, 28), Vector2(300, 44), 40, Color("f3d778")))
	customize_panel.add_child(_make_label("Choisis l'apparence du héros. Les prochaines skins seront ajoutées ici.", Vector2(54, 74), Vector2(760, 24), 16, Color("d7e2f2")))

	var left_card: Panel = _make_card_panel(Vector2(52, 116), Vector2(420, 556), Color(0.038, 0.052, 0.086, 0.95), Color(0.36, 0.66, 0.90, 0.40))
	customize_panel.add_child(left_card)
	left_card.add_child(_make_label("APERÇU", Vector2(24, 18), Vector2(140, 20), 12, Color("77dcff")))
	left_card.add_child(_make_texture_preview(HERO_PREVIEW_IDLE, Vector2(22, 48), Vector2(376, 244)))
	custom_name_label = _make_label("", Vector2(24, 306), Vector2(360, 30), 24, Color("eff5ff"))
	left_card.add_child(custom_name_label)
	custom_look_label = _make_label("", Vector2(24, 346), Vector2(360, 48), 16, Color("d5e1ef"), HORIZONTAL_ALIGNMENT_LEFT, true)
	left_card.add_child(custom_look_label)
	custom_weapon_label = _make_label("", Vector2(24, 404), Vector2(368, 64), 15, Color("c7d4e4"), HORIZONTAL_ALIGNMENT_LEFT, true)
	left_card.add_child(custom_weapon_label)
	custom_progress_label = _make_label("", Vector2(24, 482), Vector2(368, 46), 14, Color("7be3ff"), HORIZONTAL_ALIGNMENT_LEFT, true)
	left_card.add_child(custom_progress_label)

	var right_card: Panel = _make_card_panel(Vector2(496, 116), Vector2(732, 556), Color(0.034, 0.046, 0.076, 0.97), Color(0.40, 0.69, 0.96, 0.34))
	customize_panel.add_child(right_card)
	right_card.add_child(_make_label("SÉLECTION", Vector2(28, 18), Vector2(150, 20), 12, Color("77dcff")))
	right_card.add_child(_make_label("Slots de skins", Vector2(28, 38), Vector2(300, 38), 32, Color("eef5ff")))
	right_card.add_child(_make_label("Le premier slot est actif. Les autres seront disponibles après création de leurs assets.", Vector2(28, 82), Vector2(660, 40), 15, Color("d5dfeb"), HORIZONTAL_ALIGNMENT_LEFT, true))

	skin_slot_buttons = []
	for i: int in range(outfit_styles.size()):
		var col: int = i % 3
		var row: int = int(i / 3)
		var button: Button = _make_big_button("", Vector2(28 + col * 226, 140 + row * 116), Vector2(204, 96))
		button.add_theme_font_size_override("font_size", 15)
		button.pressed.connect(_select_skin_slot.bind(i))
		skin_slot_buttons.append(button)
		right_card.add_child(button)

	custom_legal_label = _make_label("", Vector2(28, 386), Vector2(676, 48), 14, Color("aebccf"), HORIZONTAL_ALIGNMENT_LEFT, true)
	right_card.add_child(custom_legal_label)
	var back_button: Button = _make_big_button("Retour", Vector2(28, 458), Vector2(210, 54))
	back_button.pressed.connect(_show_main_menu)
	right_card.add_child(back_button)
	var play_button: Button = _make_big_button("Combattre", Vector2(252, 458), Vector2(452, 54), true)
	play_button.pressed.connect(start_game)
	right_card.add_child(play_button)
func _build_mission_panel() -> void:
	mission_panel = Control.new()
	mission_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(mission_panel)
	mission_panel.visible = false
	_add_screen_scrim(mission_panel, 0.34)

	mission_panel.add_child(_make_label("ARÈNE", Vector2(52, 28), Vector2(300, 44), 40, Color("f3d778")))
	mission_panel.add_child(_make_label("Une seule salle est active pour cette build : la Forge orbitale.", Vector2(54, 74), Vector2(720, 24), 16, Color("d7e2f2")))

	var arena_card: Panel = _make_card_panel(Vector2(140, 126), Vector2(1000, 456), Color(0.038, 0.052, 0.086, 0.96), Color(0.36, 0.66, 0.90, 0.40))
	mission_panel.add_child(arena_card)
	var image: TextureRect = _make_texture_preview(BG_FORGE, Vector2(24, 24), Vector2(952, 236))
	image.modulate = Color(1.0, 1.0, 1.0, 0.80)
	arena_card.add_child(image)
	arena_card.add_child(_make_label("Forge orbitale", Vector2(28, 280), Vector2(360, 34), 30, Color("eef6ff")))
	arena_card.add_child(_make_label("Salle officielle : lisible, stable et optimisée pour le gameplay actuel.", Vector2(28, 322), Vector2(760, 28), 16, Color("dbe7f4"), HORIZONTAL_ALIGNMENT_LEFT, true))
	mission_title_label = _make_label("Forge orbitale", Vector2(28, 364), Vector2(260, 24), 16, Color("7be3ff"))
	arena_card.add_child(mission_title_label)
	mission_desc_label = _make_label("Résistance ×1.00  •  Dégâts ×1.00  •  Crédits ×1.00", Vector2(28, 392), Vector2(620, 22), 14, Color("c9d5e5"), HORIZONTAL_ALIGNMENT_LEFT)
	arena_card.add_child(mission_desc_label)
	mission_reward_label = _make_label("Configuration fixe", Vector2(760, 392), Vector2(190, 22), 14, Color("aebccf"), HORIZONTAL_ALIGNMENT_RIGHT)
	arena_card.add_child(mission_reward_label)

	var back_button: Button = _make_big_button("Retour", Vector2(844, 612), Vector2(170, 48))
	back_button.pressed.connect(_show_main_menu)
	mission_panel.add_child(back_button)
	var play_button: Button = _make_big_button("Combattre", Vector2(1030, 612), Vector2(196, 48), true)
	play_button.pressed.connect(start_game)
	mission_panel.add_child(play_button)
func _build_options_panel() -> void:
	options_panel = Control.new()
	options_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(options_panel)
	options_panel.visible = false
	_add_screen_scrim(options_panel, 0.36)

	options_panel.add_child(_make_label("OPTIONS", Vector2(52, 28), Vector2(300, 44), 40, Color("f3d778")))
	options_panel.add_child(_make_label("Confort, performances et sauvegarde locale", Vector2(54, 74), Vector2(620, 24), 16, Color("d7e2f2")))

	var summary_card: Panel = _make_card_panel(Vector2(52, 116), Vector2(400, 226), Color(0.038, 0.052, 0.086, 0.95), Color(0.36, 0.66, 0.90, 0.40))
	options_panel.add_child(summary_card)
	summary_card.add_child(_make_label("CONFIGURATION", Vector2(24, 18), Vector2(180, 20), 12, Color("77dcff")))
	options_summary_label = _make_label("", Vector2(24, 56), Vector2(352, 140), 18, Color("eef4ff"), HORIZONTAL_ALIGNMENT_LEFT, true)
	summary_card.add_child(options_summary_label)

	var controls_card: Panel = _make_card_panel(Vector2(476, 116), Vector2(752, 226), Color(0.034, 0.046, 0.076, 0.97), Color(0.40, 0.69, 0.96, 0.34))
	options_panel.add_child(controls_card)
	controls_card.add_child(_make_label("PLATEFORME", Vector2(28, 18), Vector2(180, 20), 12, Color("77dcff")))
	controls_card.add_child(_make_label("Réglages rapides", Vector2(28, 38), Vector2(300, 38), 30, Color("eef5ff")))
	controls_card.add_child(_make_label("Les réglages sont appliqués immédiatement et sauvegardés automatiquement.", Vector2(28, 82), Vector2(680, 28), 15, Color("d5dfeb"), HORIZONTAL_ALIGNMENT_LEFT, true))
	controls_card.add_child(_make_stat_tile(Vector2(28, 136), Vector2(214, 62), "PWA", "Installable", Color("53d9ff"), 13))
	controls_card.add_child(_make_stat_tile(Vector2(256, 136), Vector2(214, 62), "MOBILE", "Paysage", Color("f1cf63"), 13))
	controls_card.add_child(_make_stat_tile(Vector2(484, 136), Vector2(240, 62), "EFFETS", "Réglables", Color("9c8cff"), 13))

	options_shake_button = _make_big_button("Secousse écran", Vector2(52, 374), Vector2(368, 60))
	options_shake_button.pressed.connect(_toggle_screen_shake)
	options_panel.add_child(options_shake_button)
	var joystick_info: Panel = _make_stat_tile(Vector2(456, 374), Vector2(368, 60), "JOYSTICK FLOTTANT", "Touche et glisse n'importe où", Color("53d9ff"), 14)
	options_panel.add_child(joystick_info)
	options_fx_button = _make_big_button("Effets", Vector2(860, 374), Vector2(368, 60))
	options_fx_button.pressed.connect(_toggle_low_fx)
	options_panel.add_child(options_fx_button)

	var save_card: Panel = _make_card_panel(Vector2(52, 462), Vector2(824, 194), Color(0.038, 0.052, 0.086, 0.95), Color(0.36, 0.66, 0.90, 0.28))
	options_panel.add_child(save_card)
	save_card.add_child(_make_label("SAUVEGARDE", Vector2(20, 18), Vector2(180, 20), 12, Color("77dcff")))
	options_save_label = _make_label("", Vector2(20, 48), Vector2(410, 92), 16, Color("eef4ff"), HORIZONTAL_ALIGNMENT_LEFT, true)
	save_card.add_child(options_save_label)
	var manual_save_button: Button = _make_big_button("Sauvegarder", Vector2(448, 28), Vector2(166, 48), true)
	manual_save_button.pressed.connect(_manual_save_progress)
	save_card.add_child(manual_save_button)
	var manual_load_button: Button = _make_big_button("Recharger", Vector2(632, 28), Vector2(166, 48))
	manual_load_button.pressed.connect(_manual_reload_progress)
	save_card.add_child(manual_load_button)
	var reset_button: Button = _make_big_button("Réinitialiser", Vector2(448, 92), Vector2(350, 48))
	reset_button.pressed.connect(_reset_save_data)
	save_card.add_child(reset_button)

	var back_button: Button = _make_big_button("Retour", Vector2(900, 590), Vector2(154, 52))
	back_button.pressed.connect(_show_main_menu)
	options_panel.add_child(back_button)
	var play_button: Button = _make_big_button("Combattre", Vector2(1072, 590), Vector2(156, 52), true)
	play_button.pressed.connect(start_game)
	options_panel.add_child(play_button)
func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(hud)
	hud.visible = false

	var left_card: Panel = _make_card_panel(Vector2(16, 12), Vector2(432, 132), Color(0.032, 0.046, 0.076, 0.92), Color(0.32, 0.66, 0.94, 0.32))
	hud.add_child(left_card)
	left_card.add_child(_make_label("RIFT NOMAD", Vector2(18, 14), Vector2(180, 20), 14, Color("78deff")))
	left_card.add_child(_make_label("PROTOCOLE DE SURVIE", Vector2(18, 32), Vector2(220, 18), 11, Color("90a8c0")))
	left_card.add_child(_make_label("INTÉGRITÉ", Vector2(18, 62), Vector2(120, 16), 11, Color("8beaa9")))

	health_bar = ProgressBar.new()
	health_bar.position = Vector2(18, 80)
	health_bar.size = Vector2(396, 22)
	health_bar.show_percentage = false
	_style_progress_bar(health_bar, Color("57dd83"))
	health_value_label = Label.new()
	health_value_label.position = Vector2(0, -1)
	health_value_label.size = health_bar.size
	health_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	health_value_label.add_theme_font_size_override("font_size", 13)
	health_value_label.add_theme_color_override("font_color", Color("eef7ff"))
	health_bar.add_child(health_value_label)
	left_card.add_child(health_bar)

	left_card.add_child(_make_label("PROGRESSION", Vector2(18, 105), Vector2(120, 14), 11, Color("79dfff")))
	xp_bar = ProgressBar.new()
	xp_bar.position = Vector2(108, 106)
	xp_bar.size = Vector2(306, 14)
	xp_bar.show_percentage = false
	_style_progress_bar(xp_bar, Color("66cfff"))
	xp_value_label = Label.new()
	xp_value_label.position = Vector2(0, -2)
	xp_value_label.size = xp_bar.size
	xp_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	xp_value_label.add_theme_font_size_override("font_size", 11)
	xp_value_label.add_theme_color_override("font_color", Color("eef7ff"))
	xp_bar.add_child(xp_value_label)
	left_card.add_child(xp_bar)

	var center_card: Panel = _make_card_panel(Vector2(470, 14), Vector2(340, 46), Color(0.026, 0.038, 0.064, 0.90), Color(0.29, 0.54, 0.80, 0.26))
	hud.add_child(center_card)
	announcement_label = _make_label("", Vector2(10, 8), Vector2(320, 30), 22, Color("f1cf63"), HORIZONTAL_ALIGNMENT_CENTER)
	center_card.add_child(announcement_label)

	var stats_card: Panel = _make_card_panel(Vector2(470, 72), Vector2(340, 58), Color(0.030, 0.043, 0.070, 0.90), Color(0.26, 0.48, 0.70, 0.22))
	hud.add_child(stats_card)
	wave_label = _make_label("VAGUE 0", Vector2(18, 10), Vector2(144, 20), 20, Color("f3d778"))
	stats_card.add_child(wave_label)
	score_label = _make_label("SCORE 0  •  KO 0", Vector2(18, 32), Vector2(304, 18), 15, Color("dbe7f4"), HORIZONTAL_ALIGNMENT_LEFT)
	stats_card.add_child(score_label)

	var right_card: Panel = _make_card_panel(Vector2(828, 12), Vector2(436, 132), Color(0.032, 0.046, 0.076, 0.92), Color(0.34, 0.66, 0.90, 0.34))
	hud.add_child(right_card)
	right_card.add_child(_make_label("OPÉRATEUR", Vector2(16, 12), Vector2(100, 18), 12, Color("78deff")))
	hero_label = _make_label("", Vector2(16, 32), Vector2(236, 20), 17, Color("eef7ff"), HORIZONTAL_ALIGNMENT_LEFT)
	right_card.add_child(hero_label)
	level_label = _make_label("", Vector2(16, 58), Vector2(250, 18), 15, Color("dbe7f4"), HORIZONTAL_ALIGNMENT_LEFT)
	right_card.add_child(level_label)
	special_label = _make_label("", Vector2(16, 84), Vector2(250, 18), 14, Color("83e6ff"), HORIZONTAL_ALIGNMENT_LEFT)
	right_card.add_child(special_label)
	var menu_button: Button = _make_big_button("Menu", Vector2(306, 28), Vector2(104, 60))
	menu_button.add_theme_font_size_override("font_size", 20)
	menu_button.pressed.connect(_show_main_menu)
	right_card.add_child(menu_button)
	right_card.add_child(_make_label("sortie rapide", Vector2(286, 94), Vector2(136, 16), 10, Color("7288a0"), HORIZONTAL_ALIGNMENT_CENTER))

	var footer_card: Panel = _make_card_panel(Vector2(16, 674), Vector2(460, 30), Color(0.026, 0.038, 0.064, 0.84), Color(0.24, 0.46, 0.68, 0.18))
	hud.add_child(footer_card)
	footer_card.add_child(_make_label("Déplacement libre • combat automatique • spécial contextuel", Vector2(14, 6), Vector2(432, 18), 12, Color("8096ad"), HORIZONTAL_ALIGNMENT_CENTER))

func _build_level_panel() -> void:
	level_panel = Control.new()
	level_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(level_panel)
	level_panel.visible = false

	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.78)
	overlay.position = Vector2.ZERO
	overlay.size = VIEW
	level_panel.add_child(overlay)

	var frame: Panel = _make_card_panel(Vector2(48, 72), Vector2(1184, 576), Color(0.026, 0.037, 0.061, 0.97), Color(0.38, 0.70, 0.98, 0.34))
	level_panel.add_child(frame)
	var emblem: TextureRect = _make_texture_preview(UI_LOGO_EMBLEM, Vector2(876, 10), Vector2(264, 264))
	emblem.modulate = Color(1.0, 1.0, 1.0, 0.13)
	frame.add_child(emblem)
	frame.add_child(_make_label("AMPLIFICATION", Vector2(30, 24), Vector2(180, 20), 13, Color("7be3ff")))
	frame.add_child(_make_label("Choisis ton protocole", Vector2(30, 46), Vector2(420, 42), 40, Color("f1cf63")))
	frame.add_child(_make_label("Une seule amélioration est conservée. Le temps est figé pendant le choix.", Vector2(30, 92), Vector2(620, 24), 17, Color("d7e2f2")))
	frame.add_child(_make_chip_label("RIFT NOMAD", Vector2(904, 34), Vector2(136, 30), Color("67ddff")))
	frame.add_child(_make_chip_label("CHOIX x3", Vector2(1050, 34), Vector2(104, 30), Color("f1cf63")))
	frame.add_child(_make_chip_label("TEMPS FIGÉ", Vector2(912, 74), Vector2(242, 30), Color("9c8cff")))

	level_buttons = []
	for i: int in range(3):
		var x_pos: float = 34 + i * 372
		var card: Panel = _make_card_panel(Vector2(x_pos, 154), Vector2(340, 352), Color(0.036, 0.050, 0.082, 0.96), Color(0.34, 0.66, 0.90, 0.30))
		frame.add_child(card)
		card.add_child(_make_label("PROTOCOLE %d" % [i + 1], Vector2(18, 18), Vector2(120, 18), 12, Color("78deff")))
		card.add_child(_make_label("Amplification tactique", Vector2(18, 38), Vector2(220, 18), 14, Color("9cb2c8")))
		var button: Button = _make_big_button("", Vector2(16, 72), Vector2(308, 220), i == 0)
		button.add_theme_font_size_override("font_size", 22)
		button.pressed.connect(_on_upgrade_choice.bind(i))
		level_buttons.append(button)
		card.add_child(button)
		card.add_child(_make_label("Application immédiate pour le reste de la run", Vector2(18, 308), Vector2(304, 30), 13, Color("91a6bc"), HORIZONTAL_ALIGNMENT_CENTER, true))

	var footer: Panel = _make_card_panel(Vector2(32, 522), Vector2(1120, 34), Color(0.022, 0.032, 0.054, 0.88), Color(0.25, 0.42, 0.60, 0.16))
	frame.add_child(footer)
	footer.add_child(_make_label("Astuce : priorise dégâts et survie au début, puis vitesse d'attaque et portée au milieu de run.", Vector2(18, 7), Vector2(1084, 18), 13, Color("8398ad"), HORIZONTAL_ALIGNMENT_CENTER))

func _build_game_over_panel() -> void:
	game_over_panel = Control.new()
	game_over_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(game_over_panel)
	game_over_panel.visible = false

	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.82)
	overlay.position = Vector2.ZERO
	overlay.size = VIEW
	game_over_panel.add_child(overlay)

	var frame: Panel = _make_card_panel(Vector2(220, 90), Vector2(840, 520), Color(0.024, 0.036, 0.060, 0.98), Color(0.40, 0.69, 0.96, 0.34))
	game_over_panel.add_child(frame)
	var logo: TextureRect = _make_texture_preview(UI_LOGO_MAIN, Vector2(134, 18), Vector2(572, 116))
	frame.add_child(logo)
	frame.add_child(_make_chip_label("FIN DE RUN", Vector2(342, 120), Vector2(156, 30), Color("7be3ff")))
	game_over_title = _make_label("Défaite", Vector2(0, 160), Vector2(840, 44), 42, Color("f1cf63"), HORIZONTAL_ALIGNMENT_CENTER)
	frame.add_child(game_over_title)
	frame.add_child(_make_label("Les crédits et la progression ont été sécurisés.", Vector2(0, 208), Vector2(840, 24), 18, Color("dbe7f4"), HORIZONTAL_ALIGNMENT_CENTER))
	var stats_card: Panel = _make_card_panel(Vector2(72, 252), Vector2(696, 126), Color(0.036, 0.050, 0.082, 0.96), Color(0.34, 0.66, 0.90, 0.24))
	frame.add_child(stats_card)
	stats_card.add_child(_make_label("RAPPORT D'EXTRACTION", Vector2(20, 14), Vector2(240, 18), 12, Color("78deff")))
	game_over_stats = _make_label("", Vector2(20, 38), Vector2(656, 74), 22, Color("eef5ff"), HORIZONTAL_ALIGNMENT_CENTER, true)
	stats_card.add_child(game_over_stats)
	frame.add_child(_make_label("Tu peux repartir immédiatement ou revenir au hub pour ajuster ton équipement.", Vector2(112, 394), Vector2(616, 24), 15, Color("aebccf"), HORIZONTAL_ALIGNMENT_CENTER, true))

	var restart_button: Button = _make_big_button("REJOUER", Vector2(134, 440), Vector2(252, 56), true)
	restart_button.add_theme_font_size_override("font_size", 22)
	restart_button.pressed.connect(start_game)
	frame.add_child(restart_button)
	var menu_button: Button = _make_big_button("MENU", Vector2(454, 440), Vector2(252, 56))
	menu_button.add_theme_font_size_override("font_size", 22)
	menu_button.pressed.connect(_show_main_menu)
	frame.add_child(menu_button)

func _add_screen_scrim(panel: Control, alpha: float) -> void:
	var scrim: ColorRect = ColorRect.new()
	scrim.color = Color(0.012, 0.020, 0.038, alpha)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(scrim)

func _make_card_panel(position_value: Vector2, size_value: Vector2, bg_color: Color, border_color: Color) -> Panel:
	var panel: Panel = Panel.new()
	panel.position = position_value
	panel.size = size_value
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(bg_color.r * 0.98, bg_color.g * 0.98, minf(1.0, bg_color.b * 1.02), bg_color.a)
	style.border_color = border_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 22
	style.corner_radius_top_right = 22
	style.corner_radius_bottom_left = 22
	style.corner_radius_bottom_right = 22
	style.anti_aliasing = true
	style.anti_aliasing_size = 1.2
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.34)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 6)
	style.content_margin_left = 4
	style.content_margin_top = 4
	style.content_margin_right = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _make_label(text_value: String, position_value: Vector2, size_value: Vector2, font_size: int, font_color: Color, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, wrap_text: bool = false) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	label.position = position_value
	label.size = size_value
	label.horizontal_alignment = alignment
	if wrap_text:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.04, 0.68))
	label.add_theme_constant_override("outline_size", 2)
	return label

func _make_chip_label(text_value: String, position_value: Vector2, size_value: Vector2, accent: Color) -> Panel:
	var chip: Panel = _make_card_panel(position_value, size_value, Color(accent.r * 0.10, accent.g * 0.10, accent.b * 0.10, 0.64), Color(accent.r, accent.g, accent.b, 0.56))
	chip.add_child(_make_label(text_value, Vector2(0, 4), size_value, 13, Color(lerp(accent.r, 1.0, 0.25), lerp(accent.g, 1.0, 0.25), lerp(accent.b, 1.0, 0.25), 1.0), HORIZONTAL_ALIGNMENT_CENTER))
	return chip

func _make_texture_preview(texture: Texture2D, position_value: Vector2, size_value: Vector2) -> TextureRect:
	var preview: TextureRect = TextureRect.new()
	preview.texture = texture
	preview.position = position_value
	preview.size = size_value
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return preview

func _make_stat_tile(position_value: Vector2, size_value: Vector2, title_text: String, body_text: String, accent: Color, body_font_size: int = 17) -> Panel:
	var tile: Panel = _make_card_panel(position_value, size_value, Color(0.030, 0.045, 0.073, 0.92), Color(accent.r, accent.g, accent.b, 0.34))
	tile.add_child(_make_label(title_text, Vector2(16, 12), Vector2(size_value.x - 24.0, 18), 13, accent))
	tile.add_child(_make_label(body_text, Vector2(16, 34), Vector2(size_value.x - 24.0, size_value.y - 40.0), body_font_size, Color("eef4ff"), HORIZONTAL_ALIGNMENT_LEFT, true))
	return tile

func _make_big_button(text_value: String, position_value: Vector2, size_value: Vector2, primary: bool = false) -> Button:
	var button: Button = Button.new()
	button.text = text_value
	button.position = position_value
	button.size = size_value
	button.add_theme_font_size_override("font_size", 21 if size_value.y < 64.0 else 24)
	button.add_theme_color_override("font_color", Color("f4f8ff"))
	button.add_theme_color_override("font_hover_color", Color("ffffff"))
	button.add_theme_color_override("font_pressed_color", Color("ffffff"))
	button.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.04, 0.72))
	button.add_theme_constant_override("outline_size", 2)
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color(0.050, 0.075, 0.115, 0.97) if not primary else Color(0.07, 0.17, 0.22, 0.99)
	normal.border_color = Color(0.40, 0.62, 0.82, 0.88) if not primary else Color(0.54, 0.92, 1.0, 1.0)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.corner_radius_top_left = 16
	normal.corner_radius_top_right = 16
	normal.corner_radius_bottom_left = 16
	normal.corner_radius_bottom_right = 16
	normal.anti_aliasing = true
	normal.anti_aliasing_size = 1.2
	normal.shadow_color = Color(0.0, 0.0, 0.0, 0.28) if not primary else Color(0.18, 0.70, 0.92, 0.22)
	normal.shadow_size = 12 if not primary else 16
	normal.shadow_offset = Vector2(0, 5)
	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.085, 0.14, 0.22, 0.99) if not primary else Color(0.08, 0.25, 0.31, 1.0)
	hover.border_color = Color("7fe6ff") if not primary else Color("9eefff")
	hover.shadow_size = 16 if not primary else 20
	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.038, 0.062, 0.098, 0.99) if not primary else Color(0.05, 0.14, 0.19, 0.99)
	pressed.border_color = Color("92d6ff") if not primary else Color("6fd9ff")
	pressed.shadow_size = 8 if not primary else 12
	var disabled: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.05, 0.06, 0.08, 0.80)
	disabled.border_color = Color(0.24, 0.30, 0.40, 0.55)
	disabled.shadow_size = 4
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.mouse_entered.connect(_on_ui_button_entered.bind(button))
	button.mouse_exited.connect(_on_ui_button_exited.bind(button))
	button.button_down.connect(_on_ui_button_down.bind(button))
	button.button_up.connect(_on_ui_button_up.bind(button))
	return button

func _style_home_primary_button(button: Button) -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color(0.06, 0.22, 0.28, 0.99)
	normal.border_color = Color(0.58, 0.93, 1.0, 1.0)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.corner_radius_top_left = 16
	normal.corner_radius_top_right = 16
	normal.corner_radius_bottom_left = 16
	normal.corner_radius_bottom_right = 16
	normal.anti_aliasing = true
	normal.anti_aliasing_size = 1.2
	normal.shadow_color = Color(0.18, 0.78, 0.96, 0.26)
	normal.shadow_size = 20
	normal.shadow_offset = Vector2(0, 6)
	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.08, 0.30, 0.38, 1.0)
	hover.border_color = Color(0.82, 0.98, 1.0, 1.0)
	hover.shadow_size = 24
	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.05, 0.16, 0.22, 1.0)
	pressed.border_color = Color(0.48, 0.88, 1.0, 1.0)
	pressed.shadow_size = 14
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color("f5fbff"))
	button.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.04, 0.70))
	button.add_theme_constant_override("outline_size", 2)

func _make_metric_tile(position_value: Vector2, size_value: Vector2, title_text: String, accent: Color, value_font_size: int = 30) -> Panel:
	var tile: Panel = _make_card_panel(position_value, size_value, Color(0.027, 0.041, 0.068, 0.96), Color(accent.r, accent.g, accent.b, 0.32))
	tile.add_child(_make_label(title_text, Vector2(14, 10), Vector2(size_value.x - 28.0, 18), 11, accent))
	var value: Label = _make_label("0", Vector2(14, 31), Vector2(size_value.x - 28.0, 42), value_font_size, Color("f4f8ff"))
	value.name = "Value"
	value.clip_text = true
	tile.add_child(value)
	return tile

func _update_menu_meta() -> void:
	if menu_meta_label == null:
		return
	menu_meta_label.text = "Run sauvegardée • reprise immédiate disponible" if saved_run_available else "Progression locale • sauvegarde automatique"
	if menu_best_wave_value != null:
		menu_best_wave_value.text = str(best_wave)
	if menu_kills_value != null:
		menu_kills_value.text = str(lifetime_kills)
	if menu_credits_value != null:
		menu_credits_value.text = str(lifetime_credits)
	if menu_arena_value != null:
		menu_arena_value.text = "FORGE ORBITALE  •  MODE SURVIE"
	if menu_status_label != null:
		menu_status_label.text = "RUN EN ATTENTE" if saved_run_available else "PRÊT AU DÉPLOIEMENT"
	if menu_play_button != null:
		menu_play_button.text = "CONTINUER" if saved_run_available else "JOUER"

func _update_menu_preview() -> void:
	if menu_hero_preview == null:
		return
	menu_preview_frame = 0
	menu_preview_timer = 0.0
	menu_hero_preview.texture = HERO_PREVIEW_IDLE
	menu_hero_preview.position = Vector2(0, 18)
	menu_hero_preview.scale = Vector2.ONE

func _update_loading_motion(delta: float) -> void:
	if state != GameState.LOADING or loading_panel == null or not loading_panel.visible:
		return
	loading_elapsed += delta
	if loading_progress_bar != null:
		loading_progress_bar.value = minf(100.0, loading_elapsed / 1.45 * 100.0)
	if loading_status_label != null:
		var dots: int = int(floor(loading_elapsed * 3.0)) % 4
		var dot_text: String = ""
		for _i: int in range(dots):
			dot_text += "."
		loading_status_label.text = "Synchronisation de la faille" + dot_text
	if loading_hint_label != null:
		loading_hint_label.modulate = Color(0.78 + sin(loading_elapsed * 3.2) * 0.08, 0.90 + sin(loading_elapsed * 3.2) * 0.04, 1.0, 1.0)

func _update_menu_motion(delta: float) -> void:
	if state != GameState.MENU or menu_panel == null or not menu_panel.visible:
		return
	menu_anim_time += delta
	if menu_hero_preview != null:
		menu_hero_preview.texture = HERO_PREVIEW_IDLE
		menu_hero_preview.position = Vector2(0, 18 + sin(menu_anim_time * 1.20) * 2.2)
		var hero_scale: float = 1.0 + sin(menu_anim_time * 1.20) * 0.0025
		menu_hero_preview.scale = Vector2(hero_scale, hero_scale)
	if menu_title_label != null:
		var title_alpha: float = menu_title_label.modulate.a
		var pulse: float = 0.985 + sin(menu_anim_time * 1.35) * 0.015
		menu_title_label.modulate = Color(pulse, pulse, 1.0, title_alpha)
	if menu_play_button != null:
		var play_alpha: float = 0.975 + sin(menu_anim_time * 2.0) * 0.020
		menu_play_button.modulate = Color(1.0, 1.0, 1.0, play_alpha)

func _animate_menu_entry() -> void:
	if menu_left_card == null or menu_right_card == null:
		return
	menu_anim_time = 0.0
	menu_preview_timer = 0.0
	menu_left_card.modulate.a = 0.0
	menu_right_card.modulate.a = 0.0
	menu_left_card.position = Vector2(18, 54)
	menu_right_card.position = Vector2(700, 54)
	if menu_title_label != null:
		menu_title_label.modulate.a = 0.0
		menu_title_label.position.y = 102.0
	if menu_subtitle_label != null:
		menu_subtitle_label.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(menu_left_card, "position", Vector2(62, 54), 0.34)
	tween.tween_property(menu_left_card, "modulate:a", 1.0, 0.28)
	tween.tween_property(menu_right_card, "position", Vector2(650, 54), 0.42).set_delay(0.04)
	tween.tween_property(menu_right_card, "modulate:a", 1.0, 0.34).set_delay(0.04)
	if menu_title_label != null:
		tween.tween_property(menu_title_label, "position:y", 90.0, 0.32)
		tween.tween_property(menu_title_label, "modulate:a", 1.0, 0.26)
	if menu_subtitle_label != null:
		tween.tween_property(menu_subtitle_label, "modulate:a", 1.0, 0.38).set_delay(0.08)

func _animate_panel_reveal(panel: Control) -> void:
	if panel == null:
		return
	panel.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.22)

func _animate_button_scale(button: Button, target_scale: Vector2, duration: float) -> void:
	if button == null:
		return
	button.pivot_offset = button.size * 0.5
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target_scale, duration)

func _on_ui_button_entered(button: Button) -> void:
	_animate_button_scale(button, Vector2(1.018, 1.018), 0.10)

func _on_ui_button_exited(button: Button) -> void:
	_animate_button_scale(button, Vector2.ONE, 0.12)

func _on_ui_button_down(button: Button) -> void:
	_animate_button_scale(button, Vector2(0.985, 0.985), 0.05)

func _on_ui_button_up(button: Button) -> void:
	_animate_button_scale(button, Vector2.ONE, 0.08)

func _style_progress_bar(bar: ProgressBar, fill_color: Color) -> void:
	var background: StyleBoxFlat = StyleBoxFlat.new()
	background.bg_color = Color(0.03, 0.04, 0.06, 0.88)
	background.border_color = Color(0.35, 0.45, 0.58, 0.50)
	background.border_width_left = 1
	background.border_width_top = 1
	background.border_width_right = 1
	background.border_width_bottom = 1
	background.corner_radius_top_left = 6
	background.corner_radius_top_right = 6
	background.corner_radius_bottom_left = 6
	background.corner_radius_bottom_right = 6
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.corner_radius_top_left = 5
	fill.corner_radius_top_right = 5
	fill.corner_radius_bottom_left = 5
	fill.corner_radius_bottom_right = 5
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)

func _select_skin_slot(index: int) -> void:
	if index < 0 or index >= outfit_styles.size():
		return
	if int(outfit_styles[index]["unlock"]) >= 999999999:
		_announcement_text("Cette skin sera ajoutée plus tard", Color("ffcf72"))
		return
	player_config["outfit_idx"] = index
	_save_progress()
	_update_customize_panel()
	_announcement_text("Skin sélectionnée : %s" % [String(outfit_styles[index]["name"])], Color("7be3ff"))
func _update_skin_slots() -> void:
	for i: int in range(skin_slot_buttons.size()):
		var button: Button = skin_slot_buttons[i]
		var skin_data: Dictionary = outfit_styles[i]
		var available: bool = int(skin_data["unlock"]) < 999999999
		var selected: bool = available and i == int(player_config["outfit_idx"])
		var state_text: String = "ACTIF" if selected else ("DISPONIBLE" if available else "À VENIR")
		button.text = "SLOT %02d\n%s\n%s" % [i + 1, String(skin_data["name"]), state_text]
		button.disabled = not available
func _apply_loaded_values() -> void:
	_validate_saved_cosmetics()
	_update_background_assets()
	if menu_panel != null:
		_update_menu_meta()
		_update_menu_preview()
	if mission_panel != null:
		_update_mission_panel()
	if customize_panel != null:
		_update_customize_panel()
	if options_panel != null:
		_update_options_panel()
	queue_redraw()

func _manual_save_progress() -> void:
	_save_progress()
	_update_options_panel()
	_announcement_text("Sauvegarde locale effectuée", Color("7be3a2"))

func _manual_reload_progress() -> void:
	_load_save()
	_apply_loaded_values()
	_announcement_text("Sauvegarde rechargée", Color("7be3ff"))

func _reset_save_data() -> void:
	lifetime_credits = 0
	best_wave = 0
	lifetime_kills = 0
	total_runs = 0
	best_score = 0
	selected_mission = 0
	player_config["mask_on"] = true
	player_config["mask_style"] = 0
	player_config["outfit_idx"] = 0
	player_config["weapon_type"] = "blade"
	player_config["blade_skin_idx"] = 0
	player_config["blaster_skin_idx"] = 0
	options_config["screen_shake"] = true
	options_config["low_fx"] = false
	save_status_text = "Réinitialisée"
	_save_progress()
	_apply_loaded_values()
	_announcement_text("Sauvegarde réinitialisée", Color("ff9b72"))

func _toggle_mask() -> void:
	player_config["mask_on"] = not bool(player_config["mask_on"])
	_save_progress()
	_update_customize_panel()

func _next_mask_style() -> void:
	player_config["mask_style"] = _next_unlocked_index(mask_styles, int(player_config["mask_style"]))
	_save_progress()
	_update_customize_panel()

func _prev_outfit() -> void:
	player_config["outfit_idx"] = _prev_unlocked_index(outfit_styles, int(player_config["outfit_idx"]))
	_save_progress()
	_update_customize_panel()

func _next_outfit() -> void:
	player_config["outfit_idx"] = _next_unlocked_index(outfit_styles, int(player_config["outfit_idx"]))
	_save_progress()
	_update_customize_panel()

func _toggle_weapon() -> void:
	player_config["weapon_type"] = "blaster" if String(player_config["weapon_type"]) == "blade" else "blade"
	_save_progress()
	_update_customize_panel()

func _next_weapon_skin() -> void:
	if String(player_config["weapon_type"]) == "blade":
		player_config["blade_skin_idx"] = _next_unlocked_index(blade_skins, int(player_config["blade_skin_idx"]))
	else:
		player_config["blaster_skin_idx"] = _next_unlocked_index(blaster_skins, int(player_config["blaster_skin_idx"]))
	_save_progress()
	_update_customize_panel()

func _next_unlocked_index(collection: Array[Dictionary], current_index: int) -> int:
	if collection.is_empty():
		return 0
	for offset: int in range(1, collection.size() + 1):
		var candidate: int = (current_index + offset) % collection.size()
		if int(collection[candidate]["unlock"]) <= lifetime_credits:
			return candidate
	return current_index

func _prev_unlocked_index(collection: Array[Dictionary], current_index: int) -> int:
	if collection.is_empty():
		return 0
	for offset: int in range(1, collection.size() + 1):
		var candidate: int = posmod(current_index - offset, collection.size())
		if int(collection[candidate]["unlock"]) <= lifetime_credits:
			return candidate
	return current_index

func _select_mission(index: int) -> void:
	selected_mission = clampi(index, 0, missions.size() - 1)
	_save_progress()
	_update_mission_panel()
	_update_background_assets()
	queue_redraw()

func _toggle_screen_shake() -> void:
	options_config["screen_shake"] = not bool(options_config["screen_shake"])
	_save_progress()
	_update_options_panel()

func _toggle_low_fx() -> void:
	options_config["low_fx"] = not bool(options_config["low_fx"])
	_generate_stars()
	_save_progress()
	_update_options_panel()

func _load_save() -> void:
	var save: ConfigFile = ConfigFile.new()
	var result: Error = save.load("user://galactic_auto_arena_save.cfg")
	if result != OK:
		save_status_text = "Nouveau profil"
		return
	lifetime_credits = int(save.get_value("meta", "credits", 0))
	best_wave = int(save.get_value("meta", "best_wave", 0))
	lifetime_kills = int(save.get_value("meta", "kills", 0))
	total_runs = int(save.get_value("meta", "runs", 0))
	best_score = int(save.get_value("meta", "best_score", 0))
	save_status_text = String(save.get_value("meta", "save_status", "Profil chargé"))
	selected_mission = 0
	player_config["mask_on"] = bool(save.get_value("player", "mask_on", true))
	player_config["mask_style"] = int(save.get_value("player", "mask_style", 0))
	player_config["outfit_idx"] = int(save.get_value("player", "outfit_idx", 0))
	player_config["weapon_type"] = String(save.get_value("player", "weapon_type", "blade"))
	player_config["blade_skin_idx"] = int(save.get_value("player", "blade_skin_idx", 0))
	player_config["blaster_skin_idx"] = int(save.get_value("player", "blaster_skin_idx", 0))
	options_config["screen_shake"] = bool(save.get_value("options", "screen_shake", true))
	options_config["low_fx"] = bool(save.get_value("options", "low_fx", false))
	_validate_saved_cosmetics()
	saved_run_available = bool(save.get_value("run", "active", false))
	saved_run_data.clear()
	if saved_run_available:
		saved_run_data = {
			"balance_version": int(save.get_value("run", "balance_version", 0)),
			"wave": int(save.get_value("run", "wave", 1)),
			"score": int(save.get_value("run", "score", 0)),
			"kills": int(save.get_value("run", "kills", 0)),
			"run_credits": int(save.get_value("run", "credits", 0)),
			"player_level": int(save.get_value("run", "player_level", 1)),
			"player_xp": int(save.get_value("run", "player_xp", 0)),
			"xp_to_next": int(save.get_value("run", "xp_to_next", 80)),
			"total_upgrades": int(save.get_value("run", "total_upgrades", 0)),
			"special_timer": float(save.get_value("run", "special_timer", 0.0)),
			"max_health": float(save.get_value("run", "max_health", 135.0)),
			"health": float(save.get_value("run", "health", 135.0)),
			"speed": float(save.get_value("run", "speed", PLAYER_BASE_SPEED)),
			"damage": float(save.get_value("run", "damage", 26.0)),
			"attack_range": float(save.get_value("run", "attack_range", 92.0)),
			"attack_cooldown": float(save.get_value("run", "attack_cooldown", 0.58)),
			"critical_chance": float(save.get_value("run", "critical_chance", 0.08)),
			"lifesteal": float(save.get_value("run", "lifesteal", 0.0)),
			"regeneration": float(save.get_value("run", "regeneration", 0.0)),
			"armor": float(save.get_value("run", "armor", 0.0))
		}

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_progress()

func _validate_saved_cosmetics() -> void:
	player_config["mask_on"] = true
	player_config["mask_style"] = 0
	player_config["outfit_idx"] = _validated_index(outfit_styles, int(player_config["outfit_idx"]))
	player_config["weapon_type"] = "blade"
	player_config["blade_skin_idx"] = 0
	player_config["blaster_skin_idx"] = 0

func _validated_index(collection: Array[Dictionary], index: int) -> int:
	if index < 0 or index >= collection.size():
		return 0
	if int(collection[index]["unlock"]) > lifetime_credits:
		return 0
	return index

func _save_progress() -> void:
	var save: ConfigFile = ConfigFile.new()
	save_status_text = "OK"
	save.set_value("meta", "credits", lifetime_credits)
	save.set_value("meta", "best_wave", best_wave)
	save.set_value("meta", "kills", lifetime_kills)
	save.set_value("meta", "runs", total_runs)
	save.set_value("meta", "best_score", best_score)
	save.set_value("meta", "save_status", save_status_text)
	save.set_value("meta", "mission", 0)
	save.set_value("player", "mask_on", bool(player_config["mask_on"]))
	save.set_value("player", "mask_style", int(player_config["mask_style"]))
	save.set_value("player", "outfit_idx", int(player_config["outfit_idx"]))
	save.set_value("player", "weapon_type", String(player_config["weapon_type"]))
	save.set_value("player", "blade_skin_idx", int(player_config["blade_skin_idx"]))
	save.set_value("player", "blaster_skin_idx", int(player_config["blaster_skin_idx"]))
	save.set_value("options", "screen_shake", bool(options_config["screen_shake"]))
	save.set_value("options", "low_fx", bool(options_config["low_fx"]))
	var active_run: bool = (state == GameState.PLAYING or state == GameState.LEVEL_UP) and not run_banked and is_instance_valid(player) and not player.dead
	save.set_value("run", "active", active_run)
	if active_run:
		save.set_value("run", "balance_version", BALANCE_VERSION)
		save.set_value("run", "wave", maxi(wave, 1))
		save.set_value("run", "score", score)
		save.set_value("run", "kills", kills)
		save.set_value("run", "credits", run_credits)
		save.set_value("run", "player_level", player_level)
		save.set_value("run", "player_xp", player_xp)
		save.set_value("run", "xp_to_next", xp_to_next)
		save.set_value("run", "total_upgrades", total_upgrades)
		save.set_value("run", "special_timer", special_timer)
		save.set_value("run", "max_health", player.max_health)
		save.set_value("run", "health", player.health)
		save.set_value("run", "speed", player.speed)
		save.set_value("run", "damage", player.damage)
		save.set_value("run", "attack_range", player.attack_range)
		save.set_value("run", "attack_cooldown", player.attack_cooldown_base)
		save.set_value("run", "critical_chance", player.critical_chance)
		save.set_value("run", "lifesteal", player.lifesteal)
		save.set_value("run", "regeneration", player.regeneration)
		save.set_value("run", "armor", player.armor)
	var result: Error = save.save("user://galactic_auto_arena_save.cfg")
	if result != OK:
		save_status_text = "Erreur d'écriture"
		push_warning("Impossible de sauvegarder la progression locale.")

func _update_background_assets() -> void:
	if background_base_sprite == null or background_overlay_sprite == null:
		return
	_generate_ambient_particles()
	background_base_sprite.texture = BG_FORGE
	background_overlay_sprite.texture = OVERLAY_FORGE
	var base_scale: float = maxf(VIEW.x / float(background_base_sprite.texture.get_width()), VIEW.y / float(background_base_sprite.texture.get_height()))
	background_base_sprite.scale = Vector2.ONE * base_scale * 1.018
	background_overlay_sprite.scale = Vector2.ONE * base_scale * 1.028
	background_base_sprite.position = VIEW * 0.5
	background_overlay_sprite.position = VIEW * 0.5

func _update_dynamic_background() -> void:
	if background_base_sprite == null or background_overlay_sprite == null:
		return
	var drift_x: float = sin(pulse_time * 0.16) * 5.0
	var drift_y: float = cos(pulse_time * 0.13) * 2.5
	background_base_sprite.position = VIEW * 0.5 + Vector2(drift_x, drift_y)
	background_overlay_sprite.position = VIEW * 0.5 + Vector2(-drift_x * 1.45, -drift_y * 1.8)
	var overlay_alpha: float = 0.54 + sin(pulse_time * 0.72) * 0.05
	if bool(options_config["low_fx"]):
		overlay_alpha = 0.32
	background_overlay_sprite.modulate = Color(1.0, 1.0, 1.0, overlay_alpha)
	var base_alpha: float = 1.0 if state == GameState.PLAYING or state == GameState.LEVEL_UP else 0.78
	background_base_sprite.modulate = Color(base_alpha, base_alpha, base_alpha, 1.0)

func _draw() -> void:
	if selected_mission != 0:
		_draw_room_stage()
	_draw_ambient_particles()
	_draw_impact_effects()
	if special_fx_time > 0.0 and is_instance_valid(player):
		var ratio: float = special_fx_time / (0.34 if String(player_config["weapon_type"]) == "blade" else 0.26)
		var fx_pos: Vector2 = player.global_position + world_root.position
		var radius: float = special_fx_radius * (1.0 - ratio * 0.35)
		draw_circle(fx_pos, radius, Color(special_fx_color.r, special_fx_color.g, special_fx_color.b, 0.04 + ratio * 0.08), false, 4.0 + ratio * 3.0, true)
		draw_circle(fx_pos, radius * 0.72, Color(1.0, 1.0, 1.0, 0.03 + ratio * 0.07), false, 2.0, true)

	if state == GameState.PLAYING:
		_draw_joystick()

func _draw_sky_gradient(background: Color, accent: Color, secondary: Color) -> void:
	for i: int in range(8):
		var ratio: float = float(i) / 8.0
		var band_color: Color = background.lerp(accent.darkened(0.65), 0.10 + ratio * 0.06)
		band_color.a = 0.10 - ratio * 0.008
		draw_rect(Rect2(0.0, ratio * VIEW.y * 0.75, VIEW.x, VIEW.y / 10.0 + 2.0), band_color, true)
	draw_rect(Rect2(0.0, VIEW.y * 0.74, VIEW.x, VIEW.y * 0.26), Color(secondary.r, secondary.g, secondary.b, 0.03), true)

func _draw_celestial_body(accent: Color, secondary: Color) -> void:
	var planet_pos: Vector2 = Vector2(1110.0, 122.0)
	var planet_radius: float = 78.0
	if selected_mission == 1:
		planet_pos = Vector2(1060.0, 130.0)
		planet_radius = 92.0
	elif selected_mission == 2:
		planet_pos = Vector2(1120.0, 118.0)
		planet_radius = 72.0
	draw_circle(planet_pos, planet_radius + 20.0, Color(accent.r, accent.g, accent.b, 0.05))
	draw_circle(planet_pos, planet_radius, Color(secondary.r, secondary.g, secondary.b, 0.12))
	draw_circle(planet_pos + Vector2(-16, -14), planet_radius * 0.82, Color(1.0, 1.0, 1.0, 0.04))
	if selected_mission == 2:
		draw_arc(planet_pos, planet_radius + 18.0, -0.55, 2.85, 40, Color(accent.r, accent.g, accent.b, 0.18), 3.0, true)
	else:
		draw_arc(planet_pos, planet_radius + 10.0, -0.25, 3.35, 32, Color(1.0, 1.0, 1.0, 0.09), 2.0, true)

func _draw_ship_silhouettes(accent: Color) -> void:
	for i: int in range(3):
		var base_x: float = 190.0 + float(i) * 290.0 + sin(pulse_time * 0.4 + float(i)) * 12.0
		var base_y: float = 124.0 + float(i % 2) * 42.0
		var ship: PackedVector2Array = PackedVector2Array([
			Vector2(base_x - 26.0, base_y + 3.0),
			Vector2(base_x + 12.0, base_y - 2.0),
			Vector2(base_x + 34.0, base_y + 1.0),
			Vector2(base_x + 8.0, base_y + 9.0)
		])
		draw_colored_polygon(ship, Color(1.0, 1.0, 1.0, 0.035))
		draw_line(Vector2(base_x - 30.0, base_y + 3.0), Vector2(base_x - 48.0, base_y + 5.0), Color(accent.r, accent.g, accent.b, 0.12), 1.0, true)

func _draw_hangar_architecture(accent: Color, secondary: Color) -> void:
	var wall_color: Color = Color(1.0, 1.0, 1.0, 0.045)
	for i: int in range(10):
		var px: float = ARENA_RECT.position.x + float(i) * 118.0
		draw_rect(Rect2(px, ARENA_RECT.position.y - 28.0, 58.0, 18.0), wall_color, true)
		draw_rect(Rect2(px + 6.0, ARENA_RECT.end.y + 12.0, 46.0, 16.0), Color(secondary.r, secondary.g, secondary.b, 0.07), true)
	for i: int in range(4):
		var y: float = ARENA_RECT.position.y + 44.0 + float(i) * 128.0
		draw_rect(Rect2(ARENA_RECT.position.x - 18.0, y, 10.0, 46.0), Color(accent.r, accent.g, accent.b, 0.10), true)
		draw_rect(Rect2(ARENA_RECT.end.x + 8.0, y, 10.0, 46.0), Color(secondary.r, secondary.g, secondary.b, 0.10), true)
	var door_rect: Rect2 = Rect2(ARENA_RECT.get_center().x - 82.0, ARENA_RECT.position.y - 28.0, 164.0, 24.0)
	draw_rect(door_rect, Color(1.0, 1.0, 1.0, 0.06), true)
	draw_line(Vector2(door_rect.position.x + 82.0, door_rect.position.y), Vector2(door_rect.position.x + 82.0, door_rect.end.y), Color(accent.r, accent.g, accent.b, 0.18), 2.0, true)

func _draw_forge_arena(accent: Color, secondary: Color) -> void:
	draw_rect(Rect2(ARENA_RECT.position, ARENA_RECT.size), Color("161f2d"), true)
	for xi: int in range(int(ARENA_RECT.position.x), int(ARENA_RECT.end.x), 74):
		var x: float = float(xi)
		draw_line(Vector2(x, ARENA_RECT.position.y), Vector2(x, ARENA_RECT.end.y), Color(1.0, 1.0, 1.0, 0.045), 1.0, true)
	for yi: int in range(int(ARENA_RECT.position.y), int(ARENA_RECT.end.y), 74):
		var y: float = float(yi)
		draw_line(Vector2(ARENA_RECT.position.x, y), Vector2(ARENA_RECT.end.x, y), Color(1.0, 1.0, 1.0, 0.045), 1.0, true)
	var center: Vector2 = ARENA_RECT.get_center()
	draw_circle(center, 126.0, Color(accent.r, accent.g, accent.b, 0.06))
	draw_arc(center, 116.0, 0.0, TAU, 48, Color(accent.r, accent.g, accent.b, 0.25), 3.0, true)
	draw_arc(center, 152.0, 0.0, TAU, 56, Color(secondary.r, secondary.g, secondary.b, 0.15), 2.0, true)
	for i: int in range(12):
		var angle: float = TAU * float(i) / 12.0
		var p1: Vector2 = center + Vector2(cos(angle), sin(angle)) * 88.0
		var p2: Vector2 = center + Vector2(cos(angle), sin(angle)) * 146.0
		draw_line(p1, p2, Color(1.0, 1.0, 1.0, 0.06), 2.0, true)
	_draw_edge_lights(accent, secondary)

func _draw_ash_arena(accent: Color, secondary: Color) -> void:
	draw_rect(Rect2(ARENA_RECT.position, ARENA_RECT.size), Color("241613"), true)
	for i: int in range(28):
		var seed_x: float = ARENA_RECT.position.x + 30.0 + float((i * 137) % 1110)
		var seed_y: float = ARENA_RECT.position.y + 28.0 + float((i * 83) % 520)
		var len: float = 26.0 + float(i % 5) * 16.0
		draw_line(Vector2(seed_x, seed_y), Vector2(seed_x + len, seed_y + sin(float(i)) * 18.0), Color(accent.r, accent.g * 0.55, accent.b * 0.42, 0.24), 2.0, true)
	for j: int in range(8):
		var cx: float = ARENA_RECT.position.x + 100.0 + float(j) * 130.0
		var cy: float = ARENA_RECT.position.y + 120.0 + float(j % 2) * 170.0
		draw_circle(Vector2(cx, cy), 22.0 + float(j % 3) * 5.0, Color(secondary.r, secondary.g * 0.7, secondary.b * 0.4, 0.05))
	var center: Vector2 = ARENA_RECT.get_center()
	draw_circle(center, 122.0, Color(accent.r, accent.g, accent.b, 0.06))
	draw_arc(center, 128.0, 0.0, TAU, 48, Color(secondary.r, secondary.g, secondary.b, 0.22), 3.0, true)
	_draw_edge_lights(accent, secondary)

func _draw_neon_arena(accent: Color, secondary: Color) -> void:
	draw_rect(Rect2(ARENA_RECT.position, ARENA_RECT.size), Color("151126"), true)
	for xi: int in range(int(ARENA_RECT.position.x), int(ARENA_RECT.end.x), 92):
		var x: float = float(xi)
		draw_line(Vector2(x, ARENA_RECT.position.y), Vector2(x + 170.0, ARENA_RECT.end.y), Color(accent.r, accent.g, accent.b, 0.055), 1.0, true)
	for yi: int in range(int(ARENA_RECT.position.y), int(ARENA_RECT.end.y), 88):
		var y: float = float(yi)
		draw_line(Vector2(ARENA_RECT.position.x, y), Vector2(ARENA_RECT.end.x, y), Color(secondary.r, secondary.g, secondary.b, 0.050), 1.0, true)
	var center: Vector2 = ARENA_RECT.get_center()
	draw_circle(center, 118.0, Color(accent.r, accent.g, accent.b, 0.06))
	draw_arc(center, 112.0, 0.0, TAU, 48, Color(accent.r, accent.g, accent.b, 0.32), 3.0, true)
	draw_arc(center, 158.0, 0.0, TAU, 56, Color(secondary.r, secondary.g, secondary.b, 0.22), 2.0, true)
	for i: int in range(8):
		var angle: float = TAU * float(i) / 8.0 + pulse_time * 0.08
		var p1: Vector2 = center + Vector2(cos(angle), sin(angle)) * 134.0
		draw_circle(p1, 4.0, accent)
		var p2: Vector2 = center + Vector2(cos(angle), sin(angle)) * 84.0
		draw_line(p2, p1, Color(1.0, 1.0, 1.0, 0.08), 1.5, true)
	_draw_edge_lights(accent, secondary)

func _draw_edge_lights(accent: Color, secondary: Color) -> void:
	for i: int in range(7):
		var px: float = ARENA_RECT.position.x + 80.0 + float(i) * 170.0
		draw_rect(Rect2(px, ARENA_RECT.position.y - 18.0, 70.0, 6.0), Color(accent.r, accent.g, accent.b, 0.58), true)
		draw_rect(Rect2(px, ARENA_RECT.end.y + 12.0, 70.0, 6.0), Color(secondary.r, secondary.g, secondary.b, 0.50), true)
		draw_rect(Rect2(px + 10.0, ARENA_RECT.position.y - 22.0, 50.0, 2.0), Color(1.0, 1.0, 1.0, 0.16), true)

func _draw_room_stage() -> void:
	var mission: Dictionary = missions[selected_mission]
	var accent: Color = mission["accent"] as Color
	var secondary: Color = mission["secondary"] as Color
	var stage_alpha: float = 0.92 if state == GameState.PLAYING or state == GameState.LEVEL_UP else 0.68
	var wall_top: float = ARENA_RECT.position.y + 82.0
	var floor_back_y: float = ARENA_RECT.position.y + 192.0
	var room_rect: Rect2 = Rect2(ARENA_RECT.position.x - 36.0, wall_top - 28.0, ARENA_RECT.size.x + 72.0, ARENA_RECT.end.y - wall_top + 42.0)
	match selected_mission:
		1:
			_draw_ash_room(room_rect, floor_back_y, accent, secondary, stage_alpha)
		2:
			_draw_neon_room(room_rect, floor_back_y, accent, secondary, stage_alpha)
		_:
			_draw_forge_room(room_rect, floor_back_y, accent, secondary, stage_alpha)

func _draw_room_shell(room_rect: Rect2, floor_back_y: float, wall_color: Color, floor_color: Color, line_color: Color, rim_color: Color) -> void:
	draw_rect(room_rect, wall_color, true)
	var horizon_y: float = floor_back_y - 10.0
	draw_rect(Rect2(room_rect.position.x, horizon_y - 16.0, room_rect.size.x, 18.0), Color(1.0, 1.0, 1.0, 0.03), true)
	var floor_poly: PackedVector2Array = PackedVector2Array([
		Vector2(room_rect.position.x + 72.0, floor_back_y),
		Vector2(room_rect.end.x - 72.0, floor_back_y),
		Vector2(room_rect.end.x + 18.0, room_rect.end.y),
		Vector2(room_rect.position.x - 18.0, room_rect.end.y)
	])
	draw_colored_polygon(floor_poly, floor_color)
	draw_polyline(PackedVector2Array([floor_poly[0], floor_poly[1], floor_poly[2], floor_poly[3], floor_poly[0]]), Color(line_color.r, line_color.g, line_color.b, 0.18), 2.0, true)
	draw_line(Vector2(room_rect.position.x + 76.0, floor_back_y), Vector2(room_rect.end.x - 76.0, floor_back_y), Color(rim_color.r, rim_color.g, rim_color.b, 0.20), 2.0, true)
	draw_rect(Rect2(room_rect.position.x + 12.0, room_rect.position.y + 14.0, room_rect.size.x - 24.0, 12.0), Color(1.0, 1.0, 1.0, 0.03), true)
	for i: int in range(6):
		var ratio: float = float(i) / 5.0
		var x_left: float = lerpf(room_rect.position.x + 72.0, room_rect.position.x - 18.0, ratio)
		var x_right: float = lerpf(room_rect.end.x - 72.0, room_rect.end.x + 18.0, ratio)
		var y: float = lerpf(floor_back_y, room_rect.end.y, ratio)
		draw_line(Vector2(x_left, y), Vector2(x_right, y), Color(1.0, 1.0, 1.0, 0.025 + ratio * 0.025), 1.0, true)
	for i: int in range(7):
		var ratio_v: float = float(i) / 6.0
		var start_x: float = lerpf(room_rect.position.x + 72.0, room_rect.end.x - 72.0, ratio_v)
		var end_x: float = lerpf(room_rect.position.x - 18.0, room_rect.end.x + 18.0, ratio_v)
		draw_line(Vector2(start_x, floor_back_y), Vector2(end_x, room_rect.end.y), Color(1.0, 1.0, 1.0, 0.02), 1.0, true)
	var platform_center: Vector2 = Vector2(room_rect.get_center().x, floor_back_y + 142.0)
	draw_custom_ellipse(platform_center, Vector2(176.0, 64.0), Color(rim_color.r, rim_color.g, rim_color.b, 0.05))
	draw_custom_ellipse(platform_center, Vector2(138.0, 50.0), Color(line_color.r, line_color.g, line_color.b, 0.10))
	draw_custom_ellipse(platform_center, Vector2(116.0, 40.0), Color(0.0, 0.0, 0.0, 0.08))
	draw_arc(platform_center, 118.0, 0.0, TAU, 56, Color(rim_color.r, rim_color.g, rim_color.b, 0.26), 2.6, true)
	draw_arc(platform_center, 82.0, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.08), 1.4, true)
	for k: int in range(8):
		var angle: float = TAU * float(k) / 8.0
		var inner: Vector2 = platform_center + Vector2(cos(angle), sin(angle)) * 56.0
		var outer: Vector2 = platform_center + Vector2(cos(angle), sin(angle)) * 112.0
		draw_line(inner, outer, Color(rim_color.r, rim_color.g, rim_color.b, 0.14), 1.8, true)
	draw_rect(Rect2(room_rect.position.x - 2.0, room_rect.position.y + 56.0, 14.0, room_rect.size.y - 96.0), Color(line_color.r, line_color.g, line_color.b, 0.06), true)
	draw_rect(Rect2(room_rect.end.x - 12.0, room_rect.position.y + 56.0, 14.0, room_rect.size.y - 96.0), Color(line_color.r, line_color.g, line_color.b, 0.06), true)
	for p: int in range(4):
		var py: float = room_rect.position.y + 76.0 + float(p) * 116.0
		draw_rect(Rect2(room_rect.position.x + 8.0, py, 10.0, 48.0), Color(rim_color.r, rim_color.g, rim_color.b, 0.14), true)
		draw_rect(Rect2(room_rect.end.x - 18.0, py, 10.0, 48.0), Color(rim_color.r, rim_color.g, rim_color.b, 0.14), true)
	draw_rect(Rect2(room_rect.position.x + 44.0, room_rect.end.y - 8.0, room_rect.size.x - 88.0, 8.0), Color(0.0, 0.0, 0.0, 0.18), true)

func _draw_forge_room(room_rect: Rect2, floor_back_y: float, accent: Color, secondary: Color, alpha_scale: float) -> void:
	var wall_color: Color = Color(0.08, 0.11, 0.16, 0.74 * alpha_scale)
	var floor_color: Color = Color(0.10, 0.14, 0.20, 0.88 * alpha_scale)
	_draw_room_shell(room_rect, floor_back_y, wall_color, floor_color, accent, secondary)
	for i: int in range(5):
		var px: float = room_rect.position.x + 120.0 + float(i) * 190.0
		draw_rect(Rect2(px, floor_back_y + 84.0, 56.0, 10.0), Color(secondary.r, secondary.g, secondary.b, 0.16), true)
		draw_rect(Rect2(px + 8.0, floor_back_y + 88.0, 40.0, 2.0), Color(1.0, 1.0, 1.0, 0.10), true)
	for i: int in range(7):
		var x: float = room_rect.position.x + 88.0 + float(i) * 156.0
		draw_line(Vector2(x, floor_back_y + 4.0), Vector2(x + 24.0, room_rect.end.y - 24.0), Color(accent.r, accent.g, accent.b, 0.08), 1.0, true)

func _draw_ash_room(room_rect: Rect2, floor_back_y: float, accent: Color, secondary: Color, alpha_scale: float) -> void:
	var wall_color: Color = Color(0.15, 0.10, 0.08, 0.78 * alpha_scale)
	var floor_color: Color = Color(0.18, 0.11, 0.09, 0.92 * alpha_scale)
	_draw_room_shell(room_rect, floor_back_y, wall_color, floor_color, accent, secondary)
	for i: int in range(10):
		var ratio: float = float(i) / 9.0
		var x: float = lerpf(room_rect.position.x + 80.0, room_rect.end.x - 80.0, ratio)
		var y: float = floor_back_y + 30.0 + sin(float(i) * 1.3) * 20.0
		var crack: PackedVector2Array = PackedVector2Array([
			Vector2(x - 14.0, y), Vector2(x + 2.0, y + 10.0), Vector2(x - 8.0, y + 26.0), Vector2(x + 12.0, y + 42.0)
		])
		draw_polyline(crack, Color(accent.r, secondary.g * 0.78, secondary.b * 0.55, 0.22), 2.0, true)
	for j: int in range(6):
		var ember_x: float = room_rect.position.x + 120.0 + float(j) * 170.0
		draw_circle(Vector2(ember_x, floor_back_y + 120.0 + float(j % 2) * 36.0), 22.0, Color(secondary.r, secondary.g * 0.8, secondary.b * 0.48, 0.04))

func _draw_neon_room(room_rect: Rect2, floor_back_y: float, accent: Color, secondary: Color, alpha_scale: float) -> void:
	var wall_color: Color = Color(0.09, 0.08, 0.16, 0.80 * alpha_scale)
	var floor_color: Color = Color(0.07, 0.06, 0.15, 0.90 * alpha_scale)
	_draw_room_shell(room_rect, floor_back_y, wall_color, floor_color, accent, secondary)
	for i: int in range(8):
		var ratio: float = float(i) / 7.0
		var x0: float = lerpf(room_rect.position.x + 82.0, room_rect.end.x - 82.0, ratio)
		var x1: float = lerpf(room_rect.position.x - 18.0, room_rect.end.x + 18.0, ratio)
		draw_line(Vector2(x0, floor_back_y), Vector2(x1, room_rect.end.y), Color(accent.r, accent.g, accent.b, 0.08), 1.2, true)
	for j: int in range(5):
		var py: float = room_rect.position.y + 62.0 + float(j) * 116.0
		draw_rect(Rect2(room_rect.position.x + 44.0, py, room_rect.size.x - 88.0, 4.0), Color(secondary.r, secondary.g, secondary.b, 0.10), true)
	var sign_rect: Rect2 = Rect2(room_rect.get_center().x - 76.0, room_rect.position.y + 34.0, 152.0, 22.0)
	draw_rect(sign_rect, Color(0.0, 0.0, 0.0, 0.22), true)
	draw_rect(sign_rect, Color(accent.r, accent.g, accent.b, 0.16), false, 2.0, true)
	draw_line(Vector2(sign_rect.position.x + 16.0, sign_rect.get_center().y), Vector2(sign_rect.end.x - 16.0, sign_rect.get_center().y), Color(secondary.r, secondary.g, secondary.b, 0.28), 2.0, true)

func draw_custom_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(28):
		var angle: float = TAU * float(i) / 28.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)

func _draw_ambient_particles() -> void:
	var mission: Dictionary = missions[selected_mission]
	var accent: Color = mission["accent"] as Color
	var secondary: Color = mission["secondary"] as Color
	for particle in ambient_particles:
		var base: Vector2 = particle["base"] as Vector2
		var phase: float = float(particle["phase"])
		var depth: float = float(particle["depth"])
		var size: float = float(particle["size"])
		var speed: float = float(particle["speed"])
		var drift: float = float(particle["drift"])
		var pos: Vector2 = base + Vector2(sin(pulse_time * speed + phase) * (10.0 + depth * 10.0), cos(pulse_time * speed * 0.8 + phase * 1.7) * (5.0 + depth * 7.0))
		var alpha: float = (0.028 + depth * 0.065) * (0.65 if state != GameState.PLAYING and state != GameState.LEVEL_UP else 1.0)
		match selected_mission:
			1:
				var ember_color: Color = Color(accent.r, secondary.g * 0.82, secondary.b * 0.55, alpha)
				draw_line(pos + Vector2(-drift * 0.08, 5.0 + depth * 7.0), pos, ember_color, 1.2 + depth * 0.7, true)
				draw_circle(pos, size * 0.72, ember_color)
			2:
				var neon_color: Color = accent if int(roundi(phase * 10.0)) % 2 == 0 else secondary
				var neon_alpha: float = alpha * 1.18
				draw_line(pos + Vector2(-size * 2.0, 0.0), pos + Vector2(size * 2.0, 0.0), Color(neon_color.r, neon_color.g, neon_color.b, neon_alpha), 1.4, true)
				draw_circle(pos, size * 0.34, Color(1.0, 1.0, 1.0, neon_alpha * 0.55))
			_:
				var forge_color: Color = Color(secondary.r, secondary.g, secondary.b, alpha * 0.95)
				draw_circle(pos, size * 0.68, forge_color)
				draw_circle(pos + Vector2(0.0, -1.0), size * 0.28, Color(1.0, 1.0, 1.0, alpha * 0.40))

func _draw_impact_effects() -> void:
	for effect in impact_effects:
		var max_time: float = float(effect["max_time"])
		if max_time <= 0.0:
			continue
		var remaining: float = float(effect["time"])
		var t: float = clampf(1.0 - remaining / max_time, 0.0, 1.0)
		var base_pos: Vector2 = effect["pos"] as Vector2
		var pos: Vector2 = base_pos + world_root.position
		var color: Color = effect["color"] as Color
		var alpha: float = 1.0 - t
		var strong: bool = bool(effect.get("strong", false))
		var kind: String = String(effect.get("kind", "impact"))

		if kind == "muzzle":
			var dir: Vector2 = effect.get("direction", Vector2.RIGHT) as Vector2
			if dir.length_squared() < 0.01:
				dir = Vector2.RIGHT
			dir = dir.normalized()
			var side: Vector2 = Vector2(-dir.y, dir.x)
			var muzzle_len: float = 10.0 + 18.0 * t
			draw_circle(pos, (7.0 if strong else 5.0) * (1.0 - t * 0.35), Color(color.r, color.g, color.b, 0.24 * alpha))
			draw_line(pos - dir * 3.0, pos + dir * muzzle_len, Color(1.0, 1.0, 1.0, 0.70 * alpha), 2.2 if strong else 1.6, true)
			draw_line(pos - side * 6.0, pos + side * 6.0, Color(color.r, color.g, color.b, 0.38 * alpha), 1.5, true)
			continue

		var radius: float = float(effect["radius"]) + float(effect["growth"]) * t
		var start_angle: float = float(effect.get("angle", 0.0))
		draw_circle(pos, radius, Color(color.r, color.g, color.b, (0.18 if strong else 0.12) * alpha), false, 3.6 - t * 1.6, true)
		draw_circle(pos, radius * 0.52, Color(1.0, 1.0, 1.0, (0.15 if strong else 0.08) * alpha), false, 1.8, true)
		var ray_count: int = 8 if strong else 5
		for i: int in range(ray_count):
			var angle: float = start_angle + float(i) * TAU / float(ray_count)
			var ray_dir: Vector2 = Vector2(cos(angle), sin(angle))
			var inner: Vector2 = pos + ray_dir * (radius * 0.22)
			var outer: Vector2 = pos + ray_dir * (radius * (0.82 + t * 0.18))
			draw_line(inner, outer, Color(color.r, color.g, color.b, (0.28 if strong else 0.16) * alpha), 2.0 if strong else 1.3, true)

func _draw_joystick() -> void:
	if not joystick_active:
		return
	var input_strength: float = clampf(joystick_origin.distance_to(joystick_knob) / JOYSTICK_RADIUS, 0.0, 1.0)
	draw_circle(joystick_origin, JOYSTICK_RADIUS + 5.0, Color(0.18, 0.70, 1.0, 0.05))
	draw_circle(joystick_origin, JOYSTICK_RADIUS, Color(0.04, 0.10, 0.18, 0.34))
	draw_circle(joystick_origin, JOYSTICK_RADIUS, Color(0.48, 0.84, 1.0, 0.46), false, 2.0, true)
	draw_circle(joystick_origin, JOYSTICK_DEADZONE, Color(0.70, 0.92, 1.0, 0.10), false, 1.0, true)
	if joystick_knob.distance_to(joystick_origin) > 1.0:
		draw_line(joystick_origin, joystick_knob, Color(0.40, 0.80, 1.0, 0.18 + input_strength * 0.20), 4.0, true)
	draw_circle(joystick_knob, 28.0, Color(0.44, 0.84, 1.0, 0.18 + input_strength * 0.16))
	draw_circle(joystick_knob, 28.0, Color(0.72, 0.94, 1.0, 0.58), false, 2.0, true)

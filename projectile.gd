extends Node2D
class_name ArenaProjectile

signal hit_target(shooter: ArenaFighter, victim: ArenaFighter, damage_amount: float, critical: bool)

var arena_rect: Rect2 = Rect2(40, 100, 1200, 580)
var velocity: Vector2 = Vector2.ZERO
var team: int = 0
var damage: float = 10.0
var life: float = 1.8
var radius: float = 5.2
var shot_color: Color = Color("52d6ff")
var critical: bool = false
var owner_fighter: ArenaFighter
var pulse_time: float = 0.0

func _process(delta: float) -> void:
	pulse_time += delta * 12.0
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	global_position += velocity * delta
	if not arena_rect.has_point(global_position):
		queue_free()
		return

	for node: Node in get_tree().get_nodes_in_group("fighters"):
		var other: ArenaFighter = node as ArenaFighter
		if other == null or other.dead or other.team == team:
			continue
		var hit_distance: float = radius + other.hit_radius * 0.72
		if global_position.distance_squared_to(other.global_position) <= hit_distance * hit_distance:
			var projectile_knockback: float = 220.0 if critical else 155.0
			var projectile_stagger: float = 0.12 if critical else 0.07
			var actual_damage: float = other.take_damage(damage * (1.65 if critical else 1.0), velocity.normalized() * projectile_knockback, projectile_stagger)
			if is_instance_valid(owner_fighter) and owner_fighter.lifesteal > 0.0 and actual_damage > 0.0:
				owner_fighter.health = minf(owner_fighter.max_health, owner_fighter.health + actual_damage * owner_fighter.lifesteal)
				owner_fighter.health_changed.emit(owner_fighter)
			hit_target.emit(owner_fighter, other, actual_damage, critical)
			queue_free()
			return
	queue_redraw()

func _draw() -> void:
	var direction: Vector2 = velocity.normalized()
	if direction.length_squared() < 0.01:
		direction = Vector2.RIGHT
	var side: Vector2 = Vector2(-direction.y, direction.x)
	var critical_boost: float = 1.35 if critical else 1.0
	var pulse: float = 0.75 + sin(pulse_time) * 0.25

	draw_line(-direction * 40.0, Vector2.ZERO, Color(shot_color.r, shot_color.g, shot_color.b, 0.08 * critical_boost), radius + 9.0, true)
	draw_line(-direction * 27.0, Vector2.ZERO, Color(shot_color.r, shot_color.g, shot_color.b, 0.28 * critical_boost), radius * 1.25, true)
	draw_line(-direction * 18.0, direction * 3.0, Color(shot_color.r, shot_color.g, shot_color.b, 0.62), maxf(2.2, radius * 0.72), true)

	var flare: PackedVector2Array = PackedVector2Array([
		-direction * 5.0 + side * 3.2,
		-direction * 24.0,
		-direction * 5.0 - side * 3.2,
		direction * 2.0
	])
	draw_colored_polygon(flare, Color(shot_color.r, shot_color.g, shot_color.b, 0.20 * critical_boost))

	var pulse_radius: float = radius + 1.1 * pulse
	draw_circle(Vector2.ZERO, pulse_radius + 5.0, Color(shot_color.r, shot_color.g, shot_color.b, 0.16 * critical_boost))
	draw_circle(Vector2.ZERO, pulse_radius + (1.6 if critical else 0.0), shot_color.lightened(0.20))
	draw_circle(Vector2.ZERO, radius * 0.48, Color.WHITE)
	draw_line(side * 5.0, -side * 5.0, Color(1.0, 1.0, 1.0, 0.34), 1.5, true)

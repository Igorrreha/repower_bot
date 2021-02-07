extends KinematicBody2D

onready var nodeDashRay = $DashRay
onready var nodeSprite = $Sprite
onready var nodeCollisionShape = $CollisionShape2D


signal dash_charges_changed(_val)


enum DIR {
	L, R
}
var curMoveDir = DIR.R

enum STATES {
	IDLE, CONNECTED_TO_WIRE, CASTS_DASH, GRABS_WALL, ON_ENERGY_WALL
}
var curState = STATES.IDLE


var GRAV = 1000
var maxFallSpeed = 400
var nodeCurRemoteTransform = null
var nodeCurRemoteTransformPathFollow = null

var moveVec = Vector2()
var moveSpeed = 200
var moveDec = 100
var jumpVec = Vector2(150, -400)
var dashDist = 75
var dashAng = 0
var dashImpulse = 300

var dashCharges = 1
var maxDashCharges = 2

 
func _physics_process(delta):
	match curState:
		STATES.IDLE:
			moveVec.x = Vector2(moveVec.x, 0).clamped(abs(moveVec.x) - moveDec * delta).x
			moveVec.y = clamp(moveVec.y + GRAV * delta, -INF, maxFallSpeed)
			
			move_and_slide(moveVec, Vector2.UP)
			
			var hasWallCollision = false
			for i in get_slide_count():
				var collision = get_slide_collision(i)
				if collision.collider.is_in_group("energy_wall"):
					energy_wall_collision(collision)
				elif collision.collider.is_in_group("wall"):
					wall_collision(collision)
					var collisionNormalDir = Vector2(round(collision.normal.x), round(collision.normal.y))
					if collisionNormalDir == Vector2.LEFT or collisionNormalDir == Vector2.RIGHT:
						hasWallCollision = true
			
			if hasWallCollision:
				moveVec.x = -moveVec.x
		
		
		STATES.CONNECTED_TO_WIRE:
			var prevPos = global_position
			
			# pathfollow step
			nodeCurRemoteTransformPathFollow.offset += moveSpeed * delta * (1 if curMoveDir == DIR.R else -1)
			if (curMoveDir == DIR.L and nodeCurRemoteTransformPathFollow.unit_offset <= 0) or (curMoveDir == DIR.R and nodeCurRemoteTransformPathFollow.unit_offset >= 1):
				disconnect_from_wire()
				moveVec.x = moveSpeed * (1 if curMoveDir == DIR.R else -1)
			
			else:
				# check collision
				var pathDir = (prevPos - global_position).normalized()
				
				var collision = move_and_collide(pathDir, true, true, true)
				if not collision == null:
					if collision.collider.is_in_group("energy_wall"):
						energy_wall_collision(collision)
					if collision.collider.is_in_group("wall"):
						wall_collision(collision)
		
		
		STATES.ON_ENERGY_WALL:
			moveVec = Vector2(moveSpeed * (1 if curMoveDir == DIR.R else -1), 10)
			
			move_and_slide(moveVec, Vector2.UP)
			
			var onEnergyWall = false
			for i in get_slide_count():
				var collision = get_slide_collision(i)
				
				if collision.collider.is_in_group("energy_wall"):
					if Vector2(round(collision.normal.x), round(collision.normal.y)) == Vector2.UP:
						onEnergyWall = true
				
				elif collision.collider.is_in_group("wall"):
					wall_collision(collision)
			
			if not onEnergyWall:
				moveVec = Vector2()
				curState = STATES.IDLE


func wall_collision(_collision):
	var collisionNormalDir = Vector2(round(_collision.normal.x), round(_collision.normal.y))
	
	if collisionNormalDir == Vector2.LEFT:
		curMoveDir = DIR.L
		
	elif collisionNormalDir == Vector2.RIGHT:
		curMoveDir = DIR.R


func energy_wall_collision(_collision):
	var collisionNormalDir = Vector2(round(_collision.normal.x), round(_collision.normal.y))
	
	if collisionNormalDir == Vector2.UP:
		curState = STATES.ON_ENERGY_WALL
		
	elif collisionNormalDir == Vector2.LEFT:
		curState = STATES.GRABS_WALL
		moveVec = Vector2()
		curMoveDir = DIR.L
		
	elif collisionNormalDir == Vector2.RIGHT:
		curState = STATES.GRABS_WALL
		moveVec = Vector2()
		curMoveDir = DIR.R


func _on_WireCollider_area_entered(_area):
	if _area.is_in_group("wire"):
		if not curState == STATES.CASTS_DASH: 
			connect_to_wire(_area.get_parent())


# connect to wire
func connect_to_wire(_wire: Wire):
	var nodeWirePathFollow = _wire.nodePathFollow
	var nodeWireRemoteTransform = _wire.nodeRemoteTransform
	
	nodeCurRemoteTransform = nodeWireRemoteTransform
	nodeCurRemoteTransformPathFollow = nodeWirePathFollow
	
	var pathFollowOffset = _wire.curve.get_closest_offset(position)
	nodeCurRemoteTransformPathFollow.offset = pathFollowOffset
	
	nodeCurRemoteTransform.update_position = true
	
	moveVec = Vector2()
	curState = STATES.CONNECTED_TO_WIRE


# disconnect from wire
func disconnect_from_wire():
	nodeCurRemoteTransform.update_position = false
	nodeCurRemoteTransform = null
	nodeCurRemoteTransformPathFollow = null
	
	curState = STATES.IDLE


func jump():
	match curState:
		STATES.CONNECTED_TO_WIRE:
			disconnect_from_wire()
			moveVec = Vector2(jumpVec.x * (1 if curMoveDir == DIR.R else -1), jumpVec.y)
			
		STATES.GRABS_WALL:
			curState = STATES.IDLE
			moveVec = Vector2(jumpVec.x * (1 if curMoveDir == DIR.R else -1), jumpVec.y)
			
		STATES.ON_ENERGY_WALL:
			curState = STATES.IDLE
			moveVec = Vector2(jumpVec.x * (1 if curMoveDir == DIR.R else -1), jumpVec.y)


func start_cast_dash():
	if curState == STATES.CONNECTED_TO_WIRE:
		disconnect_from_wire()
	
	moveVec = Vector2()
	curState = STATES.CASTS_DASH


func dash():
	dashCharges -= 1
	emit_signal("dash_charges_changed", dashCharges)
	
	var wallColliderOffset = Vector2(nodeCollisionShape.shape.extents.x / 2, 0).rotated(dashAng)
	nodeDashRay.cast_to = Vector2(dashDist, 0).rotated(dashAng) + wallColliderOffset
	
	nodeDashRay.force_raycast_update()
	
	var dashEndPoint = position + nodeDashRay.cast_to
	if nodeDashRay.is_colliding():
		dashEndPoint = nodeDashRay.get_collision_point() - nodeDashRay.position
	
	moveVec = Vector2(dashImpulse, 0).rotated(dashAng)
	position = dashEndPoint - wallColliderOffset
	
	if curState == STATES.CONNECTED_TO_WIRE:
		disconnect_from_wire()
	
	curState = STATES.IDLE


func _on_ItemCollider_area_entered(_area):
	if _area.is_in_group("recharger"):
		if dashCharges < maxDashCharges:
			dashCharges += 1
			_area.taken()
			emit_signal("dash_charges_changed", dashCharges)


func _input(event):
	# jump from wire
	if event.is_action_pressed("player_jump"):
		jump()
	
	# dash
	if event is InputEventMouseMotion:
		if curState == STATES.CASTS_DASH:
			dashAng = event.position.angle_to_point(nodeSprite.global_position)
	
	if event.is_action_pressed("player_dash"):
		if dashCharges > 0:
			start_cast_dash()
	
	if event.is_action_released("player_dash"):
		if curState == STATES.CASTS_DASH:
			dash()


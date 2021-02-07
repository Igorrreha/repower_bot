extends Path2D

class_name Wire

onready var nodePathFollow = $PathFollow2D
onready var nodeRemoteTransform = $PathFollow2D/RemoteTransform2D
onready var nodeCollisionPolygon = $Area2D/CollisionPolygon2D

var pathPlayerNode = "../../../../../Player"


func _ready():
	nodeRemoteTransform.remote_path = pathPlayerNode
	load_curve()
	create_collision_polygon()


func load_curve():
	curve.clear_points()
	for i in range(get_parent().points.size()):
		curve.add_point(get_parent().points[i])


func create_collision_polygon():
	var polygonHeight = 4
	
	var poly = PoolVector2Array()
	poly.append_array(get_parent().points)
	
	var invertedPoints = get_parent().points
	invertedPoints.invert()
	for i in range(invertedPoints.size()):
		poly.append(invertedPoints[i] + Vector2(0, polygonHeight))
		
	
	nodeCollisionPolygon.polygon = poly

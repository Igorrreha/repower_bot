extends EditorScript

tool

func _run():
	var wallPolygonsCont = get_scene().get_node("Game/WallPolygons")
	
	var wallsCont = get_scene().get_node("Game/Walls")
	var energyWallsCont = get_scene().get_node("Game/EnergyWalls")
	
	for wall in wallPolygonsCont.get_children():
		wall.free()
	
	for wall in wallsCont.get_children():
		var wallsPoly = Polygon2D.new()
		wallsPoly.polygon = wall.polygon
		
		wallsPoly.color = Color("000")
		wallPolygonsCont.add_child(wallsPoly)
		wallsPoly.set_owner(get_scene())
	
	for wall in energyWallsCont.get_children():
		var wallsPoly = Polygon2D.new()
		wallsPoly.polygon = wall.polygon
		
		wallsPoly.color = Color("fff")
		wallPolygonsCont.add_child(wallsPoly)
		wallsPoly.set_owner(get_scene())

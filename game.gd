extends Node2D

onready var nodePlayer = $Player
onready var nodeRechargersCont = $Rechargers

onready var nodeDashChargesBar = $UI/DashChargesBar


func _ready():
	nodePlayer.connect("dash_charges_changed", nodeDashChargesBar, "set_value")

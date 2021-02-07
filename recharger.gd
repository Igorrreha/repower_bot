extends Area2D

onready var nodeCollisionShape = $CollisionShape2D
onready var nodeSprite = $Sprite
onready var nodeTimer = $Timer

var isTaken = false


func taken():
	isTaken = true
	
	nodeCollisionShape.set_deferred("disabled", true)
	nodeSprite.modulate.a = 0
	
	nodeTimer.start()


func _on_Timer_timeout():
	isTaken = false
	nodeCollisionShape.set_deferred("disabled", false)
	nodeSprite.modulate.a = 1

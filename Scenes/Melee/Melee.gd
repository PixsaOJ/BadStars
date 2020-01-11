extends Node2D

class_name Melee

signal reloaded(ammo)

export var maxAmmo = 3
export var distance = 1000
export var damage = 50
export var aimWidth = 20
onready var ammo = maxAmmo

var canShoot = true

func _ready():
	drawAim()
	$Aim.visible = false
	pass
	
remotesync func shoot(id:int, irrelevantPoolIndex:int):
	
	if get_tree().is_network_server():
	
		for body in $Range.get_overlapping_bodies():
			if body.is_in_group("Shootable"):
				if not body.is_in_group("Ally"+String(id)):
					body.rpc("hit", damage, id)
					
					if body.is_in_group("Player") or body.is_in_group("Dummy"):
						get_tree().get_nodes_in_group("Ally"+String(id))[0].rpc("didDamage", damage)
		
		pass
	
	pass
	
func aim(do:bool):
	
	$Aim.visible = do
	
	pass

func drawAim():
	
	$Aim.polygon = PoolVector2Array([$Muzzle.position-Vector2(0, aimWidth/2), $Muzzle.position+Vector2(distance, 0)-Vector2(0, aimWidth/2), $Muzzle.position+Vector2(distance, 0)+Vector2(0, aimWidth/2), $Muzzle.position+Vector2(0, aimWidth/2)])
	
	pass

func _on_Cooldown_timeout():
	canShoot = true


func _on_Reload_timeout():
	if not ammo == maxAmmo:
		ammo += 1
		emit_signal("reloaded", ammo)
		if not ammo == maxAmmo:
			$Reload.start()

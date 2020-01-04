extends KinematicBody2D

export var maxHealth = 400
onready var health = maxHealth

export var moveSpeed = 200

export var poolSize = 100

export(Globals.characters) var character = Globals.characters.CLOT

export var gunPath:NodePath = "Gun"
onready var gun = get_node(gunPath)


var velocity = Vector2()

var mobileControls:Control
var ui:gameUI

func _ready():
	pass
	
func initialize(id:int):
	set_network_master(id)
	name = String(id)
	
	if is_network_master():
		$Camera.current = true
		
		add_to_group("Ally")
	
		if Globals.mobile:
			var controls = load("res://Scenes/UI/MobileControls.tscn")
			mobileControls = controls.instance()
			$UI.add_child(mobileControls)
			
		var uiScene = preload("res://Scenes/UI/GameUI.tscn")
		ui = uiScene.instance()
		$UI.add_child(ui)
		
		ui.setupUI(maxHealth, gun.maxAmmo)
		
		gun.connect("reloaded", ui, "setAmmo")
		
	else:
		add_to_group("Enemy")
	pass
	
func _physics_process(delta):
	if Network.gameStarted:
	
		movement()
		actions()
	
	pass
	
func movement():
	
	if is_network_master():
		
		var dir = Vector2()
		
		if Globals.mobile:
			
			dir = Globals.leftStickAxis
			
		else:
			
			if Input.is_action_pressed("left"):
				dir.x = -1
			elif Input.is_action_pressed("right"):
				dir.x = 1
			else:
				dir.x = 0
				
			if Input.is_action_pressed("up"):
				dir.y = -1
			elif Input.is_action_pressed("down"):
				dir.y = 1
			else:
				dir.y = 0
			
		dir = dir.normalized()
		
		velocity = dir*moveSpeed
		
		velocity = move_and_slide(velocity)
		
		rpc_unreliable("setPosition", global_position)
		
	pass
	
func actions():
	
	if is_network_master():
		
		if Globals.mobile:
			
			rpc("aimGun", Globals.rightStickAxis.angle())
			
			if mobileControls.shot:
				mobileControls.shot = false
				shoot()
			
		else:
			rpc("aimGun", get_angle_to(get_global_mouse_position()))
		
			if Input.is_action_just_pressed("shoot"):
				shoot()
				pass
	
	pass
	
func shoot():
	
	if gun.canShoot and not gun.ammo <= 0:
		gun.rpc("shoot", get_tree().get_network_unique_id(), ObjectPool.getAvailableObjectIndex(ObjectPool.pools[get_tree().get_network_unique_id()].bullets))
		gun.ammo -= 1
		ui.setAmmo(gun.ammo)
		gun.get_node("Cooldown").start()
		gun.canShoot = false
		if gun.get_node("Reload").is_stopped():
			gun.get_node("Reload").start()
		
	pass
	
remotesync func hit(damage:int, id:int):
	
	health -= damage
	if is_network_master():
		ui.setHealth(health)
	else:
		pass
	
	pass
	
remotesync func aimGun(direction:float):
	gun.global_rotation = direction
	pass
	
	
puppet func setPosition(pos:Vector2):
	global_position = pos
	pass

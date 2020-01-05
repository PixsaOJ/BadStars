extends Node2D


var playerObjects = {}

func _ready():
	set_network_master(1)
	spawnPlayers()
	ObjectPool.createPools()
	setReady()
	pass

func spawnPlayers():
	for player in Network.players.keys():
		var p = load(Globals.characterInfo[Network.players[player].character].playerPath).instance()
		p.name = String(player)
		add_child(p)
	pass
	
func placePlayers():
	
	var spots = $SpawnPoints.get_children()
	
	for player in playerObjects.keys():
		var spot = rand_range(0, spots.size())
		rpc("placePlayer", player, spots[spot].global_position)
		spots.remove(spot)
		pass
	
	pass
	
remotesync func placePlayer(key:String, pos:Vector2):
	playerObjects[key].global_position = pos
	pass
	
func setReady():
	if not get_tree().is_network_server():
		Network.rpc_id(1, "readyPlayer", get_tree().get_network_unique_id())
	else:
		Network.readyPlayer(1)
	if get_tree().is_network_server():
		
		yield(Network, "allPlayersReady")
		
		rpc("startGame")
		
	pass
	
remotesync func startGame():
	get_tree().paused = false
	
	for player in get_tree().get_nodes_in_group("Player"):
		player.initialize(int(player.name))
		playerObjects[player.name] = player
		
	if get_tree().is_network_server():
		placePlayers()
		
	Network.gameStarted = true
	Network.starting = false
	
	pass
extends Node


@onready var main_menu = $CanvasLayer/MainMenu
@onready var adress = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/Address
@onready var hud: Control = $CanvasLayer/HUD
@onready var health_bar: ProgressBar = $CanvasLayer/HUD/HealthBar

const Player = preload("res://player/player.tscn")
const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()

func _on_host_button_pressed():
	main_menu.hide()
	hud.show()

	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)

	add_player(multiplayer.get_unique_id())
   # Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_join_button_pressed():
	main_menu.hide()
	hud.show()
	
	enet_peer.create_client("localhost", PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.server_disconnected.connect(server_disconnected)
	#multiplayer.connection_failed.connect(connection_failed)

func add_player(peer_id: int):
	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)
	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health_bar)

func update_health_bar(new_value: int):
	health_bar.value = new_value

func _on_multiplayer_spawner_spawned(node:Node):
	if node.is_multiplayer_authority():
		node.health_changed.connect(update_health_bar)

func remove_player(peer_id: int):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()


func server_disconnected():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.hide()
	main_menu.show()

#func connection_failed():
#	print("Пизда")
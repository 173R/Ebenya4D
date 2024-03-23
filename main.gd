extends Node3D

# Достаём игрока из сцены
@onready var player: CharacterBody3D = $player
# Достаём ui инвентаря
@onready var inventory_interface: Control = $UI/InventoryInterface

func _ready():
	# Коннектим сигнал открытия инветоря которы послает плеер
	player.toggle_inventory.connect(toggle_inventory_interface)
	
	# Заполняем инвентарь данными которые достаём из игрока (ресурс установлен в игрока)
	inventory_interface.set_player_inventory_data(player.invetory_data)

func toggle_inventory_interface():
	inventory_interface.visible = !inventory_interface.visible

	if inventory_interface.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
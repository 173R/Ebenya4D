extends Node3D

const PickUp = preload("res://inventory/item/pick_up/pick_up.tscn")

# Достаём игрока из сцены
@onready var player: CharacterBody3D = $player
# Достаём ui инвентаря
@onready var inventory_interface: Control = $UI/InventoryInterface

# ui быстрого инвентаря
@onready var hot_bar_inventory: PanelContainer = $UI/HotBarInventory

func _ready():
	# Коннектим сигнал открытия инветоря которы послает плеер
	player.toggle_inventory.connect(toggle_inventory_interface)
	
	# Заполняем инвентарь данными которые достаём из игрока (ресурс установлен в игрока)
	inventory_interface.set_player_inventory_data(player.inventory_data)
	inventory_interface.set_equip_inventory_data(player.equip_inventory_data)

	inventory_interface.force_close.connect(toggle_inventory_interface)

	hot_bar_inventory.set_inventory_data(player.inventory_data)
	

	# Вешаем на каждую ноду в группе "external_inventory" сигнал открытия инвентаря
	for node in get_tree().get_nodes_in_group("external_inventory"):
		# Такой сигнал есть и у скрипта плеера и у всех нод в группе "external_inventory"
		node.toggle_inventory.connect(toggle_inventory_interface)

func toggle_inventory_interface(external_inventory_owner = null):
	inventory_interface.visible = !inventory_interface.visible

	if inventory_interface.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Если этот инвентарь не пренадлежит нашему игроку то подменяем его инвентарь на чужой
	if external_inventory_owner and inventory_interface.visible:
		inventory_interface.set_external_inventory(external_inventory_owner)
	else:
		inventory_interface.clear_external_inventory()

func _on_inventory_interface_drop_slot_data(slot_data:SlotData):
	var pick_up = PickUp.instantiate()
	pick_up.slot_data = slot_data
	pick_up.position = player.get_item_drop_position()
	add_child(pick_up)

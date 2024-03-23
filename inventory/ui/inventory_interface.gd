extends Control

@onready var player_inventory: PanelContainer = $PlayerInventory

# функция заполнения ui инвентаря на основе мета данных из ресурса
func set_player_inventory_data(inventory_data: InventoryData):
	inventory_data.inventory_interact.connect(on_inventory_interact)
	player_inventory.set_inventory_data(inventory_data)

func on_inventory_interact(inventory_data: InventoryData, index: int, button: int):
	print("%s %s %s" % [inventory_data, index, button])
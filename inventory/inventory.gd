extends PanelContainer

# Достаём сцену с ui для слота (ячейка)
const Slot = preload("res://inventory/slot/slot.tscn")
# Достаем ui сетку из сцены инвентаря
@onready var item_grid : GridContainer = $MarginContainer/ItemGrid

func set_inventory_data(inventory_data: InventoryData):
	# Заполняем ui на основе мета инфы
	populate_item_grid(inventory_data)

# Заполняет сетку эелментов слотами
func populate_item_grid(inventory_data: InventoryData) -> void:
	# Отчищаем от дочерних элементов
	for	child in item_grid.get_children():
		child.queue_free()
	
	# Создаём слот для каждого ресурса слота
	for slot_data in inventory_data.slot_datas:
		var slot = Slot.instantiate()
		item_grid.add_child(slot)
		
		# Подписываемся на клики по слоту, если клик был то вызываем функцию ресурса
		slot.slot_clicked.connect(inventory_data.on_slot_clicked)

		# Заполняем слот данными
		if slot_data:
			slot.set_slot_data(slot_data)

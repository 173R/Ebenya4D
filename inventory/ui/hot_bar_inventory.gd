extends PanelContainer

signal hot_bar_use(index: int)

const Slot = preload("res://inventory/slot/slot.tscn")

@onready var h_box_container: HBoxContainer = $MarginContainer/HBoxContainer

func _unhandled_key_input(event):
	if event.is_pressed() and range(KEY_1, KEY_7).has(event.keycode):
		hot_bar_use.emit(event.keycode - KEY_1)

func set_inventory_data(inventory_data: InventoryData):
	inventory_data.inventory_update.connect(populate_hot_bar)
	populate_hot_bar(inventory_data)
	hot_bar_use.connect(inventory_data.use_slot_data)

# Заполняет сетку эелментов слотами
func populate_hot_bar(inventory_data: InventoryData):
	print("update inventory")
	# Отчищаем от дочерних элементов
	for	child in h_box_container.get_children():
		child.queue_free()
	
	# Создаём слот для каждого ресурса слота
	for slot_data in inventory_data.slot_datas.slice(0, 6):
		var slot = Slot.instantiate()
		h_box_container.add_child(slot)

		# Заполняем слот данными
		if slot_data:
			slot.set_slot_data(slot_data)

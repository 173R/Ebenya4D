extends Resource
class_name InventoryData

signal inventory_update(inventory_data: InventoryData)
signal inventory_interact(inventory_data: InventoryData, index: int, button: int)

@export var slot_datas: Array[SlotData]

func on_slot_clicked(index: int, button: int):
    inventory_interact.emit(self, index, button)

# Возвращаем данные слота по индексу
func grab_slot_data(index: int) -> SlotData:
    var slot_data = slot_datas[index]

    if slot_data:
        slot_datas[index] = null
        # Сигнал обновления инвентаря
        inventory_update.emit(self)
        return slot_data
    return null

# Вызываем когда у нас есть захваченный айтем
func drop_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
    # Айтем который уже есть в слоте, сохраняем его, берётся по указателю???
    var slot_data = slot_datas[index]

    var resut_slot_data: SlotData
    if slot_data and slot_data.can_fully_merge_with(grabbed_slot_data):
        #slot_data.quantity += 3
        slot_data.fully_merge_with(grabbed_slot_data)
    else:
        slot_datas[index] = grabbed_slot_data
        resut_slot_data = slot_data

    inventory_update.emit(self)

    return resut_slot_data

func drop_single_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
    var slot_data = slot_datas[index]

    if not slot_data:
        slot_datas[index] = grabbed_slot_data.create_single_slot_data()
    elif slot_data.can_merge_with(grabbed_slot_data):
        slot_data.fully_merge_with(grabbed_slot_data.create_single_slot_data())

    inventory_update.emit(self)

    if grabbed_slot_data.quantity > 0:
        return grabbed_slot_data
    return null

func pick_up_slot_data(slot_data: SlotData) -> bool:
    for index in slot_datas.size():
        if slot_datas[index] and slot_datas[index].can_fully_merge_with(slot_data):
            slot_datas[index].fully_merge_with(slot_data)
            inventory_update.emit(self)
            return true
    
    for index in slot_datas.size():
        if not slot_datas[index]:
            slot_datas[index] = slot_data
            inventory_update.emit(self)
            return true
    
    return false

func use_slot_data(index: int):
    var slot_data = slot_datas[index]

    if not slot_data:
        return

    if slot_data.item_data is ItemDataConsumable:
        slot_data.quantity -= 1
        if slot_data.quantity < 1:
            slot_datas[index] = null

        inventory_update.emit(self)

    print("Using %s" % slot_data.item_data.name)
    PlayerManager.use_slot_data(slot_data)
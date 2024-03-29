extends Node

var player

# Использует переданный слот применя его на юзера
func use_slot_data(slot_data: SlotData):
	slot_data.item_data.use(player)

func get_global_position() -> Vector3:
	return player.global_position
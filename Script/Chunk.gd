class_name Chunk

var chunkData

func _init():
	chunkData = []

func setBlockData(x: int, y: int, block, override = false):
	# Check if the coord of the block is in the chunk limit
	if x < 0 or x >= Global.chunkSize or y < Global.lowLimit or y >= Global.highLimit:
		return null
	var exist = false

	for i in chunkData.size():
		if chunkData[i].coords.x == x and chunkData[i].coords.y == y:
			if override:
				chunkData[i].block = block
			else:
				exist = true
			break
	if exist:
		return null
	chunkData.append({
		"coords": {
			"x": x,
			"y": y
		},
		"block": block,
	})

func getBlockData(x: int, y: int):
	var data = null
	for i in chunkData.size():
		if chunkData[i].coords.x == x and chunkData[i].coords.y == y:
			data = i
			break
	return data

func deleteBlockData(x: int, y: int):
	var deletedData = null
	for i in chunkData.size():
		if chunkData[i].coords.x == x and chunkData[i].coords.y == y:
			deletedData = i
			chunkData.remove(i)
			break
	return deletedData

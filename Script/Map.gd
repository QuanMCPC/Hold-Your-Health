extends Node2D

enum BLOCKTYPE {
	SOLID,
	LIQUID,
	FOOD,
}

enum STRUCTURE {
	LAVAPOOL = 0,
	WALL = 1,
	SPIKE = 2,
	WATERPOOL = 3,
	CACTUS = 4,
}

const BLOCK = {
	"LAVA": {
		"id": 0,
		"type": BLOCKTYPE.LIQUID,
	},
	"LAVA_HEAD": {
		"id": 1,
		"type": BLOCKTYPE.LIQUID,
	},
	"STONE": {
		"id": 2,
		"type": BLOCKTYPE.SOLID,
	},
	"WALL": {
		"id": 3,
		"type": BLOCKTYPE.SOLID,
	},
	"WALL_HEAD": {
		"id": 4,
		"type": BLOCKTYPE.SOLID,
	},
	"SPIKE": {
		"id": 5,
		"type": BLOCKTYPE.SOLID,
	},
	"WATER": {
		"id": 6,
		"type": BLOCKTYPE.LIQUID,
	},
	"WATER_HEAD": {
		"id": 7,
		"type": BLOCKTYPE.LIQUID,
	},
	"CACTUS": {
		"id": 8,
		"type": BLOCKTYPE.SOLID,
	},
	"CACTUS_HEAD": {
		"id": 9,
		"type": BLOCKTYPE.SOLID,
	},
	"GRASS": {
		"id": 10,
		"type": BLOCKTYPE.SOLID,
	},
	"DIRT": {
		"id": 11,
		"type": BLOCKTYPE.SOLID,
	},
	"GOOD_MUSHROOM": {
		"id": 0,
		"type": BLOCKTYPE.FOOD,
	},
	"BAD_MUSHROOM": {
		"id": 1,
		"type": BLOCKTYPE.FOOD,
	},
	"BLACKBERRY": {
		"id": 2,
		"type": BLOCKTYPE.FOOD,
	},
}

const FOOD = {
	"GOOD_MUSHROOM": BLOCK.GOOD_MUSHROOM,
	"BAD_MUSHROOM": BLOCK.BAD_MUSHROOM,
	"BLACKBERRY": BLOCK.BLACKBERRY,
}

var chunk = []
var loadedChunk = []
var structureData = []
var noise = OpenSimplexNoise.new()
var worldSeed = 0
var worldGenTimer = 5
var distanceFromLastStructure = 0
var distanceFromLastFood = 0
var lastDistance = 0

func sfloor(num): return floor(abs(num)) * (1 if num >= 0 else -1)
func sceil(num): return ceil(abs(num)) * (1 if num >= 0 else -1)

#region CHUNK HANDLER
#!-- CHUNK HANDLER START --

func setChunk(pos, active = true, override = false):
	var newChunk = Chunk.new()
	var chunkExist = false

	for i in chunk.size():
		if chunk[i].chunk_coords == pos:
			if override:
				chunk[i].data = newChunk
			else:
				chunkExist = true
			break

	if chunkExist:
		return null

	chunk.append({
		"chunk_coords": pos,
		"highest_layer": 0,
		"active": active,
		"data": newChunk,
	})

func getChunk(pos):
	var data = null
	for i in chunk.size():
		if chunk[i].chunk_coords == pos:
			data = i
			break
	return data

func deleteChunk(pos):
	var deletedData = null
	for i in chunk.size():
		if chunk[i].chunk_coords == pos:
			chunk[i].active = false
			deletedData = i
	return deletedData

#! -- CHUNK HANDLER END --
#endregion

func setTile(x: int, y: int, block):
	var tilemap = null

	for i in $TileMap.get_children():
		i.set_cell(x, y, -1)

	match (block.type):
		BLOCKTYPE.SOLID:
			tilemap = $TileMap/Solid
		BLOCKTYPE.LIQUID:
			tilemap = $TileMap/Liquid
		BLOCKTYPE.FOOD:
			tilemap = $TileMap/Food

	tilemap.set_cell(x, y, block.id)

func getTile(x: int, y: int):
	var tilemap = -1
	for i in $TileMap.get_children():
		var cell = i.get_cell(x, y)
		if cell == -1:
			continue
		tilemap = cell
	return tilemap

func removeTile(x: int, y: int):
	for i in $TileMap.get_children():
		i.set_cell(x, y, -1)

#region TERRAIN GENRATION
#! -- TERRAIN GENRATION START --

func createLavaPool(x, y, offsetStart, offsetEnd, width, height, lavaHeight):
	var chunk_data = []

	for i in range(x + offsetStart, x + offsetEnd + 1):
		for j in range(y, height):
			var block = null

			if i == x or i == x + width - 1 or j == y + height - 1:
				block = BLOCK.STONE
			elif j == y + height - lavaHeight - 1:
				block = BLOCK.LAVA_HEAD
			elif j > y + height - lavaHeight - 2:
				block = BLOCK.LAVA

			chunk_data.append({
				"x": i - offsetStart,
				"y": j,
				"block": block
			})

	return chunk_data

func createWall(x, y, _offsetStart, _offsetEnd, height):
	var chunk_data = []

	for j in range(y - height + 1, y):

		var block = null

		if j == y - height + 1:
			block = BLOCK.WALL_HEAD
		else:
			block = BLOCK.WALL

		chunk_data.append({
			"x": x,
			"y": j,
			"block": block
		})

	return chunk_data

func createSpike(x, y, offsetStart, offsetEnd, _width):
	var chunk_data = []

	for i in range(x + offsetStart, x + offsetEnd + 1):
		chunk_data.append({
			"x": i - offsetStart,
			"y": y - 1,
			"block": BLOCK.SPIKE
		})

	return chunk_data

func createWaterPool(x, y, offsetStart, offsetEnd, width, height, waterHeight):
	var chunk_data = []

	for i in range(x + offsetStart, x + offsetEnd + 1):
		for j in range(y, y + height):

			var block = null

			if i == x or i == x + width - 1 or j == y + height - 1:
				block = BLOCK.STONE
			elif j == y + height - waterHeight - 1:
				block = BLOCK.WATER_HEAD
			elif j > y + height - waterHeight - 2:
				block = BLOCK.WATER

			chunk_data.append({
				"x": i - offsetStart,
				"y": j,
				"block": block
			})

	return chunk_data

func createCactus(x, y, _offsetStart, _offsetEnd, height):
	var chunk_data = []

	for j in range(y - height + 1, y):
		var block = null

		if j == y - height + 1:
			block = BLOCK.CACTUS_HEAD
		else:
			block = BLOCK.CACTUS

		chunk_data.append({
			"x": x,
			"y": j,
			"block": block
		})

	return chunk_data

#! -- TERRAIN GENRATION END --
#endregion

func getCollidedCell():
	var pos = {
		"left": floor(($Player.position.x + $Player/DCLeft.position.x - $Player/DCLeft/Collision.shape.extents.x) / Global.gridSize),
		"right": floor(($Player.position.x + $Player/DCRight.position.x) / Global.gridSize),
		"up": floor((round($Player.position.y) + $Player/DCTop.position.y - $Player/DCTop/Collision.shape.extents.x) / Global.gridSize),
		"down": floor((round($Player.position.y) + $Player/DCBottom.position.y) / Global.gridSize),
	}

	var points = {
		"left": [],
		"right": [],
		"up": [],
		"down": [],
	}

	for i in range(pos.up, pos.down):
		if $Player.collidedAt.right.collided:
			points.right.append(Vector2(pos.right, i))
		if $Player.collidedAt.left.collided:
			points.left.append(Vector2(pos.left, i))

	for i in range(pos.left + 1, pos.right):
		if $Player.collidedAt.up.collided:
			points.up.append(Vector2(i, pos.up))
		if $Player.collidedAt.down.collided:
			points.down.append(Vector2(i, pos.down))

	return points

func _process(delta):
	$Canvas/HealthLevel.min_value = Global.gameValue.health.min
	$Canvas/HealthLevel.max_value = Global.gameValue.health.max
	$Canvas/HealthLevel.value = Global.getGameValue("health")
	
	$Canvas/HLPS.min_value = Global.gameValue.hlps.min
	$Canvas/HLPS.max_value = Global.gameValue.hlps.max
	$Canvas/HLPS.value = Global.getGameValue("hlps")
	$Canvas/RichTextLabel.text = "X: " + str($Player.position.x) + "\nY: " + str($Player.position.y) + "\n"
	# Handle collision
	var collidedBlock = getCollidedCell()
	var damageFrom = []
	for i in collidedBlock.keys():
		if collidedBlock[i] == []:
			continue
		var layer = $Player.collidedAt[i].layer
		for b in collidedBlock[i]:
			var block = layer.get_cellv(b)
			match layer.name:
				"Solid":
					match block:
						BLOCK.CACTUS.id, BLOCK.CACTUS_HEAD.id:
							damageFrom.append(BLOCK.CACTUS)
							print("I've collided with cactus")
						BLOCK.SPIKE.id:
							damageFrom.append(BLOCK.SPIKE)
							print("I've collided with spike")
				"Food":
					var chealth = Global.getGameValue("health")
					var hlps = Global.getGameValue("hlps")

					var healthEat = Global.healthEffect.health.EAT
					var hlpsEat = Global.healthEffect.hlps.EAT

					var effect_health = 0
					var effect_hlps = 0

					match block:
						BLOCK.GOOD_MUSHROOM.id:
							effect_health = healthEat.GOOD_MUSHROOM
							effect_hlps = hlpsEat.GOOD_MUSHROOM
						BLOCK.BAD_MUSHROOM.id:
							effect_health = healthEat.BAD_MUSHROOM
							effect_hlps = hlpsEat.BAD_MUSHROOM
						BLOCK.BLACKBERRY.id:
							effect_health = healthEat.BLACKBERRY
							effect_hlps = hlpsEat.BLACKBERRY

					Global.setGameValue("health", chealth + effect_health)
					Global.setGameValue("hlps", hlps + effect_hlps)
					removeTile(b.x, b.y)

	worldGenTimer += delta
	#? Handle chunk and terrain generation should be run at a defined interval, not for every single frame
	if worldGenTimer >= Global.newChunkEvery:

		var distance = ($Player.position.x - lastDistance) / Global.gridSize
		lastDistance = $Player.position.x

		var minRenderDistance = round(($Player/Camera.get_viewport_rect().size * $Player/Camera.zoom).x / Global.gridSize / Global.chunkSize)
		var playerChunkCoords = floor($Player.position.x / Global.gridSize / Global.chunkSize)
		var noiseAtCurrentCoord = noise.get_noise_1d($Player.position.x)

		var width = 0
		var height = 0
		#? Generate structure
		if (noiseAtCurrentCoord > 0.3 or noiseAtCurrentCoord < -0.3) and distanceFromLastStructure > Global.minDistanceBetweenStructure:

			#? Handle structure generation
			var structureChoice = STRUCTURE[STRUCTURE.keys()[randi() % STRUCTURE.size()]]
			var structureFunction = ""
			var extraArgs = []

			distanceFromLastStructure = 0
			var x = (playerChunkCoords + minRenderDistance + Global.getGameValue("renderDistance")) * Global.chunkSize
			var y = 0 # Calculated

			match (structureChoice):
				STRUCTURE.CACTUS:
					width = 1
					height = round(rand_range(3, 7))
					structureFunction = "createCactus"
					extraArgs = [height]
				STRUCTURE.WALL:
					width = 1
					height = round(rand_range(3, 7))
					structureFunction = "createWall"
					extraArgs = [height]
				STRUCTURE.SPIKE:
					width = round(rand_range(5, 12))
					height = 1
					structureFunction = "createSpike"
					extraArgs = [width]
				STRUCTURE.LAVAPOOL:
					width = round(rand_range(6, 25))
					height = round(rand_range(3, 10))
					var lavaHeight = round(rand_range(1, height - 2) + 1)
					structureFunction = "createLavaPool"
					extraArgs = [width, y + height, lavaHeight]
				STRUCTURE.WATERPOOL:
					width = round(rand_range(6, 25))
					height = round(rand_range(3, 10))
					var waterHeight = round(rand_range(1, height - 2) + 1)
					structureFunction = "createWaterPool"
					extraArgs = [width, y + height, waterHeight]

			var startChunk = floor(x / Global.chunkSize)
			var startCoord = int(x) % Global.chunkSize
			var amountOfChunk = ceil(float(startCoord + width) / Global.chunkSize)
			var offsetCoord = startCoord
			var offsetStart = 0
			var offsetEnd = clamp(Global.chunkSize - startCoord - 1, 0, width - 1)

			for c in range(0, amountOfChunk):
				var structureExist = false
				for s in structureData:
					if s.chunk_coords == startChunk + c:
						structureExist = true
						break

				if structureExist:
					continue

				var newStructure = null
				var args = [offsetCoord, y, offsetStart, offsetEnd]
				args.append_array(extraArgs)
				newStructure = callv(structureFunction, args)

				structureData.append({
					"chunk_coords": startChunk + c,
					"data": newStructure
				})

				offsetCoord = 0
				offsetStart = offsetEnd + 1
				offsetEnd += clamp(width - (c + 1) * Global.chunkSize, 0, 8)

		else:
			distanceFromLastStructure += distance

		#? Chunk generation and modification
		for i in range(playerChunkCoords - (minRenderDistance + Global.getGameValue("renderDistance")), playerChunkCoords + minRenderDistance + Global.getGameValue("renderDistance")):
			var currentChunk = getChunk(i)

			#? Load chunk if it already exist
			if currentChunk != null:
				if not chunk[currentChunk].active:
					loadedChunk.append(i)
					chunk[currentChunk].active = true

					for c in chunk[currentChunk].data.chunkData:

						if c.block == null:
							continue

						setTile(i * Global.chunkSize + c.coords.x, c.coords.y, c.block)

				continue

			#? Create new chunk
			setChunk(i)
			currentChunk = getChunk(i)
			loadedChunk.append(i)

			#? Generate the terrain
			var posBlock = round(noise.get_noise_1d(i * Global.chunkSize) * Global.fluctuate)
			chunk[currentChunk].highest_layer = posBlock

			for x in range(0, Global.chunkSize):

				chunk[currentChunk].data.setBlockData(x, posBlock, BLOCK.GRASS)
				setTile(i * Global.chunkSize + x, posBlock, BLOCK.GRASS)

				for y in range(posBlock + 1, Global.lowLimit + 1):

					chunk[currentChunk].data.setBlockData(x, y, BLOCK.DIRT)
					setTile(i * Global.chunkSize + x, y, BLOCK.DIRT)

			#? Handle structure placing
			for s in structureData:
				if s.chunk_coords != i or s.data == null:
					continue

				for b in s.data:
					b.y += chunk[currentChunk].highest_layer
					chunk[currentChunk].data.setBlockData(b.x, b.y, b.block, true)

					if b.block == null:
						removeTile(s.chunk_coords * Global.chunkSize + b.x, b.y)
					else:
						setTile(s.chunk_coords * Global.chunkSize + b.x, b.y, b.block)

				structureData.erase(s)

			#? Generate food
			if (noiseAtCurrentCoord > 0.3 or noiseAtCurrentCoord < -0.3) and distanceFromLastFood > Global.minDistanceBetweenFood:
				var randomX = rand_range(0, 7)
				var randomY = rand_range(2, 4)
				var coord = Vector2(i * Global.chunkSize + randomX, posBlock - randomY)
				var randomFood = FOOD[FOOD.keys()[randi() % FOOD.size()]]
				if getTile(coord.x, coord.y) == -1:
					setTile(coord.x, coord.y, randomFood)
				distanceFromLastFood = 0
			else:
				distanceFromLastFood += distance

		#? Clear chunk outside the render distance
		for i in loadedChunk:
			if playerChunkCoords - (minRenderDistance + Global.getGameValue("renderDistance")) > i:
				var pos = deleteChunk(i)
				for c in chunk[pos].data.chunkData.size():
					var coord = chunk[pos].data.chunkData[c].coords
					removeTile(i * Global.chunkSize + coord.x, coord.y)
				loadedChunk.erase(i)

		worldGenTimer = 0

func _ready():
	print($Player/Light.shadow_item_cull_mask)
	$Player.position.x = 160
	lastDistance = 160
	randomize()
	worldSeed = randi()
	noise.seed = worldSeed
	noise.octaves = 4
	noise.period = 128
	noise.persistence = 0.2
	print("Seed: ", worldSeed)


func _on_DamageTimer_timeout():
	var chealth = Global.getGameValue("health")
	var hlps = Global.getGameValue("hlps")
	Global.setGameValue("health", chealth - hlps)
	print(chealth)

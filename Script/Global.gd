extends Node2D

enum GameValueType {
	NUMBER = 0,
	STRING = 1,
	NUMBER_WITH_LIMIT = 2,
}

var gameValue = {
	"hlps": {
		"type": GameValueType.NUMBER_WITH_LIMIT,
		"min": 1,
		"max": 20,
		"value": 1,
	},
	"health": {
		"type": GameValueType.NUMBER_WITH_LIMIT,
		"min": 0,
		"max": 100,
		"value": 100,
	},
	"renderDistance": {
		"type": GameValueType.NUMBER_WITH_LIMIT,
		"min": 5,
		"max": 64,
		"value": 5,
	},
}

# World generation settings
var help = "fdsafads"
const chunkSize = 8
const gridSize = 32
const lowLimit = 16
const highLimit = -47
const newChunkEvery = 0.5
const maxBacktrackLimit = 80
const fluctuate = 2
const spaceBetweenStructure = 18
const fluctuateStructure = 10
const minDistanceBetweenStructure = 32
const minDistanceBetweenFood = 24

# Health settings
const healthEffect = {
	"hlps": {
		"EAT": {
			"GOOD_MUSHROOM": -0.25,
			"BAD_MUSHROOM": 0.5,
			"BLACKBERRY": -0.75,
			"WINTERBERRY": 1,
			"PEACHES": -1,
			"POKEBERRY": 1.5,
			"BEEF": -1.5,
			"BOMB": 5,
		},
		"GO_INTO": {
			"LAVA_POOL": 5,
			"SPIKE": 1,
			"CACTUS": 2,
		},
	},
	"health": {
		"RUN": -0.5,
		"JUMP": -0.75,
		"EAT": {
			"GOOD_MUSHROOM": 3.5,
			"BAD_MUSHROOM": -3.5,
			"BLACKBERRY": 4,
			"WINTERBERRY": -4.5,
			"PEACHES": 5,
			"POKEBERRY": -5,
			"BEEF": 10,
			"BOMB": -50,
		},
		"GO_INTO": {
			"SPIKE": -2,
			"CACTUS": -4,
		}
	}
}

func setGameValue(key, value):
	if not gameValue.has(key):
		return
	match gameValue[key].type:
		GameValueType.NUMBER_WITH_LIMIT:
			if not [TYPE_INT, TYPE_REAL].has(typeof(value)):
				return
			gameValue[key].value = clamp(value, gameValue[key].min, gameValue[key].max)
		GameValueType.NUMBER:
			if not [TYPE_INT, TYPE_REAL].has(typeof(value)):
				return
			gameValue[key].value = value
		GameValueType.STRING:
			gameValue[key].value = value

func getGameValue(key):
	if not gameValue.has(key):
		return
	return gameValue[key].value

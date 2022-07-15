extends KinematicBody2D

var velocity = Vector2.ZERO

const ACCELERATION = 5000
const MAX_SPEED = 350
const RUN_SPEED = 800
const FRICTION = 1500
const RUN_FRICTION = 3300
const JUMP = 1200
const GRAVITY = 3000

var legalLimit = 0

onready var animationPlayer = $AnimationPlayer
onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")

var collidedAt = {
	"left": {
		"collided": false,
		"layer": null,
	},
	"right": {
		"collided": false,
		"layer": null,
	},
	"up": {
		"collided": false,
		"layer": null,
	},
	"down": {
		"collided": false,
		"layer": null,
	},
}

func _physics_process(delta):
	var chealth = Global.getGameValue("health")
	#print(collidedAt)
	var halfOfScreenCamera = ($Camera.get_viewport_rect().size * $Camera.zoom).x / 2

	velocity.y += GRAVITY * delta
	legalLimit = max(legalLimit, position.x - halfOfScreenCamera - Global.maxBacktrackLimit * Global.gridSize)
	$Camera.position.x = max(0, -position.x + legalLimit + halfOfScreenCamera)
	position.x = max($Collision.shape.extents.x + legalLimit, position.x)

	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	input_vector = input_vector.normalized()

	var speed = RUN_SPEED if Input.is_action_pressed("run") else MAX_SPEED
	var friction = RUN_FRICTION if Input.is_action_pressed("run") else FRICTION

	if Input.is_action_pressed("jump") and is_on_floor():
		Global.setGameValue("health", chealth + Global.healthEffect.health.JUMP)
		velocity.y -= JUMP
	if input_vector != Vector2.ZERO:

		animationTree.set("parameters/Idle/blend_position", Vector2(input_vector.x, 0))
		animationTree.set("parameters/Walk/blend_position", Vector2(input_vector.x, 0))
		animationState.travel("Walk")
		$Light.position.x = input_vector.x * 56
		velocity.x = velocity.move_toward(input_vector * speed, ACCELERATION * delta).x
	else:
		if is_on_floor():
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		animationState.travel("Idle")

	if is_on_wall():
		animationState.travel("Idle")

	velocity = move_and_slide(velocity, Vector2.UP)

func _on_DetectCollision_body_entered(body, direction):
	print("yes: ", body, " | ", direction)
	collidedAt[direction].collided = true
	collidedAt[direction].layer = body

func _on_DetectCollision_body_exited(body, direction):
	print("no: ", body, " | ", direction)
	collidedAt[direction].collided = false
	collidedAt[direction].layer = null

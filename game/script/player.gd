extends CharacterBody3D


const SPEED = 10
const JUMP_VELOCITY = 22

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var animation_tree: AnimationTree = $Visual/AnimationTree
@onready var footstep_vfx: GPUParticles3D = $Visual/VFX/Footstep_VFX

const maxHealth = 3
var currentHealth
# 当生命值为0，controllable置为false，player不可控制
var controllable = true  

func _ready() -> void:
	currentHealth = maxHealth

func _process(delta: float) -> void:
	
	handleMovementVFX()
	
	animation_tree.set("parameters/StateMachine/GroundMovement/blend_position",abs(velocity.x))
	animation_tree.set("parameters/StateMachine/Airborne/blend_position",velocity.y)
	
	if is_on_floor():
		animation_tree.changeStateToNormal()
	else:
		animation_tree.changeStateToAirborne()

func _physics_process(delta: float) -> void:
	if controllable == false:
		updateHorizontalVelecity()
		updateVerticalVelocity(delta)
		move_and_slide()
		return
	
	# 左右方向
	if velocity.x != 0:
		var faceRight = velocity.x > 0
		if faceRight:
			$Visual.rotation = Vector3(0,PI/2,0)
		else:
			$Visual.rotation = Vector3(0,-PI/2,0)
	# Add the gravity.
	if not is_on_floor():
		updateVerticalVelocity(delta)

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		playerLandingVFX()

	var horizontalInput = Input.get_axis("move_left","move_right")
	
	if horizontalInput:
		velocity.x = horizontalInput * SPEED
	else:
		updateHorizontalVelecity()

	move_and_slide()

func handleMovementVFX():
	if is_on_floor():
		if velocity.x != 0:
			footstep_vfx.emitting = true
		else:
			footstep_vfx.emitting = false
	else:
		footstep_vfx.emitting = false
		
	if is_on_floor():
		if animation_tree.checkIfStateIsAirborne():
			playerLandingVFX()

func playerLandingVFX():
	var vfxToSpawn = preload("res://Asset/VFX/Scene/land_vfx.tscn")
	var vfxInstance = vfxToSpawn.instantiate()
	get_tree().get_root().get_node("Root").add_child(vfxInstance)
	vfxInstance.global_position = global_position + Vector3(0, 0.3, 0.2)
	vfxInstance.restart()
	# 0.6秒后释放vfx节点
	await get_tree().create_timer(0.6).timeout
	vfxInstance.queue_free()
	
	
func applyDamage():
	if currentHealth == 0:
		return
	
	currentHealth -= 1
	controllable = false
	
	if currentHealth <= 0:
		animation_tree.changeStateToDead()
	else:
		await get_tree().create_timer(0.9).timeout
		controllable = true
	
	
func updateHorizontalVelecity():
	velocity.x = move_toward(velocity.x, 0, 1)
	
func updateVerticalVelocity(delta):
	velocity.y -= gravity * delta *8
	
	
	
	

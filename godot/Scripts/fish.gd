class_name Fish
extends RigidBody2D

##Managing fish in inventory

enum FishType {
	TRILOBITE,
	PIKAIA,
	CALLICHIMAERA,
	MOYTHOMASIA,
	XENACANTHUS,
	OSTEOLEPIS,
}

@export var falling_speed : float = 120.0
@export var horizontal_speed : float = 200.0
@export var inventory_grid : InventoryGrid

@onready var collision: CollisionPolygon2D = $CollisionPolygon2D


var is_dragging: bool = false #State of dragging fish
var drag_offset: Vector2 = Vector2.ZERO #Fish center position - mouse position
var landing_pending: bool = false #Recording collision with another object

var occupied_cells: Array[Vector2i] = []
var footprint: Array[Vector2i] = [Vector2i.ZERO]
var fish_texture: Texture2D
var pending_turns := 0 #For rotation


func _ready() -> void:
	gravity_scale = 0.0 #Set gravity to 0
	freeze = true #Lock fish movement
	if fish_texture != null: #Control fish have a texture
		$Sprite2D.texture = fish_texture #Assign the texture at sprite
	
	#Resize correctly the fish with cellsize and create the collision polygon
	fit_sprite_to_cell(get_footprint_bounds(footprint), inventory_grid.cell_size)


#Start falling
func start_fall() -> void:
	pending_turns = 0 #Rotation reset
	freeze = false #Freezing off


func _physics_process(_delta: float) -> void:
	if is_dragging:
		global_position = drag_offset + get_global_mouse_position()
	#Handle a pending landing while the fish is still falling
	if not freeze and landing_pending:
		#Get the width and height of the current footprint in cells
		var bounds := get_footprint_bounds(footprint)
		#Use the global center of cell (0,0) as a reference
		var first_center := inventory_grid.get_global_cell_center(Vector2i.ZERO)
		#Convert the cell counts to the last cell index on each axis
		#For a 2 x 2 footprint, the last index is (1,1)
		var last_index := bounds - Vector2i.ONE
		#Get a global center of the cell at the opposite corner
		var last_center := inventory_grid.get_global_cell_center(last_index)
		#Halve the displacement to get the offset from the first cell
		# center to the center of the whole footprint
		var center_offset := (last_center - first_center) / 2
		#Subtract the offset to find the anchor point from the fish's center
		var anchor_point := global_position - center_offset
		#Convert that global point to an integer grid coordinate
		var anchor := inventory_grid.global_to_cell(anchor_point)
		#Get every cell the fish would occupy at this anchor
		var cells := get_cells_at_anchor(anchor)
		#Place the fish only if every requested cell is aviable
		if inventory_grid.gridData.place_cells(cells):
			#Store the grid cells occupied by fish
			occupied_cells.assign(cells)
			#Stop the fish after a successful placement
			freeze = true
			#Add the same offset to the exact anchor center to snap the fish into place
			global_position = inventory_grid.get_global_cell_center(anchor) + center_offset
			#Refresh the grid drawing and log the occupied cells
			inventory_grid.queue_redraw()
			print("Fish placed: ", occupied_cells)
		else:
			#Log the cells that were requested for the rejected placement
			print("Placement rejected: ", cells)
			
		#Clear the pending flag after handling the landing attempt
		landing_pending = false
		


#Function to resize correctly fish's sprite and his collision's shape
func fit_sprite_to_cell(bounds_in_cell: Vector2i, cell_size: int) -> void:
	#Convert cell space to pixel
	var new_pixel := bounds_in_cell * cell_size
	#Measure png size
	var sprite: Sprite2D = $Sprite2D #Reference to sprite
	var texture: Texture2D = sprite.texture #Get the sprite's texture
	var image: Image = texture.get_image() #Get the texture's image
	var rect: Rect2i = image.get_used_rect() #Get only the used rect about image
	
	if not rect.has_area(): #Rect control
		return
	
	#Check the center about rect
	var crop_center := Vector2(rect.size) / 2.0
	print("Rect center: ", crop_center)
	
	sprite.region_rect = Rect2(rect) #Set the rect in sprite proprerties
	sprite.region_enabled = true #Set region enabled
	
	var width_scale_ratio: float = float(new_pixel.x) / rect.size.x #New scale ratio for sprite
	var height_scale_ratio: float = float(new_pixel.y) / rect.size.y #New scale ratio for sprite
	
	var minimum_scale_ratio: float = min(width_scale_ratio, height_scale_ratio) #Save the minimum scale from x and Y
	
	sprite.scale = Vector2(minimum_scale_ratio, minimum_scale_ratio) #Set the new scale to sprite's scale
	
	var outline := get_sprite_outline(image, rect) #Get the sprite outliner
	
	print((outline[0][0] - crop_center) * minimum_scale_ratio)
	
	var packed := PackedVector2Array()
	
	for point in outline[0]:
		packed.append((point - crop_center) * minimum_scale_ratio)
	
	collision.polygon = packed


#Get the sprite outliner
func get_sprite_outline(image: Image, rect: Rect2i) -> Array[PackedVector2Array]:
	#Rect control
	if not rect.has_area():
		return []
	
	var mask: BitMap = BitMap.new() #Create a empty BitMap
	mask.create_from_image_alpha(image, 0.5) #Collect the colored pixel from image
	#Create an Array of polygon covering a rectangular portion of a BitMap
	var outline := mask.opaque_to_polygons(rect)
	
	return outline

#Control fish's velocity and movement
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	#Apply requested turns before the fish landing
	if not freeze and not landing_pending and pending_turns != 0:
		var clockwise := pending_turns > 0
		#Rotate the footprint once for each requested quarter-turn
		for _turn in range(absi(pending_turns)):
			footprint.assign(get_rotate_footprint(clockwise))
		
		#Rotate the body around its own center
		state.transform = state.transform.rotated_local(pending_turns * PI / 2.0)
	
	#Clear the request
	pending_turns = 0
	
	var direction := Input.get_axis("ui_left" , "ui_right")
	state.linear_velocity = Vector2(direction * horizontal_speed, falling_speed)


#Manage click on fish
func _input(event: InputEvent) -> void:
	#Block input when fish is correctly placed
	if not occupied_cells.is_empty():
		return
	
	#Rotation fish
	if not freeze:
		if event.is_action_pressed("rotate_fish_ccw"):
			#Anti-clockwise
			pending_turns -= 1
		elif event.is_action_pressed("rotate_fish_cw"):
			#Clockwise
			pending_turns += 1
	
	#Check the input event
	if not is_dragging:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			var mouse_pos := collision.get_local_mouse_position()
		
			if Geometry2D.is_point_in_polygon(mouse_pos, collision.polygon):
				print("Fish clicked")
				is_dragging = true
				drag_offset = global_position - get_global_mouse_position() #Calculate click point
				freeze = true #Freezing on (gravity off)
	else:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			print("Fish released")
			global_position = drag_offset + get_global_mouse_position() #Update mouse position
			is_dragging = false
			start_fall() #Unlock the fish movement


#Get the fish's occupied cell (dimension of a fish)
func get_footprint_bounds(_footprint: Array[Vector2i]) -> Vector2i:
	var max_x := -1
	var max_y := -1
	
	for cell in _footprint:
		max_x = maxi(max_x, cell.x) #Update x
		max_y = maxi(max_y, cell.y) #Update y
		
	return Vector2i(max_x +1, max_y +1)


#Get rotated footprint
func get_rotate_footprint(clockwise: bool) -> Array[Vector2i]:
	#Create an empty array
	var cells: Array[Vector2i] = []
	var bounds := get_footprint_bounds(footprint)
	
	for offset in footprint:
		#If rotation is clockwise
		if clockwise:
			var new_x := bounds.y - 1 - offset.y
			var new_y := offset.x
			cells.append(Vector2i(new_x,new_y))
			#If rotation is anti-clockwise
		else:
			var new_x := offset.y
			var new_y := bounds.x -1 - offset.x
			cells.append(Vector2i(new_x,new_y))
			
	return cells


#Get anchor for fish (up-left cell)
func get_cells_at_anchor(anchor: Vector2i) -> Array[Vector2i]:
	#Create empty array
	var cells: Array[Vector2i] = []
	#Scroll the footprint cells
	for offset in footprint:
		#Add columns with columns and rows with rows
		cells.append(anchor + offset)
	
	return cells


func _on_body_entered(body: Node) -> void:
	if not freeze:
		if body.name == "InventoryFloor" or body is Fish:
			landing_pending = true

extends Control


## Script for manage and drawing inventory grid

@export var cell_size : int
var grid_start_point : Vector2 = Vector2.ZERO


#Calculate the correct grid's cell quantity
func grid_cell_quantity_calc() -> Vector2i:
	return Vector2i(
			floor(size.x / cell_size),#Horizontal
			floor(size.y / cell_size),#Vertical
	)


#Calculate the correct grid's dimension
func grid_dimension_calc() -> Vector2:
	var grid_cells := grid_cell_quantity_calc()
	return Vector2(
			grid_cells.x * cell_size,#Horizontal
			grid_cells.y * cell_size,#Vertical
	)


#Calculate the grid's start point (for center the grid)
func grid_origin_calc() -> Vector2:
	var grid_dimension := grid_dimension_calc()
	return Vector2(
			(size.x - grid_dimension.x) / 2,#Horizontal centered
			(size.y - grid_dimension.y) / 2,#Vertical centered
	)


#Setup drawing grid
func drawing_grid() -> void:
	#In first, we need to calculate grid dimension
	var grid_cells = grid_cell_quantity_calc()
	var grid_size = grid_dimension_calc()
	var grid_origin = grid_origin_calc()
	
	#Drawing the vertical lines
	for line in grid_cells.x + 1:
		#Calc the x position of line
		var x = grid_origin.x + (line * cell_size)
		#Calc the line's start point
		var start_point := Vector2(x, grid_origin.y)
		#Calc the line's end point 
		var end_point := Vector2(x, grid_origin.y + grid_size.y)
		#Draw the line
		draw_line(start_point, end_point, Color.BLACK, 3.0)
	
	#Drawing the horizontal lines
	for line in grid_cells.y + 1:
		#Calc the y position of line
		var y = grid_origin.y + (line * cell_size)
		#Calc the line's start point
		var start_point := Vector2(grid_origin.x, y)
		#Calc the line's end point
		var end_point := Vector2(grid_origin.x + grid_size.x, y)
		#Draw the line
		draw_line(start_point, end_point, Color.BLACK, 3.0)


#Draw grid
func _draw() -> void:
	drawing_grid()

#Signal emitted when control node change size
func _on_resized() -> void:
	if size.x == 0 or size.y == 0:
		return
	print(grid_cell_quantity_calc())
	print(grid_dimension_calc())
	print(grid_origin_calc())
	queue_redraw()

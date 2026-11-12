class_name GridData
extends RefCounted

##Script for manage the grid's data

var grid: Array = []

var test_cell := Vector2i(1,0)

#Enum for cell state in inventory grid
enum CellState {
	INVALID = -1, #Cell position is out of grid
	EMPTY = 0, #Cell is empty
	OCCUPIED = 1, #Cell is occupied
}


func initialize_grid(grid_size : Vector2i) -> void:
	#Clean the array
	grid = []
	
	#In the Vector2i x are columns, y are rows
	
	#Creating bidimensional grid's array
	#For each rows, create an array
	for rows in grid_size.y:
		grid.append([])
		
		for columns in grid_size.x:
			grid[rows].append(CellState.EMPTY)


#Function for setting a value in a cell on bidimensional array
func set_cell(cell_position: Vector2i, value: CellState) -> bool:
	#Cell control
	if not is_valid_cell(cell_position):
		return false
	
	#Check the value is correct and not invalid
	if value != CellState.EMPTY and value != CellState.OCCUPIED:
		return false
	
	#In the Vector2i x are columns, y are rows
	grid[cell_position.y][cell_position.x] = value
	
	return true


#Cell validate control
func is_valid_cell(cell_position: Vector2i) -> bool:
	#If array is empty
	if grid.is_empty():
		return false
	
	#In the Vector2i x are columns, y are rows
	if cell_position.x < 0 or cell_position.y < 0 or cell_position.x >= grid[0].size() or cell_position.y >= grid.size():
		return false
	
	#If all is correct, return true
	return true


#Function for get cell state
func get_cell(cell_position: Vector2i) -> CellState:
	#Cell control
	if not is_valid_cell(cell_position):
		return CellState.INVALID
	
	#In vector2i x are columns, y are rows
	return grid[cell_position.y][cell_position.x]


#Debugging
func inventory_debug() -> void:
	for row in grid:
		var row_names: Array[String] = []
		
		for cell in row:
			row_names.append(CellState.find_key(cell))
		
		print(row_names)
	
	match get_cell(test_cell):
		CellState.EMPTY:
			print("La cella è libera / Cell is EMPTY")
		CellState.OCCUPIED:
			print("La cella è occupata / Cell is OCCUPIED")
		CellState.INVALID:
			print("La cella non è valida / Cell is INVALID")

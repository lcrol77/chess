extends Sprite2D

const BOARD_SIZE = 8
const CELLL_WIDTH = 18
const OFFSET = (4 * CELLL_WIDTH)

const BLACK_BISHOP = preload("res://assets/black_bishop.png")
const BLACK_KING = preload("res://assets/black_king.png")
const BLACK_KNIGHT = preload("res://assets/black_knight.png")
const BLACK_PAWN = preload("res://assets/black_pawn.png")
const BLACK_QUEEN = preload("res://assets/black_queen.png")
const BLACK_ROOK = preload("res://assets/black_rook.png")
const WHITE_BISHOP = preload("res://assets/white_bishop.png")
const WHITE_KING = preload("res://assets/white_king.png")
const WHITE_KNIGHT = preload("res://assets/white_knight.png")
const WHITE_PAWN = preload("res://assets/white_pawn.png")
const WHITE_QUEEN = preload("res://assets/white_queen.png")
const WHITE_ROOK = preload("res://assets/white_rook.png")

const TURN_BLACK = preload("res://assets/turn-black.png")
const TURN_WHITE = preload("res://assets/turn-white.png")
const PIECE_MOVE = preload("res://assets/Piece_move.png")
const TEXTURE_HOLDER = preload("res://scenes/texture_holder.tscn")

@onready var pieces: Node2D = $Pieces
@onready var dots: Node2D = $Dots
@onready var turn: Sprite2D = $Turn

var board: Array
var whiteToPlay: bool = true
var state: bool = false
var moves = []
var selected_piece: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	board.append([4,2,3,5,6,3,2,4])
	board.append([1,1,1,1,1,1,1,1])
	for i in range(4):
		board.append([0,0,0,0,0,0,0,0])
		
	board.append([-1,-1,-1,-1,-1,-1,-1,-1])
	board.append([-4,-2,-3,-5,-6,-3,-2,-4])
	display_board()

func display_board() -> void:
	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			var holder = TEXTURE_HOLDER.instantiate()
			pieces.add_child(holder)
			holder.global_position = Vector2(j* CELLL_WIDTH + (CELLL_WIDTH/2), -i * CELLL_WIDTH - (CELLL_WIDTH/2))
			match board[i][j]:
				-6: holder.texture = BLACK_KING
				-5: holder.texture = BLACK_QUEEN
				-4: holder.texture = BLACK_ROOK
				-3: holder.texture = BLACK_BISHOP
				-2: holder.texture = BLACK_KNIGHT
				-1: holder.texture = BLACK_PAWN
				0: holder.texture  = null
				6: holder.texture  = WHITE_KING
				5: holder.texture  = WHITE_QUEEN
				4: holder.texture  = WHITE_ROOK
				3: holder.texture  = WHITE_BISHOP
				2: holder.texture  = WHITE_KNIGHT
				1: holder.texture  = WHITE_PAWN

func _input(event) -> void:
	if event is InputEventMouseButton && event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_mouse_out(): return
			var _pos_x = snapped(get_global_mouse_position().x,0) / CELLL_WIDTH
			var _pos_y = abs(snapped(get_global_mouse_position().y,0)) / CELLL_WIDTH
			if !state && (whiteToPlay && board[_pos_y][_pos_x] > 0 || !whiteToPlay && board[_pos_y][_pos_x] < 0):
				selected_piece = Vector2(_pos_y, _pos_x)
				state = true
				show_options()


# checks if mouse is withing x and y bounds
func is_mouse_out():
	if get_global_mouse_position().x < 0 || get_global_mouse_position().x > 144 || get_global_mouse_position().y > 0 || get_global_mouse_position().y < -144: return true
	return false

func show_options() -> void:
	moves = get_moves()
	if moves == []:
		state = false
		return
	show_dots()

func get_moves()->Array:
	match abs(board[selected_piece.x][selected_piece.y]):
		6: print("King")
		5: print("Queen")
		4: print("rook")
		3: print("bishop")
		2: print("knight")
		1: print("Pawn")
	return []

func get_rook_moves() -> Array:
	var _moves = []
	var directions = [Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0)]
	
	return _moves

func show_dots() -> void:
	for i in moves: 
		var holder = TEXTURE_HOLDER.instantiate()
		dots.add_child(holder)
		holder.texture = PIECE_MOVE
		holder.global_position = Vector2(i.y *CELLL_WIDTH + (CELLL_WIDTH/2),-i.x *CELLL_WIDTH - (CELLL_WIDTH/2))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

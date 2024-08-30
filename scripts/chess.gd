extends Sprite2D

const BOARD_SIZE = 8
const CELLL_WIDTH = 18
const OFFSET = (4 * CELLL_WIDTH)

const BISHOP_DIRECTIONS  = [Vector2(1,1),Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1)]
const ROOK_DIRECTIONS  = [Vector2(1,0),Vector2(0,-1),Vector2(0,1),Vector2(-1,0)]
const KNIGHT_DIRECTIONS = [Vector2(2,1),Vector2(2,-1),Vector2(1,2),Vector2(-1,2),Vector2(-2,1),Vector2(-2,-1),Vector2(1,-2),Vector2(-1,-2)]

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
@onready var white_pieces: Control = $"../CanvasLayer/white_pieces"
@onready var black_pieces: Control = $"../CanvasLayer/black_pieces"

var board: Array
var whiteToPlay: bool = true
var state: bool = false
var moves = []
var selected_piece: Vector2

var promotion_square = null;

var white_king_has_moved = false
var black_king_has_moved = false
var white_rook_right_has_moved = false
var white_rook_left_has_moved = false
var black_rook_right_has_moved = false
var black_rook_left_has_moved = false

var en_passant = null

var white_king_pos := Vector2(0,4)
var black_king_pos := Vector2(7,4)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	board.append([4,2,3,5,6,3,2,4])
	board.append([1,1,1,1,1,1,1,1])
	board.append([0,0,0,0,0,0,0,0])
	board.append([0,0,0,0,0,0,0,0])
	board.append([0,0,0,0,0,0,0,0])
	board.append([0,0,0,0,0,0,0,0])
	board.append([-1,-1,-1,-1,-1,-1,-1,-1])
	board.append([-4,-2,-3,-5,-6,-3,-2,-4])
	display_board()
	
	var white_buttons:Array[Node]  = get_tree().get_nodes_in_group("white_pieces")
	var black_buttons:Array[Node] = get_tree().get_nodes_in_group("black_pieces")
	
	for button: Button in white_buttons + black_buttons:
		button.pressed.connect(self._on_button_pressed.bind(button))

func display_board() -> void:
	for child in pieces.get_children():
		child.queue_free()
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
	if whiteToPlay:
		turn.texture = TURN_WHITE
	else: 
		turn.texture = TURN_BLACK

func _input(event) -> void:
	if event is InputEventMouseButton && event.pressed && promotion_square == null:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_mouse_out(): return
			var _pos_x = snapped(get_global_mouse_position().x,0) / CELLL_WIDTH
			var _pos_y = abs(snapped(get_global_mouse_position().y,0)) / CELLL_WIDTH
			if !state && (whiteToPlay && board[_pos_y][_pos_x] > 0 || !whiteToPlay && board[_pos_y][_pos_x] < 0):
				selected_piece = Vector2(_pos_y, _pos_x)
				state = true
				show_options()
			elif state:
				set_move(_pos_y, _pos_x)

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
	var _moves = []
	match abs(board[selected_piece.x][selected_piece.y]):
		6: _moves = get_king_moves(ROOK_DIRECTIONS + BISHOP_DIRECTIONS)
		5: _moves = get_moves_for_inf_pieces(ROOK_DIRECTIONS + BISHOP_DIRECTIONS)
		4: _moves = get_moves_for_inf_pieces(ROOK_DIRECTIONS)
		3: _moves = get_moves_for_inf_pieces(BISHOP_DIRECTIONS)
		2: _moves = get_moves_for_movement_limited_pieces(KNIGHT_DIRECTIONS)
		1: _moves = get_pawn_moves()
	return _moves

func get_pawn_moves()-> Array:
	var _moves = []
	var direction
	var is_first_move = whiteToPlay && selected_piece.x == 1 || !whiteToPlay && selected_piece.x ==6
	if whiteToPlay:
		direction = Vector2(1,0)
	else:
		direction = Vector2(-1,0)
	
	if en_passant != null &&  (whiteToPlay && selected_piece.x == 4 || !whiteToPlay &&selected_piece.x == 3) && abs(en_passant.y - selected_piece.y) == 1:
		_moves.append(en_passant + direction)
		
	var pos = selected_piece + direction
	if is_empty(pos):
		_moves.append(pos)
	pos = selected_piece + direction*2
	if is_first_move && is_empty(pos) && is_empty(selected_piece + direction):
		_moves.append(pos)
	
	pos = selected_piece + Vector2(direction.x, 1)
	if is_valid_position(pos) && is_enemy(pos):
		_moves.append(pos)
	pos = selected_piece + Vector2(direction.x, -1)
	if is_valid_position(pos) && is_enemy(pos):
		_moves.append(pos)
	
	return _moves
		
func get_moves_for_inf_pieces(directions: Array) -> Array:
	var _moves = []
	for i in directions:
		var pos = selected_piece
		pos += i
		while is_valid_position(pos):
			if is_empty(pos):
				_moves.append(pos)
			elif is_enemy(pos):
				_moves.append(pos)
				break
			else:
				break
			pos += i
	return _moves

func get_moves_for_movement_limited_pieces(directions: Array) -> Array:
	var _moves = []
	for i in directions:
		var pos = selected_piece + i
		if is_valid_position(pos):
			if is_empty(pos):
				_moves.append(pos)
			elif is_enemy(pos):
				_moves.append(pos)
	return _moves

func get_king_moves(directions: Array) -> Array:
	var _moves = []
	
	if whiteToPlay:
		board[white_king_pos.x][white_king_pos.y] = 0
	else:
		board[black_king_pos.x][black_king_pos.y] = 0
	for i in directions:
		var pos = selected_piece + i
		if is_valid_position(pos):
			if !is_in_check(pos):
				if is_empty(pos):
					_moves.append(pos)
				elif is_enemy(pos):
					_moves.append(pos)

	if whiteToPlay && !white_king_has_moved:
		if !white_rook_left_has_moved && is_empty(Vector2(0,1)) && is_empty(Vector2(0,2)) && is_empty(Vector2(0,3)):
			_moves.append(Vector2(0,2))
		if !white_rook_right_has_moved && is_empty(Vector2(0,5)) && is_empty(Vector2(0,6)):
			_moves.append(Vector2(0,6))
	elif !whiteToPlay && !black_king_has_moved:
		if !black_rook_left_has_moved && is_empty(Vector2(7,1)) && is_empty(Vector2(7,2)) && is_empty(Vector2(7,3)):
			_moves.append(Vector2(7,2))
		if !black_rook_right_has_moved && is_empty(Vector2(7,5)) && is_empty(Vector2(7,6)):
			_moves.append(Vector2(7,6))
	if whiteToPlay:
		board[white_king_pos.x][white_king_pos.y] = 6
	else:
		board[black_king_pos.x][black_king_pos.y] = -6
	return _moves

func is_valid_position(pos: Vector2) -> bool:
	if pos.x >=0 && pos.x < BOARD_SIZE &&pos.y >=0 && pos.y < BOARD_SIZE: return true
	return false

func is_empty(pos: Vector2) -> bool:
	return board[pos.x][pos.y] == 0

func is_enemy(pos: Vector2) -> bool:
	return whiteToPlay && board[pos.x][pos.y] < 0 || !whiteToPlay && board[pos.x][pos.y] > 0

func show_dots() -> void:
	for i in moves: 
		var holder = TEXTURE_HOLDER.instantiate()
		dots.add_child(holder)
		holder.texture = PIECE_MOVE
		holder.global_position = Vector2(i.y *CELLL_WIDTH + (CELLL_WIDTH/2),-i.x *CELLL_WIDTH - (CELLL_WIDTH/2))

func delete_dots():
	for child in dots.get_children():
		child.queue_free()

func set_move(_pos_y, _pos_x) -> void:
	var just_now = false
	for i in moves:
		if i.x == _pos_y && i.y == _pos_x:
			match board[selected_piece.x][selected_piece.y]:
				1:
					if i.x == 7: promote(i)
					if i.x == 3 && selected_piece.x == 1:
						en_passant = i
						just_now = true
					elif en_passant != null:
						if en_passant.y== i.y && selected_piece.y!= i.y && en_passant.x ==selected_piece.x:
							board[en_passant.x][en_passant.y] = 0
				-1:
					if i.x == 0:
						promote(i)
					if i.x == 4 && selected_piece.x == 6:
						en_passant = i
						just_now = true
					elif en_passant != null:
						if en_passant.y== i.y && selected_piece.y!= i.y && en_passant.x ==selected_piece.x:
							board[en_passant.x][en_passant.y] = 0
				4:
					if selected_piece.x == 0 && selected_piece.y ==0: white_rook_left_has_moved = true
					if selected_piece.x == 0 && selected_piece.y ==7: white_rook_right_has_moved = true
				-4:
					if selected_piece.x == 7 && selected_piece.y ==0: black_rook_left_has_moved = true
					if selected_piece.x == 7 && selected_piece.y ==7: black_rook_right_has_moved = true
				6:
					if selected_piece.x == 0 && selected_piece.y == 4:
						white_king_has_moved = true
						if i.y==2:
							white_rook_left_has_moved = true
							white_rook_right_has_moved = true
							board[0][0] = 0
							board[0][3] = 4
						elif i.y==6:
							white_rook_left_has_moved = true
							white_rook_right_has_moved = true
							board[0][7] = 0
							board[0][5] = 4
					white_king_pos = i
				-6:
					if selected_piece.x == 7 && selected_piece.y == 4:
						black_king_has_moved = true
						if i.y==2:
							black_rook_left_has_moved = true
							black_rook_right_has_moved = true
							board[7][7] = 0
							board[7][3] = -4
						elif i.y==6:
							black_rook_left_has_moved = true
							black_rook_right_has_moved = true
							board[7][7] = 0
							board[7][5] = -4
					black_king_pos = i

			if !just_now: en_passant = null
			board[_pos_y][_pos_x] = board[selected_piece.x][selected_piece.y]
			board[selected_piece.x][selected_piece.y] = 0
			whiteToPlay = !whiteToPlay
			display_board()
			break
	delete_dots()
	state = false

func is_in_check(king_pos: Vector2) -> bool:
	var directions: Array = BISHOP_DIRECTIONS + ROOK_DIRECTIONS
	var pawn_direction = 1 if whiteToPlay else -1
	var pawn_attacks = [
		king_pos + Vector2(pawn_direction, 1),
		king_pos + Vector2(pawn_direction, 1)
	]
	for i in pawn_attacks:
		if is_valid_position(i):
			if whiteToPlay && board[i.x][i.y] == -1 || !whiteToPlay&& board[i.x][i.y] == 1: return true
	for direction in directions:
		var pos = king_pos + direction
		if is_valid_position(pos):
			if whiteToPlay && board[pos.x][pos.y] == -6 || !whiteToPlay && board[pos.x][pos.y] == 6:return true
	for direction in directions:
		var pos = king_pos + direction
		while is_valid_position(pos):
			if !is_empty(pos):
				var piece = board[pos.x][pos.y]
				# in order for a horizontal / vertical peice to be attacking us we need x OR y to be zero
				if (direction.x == 0 || direction.y ==0) && (whiteToPlay && piece in [-4,-5]) ||(!whiteToPlay && piece in [4,5]): return true
				elif (direction.x != 0 && direction.y !=0) && (whiteToPlay && piece in [-3,-5]) ||(!whiteToPlay && piece in [3,5]): return true
				break
			pos += direction
	for direction in KNIGHT_DIRECTIONS:
		var pos = king_pos + direction
		if is_valid_position(pos):
			if (whiteToPlay && board[pos.x][pos.y] ==-2) || (!whiteToPlay && board[pos.x][pos.y] == 2): return true
			
	return false

func promote(move: Vector2) -> void:
	promotion_square = move
	white_pieces.visible = whiteToPlay
	black_pieces.visible = !whiteToPlay

func _on_button_pressed(button: Button) -> void:
	var num_char = int(button.name.substr(0,1))
	board[promotion_square.x][promotion_square.y] = -num_char if whiteToPlay else num_char
	white_pieces.visible = false
	white_pieces.visible = false
	promotion_square = null
	display_board()

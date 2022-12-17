@tool
extends Node2D

const DRAG_THRESHOLD := 2.0

signal drag_begin()
signal drag_update(pos: Vector2)
signal drag_end(cancel: bool)
#signal pointer(entered: bool)

var _pressed: bool
var _pressed_pointer_pos: Vector2
var _pressed_pos: Vector2
var _drag: bool

@onready var _button: BaseButton = $Button


func _process(_delta: float) -> void:
	global_scale = Vector2.ONE
	global_rotation = 0.0
	var pointer_pos := get_global_mouse_position()
	if _pressed:
		var delta := pointer_pos - _pressed_pointer_pos
		if delta.length_squared() >= (DRAG_THRESHOLD * DRAG_THRESHOLD):
			if !_drag:
				drag_begin.emit()
				_drag = true

			global_position = _pressed_pos + delta
			drag_update.emit(position)

			if Input.is_key_pressed(KEY_ESCAPE) || Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
				_stop(true)


func _stop(cancel: bool) -> void:
	_pressed = false
	_button.set_pressed_no_signal(false)
	if _drag:
		if cancel:
			global_position = _pressed_pos
		drag_end.emit(cancel)
		_drag = false


func _on_button_down() -> void:
	_pressed = true
	_drag = false
	_pressed_pos = global_position
	_pressed_pointer_pos = get_global_mouse_position()


func _on_button_up() -> void:
	if _pressed:
		_stop(false)

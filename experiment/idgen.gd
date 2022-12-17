@tool
extends EditorScript

var entities: Array[int]

var idrng := RandomNumberGenerator.new()

var collisions := 0

func genid() -> int:
	var id := idrng.randi() | idrng.randi() << 31
	while id <= 0 || entities.has(id):
		id = idrng.randi() | idrng.randi() << 31
		collisions += 1
	return id


func genid32() -> int:
	var id := idrng.randi()
	while id <= 0 || entities.has(id):
		id = idrng.randi()
		collisions += 1
	return id


func test_calln(f: Callable, n: int) -> void:
	entities.clear()
	for _i in range(n):
		var id: int = f.call()
		entities.push_back(id)
	print("\tdone (%d): %d collisions" % [ entities.size(), collisions ])

func test_32(n: int) -> void:
	print("generating %d 32-bit IDs..." % n)
	entities.clear()
	for _i in range(n):
		var id := genid32()
		entities.push_back(id)
	print("\tdone (%d): %d collisions" % [ entities.size(), collisions ])

# Called when the script is executed (using File -> Run in Script Editor).
func _run() -> void:
	test_32(50000)
#	var n := 50
#	print("generating IDs ...")
#	for _i in range(n):
#		var id := genid()
#		entities.push_back(id)
#	print("done (%d): %d collisions" % [ entities.size(), collisions ])


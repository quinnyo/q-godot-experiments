extends Control

enum GodotMonitor {
	TIME_FPS = Performance.TIME_FPS,
	TIME_PROCESS = Performance.TIME_PROCESS,
	TIME_PHYSICS_PROCESS = Performance.TIME_PHYSICS_PROCESS,
	MEMORY_STATIC = Performance.MEMORY_STATIC,
	MEMORY_STATIC_MAX = Performance.MEMORY_STATIC_MAX,
	MEMORY_MESSAGE_BUFFER_MAX = Performance.MEMORY_MESSAGE_BUFFER_MAX,
	OBJECT_COUNT = Performance.OBJECT_COUNT,
	OBJECT_RESOURCE_COUNT = Performance.OBJECT_RESOURCE_COUNT,
	OBJECT_NODE_COUNT = Performance.OBJECT_NODE_COUNT,
	OBJECT_ORPHAN_NODE_COUNT = Performance.OBJECT_ORPHAN_NODE_COUNT,
	RENDER_TOTAL_OBJECTS_IN_FRAME = Performance.RENDER_TOTAL_OBJECTS_IN_FRAME,
	RENDER_TOTAL_PRIMITIVES_IN_FRAME = Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME,
	RENDER_TOTAL_DRAW_CALLS_IN_FRAME = Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME,
	RENDER_VIDEO_MEM_USED = Performance.RENDER_VIDEO_MEM_USED,
	RENDER_TEXTURE_MEM_USED = Performance.RENDER_TEXTURE_MEM_USED,
	RENDER_BUFFER_MEM_USED = Performance.RENDER_BUFFER_MEM_USED,
	PHYSICS_2D_ACTIVE_OBJECTS = Performance.PHYSICS_2D_ACTIVE_OBJECTS,
	PHYSICS_2D_COLLISION_PAIRS = Performance.PHYSICS_2D_COLLISION_PAIRS,
	PHYSICS_2D_ISLAND_COUNT = Performance.PHYSICS_2D_ISLAND_COUNT,
	PHYSICS_3D_ACTIVE_OBJECTS = Performance.PHYSICS_3D_ACTIVE_OBJECTS,
	PHYSICS_3D_COLLISION_PAIRS = Performance.PHYSICS_3D_COLLISION_PAIRS,
	PHYSICS_3D_ISLAND_COUNT = Performance.PHYSICS_3D_ISLAND_COUNT,
	AUDIO_OUTPUT_LATENCY = Performance.AUDIO_OUTPUT_LATENCY,
}


var items := [
	{
		"name": "FPS",
		"engine_monitor": Performance.TIME_FPS,
		"format": "%10.2f",
	},
	{
		"name": "process",
		"engine_monitor": Performance.TIME_PROCESS,
		"scale": 1000.0,
		"format": "%10.3fms",
	},
	{
		"name": "physics",
		"engine_monitor": Performance.TIME_PHYSICS_PROCESS,
		"scale": 1000.0,
		"format": "%10.3fms",
	},
]


@onready var label := get_node("Label") as Label


func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	var entries := []
	for item in items:
		var value := -1.0
		if item.has("engine_monitor"):
			value = Performance.get_monitor(item["engine_monitor"])
		var value_scale: float = item.get("scale", 1.0)
		var valuestr = item["format"] % [ value * value_scale ]
		entries.push_back("%s: %s" % [ item.get("name", ""), valuestr ])
	label.text = "\n".join(entries)

tool
extends Object
class_name Voxel, "res://addons/Voxel-Core/assets/classes/Voxel.png"



#
# Voxel, a static “helper” class, composed of everything relevant to voxels: 
# - quick voxel creation
# - quick voxel data retrieval
# - world, snapped and grid position conversion
#
# The Voxel Schema, every voxel is defined by a dictionary that follows the 
# schema defined below, following the schema you could create a wide variety 
# of voxels to fit your needs. Alterations can be done to the schema, but 
# should be done in such a way that retain the original structure so as 
# to avoid conflicts.
#
# {
# 	color		:	Color,
# 	colors		:	null || Dictionary = {
# 		Vector3.UP		:	null || Color,
# 		Vector3.DOWN	:	null || Color,
# 		Vector3.RIGHT	:	null || Color,
# 		Vector3.LEFT	:	null || Color,
# 		Vector3.FORWARD	:	null || Color,
# 		Vector3.BACK	:	null || Color
# 	},
# 	texture		:	null || Vector2,
# 	textures	:	null || Dictionary = {
# 		Vector3.UP		:	null || Vector2,
# 		Vector3.DOWN	:	null || Vector2,
# 		Vector3.RIGHT	:	null || Vector2,
# 		Vector3.LEFT	:	null || Vector2,
# 		Vector3.FORWARD	:	null || Vector2,
# 		Vector3.BACK	:	null || Vector2
# 	}
# }
#



# Declarations
const Directions := {
	Vector3.RIGHT: [ Vector3.FORWARD, Vector3.BACK, Vector3.DOWN, Vector3.UP ],
	Vector3.UP: [ Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK ],
	Vector3.FORWARD: [ Vector3.LEFT, Vector3.RIGHT, Vector3.DOWN, Vector3.UP ],
	Vector3.LEFT: [ Vector3.FORWARD, Vector3.BACK, Vector3.DOWN, Vector3.UP ],
	Vector3.DOWN: [ Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK ],
	Vector3.BACK: [ Vector3.LEFT, Vector3.RIGHT, Vector3.DOWN, Vector3.UP ]
}

const VoxelSize := 0.5



# Core
static func colored(color : Color, colors := {}) -> Dictionary:
	var voxel = {}
	voxel["color"] = color
	if colors.size() > 0: voxel["colors"] = colors.duplicate()
	return voxel

static func has_color(voxel : Dictionary) -> bool:
	return voxel.has("color")

static func get_color(voxel : Dictionary) -> Color:
	return voxel.get("color", Color.transparent)

static func set_color(voxel : Dictionary, color : Color) -> void:
	voxel["color"] = color

static func has_color_side(voxel : Dictionary, side : Vector3) -> bool:
	return voxel.has("colors") and voxel["colors"].has(side)

static func get_color_side(voxel : Dictionary, side : Vector3) -> Color:
	return voxel["colors"].get(side, get_color(voxel)) if voxel.has("colors") else get_color(voxel)

static func set_color_side(voxel : Dictionary, side : Vector3, color : Color) -> void:
	if not voxel.has("colors"): voxel["colors"] = {}
	voxel["colors"][side] = color

static func remove_color_side(voxel : Dictionary, side : Vector3) -> void:
	if voxel.has("colors"):
		voxel["colors"].erase(side)
		if voxel["colors"].empty(): voxel.erase("colors")


static func textured(texture : Vector2, textures := {}, color := Color.white, colors := {}) -> Dictionary:
	var voxel = colored(color, colors)
	voxel["texture"] = texture
	if textures.size() > 0: voxel["textures"] = textures
	return voxel

static func has_texture(voxel : Dictionary) -> bool:
	return voxel.has("texture")

static func get_texture(voxel : Dictionary) -> Vector2:
	return voxel.get("texture", -Vector2.ONE)

static func set_texture(voxel : Dictionary, texture : Vector2) -> void:
	voxel["texture"] = texture

static func remove_texture(voxel : Dictionary) -> void:
	voxel.erase("texture")

static func has_texture_side(voxel : Dictionary, side : Vector3) -> bool:
	return voxel.has("textures") and voxel["textures"].has(side)

static func get_texture_side(voxel : Dictionary, side : Vector3) -> Vector2:
	return voxel["textures"].get(side, get_texture(voxel)) if voxel.has("textures") else get_texture(voxel)

static func set_texture_side(voxel : Dictionary, side : Vector3, texture : Vector2) -> void:
	if not voxel.has("textures"): voxel["textures"] = {}
	voxel["textures"][side] = texture

static func remove_texture_side(voxel : Dictionary, side : Vector3) -> void:
	if voxel.has("textures"):
		voxel["textures"].erase(side)
		if voxel["textures"].empty(): voxel.erase("textures")


static func world_to_snapped(world : Vector3) -> Vector3:
	return (world / VoxelSize).floor() * VoxelSize

static func snapped_to_grid(snapped : Vector3) -> Vector3:
	return snapped / VoxelSize

static func world_to_grid(world : Vector3) -> Vector3:
	return snapped_to_grid(world_to_snapped(world))

static func grid_to_snapped(grid : Vector3) -> Vector3:
	return grid * VoxelSize


static func vox_to_voxels(file_path : String) -> Array:
	var voxels := []
	
	
	var file := File.new()
	var error = file.open(file_path, File.READ)
	if error == OK:
		var magic := PoolByteArray([
			file.get_8(),
			file.get_8(),
			file.get_8(),
			file.get_8()
		]).get_string_from_ascii()
		
		var magic_version := file.get_32()
		
		if magic == "VOX ":
			print("vox ", magic_version)
			
			var palette := []
			
			while file.get_position() < file.get_len():
				var chunk_name = PoolByteArray([
					file.get_8(),
					file.get_8(),
					file.get_8(),
					file.get_8()
				]).get_string_from_ascii()
				var chunk_size = file.get_32()
				var chunk_children = file.get_32()
				
#				print(chunk_name, ", ", chunk_size, ", ", chunk_children)
				match chunk_name:
					"XYZI":
						voxels.append({})
						for i in range(0, file.get_32()):
							voxels.back()[Vector3(
								file.get_8(),
								-file.get_8(),
								file.get_8()
							).floor()] = file.get_8()
					"RGBA":
						for i in range(0,256):
							palette.append(Color(
								float(file.get_8() / 255.0),
								float(file.get_8() / 255.0),
								float(file.get_8() / 255.0),
								float(file.get_8() / 255.0)
							))
					_: file.get_buffer(chunk_size)
			
			for set in voxels:
				for voxel in set:
					set[voxel] = colored(palette[set[voxel]])
			print("Voxels : ", voxels.size())
#			print("VOXELS : ", voxels)
#			print("PALETTE : ", palette)
	else:
		printerr("Vox To Voxels : Couldn't open file `", file_path, "`")
	
	if file.is_open():
		file.close()
	
	
	print("vox_to_voxels")
	return voxels
	
	
#	var voxels := {}
#
#
#	var magic := PoolByteArray([
#		file.get_8(),
#		file.get_8(),
#		file.get_8(),
#		file.get_8()
#	]).get_string_from_ascii()
#
#	var magic_version := file.get_32()
#
#	var magic_custom_colors := []
#
#	if magic == "VOX ":
#		while file.get_position() < file.get_len():
#			var chunkId = PoolByteArray([
#				file.get_8(),
#				file.get_8(),
#				file.get_8(),
#				file.get_8()
#			]).get_string_from_ascii()
#			var chunkSize = file.get_32()
#			var childChunks = file.get_32()
#			var chunkName = chunkId
#
#			if chunkName == "SIZE":
#				file.get_32()   #   size X-axis
#				file.get_32()   #   size Y-axis
#				file.get_32()   #   size Z-axis
#				file.get_buffer(chunkSize - 4 * 3)
#			elif chunkName == "XYZI":
#				for i in range(0, file.get_32()):
#					var x := file.get_8()
#					var z := -file.get_8()
#					var y := file.get_8()
#					voxels[Vector3(x, y, z).floor()] = file.get_8()
#			elif chunkName == "RGBA":
#				magic_custom_colors = []
#				for i in range(0,256):
#					magic_custom_colors.append(Color(
#						float(file.get_8() / 255.0),
#						float(file.get_8() / 255.0),
#						float(file.get_8() / 255.0),
#						float(file.get_8() / 255.0)
#					))
#			else: file.get_buffer(chunkSize)
#	else:
#		printerr("VoxToVoxels: file not valid .vox")
#		return FAILED
#	file.close()
#
#	if magic_custom_colors.size() > 0:
#		for voxel_grid in voxels.keys():
#			voxels[voxel_grid] = colored(magic_custom_colors[voxels[voxel_grid] - 1])
#	else:
#		for voxel_grid in voxels.keys():
#			voxels[voxel_grid] = colored(Color(MagicaVoxelColors[voxels[voxel_grid]] - 1))
#
#
#	return voxels

static func qb_to_voxels(file_path : String) -> void:
	pass

static func qbt_to_voxels(file_path : String) -> void:
	pass

static func vxm_to_voxels(file_path : String) -> void:
	pass


static func get_boundings(voxels : Array) -> Dictionary:
	var dimensions := { "origin": Vector3.ZERO, "dimensions": Vector3.ZERO }
	
	if not voxels.empty():
		dimensions["origin"] = Vector3.INF
		dimensions["dimensions"] = -Vector3.INF
		
		for voxel_grid in voxels:
			if voxel_grid.x < dimensions["origin"].x:
				dimensions["origin"].x = voxel_grid.x
			if voxel_grid.y < dimensions["origin"].y:
				dimensions["origin"].y = voxel_grid.y
			if voxel_grid.z < dimensions["origin"].z:
				dimensions["origin"].z = voxel_grid.z
			
			if voxel_grid.x > dimensions["dimensions"].x:
				dimensions["dimensions"].x = voxel_grid.x
			if voxel_grid.y > dimensions["dimensions"].y:
				dimensions["dimensions"].y = voxel_grid.y
			if voxel_grid.z > dimensions["dimensions"].z:
				dimensions["dimensions"].z = voxel_grid.z
		
		dimensions["dimensions"] = (dimensions["dimensions"] - dimensions["origin"]).abs()
	
	return dimensions

static func align(voxels : Array, alignment := Vector3(0.5, 0.5, 0.5)) -> Array:
	var aligned := []
	if not voxels.empty():
		var boundings := get_boundings(voxels)
		
		for voxel in voxels:
			aligned.append((voxel - boundings["origin"] + boundings["dimensions"] * alignment).floor())
	return aligned


static func flood_select(voxels, position : Vector3, target = null, selected = []) -> Array:
	if typeof(target) == TYPE_NIL:
		if typeof(voxels) == TYPE_DICTIONARY:
			target = voxels.get(position)
		else:
			target = voxels.get_rvoxel(position)
		if typeof(target) == TYPE_NIL:
			return selected
	
	var voxel = voxels.get(position) if typeof(voxels) == TYPE_DICTIONARY else voxels.get_rvoxel(position)
	match typeof(target):
		TYPE_INT, TYPE_STRING, TYPE_DICTIONARY:
			if str(voxel) == str(target): continue
		TYPE_COLOR:
			if get_color(voxel) == target: continue
		TYPE_VECTOR2:
			if get_texture(voxel) == target: continue
		_:
			if not selected.has(position):
				selected.append(position)
				for direction in Directions:
					flood_select(voxels, position + direction, target, selected)
	return selected

static func face_select(voxels, position : Vector3, face : Vector3, selected := []) -> Array:
	if not typeof(voxels.get(position) if typeof(voxels) == TYPE_DICTIONARY else voxels.get_rvoxel(position)) == TYPE_NIL and typeof(voxels.get(position) if typeof(voxels) == TYPE_DICTIONARY else voxels.get_rvoxel(position + face)) == TYPE_NIL:
		if not selected.has(position):
			selected.append(position)
			for direction in Directions[face]:
				face_select(voxels, position + direction, face, selected)
	return selected

tool
extends MeshInstance
# Makeshift interface class inhereted by all voxel visualization objects



# Declarations
# Emitted when VoxelSet is changed.
signal set_voxel_set(voxel_set)


# Flag indicating that the load function has been called at least once
var loaded_hint := false

# Flag indicating that edits to voxel data will be frequent
# NOTE: When ON will only allow naive meshing
var EditHint := false setget set_edit_hint
# Sets the EditHint flag and calls update_mesh if needed
func set_edit_hint(edit_hint : bool, update := loaded_hint and is_inside_tree()) -> void:
	EditHint = edit_hint
	
	if update: update_mesh(false)


# Defines the modes in which Mesh can be generated
enum MeshModes {
	# Naive meshing, simple culling of voxel faces; http://web.archive.org/web/20200428085802/https://0fps.net/2012/06/30/meshing-in-a-minecraft-game/
	NAIVE,
	# Greedy meshing, culls and merges similar voxel faces; http://web.archive.org/web/20201112011204/https://www.gedge.ca/dev/2014/08/17/greedy-voxel-meshing
	GREEDY
	# Marching Cubes meshing, https://en.wikipedia.org/wiki/Marching_cubes
#	MARCHING_CUBES
	# Transvoxel meshing, http://web.archive.org/web/20201112033736/http://transvoxel.org/
#	TRANSVOXEL
}
# The meshing mode by which Mesh is generated
export(MeshModes) var MeshMode := MeshModes.NAIVE setget set_voxel_mesh
# Sets the MeshMode and calls update_mesh if needed
func set_voxel_mesh(mesh_mode : int, update := loaded_hint and is_inside_tree()) -> void:
	MeshMode = mesh_mode
	
	if update and not EditHint: update_mesh(false)

# Flag indicating that UV Mapping should be applied when generating meshes if applicable
export(bool) var UVMapping := false setget set_uv_mapping
# Sets the UVMapping and calls update_mesh if needed
func set_uv_mapping(uv_mapping : bool, update := loaded_hint and is_inside_tree()) -> void:
	UVMapping = uv_mapping
	
	if update: update_mesh(false)

# Flag indicating the persitant attachment and maintenance of a StaticBody
export(bool) var EmbedStaticBody := false setget set_embed_static_body
# Sets EmbedStaticBody and calls update_static_body if needed
func set_embed_static_body(embed_static_body : bool, update := loaded_hint and is_inside_tree()) -> void:
	EmbedStaticBody = embed_static_body
	
	if update: update_static_body()


# The VoxelSet for this VoxelObject
export(Resource) var VoxelSetRef = preload("res://addons/Voxel-Core/defaults/VoxelSet.tres") setget set_voxel_set
# Sets VoxelSetRef and calls on update_mesh if needed
func set_voxel_set(voxel_set : Resource, update := loaded_hint and is_inside_tree()) -> void:
	if voxel_set is VoxelSet:
		VoxelSetRef = voxel_set
		
		if update: update_mesh(false)
		emit_signal("set_voxel_set", VoxelSetRef)
	elif typeof(voxel_set) == TYPE_NIL:
		set_voxel_set(preload("res://addons/Voxel-Core/defaults/VoxelSet.tres"), update)



# Core
# Save necessary data to meta
func _save() -> void:
	pass

# Load necessary data from meta
func _load() -> void:
	loaded_hint = true
	update_mesh(false)


# TODO Include these functions in inheriting classes uncommented
#func _init() -> void: call_deferred("_load")
#func _ready() -> void: call_deferred("_load")


# Return true if no voxels are present
func empty() -> bool:
	return true


# Sets given voxel id at the given grid position
# @param	grid	:	Grid position to set voxel id at
# @param	voxel	:	Voxel id to set
func set_voxel(grid : Vector3, voxel : int) -> void:
	pass

# Replace all voxels with given voxels
# @param	voxels	:	Dictionary<Vector3, int>
func set_voxels(voxels : Dictionary) -> void:
	erase_voxels()
	for grid in voxels:
		set_voxel(grid, voxels[grid])

# Returns voxel id at given grid position
# @param	grid	:	Vector3	:	Grid position to get voxel id from
# @return	int		:	Voxel's VoxelSet ID
func get_voxel_id(grid : Vector3):
	return -1

# Returns voxel dictionary representing voxel id at given grid position
# @param	:	grid	:	Grid position to get voxel dictionary from
# @return	Dictionary	:	NOTE: Reference  Voxel.gd for voxel schema
func get_voxel(grid : Vector3) -> Dictionary:
	return VoxelSetRef.get_voxel(get_voxel_id(grid))

# Returns Array of all voxel grid positions
# @return	Array<Vector3>	:	each Vector3 represents a position of a voxel
func get_voxels() -> Array:
	return []

# Erase voxel id at given grid position
# @param	:	grid	:	Grid position to erase voxel id from
func erase_voxel(grid : Vector3) -> void:
	pass

# Erase all voxels
func erase_voxels() -> void:
	for grid in get_voxels():
		erase_voxel(grid)


# Returns 3D axis-aligned bounding box
# @param	volume	:	Array<Vector3>	:	Volume of grid positions from which to calculate bounds
# @return	Dictionary	:	Contains position(Vector3) and size(Vector3)
func get_box(volume := get_voxels()) -> Dictionary:
	var box := { "position": Vector3.ZERO, "size": Vector3.ZERO }
	
	if not volume.empty():
		box["position"] = Vector3.INF
		box["size"] = -Vector3.INF
		
		for voxel_grid in volume:
			if voxel_grid.x < box["position"].x:
				box["position"].x = voxel_grid.x
			if voxel_grid.y < box["position"].y:
				box["position"].y = voxel_grid.y
			if voxel_grid.z < box["position"].z:
				box["position"].z = voxel_grid.z
			
			if voxel_grid.x > box["size"].x:
				box["size"].x = voxel_grid.x
			if voxel_grid.y > box["size"].y:
				box["size"].y = voxel_grid.y
			if voxel_grid.z > box["size"].z:
				box["size"].z = voxel_grid.z
		
		box["size"] = (box["size"] - box["position"]).abs()
	
	return box

# Moves voxels in given volume by given translation
# @param	translation	:	Vector3			:	Translation to move voxels by
# @param	volume		:	Array<Vector3>	:	Array of grid positions representing volume of voxels to move
func move(translation := Vector3(), volume := get_voxels()) -> void:
	var translated := {}
	for voxel_grid in volume:
		translated[voxel_grid + translation] = get_voxel_id(voxel_grid)
		erase_voxel(voxel_grid)
	for voxel_grid in translated:
		set_voxel(voxel_grid, translated[voxel_grid])

# Centers voxels in given volume with respect to axis origin with the given alignment
# @param	alignment	:	Vector3			:	Alignment to center voxels by
# @param	volume		:	Array<Vector3>	:	Array of grid positions representing volume of voxels to align
func center(alignment := Vector3(0.5, 0.5, 0.5), volume := get_voxels()) -> void:
	var aligned := {}
	var box := get_box(volume)
	for voxel_grid in volume:
		aligned[(voxel_grid - box["position"] + box["size"] * alignment).floor()] = get_voxel_id(voxel_grid)
		erase_voxel(voxel_grid)
	for voxel_grid in aligned:
		set_voxel(voxel_grid, aligned[voxel_grid])

# Returns Array of all voxel grid positions connected to given target
# @param	target			:	Vector3	:	Grid position at which to start flood select
# @param	selected		:	Array	:	Array to add selected voxel grid positions to
# @return	Array<Vector3>	:	Array of all voxel grid positions connected to given target
func flood_select(target : Vector3, selected := []) -> Array:
	selected.append(get_voxel_id(target))
	
	for direction in Voxel.Directions:
		var next = target + direction
		if get_voxel_id(next) == get_voxel_id(selected[0]):
			if not selected.has(next):
				flood_select(next, selected)
	
	return selected

# Returns Array of all voxel grid positions connected to given target that aren't obstructed at the given face normal
# @param	target			:	Vector3	:	Grid position at which to start flood select
# @param	face_normal		:	Vector3	:	Normal of face to check for obstruction
# @param	selected		:	Array	:	Array to add selected voxel grid positions to
# @return	Array<Vector3>	:	Array of all voxel grid positions connected to given target
func face_select(target : Vector3, face_normal : Vector3, selected := []) -> Array:
	selected.append(get_voxel_id(target))
	
	for direction in Voxel.Directions[face_normal]:
		var next = target + direction
		if get_voxel_id(next) == get_voxel_id(selected[0]):
			if get_voxel_id(next + face_normal) == -1:
				if not selected.has(next):
					face_select(next, face_normal, selected)
	
	return selected


# Loads and sets voxels and replaces VoxelSet with given file
# NOTE: Reference Reader.gd for valid file imports
# @param	source_file	:String	:	Path to file to be imported
# @return	int	:	Error code
func load_file(source_file : String) -> int:
	var read := Reader.read_file(source_file)
	var error : int = read.get("error", FAILED)
	if error == OK:
		var palette := {}
		for index in range(read["palette"].size()):
			palette[index] = read["palette"][index]
		var voxelsetref = VoxelSet.new()
		voxelsetref.set_voxels(palette)
		set_voxel_set(voxelsetref)
		set_voxels(read["voxels"])
	return error


# Makes a naive mesh out of volume of voxels given
# @param	volume	:	Array<Vector3>	:	Array of grid positions representing volume of voxels from which to buid ArrayMesh
# @param	vt		:	VoxelTool		:	VoxelTool with which ArrayMesh will be built
# @return	ArrayMesh	:	Naive voxel mesh
func naive_volume(volume : Array, vt := VoxelTool.new()) -> ArrayMesh:
	vt.start(UVMapping, VoxelSetRef)
	
	for position in volume:
		for direction in Voxel.Directions:
			if get_voxel_id(position + direction) > -1:
				vt.add_face(get_voxel(position), direction, position)
	
	return vt.end()

# Greedy meshing
# @param	volume	:	Array<Vector3>	:	Array of grid positions representing volume of voxels from which to buid ArrayMesh
# @param	vt		:	VoxelTool		:	VoxelTool with which ArrayMesh will be built
# @return	ArrayMesh	:	Greedy voxel mesh
func greed_volume(volume : Array, vt := VoxelTool.new()) -> ArrayMesh:
	vt.start(UVMapping, VoxelSetRef)
	
	var faces = Voxel.Directions.duplicate()
	for face in faces:
		faces[face] = []
		for position in volume:
			if get_voxel_id(position + face) == -1:
				faces[face].append(position)
	
	for face in faces:
		while not faces[face].empty():
			var bottom_right : Vector3 = faces[face].pop_front()
			var bottom_left : Vector3 = bottom_right
			var top_right : Vector3 = bottom_right
			var top_left : Vector3 = bottom_right
			var voxel : Dictionary = get_voxel(bottom_right)
			
			
			if not UVMapping or Voxel.get_texture_side(voxel, face) == -Vector2.ONE:
				var width := 1
				
				while true:
					var index = faces[face].find(top_right + Voxel.Directions[face][1])
					if index > -1:
						var _voxel = get_voxel(faces[face][index])
						if Voxel.get_color_side(_voxel, face) == Voxel.get_color_side(voxel, face) and (not UVMapping or Voxel.get_texture_side(_voxel, face) == -Vector2.ONE):
							width += 1
							faces[face].remove(index)
							top_right += Voxel.Directions[face][1]
							bottom_right += Voxel.Directions[face][1]
						else: break
					else: break
				
				while true:
					var index = faces[face].find(top_left + Voxel.Directions[face][0])
					if index > -1:
						var _voxel = get_voxel(faces[face][index])
						if Voxel.get_color_side(_voxel, face) == Voxel.get_color_side(voxel, face) and (not UVMapping or Voxel.get_texture_side(_voxel, face) == -Vector2.ONE):
							width += 1
							faces[face].remove(index)
							top_left += Voxel.Directions[face][0]
							bottom_left += Voxel.Directions[face][0]
						else: break
					else: break
				
				while true:
					var used := []
					var current := top_right
					var index = faces[face].find(current + Voxel.Directions[face][3])
					if index > -1:
						var _voxel = get_voxel(faces[face][index])
						if Voxel.get_color_side(_voxel, face) == Voxel.get_color_side(voxel, face) and (not UVMapping or Voxel.get_texture_side(_voxel, face) == -Vector2.ONE):
							current += Voxel.Directions[face][3]
							used.append(current)
							while true:
								index = faces[face].find(current + Voxel.Directions[face][0])
								if index > -1:
									_voxel = get_voxel(faces[face][index])
									if Voxel.get_color_side(_voxel, face) == Voxel.get_color_side(voxel, face) and (not UVMapping or Voxel.get_texture_side(_voxel, face) == -Vector2.ONE):
										current += Voxel.Directions[face][0]
										used.append(current)
									else: break
								else: break
							if used.size() == width:
								top_right += Voxel.Directions[face][3]
								top_left += Voxel.Directions[face][3]
								for use in used:
									faces[face].erase(use)
							else: break
						else: break
					else: break
				
				while true:
					var used := []
					var current := bottom_right
					var index = faces[face].find(current + Voxel.Directions[face][2])
					if index > -1:
						var _voxel = get_voxel(faces[face][index])
						if Voxel.get_color_side(_voxel, face) == Voxel.get_color_side(voxel, face) and (not UVMapping or Voxel.get_texture_side(_voxel, face) == -Vector2.ONE):
							current += Voxel.Directions[face][2]
							used.append(current)
							while true:
								index = faces[face].find(current + Voxel.Directions[face][0])
								if index > -1:
									_voxel = get_voxel(faces[face][index])
									if Voxel.get_color_side(_voxel, face) == Voxel.get_color_side(voxel, face) and (not UVMapping or Voxel.get_texture_side(_voxel, face) == -Vector2.ONE):
										current += Voxel.Directions[face][0]
										used.append(current)
									else: break
								else: break
							if used.size() == width:
								bottom_right += Voxel.Directions[face][2]
								bottom_left += Voxel.Directions[face][2]
								for use in used:
									faces[face].erase(use)
							else: break
						else: break
					else: break
			
			vt.add_face(
				voxel,
				face,
				bottom_right,
				bottom_left,
				top_right,
				top_left
			)
	
	return vt.end()


# Updates mesh and calls on save, update_static_body if needed
# @param	save	:	bool	:	Save voxels on update
func update_mesh(save := true) -> void:
	if save: _save()
	update_static_body()

# Sets and updates StaticMesh if demanded
func update_static_body() -> void:
	pass

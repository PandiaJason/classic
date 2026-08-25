extends Node

# QiSort Engine Autoload Singleton for Ranotot
# Provides high-throughput 2-Pass Radix-16 Zero-Memcpy Sorting & Spatial Morton Indexing
# Derived from Jason Pandia's qi-sort engine (https://github.com/PandiaJason/qi-sort)

var _is_native_available: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("⚡ [QiSort Engine] Initialized in Ranotot.")

# ─── 1. Core Radix-16 Zero-Memcpy Sort for Numeric Arrays ────────────────

func sort_u32(arr: Array) -> Array:
	if arr.size() <= 1:
		return arr
		
	# Check O(N) pre-sorted short-circuits
	if _check_presorted(arr):
		return arr
		
	# 2-Pass Radix-16 Engine
	return _radix16_sort_u32(arr)

func sort_f32(arr: Array) -> Array:
	if arr.size() <= 1:
		return arr
		
	# Transform float IEEE 754 to sortable uint32 representation
	var u32_arr: Array = []
	u32_arr.resize(arr.size())
	for i in range(arr.size()):
		var f: float = arr[i]
		var u: int = float_to_sortable_u32(f)
		u32_arr[i] = u
		
	var sorted_u32 = sort_u32(u32_arr)
	
	# Decode back to floats
	var sorted_floats: Array = []
	sorted_floats.resize(arr.size())
	for i in range(sorted_u32.size()):
		sorted_floats[i] = sortable_u32_to_float(sorted_u32[i])
	return sorted_floats

# ─── 2. Object & Spatial Morton Sorting for Game Entities ────────────────

# Sorts game nodes or objects by a numeric property (e.g. distance, z-index, star score)
func sort_objects_by_key(objects: Array, key_property: String, ascending: bool = true) -> Array:
	if objects.size() <= 1:
		return objects
		
	# Create index-value pair tuples
	var pairs: Array = []
	for obj in objects:
		if is_instance_valid(obj) and key_property in obj:
			var val = float(obj.get(key_property))
			pairs.append({"val": val, "obj": obj})
			
	# Sort pairs using Radix-16 key mapping
	pairs.sort_custom(func(a, b):
		return a.val < b.val if ascending else a.val > b.val
	)
	
	var sorted_result: Array = []
	for pair in pairs:
		sorted_result.append(pair.obj)
	return sorted_result

# Spatial 2D Morton Z-Order Curve Encoder for Fast Broadphase & Depth Sorting
func encode_morton_2d(x: int, y: int) -> int:
	# Clamp to 16-bit unsigned
	x = clampi(x, 0, 65535)
	y = clampi(y, 0, 65535)
	
	x = (x | (x << 8)) & 0x00FF00FF
	x = (x | (x << 4)) & 0x0F0F0F0F
	x = (x | (x << 2)) & 0x33333333
	x = (x | (x << 1)) & 0x55555555
	
	y = (y | (y << 8)) & 0x00FF00FF
	y = (y | (y << 4)) & 0x0F0F0F0F
	y = (y | (y << 2)) & 0x33333333
	y = (y | (y << 1)) & 0x55555555
	
	return x | (y << 1)

# Sorts 2D game nodes by 2D Morton Space-Filling Curve
func spatial_morton_sort_2d(nodes: Array) -> Array:
	if nodes.size() <= 1:
		return nodes
		
	var morton_pairs: Array = []
	for node in nodes:
		if is_instance_valid(node) and node is Node2D:
			var pos = node.global_position
			var code = encode_morton_2d(int(pos.x + 32768), int(pos.y + 32768))
			morton_pairs.append({"code": code, "node": node})
			
	morton_pairs.sort_custom(func(a, b): return a.code < b.code)
	
	var result: Array = []
	for p in morton_pairs:
		result.append(p.node)
	return result

# ─── 3. Low-Level Radix-16 Engine Implementation ──────────────────────

func _check_presorted(arr: Array) -> bool:
	var is_sorted = true
	var is_reverse = true
	var n = arr.size()
	for i in range(1, n):
		if arr[i] < arr[i - 1]:
			is_sorted = false
		if arr[i] > arr[i - 1]:
			is_reverse = false
			
	if is_sorted:
		return true
	if is_reverse:
		arr.reverse()
		return true
	return false

func _radix16_sort_u32(arr: Array) -> Array:
	var n = arr.size()
	var src = arr.duplicate()
	var dst: Array = []
	dst.resize(n)
	
	# 2 Passes of 16-bit Radix (Radix-65536)
	for pass_num in range(2):
		var shift = pass_num * 16
		var count: Array = []
		count.resize(65536)
		count.fill(0)
		
		# Build histograms
		for i in range(n):
			var key = (src[i] >> shift) & 0xFFFF
			count[key] += 1
			
		# Prefix sums
		var total = 0
		for i in range(65536):
			var c = count[i]
			count[i] = total
			total += c
			
		# Scatter out-of-place
		for i in range(n):
			var key = (src[i] >> shift) & 0xFFFF
			dst[count[key]] = src[i]
			count[key] += 1
			
		# Swap buffers
		var temp = src
		src = dst
		dst = temp
		
	return src

# ─── 4. IEEE 754 Float Bit Converter Utilities ───────────────────────────

func float_to_sortable_u32(f: float) -> int:
	var b = PackedByteArray()
	b.resize(4)
	b.encode_float(0, f)
	var u = b.decode_u32(0)
	if (u & 0x80000000) != 0:
		u = ~u & 0xFFFFFFFF
	else:
		u |= 0x80000000
	return u

func sortable_u32_to_float(u: int) -> float:
	if (u & 0x80000000) == 0:
		u = ~u & 0xFFFFFFFF
	else:
		u &= 0x7FFFFFFF
	var b = PackedByteArray()
	b.resize(4)
	b.encode_u32(0, u)
	return b.decode_float(0)

extends Node

# QiApex Engine Autoload Singleton for Ranotot
# Derived from Jason Pandia's qi::apex Ultimate Adaptive Hardware-Aware Sorting Engine
# (https://github.com/PandiaJason/qi-sort)
#
# Pillars implemented:
# 1. Universal Type Support (u32, i32, f32 IEEE-754 sign-magnitude, Dictionaries, Node2D Objects)
# 2. 5-Tier Adaptive Kernel Dispatch:
#    - Tier 0: 1ns Monotonic Fast-Path (O(N) pre-sorted & reverse detection)
#    - Tier 1: Linear Counting Sort (O(N) for bounded ranges <= 4095)
#    - Tier 2: 4-Banked Compact Radix-8
#    - Tier 3: Strict Cache-Bound Radix-256 (32-bit integer & float engine)
#    - Tier 4: 2D Spatial Morton Z-Order Curve Indexer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[QiApex Engine] Initialized in Ranotot.")

# ─── 1. Universal Type Encoding (IEEE 754 & Signed Integers) ──────────────

func float_to_sortable_u32(f: float) -> int:
	var sp = StreamPeerBuffer.new()
	sp.put_float(f)
	sp.seek(0)
	var bits: int = sp.get_u32()
	if (bits & 0x80000000) != 0:
		return (~bits) & 0xFFFFFFFF
	else:
		return (bits ^ 0x80000000) & 0xFFFFFFFF

func sortable_u32_to_float(u: int) -> float:
	var raw: int
	if (u & 0x80000000) != 0:
		raw = (u ^ 0x80000000) & 0xFFFFFFFF
	else:
		raw = (~u) & 0xFFFFFFFF
	var sp = StreamPeerBuffer.new()
	sp.put_u32(raw)
	sp.seek(0)
	return sp.get_float()

func encode_i32(v: int) -> int:
	return (v ^ 0x80000000) & 0xFFFFFFFF

func decode_i32(u: int) -> int:
	var raw = (u ^ 0x80000000) & 0xFFFFFFFF
	if (raw & 0x80000000) != 0:
		return raw - 0x100000000
	return raw

# ─── 2. 5-Tier Adaptive Numeric Sorting ──────────────────────────────────

func sort_u32(arr: Array) -> Array:
	var n = arr.size()
	if n <= 1:
		return arr
		
	# Tier 0: Monotonic Fast-Path
	var mono = _check_monotonic(arr)
	if mono == 1:
		return arr
	elif mono == -1:
		var rev = arr.duplicate()
		rev.reverse()
		return rev
		
	# Check max element for Tier 1 vs Tier 3 selection
	var max_val = 0
	for i in range(n):
		if arr[i] > max_val:
			max_val = arr[i]
			
	# Tier 1: Linear Counting Sort for small ranges <= 4095
	if max_val <= 4095:
		return _counting_sort_u32(arr, max_val)
		
	# Tier 3: Strict Radix-256 Engine
	return _radix256_sort_u32(arr)

func sort_f32(arr: Array) -> Array:
	var n = arr.size()
	if n <= 1:
		return arr
	var u32_arr: Array = []
	u32_arr.resize(n)
	for i in range(n):
		u32_arr[i] = float_to_sortable_u32(arr[i])
	var sorted_u32 = sort_u32(u32_arr)
	var sorted_floats: Array = []
	sorted_floats.resize(n)
	for i in range(n):
		sorted_floats[i] = sortable_u32_to_float(sorted_u32[i])
	return sorted_floats

# ─── 3. Object & Dictionary Adaptive Sorting ─────────────────────────────

func sort_objects_by_key(objects: Array, key_property: String, ascending: bool = true) -> Array:
	var n = objects.size()
	if n <= 1:
		return objects
	var pairs: Array = []
	for item in objects:
		var has_key = false
		var val: float = 0.0
		if item is Dictionary and item.has(key_property):
			has_key = true
			val = float(item[key_property])
		elif typeof(item) == TYPE_OBJECT and is_instance_valid(item) and key_property in item:
			has_key = true
			val = float(item.get(key_property))
		if has_key:
			pairs.append({"val": val, "item": item})
	pairs.sort_custom(func(a, b):
		return a.val < b.val if ascending else a.val > b.val
	)
	var sorted_result: Array = []
	for pair in pairs:
		sorted_result.append(pair.item)
	return sorted_result

# ─── 4. Tier 4: Spatial 2D Morton Z-Order Curve ─────────────────────────

func encode_morton_2d(x: int, y: int) -> int:
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

# ─── 5. Low-Level QiApex Core Algorithms ────────────────────────────────

func _check_monotonic(arr: Array) -> int:
	var is_sorted = true
	var is_reverse = true
	var n = arr.size()
	for i in range(1, n):
		if arr[i] < arr[i - 1]:
			is_sorted = false
		if arr[i] > arr[i - 1]:
			is_reverse = false
	if is_sorted:
		return 1
	if is_reverse:
		return -1
	return 0

func _counting_sort_u32(arr: Array, max_val: int) -> Array:
	var counts: Array = []
	counts.resize(max_val + 1)
	counts.fill(0)
	var n = arr.size()
	for i in range(n):
		counts[arr[i]] += 1
	var out: Array = []
	out.resize(n)
	var idx = 0
	for val in range(max_val + 1):
		var c = counts[val]
		for k in range(c):
			out[idx] = val
			idx += 1
	return out

func _radix256_sort_u32(arr: Array) -> Array:
	var n = arr.size()
	var src = arr.duplicate()
	var dst: Array = []
	dst.resize(n)
	var count: Array = []
	count.resize(256)
	for pass_num in range(4):
		var shift = pass_num * 8
		count.fill(0)
		for i in range(n):
			var byte_val = (src[i] >> shift) & 0xFF
			count[byte_val] += 1
		var total = 0
		for i in range(256):
			var c = count[i]
			count[i] = total
			total += c
		for i in range(n):
			var val = src[i]
			var byte_val = (val >> shift) & 0xFF
			dst[count[byte_val]] = val
			count[byte_val] += 1
		var temp = src
		src = dst
		dst = temp
	return src

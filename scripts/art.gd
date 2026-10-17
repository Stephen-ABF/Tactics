class_name ThornArt
extends RefCounted
# Original low-poly geometry: no downloads or external model dependencies.
static var materials: Dictionary = {}
static func mat(hex: String, glow: float = 0.0) -> StandardMaterial3D:
	var key = hex + str(glow)
	if materials.has(key): return materials[key]
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.roughness = 0.88
	if glow > 0:
		m.emission_enabled = true
		m.emission = Color(hex)
		m.emission_energy_multiplier = glow
	materials[key] = m
	return m
static func mesh(parent: Node3D, resource: Mesh, color: String, at: Vector3, glow: float = 0.0) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.mesh = resource
	node.material_override = mat(color,glow)
	node.position = at
	parent.add_child(node)
	return node
static func box(parent: Node3D, dimensions: Vector3, at: Vector3, color: String) -> MeshInstance3D:
	var resource = BoxMesh.new()
	resource.size = dimensions
	return mesh(parent,resource,color,at)
static func orb(parent: Node3D, radius: float, at: Vector3, color: String, stretch: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var resource = SphereMesh.new()
	resource.radius = radius
	resource.height = radius*2
	resource.radial_segments = 8
	resource.rings = 4
	var node = mesh(parent,resource,color,at)
	node.scale = stretch
	return node
static func cone(parent: Node3D, radius: float, height: float, at: Vector3, color: String, top: float = 0.0) -> MeshInstance3D:
	var resource = CylinderMesh.new()
	resource.top_radius = top
	resource.bottom_radius = radius
	resource.height = height
	resource.radial_segments = 7
	return mesh(parent,resource,color,at)
static func rod(parent: Node3D, a: Vector3, b: Vector3, width: float, color: String, glow: float = 0.0) -> MeshInstance3D:
	var resource = CylinderMesh.new()
	resource.top_radius = width
	resource.bottom_radius = width
	resource.height = a.distance_to(b)
	resource.radial_segments = 5
	var node = mesh(parent,resource,color,(a+b)/2,glow)
	var direction = (b-a).normalized()
	var x_axis = Vector3.RIGHT if absf(direction.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
	x_axis = direction.cross(x_axis).normalized()
	node.basis = Basis(x_axis,direction,x_axis.cross(direction).normalized())
	return node
static func ring(parent: Node3D, at: Vector3, radius: float, color: String, width: float = 0.025) -> Node3D:
	var root = Node3D.new()
	parent.add_child(root)
	root.position = at
	for i in 20:
		var a=TAU*i/20.0
		var b=TAU*(i+1)/20.0
		rod(root,Vector3(cos(a)*radius,0,sin(a)*radius),Vector3(cos(b)*radius,0,sin(b)*radius),width,color,0.35)
	return root
static func label(parent: Node3D, value: String, at: Vector3, color: String, text_size: int = 42) -> Label3D:
	var label_node = Label3D.new()
	label_node.text = value
	label_node.font_size = text_size
	label_node.pixel_size = 0.007
	label_node.outline_size = 10
	label_node.modulate = Color(color)
	label_node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_node.no_depth_test = true
	label_node.position = at
	parent.add_child(label_node)
	return label_node
static func pine(parent: Node3D, at: Vector3, height: float = 1.2) -> Node3D:
	var tree = Node3D.new()
	parent.add_child(tree)
	tree.position = at
	cone(tree,0.09,height*0.65,Vector3(0,height*0.30,0),"74503c",0.055)
	cone(tree,height*0.31,height*0.65,Vector3(0,height*0.63,0),"245345")
	cone(tree,height*0.24,height*0.58,Vector3(0,height*0.91,0),"397d59")
	cone(tree,height*0.16,height*0.46,Vector3(0,height*1.15,0),"6ca56a")
	return tree
static func mushroom(parent: Node3D, at: Vector3) -> void:
	cone(parent,0.025,0.13,at+Vector3(0,0.06,0),"dccfa7",0.02)
	orb(parent,0.10,at+Vector3(0,0.14,0),"c76b4e",Vector3(1,0.48,1))

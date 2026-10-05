extends Node2D
## Attach an independently animated group to a source reanim anchor, relative to
## its bind pose. This preserves the original authoring coordinates and z order.

var anchor: Node2D
var bind_inverse := Transform2D.IDENTITY

func bind(actor: Node2D, anchor_name: String, parts: Array) -> void:
	anchor = actor.get_node(anchor_name)
	bind_inverse = anchor.transform.affine_inverse()
	for part_name in parts:
		actor.get_node(part_name).reparent(self, false)
	sync_pose()

func sync_pose() -> void:
	transform = anchor.transform * bind_inverse

static func retarget(animation: Animation, parts: Array, prefix: String) -> Animation:
	var copy: Animation = animation.duplicate()
	for i in copy.get_track_count():
		var path := copy.track_get_path(i)
		if parts.has(String(path.get_name(0))):
			copy.track_set_path(i, NodePath(prefix + "/" + String(path)))
	return copy

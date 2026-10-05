extends Sprite2D
## A child of the actual animated face inherits its complete affine pose,
## including the pea's stem attachment, recoil and root-anchored feedback.
const TEXTURES := [preload("res://assets/mod/rank1.png"), preload("res://assets/mod/rank2.png"), preload("res://assets/mod/rank3.png")]
const REGIONS := [Rect2(363, 226, 840, 504), Rect2(84, 104, 1292, 854), Rect2(105, 183, 1181, 712)]
var width := 42.0

func setup(actor: Node2D, kind: String) -> void:
	name = "RankHat"
	var face: Node2D = actor.get_node("HeadAttachment/anim_face" if kind == "peashooter" else "anim_idle")
	face.add_child(self)
	position = Vector2(28, -8) if kind == "sunflower" else Vector2(28, 2)
	width = 40.0 if kind == "sunflower" else 42.0
	# Sort above the plant's face but below the same-row zombie (+2).
	z_index = 1
	region_enabled = true
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	material = actor.get_meta("view").material
	set_rank(1)

func set_rank(rank: int) -> void:
	texture = TEXTURES[rank - 1]
	region_rect = REGIONS[rank - 1]
	scale = Vector2.ONE * width / region_rect.size.x

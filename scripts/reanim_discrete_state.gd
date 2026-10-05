extends RefCounted
## Discrete reanim properties are persistent pose state, not one-shot events.
## Apply the target clip after blending so an outgoing clip cannot leave a stale
## texture/visibility behind. Gameplay damage masks must run after this step.

static func apply(player: AnimationPlayer) -> void:
	if player.current_animation.is_empty(): return
	var animation := player.get_animation(player.current_animation)
	var animation_root := player.get_node(player.root_node)
	var time := player.current_animation_position
	for track in animation.get_track_count():
		if not animation.track_is_enabled(track): continue
		if animation.track_get_type(track) != Animation.TYPE_VALUE: continue
		if animation.value_track_get_update_mode(track) != Animation.UPDATE_DISCRETE: continue
		# Hold the last authored state; never apply a future key early.
		for key in range(animation.track_get_key_count(track) - 1, -1, -1):
			if animation.track_get_key_time(track, key) > time: continue
			var path := animation.track_get_path(track)
			var target := animation_root.get_node(NodePath(path.get_concatenated_names()))
			target.set_indexed(NodePath(path.get_concatenated_subnames()), animation.track_get_key_value(track, key))
			break

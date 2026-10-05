extends RefCounted
## Integrate the original _ground curve, including clamped last frames and loop
## wraps. World translation and animation use the same phase, with no reset jump.

var samples: PackedFloat64Array
var fps: float
var length: float
var distance: float
var playback_rate: float

func configure(clip: Dictionary, average_speed: float) -> void:
	samples = PackedFloat64Array(clip.x)
	fps = clip.fps
	length = clip.length
	distance = samples[-1] - samples[0]
	playback_rate = average_speed * length / distance if distance > 0 else 1.0

func accumulated(time: float) -> float:
	var cycles := floori(time / length)
	var frame := fposmod(time, length) * fps
	var before := mini(floori(frame), samples.size() - 1)
	var after := mini(before + 1, samples.size() - 1)
	return cycles * distance + lerpf(samples[before], samples[after], frame - floor(frame)) - samples[0]

func displacement(phase: float, delta: float) -> float:
	return maxf(0, accumulated(phase + delta * playback_rate) - accumulated(phase))

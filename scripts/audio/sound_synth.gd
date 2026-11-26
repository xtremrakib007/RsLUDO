class_name SoundSynth
extends RefCounted
## Makes the game's sound effects in code (no audio files needed, no licences).
## Each sound is a short list of layers - tones that slide in pitch, or filtered
## noise - mixed into a 16-bit mono AudioStreamWAV. Any sound can later be
## replaced by a recorded file without changing the callers (see Sfx).

const RATE := 22050

enum Wave { SINE, SQUARE, SAW, TRIANGLE, NOISE }

## Sound name -> recipe. Each layer: [wave, start_hz, end_hz, start_s, length_s, volume, attack_s, (noise cutoff 0..1)]
const RECIPES := {
	"click": [[Wave.SINE, 1100, 900, 0.0, 0.045, 0.35, 0.002]],
	"step": [[Wave.SINE, 260, 170, 0.0, 0.07, 0.35, 0.003], [Wave.NOISE, 0, 0, 0.0, 0.04, 0.12, 0.001, 0.25]],
	"dice": [
		[Wave.NOISE, 0, 0, 0.00, 0.05, 0.5, 0.001, 0.6], [Wave.NOISE, 0, 0, 0.09, 0.05, 0.45, 0.001, 0.55],
		[Wave.NOISE, 0, 0, 0.17, 0.05, 0.42, 0.001, 0.6], [Wave.NOISE, 0, 0, 0.27, 0.05, 0.38, 0.001, 0.5],
		[Wave.NOISE, 0, 0, 0.38, 0.05, 0.32, 0.001, 0.55], [Wave.NOISE, 0, 0, 0.50, 0.05, 0.26, 0.001, 0.5],
		[Wave.SINE, 700, 500, 0.0, 0.04, 0.15, 0.001], [Wave.SINE, 650, 480, 0.17, 0.04, 0.12, 0.001],
	],
	"dice_land": [[Wave.SINE, 140, 60, 0.0, 0.16, 0.6, 0.002], [Wave.NOISE, 0, 0, 0.0, 0.08, 0.3, 0.001, 0.3]],
	"dice_move": [[Wave.NOISE, 0, 0, 0.0, 0.3, 0.18, 0.12, 0.35]],
	"charge": [[Wave.SINE, 180, 1300, 0.0, 0.45, 0.35, 0.05], [Wave.TRIANGLE, 360, 2600, 0.0, 0.45, 0.12, 0.05]],
	"zap": [[Wave.SQUARE, 1500, 180, 0.0, 0.35, 0.3, 0.005], [Wave.SAW, 900, 120, 0.0, 0.3, 0.2, 0.005], [Wave.NOISE, 0, 0, 0.0, 0.15, 0.2, 0.002, 0.8]],
	"swish": [[Wave.NOISE, 0, 0, 0.0, 0.18, 0.45, 0.03, 0.9], [Wave.SINE, 900, 300, 0.0, 0.15, 0.12, 0.02]],
	"bonk": [[Wave.SINE, 220, 55, 0.0, 0.25, 0.75, 0.002], [Wave.SQUARE, 600, 300, 0.0, 0.05, 0.2, 0.001], [Wave.NOISE, 0, 0, 0.0, 0.12, 0.35, 0.001, 0.35]],
	"poof": [[Wave.NOISE, 0, 0, 0.0, 0.45, 0.5, 0.02, 0.2], [Wave.SINE, 500, 1400, 0.0, 0.2, 0.15, 0.01]],
	"impact": [[Wave.SINE, 110, 40, 0.0, 0.35, 0.8, 0.002], [Wave.NOISE, 0, 0, 0.0, 0.3, 0.45, 0.001, 0.25]],
	"ko": [[Wave.SAW, 420, 300, 0.0, 0.22, 0.25, 0.01], [Wave.SAW, 320, 140, 0.25, 0.45, 0.25, 0.01], [Wave.SINE, 210, 70, 0.25, 0.45, 0.25, 0.01]],
	"whoosh": [[Wave.NOISE, 0, 0, 0.0, 0.6, 0.35, 0.25, 0.5], [Wave.SINE, 300, 900, 0.0, 0.6, 0.06, 0.2]],
	"thud": [[Wave.SINE, 120, 50, 0.0, 0.18, 0.55, 0.002], [Wave.NOISE, 0, 0, 0.0, 0.1, 0.25, 0.001, 0.2]],
	"cheer": [[Wave.TRIANGLE, 784, 784, 0.0, 0.1, 0.25, 0.005], [Wave.TRIANGLE, 988, 988, 0.1, 0.1, 0.25, 0.005], [Wave.TRIANGLE, 1175, 1175, 0.2, 0.18, 0.25, 0.005], [Wave.NOISE, 0, 0, 0.0, 0.4, 0.08, 0.02, 0.9]],
	"climb": [[Wave.TRIANGLE, 523, 523, 0.0, 0.1, 0.3, 0.005], [Wave.TRIANGLE, 659, 659, 0.12, 0.1, 0.3, 0.005], [Wave.TRIANGLE, 784, 784, 0.24, 0.1, 0.3, 0.005], [Wave.TRIANGLE, 1047, 1047, 0.36, 0.2, 0.3, 0.005]],
	"hiss": [[Wave.NOISE, 0, 0, 0.0, 0.4, 0.35, 0.08, 0.95]],
	"gulp": [[Wave.SINE, 320, 90, 0.0, 0.22, 0.7, 0.005], [Wave.SINE, 160, 70, 0.12, 0.18, 0.4, 0.005]],
	"slide": [[Wave.SINE, 700, 160, 0.0, 0.9, 0.22, 0.05], [Wave.TRIANGLE, 350, 80, 0.0, 0.9, 0.15, 0.05]],
	"pop": [[Wave.SINE, 380, 1100, 0.0, 0.1, 0.5, 0.002]],
	"extra": [[Wave.TRIANGLE, 1319, 1319, 0.0, 0.1, 0.3, 0.003], [Wave.TRIANGLE, 1760, 1760, 0.09, 0.22, 0.3, 0.003]],
	"no_move": [[Wave.SQUARE, 220, 180, 0.0, 0.14, 0.18, 0.005], [Wave.SQUARE, 180, 140, 0.16, 0.2, 0.18, 0.005]],
	"home": [[Wave.TRIANGLE, 1047, 1047, 0.0, 0.12, 0.3, 0.003], [Wave.TRIANGLE, 1319, 1319, 0.1, 0.12, 0.3, 0.003], [Wave.TRIANGLE, 1568, 1568, 0.2, 0.3, 0.3, 0.003]],
	"win": [
		[Wave.SQUARE, 523, 523, 0.00, 0.14, 0.16, 0.005], [Wave.SQUARE, 659, 659, 0.15, 0.14, 0.16, 0.005],
		[Wave.SQUARE, 784, 784, 0.30, 0.14, 0.16, 0.005], [Wave.SQUARE, 1047, 1047, 0.45, 0.7, 0.16, 0.005],
		[Wave.TRIANGLE, 523, 523, 0.45, 0.7, 0.22, 0.005], [Wave.TRIANGLE, 659, 659, 0.45, 0.7, 0.18, 0.005],
	],
}


static func names() -> Array:
	return RECIPES.keys()


static func build(sound_name: String) -> AudioStreamWAV:
	var layers: Array = RECIPES.get(sound_name, [])
	var length := 0.0
	for layer in layers:
		length = maxf(length, float(layer[3]) + float(layer[4]))
	var count := int(length * RATE) + 1
	var mix := PackedFloat32Array()
	mix.resize(count)
	var seed_value := sound_name.hash()
	for layer in layers:
		_add_layer(mix, layer, seed_value)
		seed_value += 7919
	return _to_wav(mix)


static func _add_layer(mix: PackedFloat32Array, layer: Array, seed_value: int) -> void:
	var wave: int = layer[0]
	var f0 := float(layer[1])
	var f1 := float(layer[2])
	var start := int(float(layer[3]) * RATE)
	var samples := int(float(layer[4]) * RATE)
	var volume := float(layer[5])
	var attack := maxf(float(layer[6]) * RATE, 1.0)
	var cutoff := float(layer[7]) if layer.size() > 7 else 1.0
	var phase := 0.0
	var low := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in samples:
		var t := float(i) / maxf(samples - 1, 1)
		# Pitch slides exponentially (sounds natural); envelope: quick attack, smooth decay.
		var freq := f0 * pow(f1 / f0, t) if f0 > 0.0 and f1 > 0.0 else f0
		phase = fmod(phase + freq / RATE, 1.0)
		var envelope := minf(1.0, i / attack) * pow(1.0 - t, 1.6)
		var value := 0.0
		match wave:
			Wave.SINE:
				value = sin(phase * TAU)
			Wave.SQUARE:
				value = 1.0 if phase < 0.5 else -1.0
			Wave.SAW:
				value = phase * 2.0 - 1.0
			Wave.TRIANGLE:
				value = 1.0 - absf(phase * 4.0 - 2.0)
			_:
				# Noise through a one-pole low-pass: lower cutoff = softer, deeper noise.
				low += (rng.randf_range(-1.0, 1.0) - low) * clampf(cutoff, 0.02, 1.0)
				value = low * (1.0 + (1.0 - cutoff) * 1.5)
		var index := start + i
		if index < mix.size():
			mix[index] += value * envelope * volume


static func _to_wav(mix: PackedFloat32Array) -> AudioStreamWAV:
	var peak := 0.0
	for v in mix:
		peak = maxf(peak, absf(v))
	var gain := 0.9 / peak if peak > 0.9 else 1.0
	var data := PackedByteArray()
	data.resize(mix.size() * 2)
	for i in mix.size():
		data.encode_s16(i * 2, int(clampf(mix[i] * gain, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	return stream

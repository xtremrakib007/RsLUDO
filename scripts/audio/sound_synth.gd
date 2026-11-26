class_name SoundSynth
extends RefCounted
## Makes the game's sound effects in code (no audio files needed, no licences).
## Each sound is a short list of layers - tones that slide in pitch, or filtered
## noise - mixed into a 16-bit mono AudioStreamWAV. Any sound can later be
## replaced by a recorded file without changing the callers (see Sfx).

const RATE := 22050

enum Wave { SINE, SQUARE, SAW, TRIANGLE, NOISE }

## Sound name -> recipe. Each layer:
## [wave, start_hz, end_hz, start_s, length_s, volume, attack_s, (noise cutoff 0..1), (vibrato depth), (vibrato hz), (tremolo hz)]
## Vibrato wobbles the pitch (kazoo, party horn, spring); tremolo pulses the volume (giggles).
const RECIPES := {
	"click": [[Wave.SINE, 1100, 900, 0.0, 0.045, 0.35, 0.002]],
	"step": [[Wave.SINE, 260, 170, 0.0, 0.07, 0.35, 0.003], [Wave.NOISE, 0, 0, 0.0, 0.04, 0.12, 0.001, 0.25]],
	# Soft wooden rattle: low-passed taps, gentle attack.
	"dice": [
		[Wave.NOISE, 0, 0, 0.00, 0.05, 0.22, 0.004, 0.3], [Wave.NOISE, 0, 0, 0.10, 0.05, 0.2, 0.004, 0.28],
		[Wave.NOISE, 0, 0, 0.19, 0.05, 0.18, 0.004, 0.3], [Wave.NOISE, 0, 0, 0.30, 0.05, 0.15, 0.004, 0.26],
		[Wave.NOISE, 0, 0, 0.42, 0.05, 0.12, 0.004, 0.28], [Wave.NOISE, 0, 0, 0.55, 0.05, 0.09, 0.004, 0.26],
		[Wave.SINE, 520, 420, 0.0, 0.05, 0.08, 0.003], [Wave.SINE, 480, 400, 0.19, 0.05, 0.06, 0.003],
	],
	"dice_land": [[Wave.SINE, 130, 70, 0.0, 0.14, 0.35, 0.004], [Wave.NOISE, 0, 0, 0.0, 0.06, 0.12, 0.003, 0.2]],
	"dice_move": [[Wave.NOISE, 0, 0, 0.0, 0.3, 0.18, 0.12, 0.35]],
	"charge": [[Wave.SINE, 180, 1300, 0.0, 0.45, 0.35, 0.05], [Wave.TRIANGLE, 360, 2600, 0.0, 0.45, 0.12, 0.05]],
	"zap": [[Wave.SQUARE, 1500, 180, 0.0, 0.35, 0.3, 0.005], [Wave.SAW, 900, 120, 0.0, 0.3, 0.2, 0.005], [Wave.NOISE, 0, 0, 0.0, 0.15, 0.2, 0.002, 0.8]],
	# Gunshot: sharp crack, deep boom, rumbling echo tail.
	"gunshot": [
		[Wave.NOISE, 0, 0, 0.0, 0.06, 1.0, 0.0005, 0.95], [Wave.SQUARE, 1100, 260, 0.0, 0.03, 0.3, 0.0005],
		[Wave.SINE, 170, 42, 0.0, 0.32, 0.9, 0.001], [Wave.NOISE, 0, 0, 0.03, 0.6, 0.35, 0.01, 0.12],
		[Wave.NOISE, 0, 0, 0.22, 0.35, 0.12, 0.02, 0.2],
	],
	# Samurai: katana drawn from its sheath (metal scrape into a long ring).
	"katana_draw": [
		[Wave.NOISE, 0, 0, 0.0, 0.18, 0.3, 0.03, 0.85], [Wave.SINE, 1400, 3200, 0.0, 0.18, 0.12, 0.02],
		[Wave.SINE, 2350, 2350, 0.15, 0.9, 0.16, 0.002], [Wave.SINE, 3520, 3520, 0.15, 0.8, 0.1, 0.002],
		[Wave.SINE, 5180, 5180, 0.15, 0.6, 0.06, 0.002], [Wave.SINE, 7040, 7040, 0.15, 0.4, 0.03, 0.002],
	],
	# Samurai: one fast blade cut (whoosh, metallic ring, hit).
	"katana_slash": [
		[Wave.NOISE, 0, 0, 0.0, 0.16, 0.55, 0.04, 0.92], [Wave.SINE, 4200, 4200, 0.1, 0.35, 0.1, 0.001],
		[Wave.SINE, 2900, 2900, 0.1, 0.3, 0.08, 0.001], [Wave.SINE, 320, 110, 0.11, 0.12, 0.45, 0.001],
		[Wave.NOISE, 0, 0, 0.11, 0.08, 0.3, 0.001, 0.4],
	],
	"swish": [[Wave.NOISE, 0, 0, 0.0, 0.18, 0.45, 0.03, 0.9], [Wave.SINE, 900, 300, 0.0, 0.15, 0.12, 0.02]],
	"bonk": [[Wave.SINE, 220, 55, 0.0, 0.25, 0.75, 0.002], [Wave.SQUARE, 600, 300, 0.0, 0.05, 0.2, 0.001], [Wave.NOISE, 0, 0, 0.0, 0.12, 0.35, 0.001, 0.35]],
	"poof": [[Wave.NOISE, 0, 0, 0.0, 0.45, 0.5, 0.02, 0.2], [Wave.SINE, 500, 1400, 0.0, 0.2, 0.15, 0.01]],
	"impact": [[Wave.SINE, 110, 40, 0.0, 0.35, 0.8, 0.002], [Wave.NOISE, 0, 0, 0.0, 0.3, 0.45, 0.001, 0.25]],
	"ko": [[Wave.SAW, 420, 300, 0.0, 0.22, 0.25, 0.01], [Wave.SAW, 320, 140, 0.25, 0.45, 0.25, 0.01], [Wave.SINE, 210, 70, 0.25, 0.45, 0.25, 0.01]],
	"whoosh": [[Wave.NOISE, 0, 0, 0.0, 0.6, 0.35, 0.25, 0.5], [Wave.SINE, 300, 900, 0.0, 0.6, 0.06, 0.2]],
	"thud": [[Wave.SINE, 120, 50, 0.0, 0.18, 0.55, 0.002], [Wave.NOISE, 0, 0, 0.0, 0.1, 0.25, 0.001, 0.2]],
	"cheer": [[Wave.TRIANGLE, 784, 784, 0.0, 0.1, 0.25, 0.005, 1.0, 0.02, 8.0], [Wave.TRIANGLE, 988, 988, 0.1, 0.1, 0.25, 0.005, 1.0, 0.02, 8.0], [Wave.TRIANGLE, 1175, 1568, 0.2, 0.25, 0.25, 0.005, 1.0, 0.04, 9.0], [Wave.NOISE, 0, 0, 0.0, 0.45, 0.08, 0.02, 0.9]],
	"climb": [[Wave.TRIANGLE, 523, 523, 0.0, 0.1, 0.3, 0.005], [Wave.TRIANGLE, 659, 659, 0.12, 0.1, 0.3, 0.005], [Wave.TRIANGLE, 784, 784, 0.24, 0.1, 0.3, 0.005], [Wave.TRIANGLE, 1047, 1047, 0.36, 0.2, 0.3, 0.005]],
	"hiss": [[Wave.NOISE, 0, 0, 0.0, 0.4, 0.35, 0.08, 0.95]],
	"gulp": [[Wave.SINE, 320, 90, 0.0, 0.22, 0.7, 0.005], [Wave.SINE, 160, 70, 0.12, 0.18, 0.4, 0.005]],
	"slide": [[Wave.SINE, 700, 160, 0.0, 0.9, 0.22, 0.05], [Wave.TRIANGLE, 350, 80, 0.0, 0.9, 0.15, 0.05]],
	"pop": [[Wave.SINE, 380, 1100, 0.0, 0.1, 0.5, 0.002]],
	"extra": [[Wave.TRIANGLE, 1319, 1319, 0.0, 0.1, 0.3, 0.003], [Wave.TRIANGLE, 1760, 1760, 0.09, 0.22, 0.3, 0.003]],
	"no_move": [[Wave.SQUARE, 220, 180, 0.0, 0.14, 0.18, 0.005], [Wave.SQUARE, 180, 140, 0.16, 0.2, 0.18, 0.005]],
	"home": [[Wave.TRIANGLE, 1047, 1047, 0.0, 0.12, 0.3, 0.003], [Wave.TRIANGLE, 1319, 1319, 0.1, 0.12, 0.3, 0.003], [Wave.TRIANGLE, 1568, 1568, 0.2, 0.3, 0.3, 0.003]],
	# Winner: bouncy "ta-da-da-DAAA" on a kazoo with a drum, a spring boing and a party horn.
	"win": [
		[Wave.NOISE, 0, 0, 0.00, 0.08, 0.35, 0.002, 0.3], [Wave.NOISE, 0, 0, 0.18, 0.08, 0.35, 0.002, 0.3],
		[Wave.NOISE, 0, 0, 0.36, 0.08, 0.35, 0.002, 0.3], [Wave.NOISE, 0, 0, 0.54, 0.12, 0.45, 0.002, 0.25],
		[Wave.SAW, 392, 392, 0.00, 0.15, 0.22, 0.01, 1.0, 0.02, 6.0], [Wave.SAW, 523, 523, 0.18, 0.15, 0.22, 0.01, 1.0, 0.02, 6.0],
		[Wave.SAW, 659, 659, 0.36, 0.15, 0.22, 0.01, 1.0, 0.02, 6.0], [Wave.SAW, 784, 784, 0.54, 0.75, 0.26, 0.01, 1.0, 0.035, 6.5],
		[Wave.SAW, 988, 988, 0.54, 0.75, 0.12, 0.01, 1.0, 0.035, 6.5], [Wave.TRIANGLE, 392, 392, 0.54, 0.75, 0.2, 0.01],
		[Wave.SINE, 180, 900, 0.40, 0.35, 0.18, 0.005, 1.0, 0.12, 16.0],
		[Wave.SAW, 520, 560, 1.05, 0.55, 0.2, 0.02, 1.0, 0.05, 9.0], [Wave.NOISE, 0, 0, 1.05, 0.5, 0.12, 0.05, 0.8],
	],
	# Party horn: buzzy "pfrrrt" with a wobble.
	"party_horn": [[Wave.SAW, 480, 540, 0.0, 0.7, 0.35, 0.03, 1.0, 0.05, 11.0], [Wave.SQUARE, 240, 270, 0.0, 0.7, 0.12, 0.03, 1.0, 0.05, 11.0], [Wave.NOISE, 0, 0, 0.0, 0.7, 0.18, 0.05, 0.7, 0.0, 0.0, 22.0]],
	# Cheeky giggle: "hee-hee-hee" falling in pitch.
	"giggle": [[Wave.TRIANGLE, 820, 560, 0.0, 0.75, 0.42, 0.01, 1.0, 0.04, 7.0, 8.5], [Wave.SINE, 1640, 1120, 0.0, 0.75, 0.1, 0.01, 1.0, 0.04, 7.0, 8.5]],
	# A crowd "yaaay!".
	"yay": [
		[Wave.SAW, 330, 420, 0.0, 0.9, 0.12, 0.08, 1.0, 0.03, 5.0], [Wave.SAW, 415, 520, 0.02, 0.88, 0.1, 0.08, 1.0, 0.03, 5.5],
		[Wave.SAW, 495, 640, 0.04, 0.86, 0.09, 0.08, 1.0, 0.03, 6.0], [Wave.SAW, 262, 330, 0.03, 0.87, 0.09, 0.08, 1.0, 0.03, 4.5],
		[Wave.NOISE, 0, 0, 0.0, 0.9, 0.12, 0.1, 0.85, 0.0, 0.0, 14.0],
	],
	# Cartoon spring.
	"boing": [[Wave.SINE, 140, 520, 0.0, 0.45, 0.5, 0.004, 1.0, 0.18, 17.0]],
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
	var vibrato_depth := float(layer[8]) if layer.size() > 8 else 0.0
	var vibrato_hz := float(layer[9]) if layer.size() > 9 else 0.0
	var tremolo_hz := float(layer[10]) if layer.size() > 10 else 0.0
	var phase := 0.0
	var low := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in samples:
		var t := float(i) / maxf(samples - 1, 1)
		# Pitch slides exponentially (sounds natural); envelope: quick attack, smooth decay.
		var seconds := float(i) / RATE
		var freq := f0 * pow(f1 / f0, t) if f0 > 0.0 and f1 > 0.0 else f0
		if vibrato_depth > 0.0:
			freq *= 1.0 + vibrato_depth * sin(TAU * vibrato_hz * seconds)
		phase = fmod(phase + freq / RATE, 1.0)
		var envelope := minf(1.0, i / attack) * pow(1.0 - t, 1.6)
		if tremolo_hz > 0.0:
			envelope *= 0.15 + 0.85 * maxf(0.0, sin(TAU * tremolo_hz * seconds))
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

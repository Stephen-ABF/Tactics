class_name ThornAudio
extends AudioStreamPlayer
var enabled = true
func tone(frequency: float, duration: float = 0.10) -> void:
	if not enabled: return
	var wave = AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = 22050
	var bytes = PackedByteArray()
	bytes.resize(int(22050 * duration) * 2)
	for i in bytes.size() / 2:
		var envelope = pow(1.0 - float(i) / (bytes.size() / 2.0), 2)
		var sample = int(sin(TAU * frequency * i / 22050.0) * envelope * 8500)
		bytes.encode_s16(i * 2, sample)
	wave.data = bytes
	stop()
	stream = wave
	play()

func _exit_tree() -> void:
	stop()
	stream = null

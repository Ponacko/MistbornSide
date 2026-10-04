extends Node
## Autoload "Audio": the slice's soundscape (DESIGN.md 13). Ambience leads:
## a quiet night of drips, distant forges and ash on tile, louder under
## tin. A low hum while the blue lines are visible, rising with flare; a
## pluck when a target locks; a bass thump on a launch; coin rings; a
## heartbeat under pewter; a thinner, reverberant mix under atium. Pitch
## follows the TimeController (AudioServer.playback_speed_scale), so
## Steelsight drops it and the ramp brings it back. Music loops per area.

const SFX := {
	"pluck": "res://audio/sfx/pluck.wav", "thump": "res://audio/sfx/thump.wav",
	"coin_ring": "res://audio/sfx/coin_ring.wav", "footstep": "res://audio/sfx/footstep.wav",
	"murmur": "res://audio/sfx/murmur.wav", "whiteout": "res://audio/sfx/whiteout.wav",
	"dagger": "res://audio/sfx/dagger.wav", "bell": "res://audio/sfx/bell.wav",
}
const MUSIC := {
	"night_city": "res://audio/music/night_city.wav",
	"kredik_shaw": "res://audio/music/kredik_shaw.wav",
}
const SILENT := -80.0

## Names of sounds started recently (tests and debugging).
var history: PackedStringArray = []
var current_track := ""

var _streams := {}
var _ambience: AudioStreamPlayer
var _hum: AudioStreamPlayer
var _heart: AudioStreamPlayer
var _music: AudioStreamPlayer
var _reverb_ambience: AudioEffectReverb
var _reverb_sfx: AudioEffectReverb
var _lowpass: AudioEffectLowPassFilter
var _atium := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_make_buses()
	_ambience = _loop_player("res://audio/ambience/night.wav", &"Ambience")
	_hum = _loop_player("res://audio/ambience/hum.wav", &"SFX")
	_heart = _loop_player("res://audio/ambience/heartbeat.wav", &"SFX")
	_music = AudioStreamPlayer.new()
	_music.bus = &"Music"
	_music.volume_db = -12.0
	add_child(_music)
	NoiseBus.noise.connect(_on_noise)


func _make_buses() -> void:
	for bus in [&"Music", &"Ambience", &"SFX"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus)
			AudioServer.set_bus_send(i, &"Master")
	_reverb_ambience = AudioEffectReverb.new()
	_reverb_ambience.wet = 0.0
	AudioServer.add_bus_effect(AudioServer.get_bus_index(&"Ambience"), _reverb_ambience)
	_reverb_sfx = AudioEffectReverb.new()
	_reverb_sfx.wet = 0.0
	AudioServer.add_bus_effect(AudioServer.get_bus_index(&"SFX"), _reverb_sfx)
	_lowpass = AudioEffectLowPassFilter.new()
	_lowpass.cutoff_hz = 20000.0
	AudioServer.add_bus_effect(0, _lowpass)


## The stream at path, set to loop over its whole length.
func looped(path: String) -> AudioStreamWAV:
	var s := _stream(path) as AudioStreamWAV
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = s.data.size() / 2
	return s


func _stream(path: String) -> AudioStream:
	if not _streams.has(path):
		_streams[path] = load(path)
	return _streams[path]


func _loop_player(path: String, bus: StringName) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = looped(path)
	p.bus = bus
	p.volume_db = SILENT
	add_child(p)
	p.play()
	return p


## Plays a one-shot, positioned in the world when `at` is given.
func play(sound: String, at := Vector2.INF, volume_db := 0.0) -> void:
	if not SFX.has(sound):
		return
	history.append(sound)
	if history.size() > 64:
		history = history.slice(history.size() - 64)
	var stream := _stream(SFX[sound])
	if at == Vector2.INF:
		var p := AudioStreamPlayer.new()
		p.stream = stream
		p.bus = &"SFX"
		p.volume_db = volume_db
		add_child(p)
		p.finished.connect(p.queue_free)
		p.play()
	else:
		var p := AudioStreamPlayer2D.new()
		p.stream = stream
		p.bus = &"SFX"
		p.volume_db = volume_db
		p.global_position = at
		p.max_distance = 900.0
		add_child(p)
		p.finished.connect(p.queue_free)
		p.play()


func play_music(track: String) -> void:
	if track == current_track or not MUSIC.has(track):
		return
	current_track = track
	_music.stream = looped(MUSIC[track])
	_music.play()


func hum_volume() -> float:
	return _hum.volume_db


func hum_pitch() -> float:
	return _hum.pitch_scale


func heartbeat_volume() -> float:
	return _heart.volume_db


func ambience_volume() -> float:
	return _ambience.volume_db


func atium_mix() -> bool:
	return _atium


func _process(delta: float) -> void:
	var real := TimeController.real_delta(delta)
	var vin := get_tree().get_first_node_in_group("player") as Vin
	var hum_target := SILENT
	var hum_pitch_target := 1.0
	var heart_target := SILENT
	var ambience_target := -12.0
	var atium := false
	if vin:
		if not vin.allomancy.lines.is_empty():
			hum_target = -18.0
			if vin.allomancy.force_active:
				hum_target = -13.0
				if vin.controls.flare_held:
					hum_pitch_target = 1.35
		if vin.pewter_on:
			heart_target = -10.0
		if vin.tin_on:
			ambience_target = -5.0
		atium = vin.atium.burning
	_hum.volume_db = move_toward(_hum.volume_db, hum_target, real * 120.0)
	_hum.pitch_scale = move_toward(_hum.pitch_scale, hum_pitch_target, real * 2.0)
	_heart.volume_db = move_toward(_heart.volume_db, heart_target, real * 90.0)
	_ambience.volume_db = move_toward(_ambience.volume_db, ambience_target, real * 30.0)
	_heart.pitch_scale = 1.25 if vin and vin.pewter_flared() else 1.0
	if atium != _atium:
		_atium = atium
		_reverb_ambience.wet = 0.45 if atium else 0.0
		_reverb_sfx.wet = 0.45 if atium else 0.0
		_lowpass.cutoff_hz = 1800.0 if atium else 20000.0


func _on_noise(pos: Vector2, loudness: float, kind: NoiseBus.Kind) -> void:
	var vin := get_tree().get_first_node_in_group("player") as Vin
	match kind:
		NoiseBus.Kind.BELL:
			play("bell", pos)
		NoiseBus.Kind.FOOTSTEP:
			# Through walls and streets away: heard only with tin.
			if vin and vin.tin_on:
				play("footstep", pos, -14.0 + loudness * 6.0)
		NoiseBus.Kind.VOICE:
			if vin and vin.tin_on:
				play("murmur", pos, -12.0)


func reset_for_test() -> void:
	history.clear()

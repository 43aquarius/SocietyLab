## AudioManager（自动加载单例）：SFX 池 + 环境氛围。
extends Node

var _streams: Dictionary = {}
var _sfx_players: Array = []
var ambient_player: AudioStreamPlayer
var ambient_on := true
var master_volume := 0.8

const SFX_IDS := ["click", "hover", "chime", "thud", "build", "celebrate"]

func _ready() -> void:
	for id in SFX_IDS:
		var path := "res://assets/audio/%s.wav" % id
		if ResourceLoader.exists(path):
			_streams[id] = load(path)
		else:
			push_warning("Audio: 音频未导入 %s" % path)
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.volume_db = linear_to_db(0.9)
		add_child(p)
		_sfx_players.append(p)
	var amb_path := "res://assets/audio/ambient_loop.wav"
	if ResourceLoader.exists(amb_path):
		ambient_player = AudioStreamPlayer.new()
		ambient_player.stream = load(amb_path)
		ambient_player.volume_db = linear_to_db(0.55)
		add_child(ambient_player)
	set_master_volume(master_volume)
	if ambient_on and ambient_player != null:
		ambient_player.play()

func play(id: String, pitch_jitter := true) -> void:
	if not _streams.has(id):
		return
	for p in _sfx_players:
		if not p.playing:
			p.stream = _streams[id]
			p.pitch_scale = randf_range(0.94, 1.07) if pitch_jitter else 1.0
			p.play()
			return
	# 全忙：复用第一个
	if not _sfx_players.is_empty():
		var p0: AudioStreamPlayer = _sfx_players[0]
		p0.stream = _streams[id]
		p0.play()

func play_ambient() -> void:
	if ambient_player != null and not ambient_player.playing:
		ambient_player.play()

func stop_ambient() -> void:
	if ambient_player != null:
		ambient_player.stop()

func set_master_volume(v: float) -> void:
	master_volume = clamp(v, 0.0, 1.0)
	var db := linear_to_db(pow(master_volume, 1.6)) if master_volume > 0.003 else -60.0
	AudioServer.set_bus_volume_db(0, db)
	for p in _sfx_players:
		p.volume_db = db + linear_to_db(0.9)
	if ambient_player != null:
		ambient_player.volume_db = db + linear_to_db(0.55)

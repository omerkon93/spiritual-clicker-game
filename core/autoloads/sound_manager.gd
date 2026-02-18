extends Node

# Pool Settings
const POOL_SIZE = 12 # How many overlapping sounds can we play?
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_player_idx = 0

# Music Player (Only need one)
var _music_player: AudioStreamPlayer

func _ready():
	# 1. Setup SFX Pool
	for i in range(POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX" # Route to SFX Bus
		add_child(player)
		_sfx_players.append(player)
		
	# 2. Setup Music Player
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music" # Route to Music Bus
	add_child(_music_player)

# Call this from ANYWHERE: SoundManager.play_sfx(my_sound)
func play_sfx(stream: AudioStream, pitch_scale: float = 1.0, pitch_randomness: float = 0.0):
	if not stream: return
	
	# Get the next available player in the ring buffer
	var player = _sfx_players[_next_player_idx]
	
	# Configure
	player.stream = stream
	player.pitch_scale = pitch_scale + randf_range(-pitch_randomness, pitch_randomness)
	player.play()
	
	# Move index (Loop back to 0 if we hit the end)
	_next_player_idx = (_next_player_idx + 1) % POOL_SIZE

func play_music(stream: AudioStream, fade_duration: float = 1.0):
	if _music_player.stream == stream and _music_player.playing:
		return

	# 1. Create a Tween for the animation
	var tween = create_tween()
	
	# 2. Fade OUT (Volume down to -80db)
	# We use half the duration for fade out, half for fade in
	if _music_player.playing:
		tween.tween_property(_music_player, "volume_db", -80.0, fade_duration / 2.0)
	
	# 3. Swap the song (Run this code after the fade out finishes)
	tween.tween_callback(func():
		_music_player.stream = stream
		_music_player.play()
	)
	
	# 4. Fade IN (Volume back up to 0db)
	tween.tween_property(_music_player, "volume_db", 0.0, fade_duration / 2.0)

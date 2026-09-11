import 'package:just_audio/just_audio.dart';

class SosAudioService {
  SosAudioService._();

  static final SosAudioService instance = SosAudioService._();

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  Future<void> playSiren() async {
    if (_isPlaying) return;
    await _player.setAsset(
      'assets/audio/freesound_community-fire-truck-siren-29900.mp3.mpeg',
    );
    await _player.setLoopMode(LoopMode.one);
    await _player.play();
    _isPlaying = true;
  }

  Future<void> stopSiren() async {
    if (!_isPlaying) return;
    await _player.stop();
    _isPlaying = false;
  }

  bool get isPlaying => _isPlaying;
}

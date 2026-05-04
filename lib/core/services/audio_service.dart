import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class AudioService extends ChangeNotifier {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  
  final AudioPlayer _player = AudioPlayer();
  int _playingReference = -1;

  AudioService._internal() {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _playingReference = -1;
        _player.stop();
      }
      notifyListeners();
    });
    
    _player.positionStream.listen((_) => notifyListeners());
    _player.durationStream.listen((_) => notifyListeners());
  }

  int get playingReference => _playingReference;
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;

  Future<void> togglePlay(int reference) async {
    if (_playingReference == reference) {
      if (isPlaying) {
        await _player.pause();
      } else {
        await _player.play();
      }
    } else {
      try {
        final String assetPath = 'assets/audio/a$reference.mp3';
        // Verify asset exists by attempting to load it
        await rootBundle.load(assetPath);
        
        await _player.stop();
        _playingReference = reference;
        await _player.setAsset(assetPath);
        await _player.play();
      } catch (e) {
        _playingReference = -1;
        debugPrint('Audio playback error for reference $reference: $e');
        // Re-throw to let UI handle it if needed
        rethrow;
      }
    }
    notifyListeners();
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> stop() async {
    await _player.stop();
    _playingReference = -1;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

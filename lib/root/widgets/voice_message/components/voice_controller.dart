import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:notesapp/root/widgets/voice_message/components/helpers/play_status.dart';
import 'package:notesapp/root/widgets/voice_message/components/helpers/utils.dart';

/// A controller for managing voice playback.
///
/// The [VoiceController] class provides functionality for playing, pausing, stopping, and seeking voice playback.
/// It uses the [just_audio](https://pub.dev/packages/just_audio) package for audio playback.
/// The controller also supports changing the playback speed and provides UI updates through a [ValueNotifier].
class VoiceController extends MyTicker {

  /// ========================================================== //
  /// Memoization Section                                        //
  /// ========================================================== //

  // 🧠 keep waveform memory cache (shared across instances)
  static final Map<String, List<double>> _waveformCache = {};

  // 🧠 keep remaining time cache so new controllers can show it immediately
  static final Map<String, String> _remainingTimeCache = {};

  // 🧠 Registry of active controllers (useful for global stopAll etc.)
  static final Set<VoiceController> _activeControllers = <VoiceController>{};

  // 🧠 Max Duration of an audio note cache
  static final Map<String, Duration> _durationCache = {}; 

  final String audioSrc;
  late Duration maxDuration;
  Duration currentDuration = Duration.zero;
  final Function() onComplete;
  final Function() onPlaying;
  final Function() onPause;
  final Function(Object)? onError;
  final double noiseWidth = 50.5.width();
  late AnimationController animController;
  final AudioPlayer _player = AudioPlayer();
  final bool isFile;
  final String? cacheKey;
  PlayStatus playStatus = PlayStatus.init;
  PlaySpeed speed = PlaySpeed.x1;
  ValueNotifier updater = ValueNotifier(null);
  List<double>? randoms;
  StreamSubscription? positionStream;
  StreamSubscription? playerStateStream;
  double? downloadProgress = 0;
  final int noiseCount;
  StreamSubscription<FileResponse>? downloadStreamSubscription;

  // Internal prepared flag: true after setFilePath/setUrl and listeners attached
  bool _isPrepared = false;

  /// Gets the current playback position of the voice in milliseconds (clamped).
  double get currentMillSeconds {
    final c = currentDuration.inMilliseconds.toDouble();
    if (c >= maxMillSeconds) {
      return maxMillSeconds;
    }
    return c;
  }

  bool isSeeking = false;

  bool get isPlaying => playStatus == PlayStatus.playing;

  bool get isInit => playStatus == PlayStatus.init;

  bool get isDownloading => playStatus == PlayStatus.downloading;

  bool get isDownloadError => playStatus == PlayStatus.downloadError;

  bool get isStop => playStatus == PlayStatus.stop;

  bool get isPause => playStatus == PlayStatus.pause;

  double get maxMillSeconds => maxDuration.inMilliseconds.toDouble();

  /// Creates a new [VoiceController] instance.
  ///
  /// Note: This constructor registers the controller in a lightweight registry but
  /// does NOT prepare the audio resource. Preparation (calling setFilePath / setUrl)
  /// is deferred until play() is called to avoid creating native AudioTrack resources
  /// for every message eagerly.
  VoiceController({
    required this.audioSrc,
    required this.maxDuration,
    required this.isFile,
    required this.onComplete,
    required this.onPause,
    required this.onPlaying,
    this.noiseCount = 24,
    this.onError,
    this.randoms,
    this.cacheKey,
  }) {
    // Debug
    if (kDebugMode) {
      debugPrint('VoiceController: created for $audioSrc');
    }

    // register for global tracking
    _activeControllers.add(this);

    // Waveform initialization (keep placeholder behaviour)
    if (randoms == null || randoms!.isEmpty) {
      if (_waveformCache.containsKey(audioSrc)) {
        randoms = _waveformCache[audioSrc]!;
      } else {
        setSilent(); // placeholders only once
        if (isFile) {
          // extract waveform asynchronously but DO NOT prepare audio player here
          getWaveform().then((wave) {
            if (wave.isNotEmpty) {
              randoms = wave;
              _waveformCache[audioSrc] = wave; // cache waveform in memory
              _updateUi();
            }
          });
        }
      }
    }

    animController = AnimationController(
      vsync: this,
      upperBound: noiseWidth,
      duration: maxDuration,
    );

    _initDuration(); // Get initial / max duration right away

    // IMPORTANT: do NOT call init() here. Preparation of the AudioPlayer is deferred
    // until the user actually plays to avoid allocating AudioTrack resources prematurely.
    // init();
    // _listenToRemainingTime();
    // _listenToPlayerState();
  }

  /// Initializes the voice controller (kept for compatibility; no longer called automatically).
  Future init() async {
    await setMaxDuration(audioSrc);
    _updateUi();
  }


  Future<void> _initDuration() async {
  // Skip if already cached
  if (_durationCache.containsKey(audioSrc)) {
    maxDuration = _durationCache[audioSrc]!;
    animController.duration = maxDuration;
    _updateUi();
    return;
  }

  // Otherwise, get and cache it
  final duration = await _getAudioDuration(audioSrc);
  if (duration != null) {
    maxDuration = duration;
    _durationCache[audioSrc] = duration;
    animController.duration = duration;
    _updateUi();
  }
}

  /// Play the audio.
  ///
  /// This method lazily prepares the audio resource on first call (via setMaxDuration),
  /// attaches listeners, and then starts playback. This avoids pre-allocating platform
  /// audio resources for every message on screen.
  Future play() async {
    if (kDebugMode) {
      debugPrint('VoiceController: play() called for $audioSrc, prepared=$_isPrepared');
    }

    try {
      playStatus = PlayStatus.downloading;
      _updateUi();

      // Prepare audio resource and attach listeners only once
      if (!_isPrepared) {
        try {
          await setMaxDuration(audioSrc); // calls _player.setFilePath / setUrl
          _isPrepared = true;

          // attach listeners after we've prepared the player
          _listenToRemainingTime();
          _listenToPlayerState();
        } catch (e) {
          playStatus = PlayStatus.downloadError;
          _updateUi();
          if (onError != null) onError!(e);
          return;
        }
      }

      if (isFile) {
        final path = await _getFileFromCache();
        await startPlaying(path);
        onPlaying();
      } else {
        // For remote sources we still use the cache-with-progress path.
        downloadStreamSubscription = _getFileFromCacheWithProgress()
            .listen((FileResponse fileResponse) async {
          if (fileResponse is FileInfo) {
            await startPlaying(fileResponse.file.path);
            onPlaying();
          } else if (fileResponse is DownloadProgress) {
            _updateUi();
            downloadProgress = fileResponse.progress;
          }
        });
      }
    } catch (err) {
      playStatus = PlayStatus.downloadError;
      _updateUi();
      if (onError != null) {
        onError!(err);
      } else {
        rethrow;
      }
    }
  }

  void _listenToRemainingTime() {
    // Attach only once
    positionStream ??= _player.positionStream.listen((Duration p) async {
      if (!isDownloading) currentDuration = p;

      // keep a cached display string so new controller instances can show it immediately
      _remainingTimeCache[audioSrc] = currentDuration.formattedTime;

      final value = (noiseWidth * currentMillSeconds) / maxMillSeconds;
      try {
        animController.value = value;
      } catch (_) {
        // ignore if controller disposed
      }
      _updateUi();

      if (p.inMilliseconds >= maxMillSeconds) {
        await _player.stop();
        currentDuration = Duration.zero;
        playStatus = PlayStatus.init;
        try {
          animController.reset();
        } catch (_) {}
        // clear cached position/time when audio completes
        _remainingTimeCache.remove(audioSrc);
        _updateUi();
        onComplete();
      }
    });
  }

  void _updateUi() {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    try {
      updater.notifyListeners();
    } catch (_) {}
  }

  /// Stops playing the voice.
  Future stopPlaying() async {
    try {
      await _player.pause();
    } catch (_) {}
    playStatus = PlayStatus.stop;
  }

  /// Starts playing the voice from the given path.
  Future startPlaying(String path) async {
    if (kDebugMode) {
      debugPrint('VoiceController: startPlaying path=$path for $audioSrc');
    }

    // Use file Uri for local files
    await _player.setAudioSource(
      AudioSource.uri(Uri.file(path)),
      initialPosition: currentDuration,
    );
    await _player.play();
    await _player.setSpeed(speed.getSpeed);
  }

  /// Dispose the controller and free native resources.
  ///
  /// This is defensive: we attempt to stop first, then dispose the player, cancel streams,
  /// unregister from the registry and dispose UI-related controllers.
  Future<void> dispose() async {
    if (kDebugMode) {
      debugPrint('VoiceController: dispose() for $audioSrc');
    }

    // unregister from registry early to avoid races
    _activeControllers.remove(this);

    // stop player first (best-effort)
    try {
      await _player.stop();
    } catch (e) {
      if (kDebugMode) debugPrint('VoiceController: stop error $e');
    }

    // then dispose the platform player
    try {
      await _player.dispose();
    } catch (e) {
      if (kDebugMode) debugPrint('VoiceController: dispose player error $e');
    }

    // cancel streams and any download subscription
    try {
      await positionStream?.cancel();
    } catch (_) {}
    try {
      await playerStateStream?.cancel();
    } catch (_) {}
    try {
      await downloadStreamSubscription?.cancel();
    } catch (_) {}

    // dispose ui animation controller
    try {
      animController.dispose();
    } catch (_) {}

    // dispose updater
    try {
      updater.dispose();
    } catch (_) {}

    // reset basic state
    currentDuration = Duration.zero;
    playStatus = PlayStatus.init;
  }

  /// Seeks to the given [duration].
  void onSeek(Duration duration) {
    isSeeking = false;
    currentDuration = duration;
    _updateUi();
    _player.seek(duration);
  }

  /// Pauses the voice playback.
  void pausePlaying() {
    try {
      _player.pause();
    } catch (_) {}
    playStatus = PlayStatus.pause;
    _updateUi();
    onPause();
  }

  Future<String> _getFileFromCache() async {
    if (isFile) {
      return audioSrc;
    }
    final p =
        await DefaultCacheManager().getSingleFile(audioSrc, key: cacheKey);
    return p.path;
  }

  Stream<FileResponse> _getFileFromCacheWithProgress() {
    if (isFile) {
      throw Exception("This method is not applicable for local files.");
    }
    return DefaultCacheManager()
        .getFileStream(audioSrc, key: cacheKey, withProgress: true);
  }

  void cancelDownload() {
    try {
      downloadStreamSubscription?.cancel();
    } catch (_) {}
    playStatus = PlayStatus.init;
    _updateUi();
  }

  /// Listen to player state (attach once).
  void _listenToPlayerState() {
    playerStateStream ??= _player.playerStateStream.listen((event) async {
      if (event.processingState == ProcessingState.completed) {
        // handled by position stream / completion logic
      } else if (event.playing) {
        playStatus = PlayStatus.playing;
        _updateUi();
      }
    });
  }

  /// Changes the speed of the voice playback.
  void changeSpeed() {
    switch (speed) {
      case PlaySpeed.x1:
        speed = PlaySpeed.x1_25;
        break;
      case PlaySpeed.x1_25:
        speed = PlaySpeed.x1_5;
        break;
      case PlaySpeed.x1_5:
        speed = PlaySpeed.x1_75;
        break;
      case PlaySpeed.x1_75:
        speed = PlaySpeed.x2;
        break;
      case PlaySpeed.x2:
        speed = PlaySpeed.x2_25;
        break;
      case PlaySpeed.x2_25:
        speed = PlaySpeed.x1;
        break;
    }
    _player.setSpeed(speed.getSpeed);
    _updateUi();
  }

  /// Called when user starts dragging the slider.
  void onChangeSliderStart(double value) {
    isSeeking = true;
    // pause the voice
    pausePlaying();
  }

  void _setRandoms() {
    randoms = [];
    for (var i = 0; i < noiseCount; i++) {
      randoms!.add(5.74.width() * Random().nextDouble() + .26.width());
    }
  }

  void setSilent({double maxHeight = 40}) {
    const minHeightFactor = 0.2;
    final minHeight = minHeightFactor * maxHeight;

    // Create an even "flat" placeholder — no randomness
    randoms = List.generate(noiseCount, (_) => minHeight);
  }

  Future<List<double>> getWaveform({double? maxHeight}) async {
    final waveOutFile = File('$audioSrc.waveform');

    // ✅ STEP 1: If waveform cache already exists, just parse it.
    if (await waveOutFile.exists()) {
      final waveform = await JustWaveform.parse(waveOutFile);
      return _convertWaveformToBars(waveform, maxHeight ?? 40);
    }

    // ✅ STEP 2: Otherwise, extract and save waveform.
    final waveformStream = JustWaveform.extract(
      audioInFile: File(audioSrc),
      waveOutFile: waveOutFile,
    );

    Waveform? waveform;
    await for (final progress in waveformStream) {
      if (progress.waveform != null) {
        waveform = progress.waveform;
        break;
      }
    }

    if (waveform == null) return [];

    // 💡 Try to get the actual duration without interfering with the main player
final duration = await _getAudioDuration(audioSrc);
if (duration != null) {
  maxDuration = duration;
  animController.duration = duration;
  _updateUi(); // ✅ force UI update
}
    return _convertWaveformToBars(waveform, maxHeight ?? 40);
  }

  List<double> _convertWaveformToBars(Waveform waveform, double maxHeight) {
    final List<double> scaled = [];
    final step = waveform.length / noiseCount;

    for (int i = 0; i < noiseCount; i++) {
      final idx = (i * step).floor().clamp(0, waveform.length - 1);
      final minVal = waveform.getPixelMin(idx);
      final maxVal = waveform.getPixelMax(idx);

      // Normalize
      final normalized = (maxVal - minVal).abs() / 65535.0;

      // Apply slight boost for quiet parts
      const minHeightFactor = 0.2;
      final value = (normalized * (1 - minHeightFactor) + minHeightFactor) * maxHeight;

      scaled.add(value);
    }

    return scaled;
  }

  Future<Duration?> _getAudioDuration(String path) async {
  try {
    final tmpPlayer = AudioPlayer();
    Duration? duration;
    if (isFile) {
      duration = await tmpPlayer.setFilePath(path);
    } else {
      duration = await tmpPlayer.setUrl(path);
    }
    await tmpPlayer.dispose();
    return duration;
  } catch (e) {
    debugPrint('VoiceController: failed to get audio duration: $e');
    return null;
  }
}

  /// Called when user moves the slider (updates UI but does not seek immediately).
  void onChanging(double d) {
    currentDuration = Duration(milliseconds: d.toInt());
    final value = (noiseWidth * d) / maxMillSeconds;
    try {
      animController.value = value;
    } catch (_) {}
    _updateUi();
  }

  ///
  String get remainingTime {
    if (currentDuration == Duration.zero) {
      return maxDuration.formattedTime;
    }
    if (isSeeking || isPause) {
      return currentDuration.formattedTime;
    }
    if (isInit) {
      return maxDuration.formattedTime;
    }
    return currentDuration.formattedTime;
  }

  /// Sets the maximum duration of the voice (prepares the player by setting the source).
  Future setMaxDuration(String path) async {
    try {
      if (_durationCache.containsKey(audioSrc)) {
        maxDuration = _durationCache[audioSrc]!;
        animController.duration = maxDuration;
        return;
      }

      final duration =
          isFile ? await _player.setFilePath(path) : await _player.setUrl(path);

      if (duration != null) {
        maxDuration = duration;
        _durationCache[audioSrc] = duration;
        animController.duration = duration;
      }
    } catch (err) {
      debugPrint("VoiceController: can't get duration from $path - $err");
      if (onError != null) onError!(err);
    }
  }


  /// Global helper to stop and dispose any active controllers (useful for emergency cleanup).
  static Future<void> stopAll() async {
    final copy = List<VoiceController>.from(_activeControllers);
    for (final c in copy) {
      try {
        await c._player.stop();
      } catch (_) {}
      try {
        await c._player.dispose();
      } catch (_) {}
      try {
        await c.positionStream?.cancel();
      } catch (_) {}
      try {
        await c.playerStateStream?.cancel();
      } catch (_) {}
      try {
        await c.downloadStreamSubscription?.cancel();
      } catch (_) {}
      try {
        c.animController.dispose();
      } catch (_) {}
      _activeControllers.remove(c);
      c.playStatus = PlayStatus.init;
    }
  }
}

///
/// A custom [TickerProvider] implementation for the voice controller.
///
/// This class provides the necessary functionality for controlling the voice playback.
/// It implements the [TickerProvider] interface, allowing it to create [Ticker] objects
/// that can be used to schedule animations or other periodic tasks.
class MyTicker extends TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick);
  }
}
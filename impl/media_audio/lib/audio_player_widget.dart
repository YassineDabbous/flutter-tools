import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerView extends StatefulWidget {
  final String url;
  const AudioPlayerView({super.key, required this.url});
  @override
  State<AudioPlayerView> createState() => _AudioPlayerViewState();
}

class _AudioPlayerViewState extends State<AudioPlayerView> {
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    // Set a sequence of audio sources that will be played by the audio player.
    _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(widget.url))).catchError((error) {
      // catch load errors: 404, invalid url ...
      logUI.error("An error occured $error");
      return null;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: _audioPlayer.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        return _playerButton(playerState);
      },
    );
  }

  Widget _playerButton(PlayerState? playerState) {
    // 1
    final processingState = playerState?.processingState;
    if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
      // 2
      return const SizedBox(
        width: 64.0,
        height: 64.0,
        child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()),
      );
    } else if (_audioPlayer.playing != true) {
      // 3
      return IconButton(icon: const Icon(Icons.play_arrow), iconSize: 64.0, onPressed: _audioPlayer.play);
    } else if (processingState != ProcessingState.completed) {
      // 4
      return IconButton(icon: const Icon(Icons.pause), iconSize: 64.0, onPressed: _audioPlayer.pause);
    } else {
      // 5
      return IconButton(
        icon: const Icon(Icons.replay),
        iconSize: 64.0,
        onPressed: () => _audioPlayer.seek(Duration.zero, index: _audioPlayer.effectiveIndices.first),
      );
    }
  }
}

import 'package:concrete/concrete.dart';
import 'package:flutter/material.dart';
import 'package:media_audio/media_audio.dart';
import 'package:media_video/media_video.dart';

class MediaWidget extends StatelessWidget {
  final FileType mediaType;
  final String url;
  final String? title;
  const MediaWidget({
    required this.url,
    required this.mediaType,
    this.title,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaType == FileType.VIDEO) {
      return InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VideoPlayerScreen(url: url)),
        ),
        child: Container(
          color: Colors.green,
          padding: const EdgeInsets.all(8),
          child: Container(
            color: Colors.white,
            width: 200,
            child: const Center(child: Icon(Icons.video_file)),
          ),
        ),
      );
    }
    if (mediaType == FileType.AUDIO) {
      return InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AudioPlayerScreen(url: url)),
        ),
        child: Container(
          color: Colors.red,
          padding: const EdgeInsets.all(8),
          child: Container(
            color: Colors.white,
            width: 200,
            child: const Center(child: Icon(Icons.audio_file)),
          ),
        ),
      );
    }
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ImageFullScreen('MediaItem', url)),
      ),
      child: Hero(tag: 'MediaItem', child: Img.network(url)),
    );
  }
}

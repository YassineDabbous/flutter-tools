import 'package:flutter/material.dart';
import 'package:media_audio/media_audio.dart';

class AudioPlayerScreen extends StatelessWidget {
  final String url;
  final String? title;
  const AudioPlayerScreen({super.key, required this.url, this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (title != null) Text(title!),
            AudioPlayerView(url: url),
          ],
        ),
      ),
    );
  }
}

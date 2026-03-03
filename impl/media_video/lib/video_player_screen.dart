import 'package:flutter/material.dart';
import 'package:media_video/media_video.dart';

class VideoPlayerScreen extends StatelessWidget {
  final String url;
  final String? title;
  const VideoPlayerScreen({super.key, required this.url, this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: true),
      body: Container(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (title != null) Text(title!),
              VideoPlayerWidget(url: url),
            ],
          ),
        ),
      ),
    );
  }
}

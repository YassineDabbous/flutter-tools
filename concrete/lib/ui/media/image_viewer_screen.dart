import 'package:concrete/concrete.dart';
import 'package:flutter/material.dart';

class ImageFullScreen extends StatelessWidget {
  final String url;
  final String tag;
  const ImageFullScreen(this.tag, this.url, {super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: Colors.black,
              child: Hero(
                tag: tag,
                child: InteractiveViewer(
                  panEnabled: true, // Set it to false to prevent panning.
                  boundaryMargin: const EdgeInsets.all(10),
                  minScale: 0.5,
                  maxScale: 10,
                  child: Img.network(url, fit: BoxFit.fitWidth),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

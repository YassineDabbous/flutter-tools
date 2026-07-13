import 'dart:typed_data';

import 'package:concrete/concrete.dart';
import 'package:flutter/material.dart';
import 'package:yaseen_file_picker/my_picker.dart';

class FileFieldPicker extends StatelessWidget {
  final FileField file;
  final String? emptyMsg;
  final Function(Uint8List?) onPick;
  const FileFieldPicker({
    super.key,
    required this.file,
    this.emptyMsg,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: FileFieldPreview(file: file, emptyMsg: emptyMsg),
      onTap: () {
        switch (file.type) {
          case FileType.SVG:
            pickOneSvg(onPick: onPick);
            break;
          case FileType.AUDIO:
            pickOneAudio(onPick: onPick);
            break;
          case FileType.VIDEO:
            pickOneVideo(onPick: onPick);
            break;
          case FileType.PDF:
            pickOnePdf(onPick: onPick);
            break;
          default:
            pickOneImage(onPick: onPick);
        }
      },
    );
  }
}

class FileFieldPreview extends StatelessWidget {
  final FileField file;
  final String? emptyMsg;
  const FileFieldPreview({super.key, required this.file, this.emptyMsg});

  @override
  Widget build(BuildContext context) {
    final isEmpty = file.data == null && file.fullUrl == null;
    final filledColor = isEmpty
        ? null
        : context.colorScheme.primary.withValues(alpha: 0.3);
    switch (file.type) {
      case FileType.IMAGE:
        if (isEmpty) {
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(child: Icon(Icons.image_outlined)),
          );
        }
        return file.isOnline && file.data == null
            ? Opacity(
                opacity: file.shouldBeRemoved ? 0.5 : 1,
                child: Img.network(
                  file.fullUrl,
                  fit: BoxFit.fitHeight,
                  emptyMsg: emptyMsg,
                ),
              )
            : Img.memory(file.data!, fit: BoxFit.fill, emptyMsg: emptyMsg);
      case FileType.VIDEO:
        return Opacity(
          opacity: file.shouldBeRemoved ? 0.5 : 1,
          child: Container(
            decoration: BoxDecoration(
              color: filledColor,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Icon(
                isEmpty ? Icons.video_file_outlined : Icons.video_file,
              ),
            ),
          ),
        );
      case FileType.AUDIO:
        return Opacity(
          opacity: file.shouldBeRemoved ? 0.5 : 1,
          child: Container(
            decoration: BoxDecoration(
              color: filledColor,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Icon(
                isEmpty ? Icons.audio_file_outlined : Icons.audio_file,
              ),
            ),
          ),
        );
      default:
        return Opacity(
          opacity: file.shouldBeRemoved ? 0.5 : 1,
          child: Container(
            decoration: BoxDecoration(
              color: filledColor,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Icon(
                isEmpty ? Icons.file_present : Icons.file_present_sharp,
              ),
            ),
          ),
        );
    }
  }
}

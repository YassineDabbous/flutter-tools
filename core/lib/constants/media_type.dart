enum FileType {
  //
  IMAGE,
  IMAGE_PNG,
  //
  SVG,
  //
  AUDIO,
  // AUDIO_WAV,
  VIDEO,
  //
  PDF,
  //
  GLTF,
  GLB,
  VR,
  //
  UNKNOWN,
}

extension FileTypeExtension on FileType {
  String extension() {
    switch (this) {
      case FileType.IMAGE:
        return 'jpg';
      case FileType.SVG:
        return 'svg';
      case FileType.AUDIO:
        return 'mp3';
      case FileType.VIDEO:
        return 'mp4';
      case FileType.PDF:
        return 'pdf';
      default:
        return 'yaseen';
    }
  }

  String mediaType() {
    switch (this) {
      case FileType.IMAGE:
        return 'image/*';
      case FileType.SVG:
        return 'image/svg+xml';
      case FileType.AUDIO:
        return 'audio/*';
      case FileType.VIDEO:
        return 'video/*';
      case FileType.GLTF:
        return 'model/gltf+json';
      case FileType.GLB:
        return 'application/octet-stream';
      case FileType.PDF:
        return 'application/pdf';
      default:
        return 'yaseen';
    }
  }
}

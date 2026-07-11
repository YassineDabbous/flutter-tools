import 'dart:typed_data';

import 'package:core/core.dart' as core;
import 'package:file_picker/file_picker.dart';

Future pickOne({
  required core.FileType type,
  required Function(Uint8List?) onPick,
}) async {
  if (type == core.FileType.IMAGE) {
    await pickOneImage(onPick: onPick);
  } else if (type == core.FileType.VIDEO) {
    await pickOneVideo(onPick: onPick);
  } else if (type == core.FileType.AUDIO) {
    await pickOneAudio(onPick: onPick);
  } else if (type == core.FileType.SVG) {
    await pickOneSvg(onPick: onPick);
  } else if (type == core.FileType.GLTF) {
    await pickOneGltf(onPick: onPick);
  } else if (type == core.FileType.VR) {
    await pickOneVR(onPick: onPick);
  } else {
    await pickOneFileData(onPick: onPick);
  }
}

Future pickOneAudio({required Function(Uint8List?) onPick}) async {
  await pickOneFileData(onPick: onPick, type: FileType.audio);
}

Future pickOneImage({required Function(Uint8List?) onPick}) async {
  await pickOneFileData(onPick: onPick, type: FileType.image);
}

Future pickOneSvg({required Function(Uint8List?) onPick}) async {
  await pickOneFileData(
    onPick: onPick,
    type: FileType.custom,
    allowedExtensions: ['svg'],
  );
}

Future pickOnePdf({required Function(Uint8List?) onPick}) async {
  await pickOneFileData(
    onPick: onPick,
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );
}

Future pickOneGltf({required Function(Uint8List?) onPick}) async {
  await pickOneFileData(
    onPick: onPick,
    type: FileType.custom,
    allowedExtensions: ['gltf', 'glb'],
  );
}

Future pickOneVideo({required Function(Uint8List?) onPick}) async {
  await pickOneFileData(onPick: onPick, type: FileType.video);
}

Future pickOneVR({required Function(Uint8List?) onPick}) async {
  await pickOneFileData(
    onPick: onPick,
    type: FileType.custom,
    allowedExtensions: ['mp4'],
  ); // m3u8
}

Future pickOneFileData({
  required Function(Uint8List?) onPick,
  FileType type = FileType.any,
  List<String>? allowedExtensions,
}) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: type,
    allowMultiple: false,
    withData: true,
    allowedExtensions: allowedExtensions,
  );
  if (result != null) {
    Uint8List? file = result.files.single.bytes;
    onPick(file);
  } else {
    onPick(null);
  }
}

Future pickOneFilePath({
  required Function(String?) onPick,
  FileType type = FileType.any,
  List<String>? allowedExtensions,
}) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: type,
    allowMultiple: false,
    withData: true,
    allowedExtensions: allowedExtensions,
  );
  if (result != null) {
    onPick(result.files.single.path);
  } else {
    onPick(null);
  }
}

Future pickMulti(Function(List<Uint8List?>?) onPick) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
  );
  if (result != null) {
    //List<File> files = result.paths.map((path) => File(path!)).toList();
    List<Uint8List?> files = result.files.map((file) => file.bytes).toList();
    onPick(files);
  } else {
    onPick(null);
  }
}

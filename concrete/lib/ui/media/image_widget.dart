import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:core/core.dart';
import 'package:concrete/concrete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

export 'svg.dart';

class Img extends StatelessWidget {
  final String? emptyMsg;
  final Uint8List? bytes;
  final String? imgUrl;
  final BoxFit fit;
  final bool isSvg;
  final bool optional;
  final Color? color;
  final double? width;
  final double? height;

  const Img.network(
    this.imgUrl, {
    super.key,
    this.color,
    this.fit = BoxFit.cover,
    this.isSvg = false,
    this.optional = false,
    this.width,
    this.height,
    this.emptyMsg,
  }) : bytes = null;

  const Img.memory(
    this.bytes, {
    super.key,
    this.color,
    this.fit = BoxFit.cover,
    this.isSvg = false,
    this.optional = false,
    this.width,
    this.height,
    this.emptyMsg,
  }) : imgUrl = null;

  Img.field(
    FileField? field, {
    super.key,
    this.color,
    this.fit = BoxFit.cover,
    this.isSvg = false,
    this.optional = false,
    this.width,
    this.height,
    this.emptyMsg,
  }) : imgUrl = field?.fullUrl,
       bytes = field?.data;

  /// Loads an image from the registered [StorageService].
  static Widget storage(
    String bucket,
    String? path, {
    Key? key,
    StorageOptions? options,
    BoxFit fit = BoxFit.cover,
    bool isSvg = false,
    bool optional = false,
    double? width,
    double? height,
    String? emptyMsg,
  }) {
    if (path == null) {
      return optional
          ? const SizedBox()
          : Center(child: Text(emptyMsg ?? 'Null path'));
    }

    return FutureBuilder<String>(
      key: key,
      future: Core.get<StorageService>().getUrl(bucket, path, options: options),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(child: Text(emptyMsg ?? 'Error resolving image'));
        }
        return Img.network(
          snapshot.data!,
          fit: fit,
          isSvg: isSvg,
          optional: optional,
          width: width,
          height: height,
          emptyMsg: emptyMsg,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (bytes != null) {
      if (isSvg) {
        return SvgPicture.memory(
          bytes!,
          width: width,
          height: height,
          theme: color == null
              ? const SvgTheme()
              : SvgTheme(
                  currentColor: color!,
                ), // Theme.of(context).iconTheme.color ?? const Color(0xFF000000))
        );
      } else {
        return Image.memory(bytes!, width: width, height: height);
      }
    }
    return imgUrl == null
        ? (optional
              ? const SizedBox()
              : Center(child: Text(emptyMsg ?? 'Empty/Null url')))
        : isSvg
        ? SvgPicture.network(
            imgUrl!,
            theme: color == null
                ? const SvgTheme()
                : SvgTheme(currentColor: color!),
            width: width,
            height: height,
            //?fit: fit,
            placeholderBuilder: (BuildContext context) => const Padding(
              padding: EdgeInsets.all(8),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        : CachedNetworkImage(
            imageUrl: imgUrl!,
            fit: fit,
            width: width,
            height: height,
            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) {
              debugPrint('Img.network error: $url → $error');
              return const Center(child: Text('Unable to load Image'));
            },
          );
  }
}

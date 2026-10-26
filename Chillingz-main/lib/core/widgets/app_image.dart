import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'custom_loader.dart';

class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.source,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  final String source;
  final double? height;
  final double? width;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (source.trim().isEmpty) {
      return _placeholder(width: width, height: height);
    }

    if (source.startsWith('data:image')) {
      final bytes = _decodeDataImage(source);
      if (bytes != null) {
        return Image.memory(
          bytes,
          height: height,
          width: width,
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: _errorBuilder,
        );
      }
      return _placeholder(width: width, height: height);
    }

    if (source.startsWith('http://') || source.startsWith('https://')) {
      return Image.network(
        source,
        height: height,
        width: width,
        fit: fit,
        gaplessPlayback: true,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return const Center(child: CustomLoader());
        },
        errorBuilder: _errorBuilder,
      );
    }

    return Image.asset(
      source,
      height: height,
      width: width,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: _errorBuilder,
    );
  }

  static Uint8List? _decodeDataImage(String value) {
    final commaIndex = value.indexOf(',');
    if (commaIndex == -1 || commaIndex == value.length - 1) {
      return null;
    }

    try {
      return base64Decode(value.substring(commaIndex + 1));
    } on FormatException {
      return null;
    }
  }

  Widget _errorBuilder(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return _placeholder(width: width, height: height);
  }

  static Widget _placeholder({
    required double? width,
    required double? height,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedWidth = width ?? _finiteOrDefault(constraints.maxWidth);
        final resolvedHeight =
            height ?? _finiteOrDefault(constraints.maxHeight);

        return SizedBox(
          width: resolvedWidth,
          height: resolvedHeight,
          child: Container(
            color: Colors.black12,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image_outlined),
          ),
        );
      },
    );
  }

  static double _finiteOrDefault(double value) {
    return value.isFinite && value > 0 ? value : 48;
  }
}

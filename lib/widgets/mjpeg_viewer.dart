import 'package:flutter/material.dart';

// Platform-specific imports - mobile is default, web overrides
import 'mjpeg_viewer_mobile.dart' if (dart.library.html) 'mjpeg_viewer_web.dart';

class MjpegViewer extends StatelessWidget {
  final String streamUrl;
  final bool isLive;
  final BoxFit fit;

  const MjpegViewer({
    super.key,
    required this.streamUrl,
    this.isLive = true,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return MjpegViewerPlatform(
      streamUrl: streamUrl,
      isLive: isLive,
      fit: fit,
    );
  }
}

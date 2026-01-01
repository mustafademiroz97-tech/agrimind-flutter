import 'package:flutter/material.dart';

/// Mobile implementation of MJPEG viewer
class MjpegViewerPlatform extends StatefulWidget {
  final String streamUrl;
  final bool isLive;
  final BoxFit fit;

  const MjpegViewerPlatform({
    super.key,
    required this.streamUrl,
    this.isLive = true,
    this.fit = BoxFit.contain,
  });

  @override
  State<MjpegViewerPlatform> createState() => _MjpegViewerPlatformState();
}

class _MjpegViewerPlatformState extends State<MjpegViewerPlatform> {
  bool _hasError = false;
  String _errorMessage = '';
  Key _imageKey = UniqueKey();

  void _refresh() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _imageKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }

    return Image.network(
      key: _imageKey,
      widget.streamUrl,
      fit: widget.fit,
      gaplessPlayback: true,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Yükleniyor...',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // Trigger error state on next frame to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_hasError) {
            setState(() {
              _hasError = true;
              _errorMessage = 'Kamera bağlantısı kurulamadı';
            });
          }
        });
        return _buildErrorWidget();
      },
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _errorMessage.isEmpty ? 'Kamera bağlantısı yok' : _errorMessage,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Yeniden Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

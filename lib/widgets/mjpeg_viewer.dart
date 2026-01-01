import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

// Web için platform-specific import
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html if (dart.library.io) 'mjpeg_viewer_stub.dart';
import 'dart:ui_web' as ui_web if (dart.library.io) 'mjpeg_viewer_stub.dart';

class MjpegViewer extends StatefulWidget {
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
  State<MjpegViewer> createState() => _MjpegViewerState();
}

class _MjpegViewerState extends State<MjpegViewer> {
  final String _viewId = 'mjpeg-viewer-${DateTime.now().millisecondsSinceEpoch}';
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _registerWebView();
    }
  }

  void _registerWebView() {
    // Web için HTML img element oluştur
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) {
        final img = html.ImageElement()
          ..src = widget.streamUrl
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'contain'
          ..style.backgroundColor = 'black';
        
        img.onLoad.listen((_) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasError = false;
            });
          }
        });
        
        img.onError.listen((_) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = 'Kamera bağlantısı kurulamadı';
            });
          }
        });
        
        return img;
      },
    );
  }

  void _refresh() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });
    
    if (kIsWeb) {
      // Web'de img src'yi güncelle
      _registerWebView();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Stack(
        children: [
          HtmlElementView(viewType: _viewId),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (_hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(_errorMessage ?? 'Kamera bağlantısı yok',
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Yenile'),
                  ),
                ],
              ),
            ),
        ],
      );
    } else {
      // Mobile için basit Image.network
      return Image.network(
        widget.streamUrl,
        fit: widget.fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.videocam_off, size: 48, color: Colors.grey),
                const SizedBox(height: 8),
                const Text('Kamera bağlantısı yok'),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Yenile'),
                ),
              ],
            ),
          );
        },
      );
    }
  }
}

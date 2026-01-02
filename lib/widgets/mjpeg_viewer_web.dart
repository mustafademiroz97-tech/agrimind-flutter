// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

/// Web implementation of MJPEG viewer using HtmlElementView
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
  late final String _viewId;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _viewId = 'mjpeg-viewer-${DateTime.now().millisecondsSinceEpoch}';
    _registerWebView();
  }

  void _registerWebView() {
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) {
        // MJPEG stream için img tag kullan - her seferinde yeni URL ile cache bypass
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final img = html.ImageElement()
          ..src = '${widget.streamUrl}?t=$timestamp'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'contain'
          ..style.backgroundColor = 'black'
          ..crossOrigin = 'anonymous';

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
      _errorMessage = '';
    });
    _registerWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        HtmlElementView(viewType: _viewId),
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Kamera yükleniyor...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        if (_hasError)
          Container(
            color: Colors.black87,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage.isEmpty
                        ? 'Kamera bağlantısı yok'
                        : _errorMessage,
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
          ),
      ],
    );
  }
}

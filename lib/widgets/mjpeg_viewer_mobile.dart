import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Mobile implementation of MJPEG viewer using snapshot polling
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
  Uint8List? _currentFrame;
  Timer? _pollingTimer;
  bool _isLoading = true;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    if (widget.isLive) {
      _startPolling();
    } else {
      _loadSingleFrame();
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(MjpegViewerPlatform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamUrl != widget.streamUrl ||
        oldWidget.isLive != widget.isLive) {
      _pollingTimer?.cancel();
      _retryCount = 0;
      if (widget.isLive) {
        _startPolling();
      } else {
        _loadSingleFrame();
      }
    }
  }

  void _startPolling() {
    _fetchFrame();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      _fetchFrame();
    });
  }

  void _loadSingleFrame() {
    _fetchFrame();
  }

  Future<void> _fetchFrame() async {
    if (!mounted) return;

    try {
      // Snapshot URL oluştur
      String snapshotUrl = widget.streamUrl;
      if (snapshotUrl.contains('/video_feed')) {
        snapshotUrl = snapshotUrl.replaceAll('/video_feed', '/api/camera/snapshot');
      }
      
      // Cache bypass için timestamp ekle
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = '$snapshotUrl?t=$timestamp';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Cache-Control': 'no-cache'},
      ).timeout(const Duration(seconds: 5));

      if (!mounted) return;

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        setState(() {
          _currentFrame = response.bodyBytes;
          _isLoading = false;
          _hasError = false;
          _retryCount = 0;
        });
      } else {
        _handleError('HTTP ${response.statusCode}');
      }
    } catch (e) {
      _handleError(e.toString());
    }
  }

  void _handleError(String error) {
    if (!mounted) return;
    
    _retryCount++;
    if (_retryCount >= _maxRetries) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Kamera bağlantısı kurulamadı';
        _isLoading = false;
      });
      _pollingTimer?.cancel();
    }
  }

  void _refresh() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _isLoading = true;
      _retryCount = 0;
    });
    if (widget.isLive) {
      _startPolling();
    } else {
      _loadSingleFrame();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }

    if (_isLoading && _currentFrame == null) {
      return _buildLoadingWidget();
    }

    if (_currentFrame != null) {
      return Stack(
        children: [
          Image.memory(
            _currentFrame!,
            fit: widget.fit,
            gaplessPlayback: true,
            width: double.infinity,
            height: double.infinity,
          ),
          if (widget.isLive)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'CANLI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    return _buildErrorWidget();
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.black87,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Kamera yükleniyor...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
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
            const SizedBox(height: 8),
            Text(
              'Sera kamerası çevrimdışı olabilir',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
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

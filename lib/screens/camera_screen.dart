import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/mqtt_service.dart';
import '../widgets/ptz_joystick.dart';
import '../widgets/elevator_controls.dart';
import '../widgets/mjpeg_viewer.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📹 Kamera'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.videocam), text: 'Canlı'),
            Tab(icon: Icon(Icons.photo_library), text: 'Galeri'),
          ],
        ),
        actions: [
          Consumer<AppProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt),
                onPressed: provider.isLoading ? null : () => _capturePhoto(context),
                tooltip: 'Fotoğraf Çek',
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLiveView(),
          _buildGalleryView(),
        ],
      ),
    );
  }

  Widget _buildLiveView() {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          child: Column(
            children: [
              // Video Stream - MJPEG
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.black,
                  child: MjpegViewer(
                    streamUrl: provider.videoFeedUrl,
                    isLive: true,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Kontroller
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PTZ Joystick
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'PTZ Kontrol',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          PtzJoystick(
                            onMove: (direction) => provider.movePtz(direction),
                            onStop: () => provider.stopPtz(),
                            onReturnHome: () => provider.ptzGoHome(),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Elevator Kontrolü
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'Asansör',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const ElevatorControls(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Asansör Durumu
              Consumer<MqttService>(
                builder: (context, mqtt, _) {
                  return Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statusItem(
                            'Raf',
                            '${provider.elevatorStatus.rack}',
                            Icons.layers,
                          ),
                          _statusItem(
                            'Pozisyon',
                            '${provider.elevatorStatus.position}',
                            Icons.straighten,
                          ),
                          _statusItem(
                            'Durum',
                            provider.elevatorStatus.moving ? 'Hareket' : 'Hazır',
                            provider.elevatorStatus.moving
                                ? Icons.sync
                                : Icons.check_circle,
                            color: provider.elevatorStatus.moving
                                ? Colors.orange
                                : Colors.green,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusItem(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.grey),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildGalleryView() {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final images = provider.galleryImages;
        
        if (images.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Henüz fotoğraf yok'),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => provider.refreshGallery(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Yenile'),
                ),
              ],
            ),
          );
        }
        
        return RefreshIndicator(
          onRefresh: () => provider.refreshGallery(),
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              final filename = images[index];
              final imageUrl = provider.getImageUrl(filename);
              
              return GestureDetector(
                onTap: () => _showImageDetail(context, imageUrl, filename),
                child: Hero(
                  tag: filename,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[900],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showImageDetail(BuildContext context, String imageUrl, String filename) {
    // Dosya adından bilgi çıkar
    // Format: raf{rack}_{date}_{time}.jpg
    String rackInfo = '';
    String dateInfo = '';
    
    final match = RegExp(r'raf(\d+)_(\d{8})_(\d{6})').firstMatch(filename);
    if (match != null) {
      rackInfo = 'Raf ${match.group(1)}';
      final dateStr = match.group(2)!;
      final timeStr = match.group(3)!;
      dateInfo = '${dateStr.substring(6,8)}.${dateStr.substring(4,6)}.${dateStr.substring(0,4)} '
                 '${timeStr.substring(0,2)}:${timeStr.substring(2,4)}';
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rackInfo.isNotEmpty ? rackInfo : filename, style: const TextStyle(fontSize: 16)),
                if (dateInfo.isNotEmpty)
                  Text(dateInfo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          body: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Hero(
                tag: filename,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _capturePhoto(BuildContext context) async {
    final provider = context.read<AppProvider>();
    final result = await provider.capturePhoto();
    
    if (!mounted) return;
    
    if (result != null && result['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Fotoğraf çekildi'),
                    if (result['analysis'] != null)
                      Text(
                        'Sağlık: ${result['analysis']['saglik_skoru']}/100',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
      
      // Galeri sekmesine geç
      _tabController.animateTo(1);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fotoğraf çekilemedi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/mqtt_service.dart';
import '../services/api_service.dart';
import '../widgets/ptz_joystick.dart';
import '../widgets/elevator_controls.dart';
import '../widgets/mjpeg_viewer.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Tab değiştiğinde analizleri yükle
    _tabController.addListener(_onTabChanged);
    // Başlangıçta galeri ve analizleri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      provider.refreshGallery();
      provider.refreshAnalyses();
    });
  }

  void _onTabChanged() {
    if (_tabController.index == 2) {
      // Analizler sekmesi
      context.read<AppProvider>().refreshAnalyses();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
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
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.videocam), text: 'Canlı'),
            Tab(icon: Icon(Icons.photo_library), text: 'Galeri'),
            Tab(icon: Icon(Icons.analytics), text: 'Analizler'),
            Tab(icon: Icon(Icons.straighten), text: 'Büyüme'),
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
                onPressed:
                    provider.isLoading ? null : () => _capturePhoto(context),
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
          _buildAnalysesView(),
          _buildGrowthView(),
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
                            provider.elevatorStatus.moving
                                ? 'Hareket'
                                : 'Hazır',
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

  Widget _statusItem(String label, String value, IconData icon,
      {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.grey),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                const Icon(Icons.photo_library_outlined,
                    size: 64, color: Colors.grey),
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

              return Stack(
                children: [
                  GestureDetector(
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
                              child:
                                  Icon(Icons.broken_image, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  // 3 nokta menüsü - sağ üst
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                        icon: const Icon(Icons.more_vert,
                            color: Colors.white, size: 20),
                        onSelected: (value) async {
                          if (value == 'delete') {
                            _confirmDelete(context, provider, filename);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text('Sil',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _confirmDelete(
      BuildContext context, AppProvider provider, String filename) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fotoğrafı Sil'),
        content: const Text('Bu fotoğrafı silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteGalleryImage(filename);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(success ? 'Fotoğraf silindi' : 'Silme başarısız'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showImageDetail(
      BuildContext context, String imageUrl, String filename) {
    // Dosya adından bilgi çıkar
    // Format: raf{rack}_{date}_{time}.jpg
    String rackInfo = '';
    String dateInfo = '';

    final match = RegExp(r'raf(\d+)_(\d{8})_(\d{6})').firstMatch(filename);
    if (match != null) {
      rackInfo = 'Raf ${match.group(1)}';
      final dateStr = match.group(2)!;
      final timeStr = match.group(3)!;
      dateInfo =
          '${dateStr.substring(6, 8)}.${dateStr.substring(4, 6)}.${dateStr.substring(0, 4)} '
          '${timeStr.substring(0, 2)}:${timeStr.substring(2, 4)}';
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rackInfo.isNotEmpty ? rackInfo : filename,
                    style: const TextStyle(fontSize: 16)),
                if (dateInfo.isNotEmpty)
                  Text(dateInfo,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
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

  Widget _buildAnalysesView() {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final analyses = provider.analyses;

        return RefreshIndicator(
          onRefresh: () => provider.refreshAnalyses(),
          child: analyses.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 100),
                    const Center(
                      child: Column(
                        children: [
                          Icon(Icons.analytics_outlined,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Henüz analiz yok'),
                          SizedBox(height: 8),
                          Text('Aşağı çekerek yenileyin',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: analyses.length,
                  itemBuilder: (context, index) {
                    final analysis = analyses[index];
                    return _buildAnalysisCard(analysis, provider);
                  },
                ),
        );
      },
    );
  }

  Widget _buildAnalysisCard(
      Map<String, dynamic> analysis, AppProvider provider) {
    final time = analysis['time'] ?? '';
    final summary = analysis['summary'] ?? 'Analiz yok';
    final healthScore = analysis['health_score'] ?? 0;
    final image = analysis['image'] ?? '';
    final anomalies = analysis['anomalies'] as List? ?? [];
    final mode = analysis['mode'] ?? 'unknown';

    // Tarih formatla
    String formattedTime = '';
    try {
      final dt = DateTime.parse(time);
      formattedTime =
          '${dt.day}.${dt.month}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      formattedTime = time;
    }

    // Sağlık skoru rengi
    Color healthColor = Colors.grey;
    if (healthScore >= 80) {
      healthColor = Colors.green;
    } else if (healthScore >= 50) {
      healthColor = Colors.orange;
    } else if (healthScore > 0) {
      healthColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: image.isNotEmpty
            ? () => _showAnalysisDetail(analysis, provider)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              if (image.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    provider.getImageUrl(image),
                    width: 80,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 60,
                      color: Colors.grey[800],
                      child: const Icon(Icons.image_not_supported, size: 24),
                    ),
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.analytics, size: 24),
                ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          mode == 'scheduled'
                              ? Icons.schedule
                              : Icons.touch_app,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedTime,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (anomalies.isNotEmpty && anomalies.first != 'unknown')
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 4,
                          children: anomalies
                              .take(3)
                              .map((a) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      a.toString(),
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.red),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
              // Health Score
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: healthColor.withOpacity(0.2),
                ),
                child: Center(
                  child: Text(
                    '$healthScore',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: healthColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAnalysisDetail(
      Map<String, dynamic> analysis, AppProvider provider) {
    final image = analysis['image'] ?? '';
    final summary = analysis['summary'] ?? '';
    final healthScore = analysis['health_score'] ?? 0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Sağlık: $healthScore/100'),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                if (image.isNotEmpty)
                  Image.network(
                    provider.getImageUrl(image),
                    fit: BoxFit.contain,
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(summary, style: const TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============ BÜYÜME SEKMESİ ============
  Widget _buildGrowthView() {
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService().getGrowthSummary(1),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.greenAccent),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildEmptyGrowthState();
        }

        final data = snapshot.data!;
        if (data.containsKey('error')) {
          return _buildEmptyGrowthState();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst butonlar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showManualHeightDialog(),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Manuel Ölçüm'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.greenAccent,
                        side: const BorderSide(color: Colors.greenAccent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showCalibrationDialog(),
                      icon: const Icon(Icons.settings, size: 18),
                      label: const Text('Kalibrasyon'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orangeAccent,
                        side: const BorderSide(color: Colors.orangeAccent),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildHeightCard(data),
              const SizedBox(height: 16),
              _buildLightCard(data),
              const SizedBox(height: 16),
              _buildGrowthRateCard(data),
              const SizedBox(height: 16),
              _buildHarvestCard(data),
            ],
          ),
        );
      },
    );
  }

  void _showManualHeightDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Row(
          children: [
            Icon(Icons.straighten, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text('Manuel Yükseklik Girişi',
                style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bitkinin cetvel ile ölçülmüş yüksekliğini girin:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 24),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '15',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                suffixText: 'cm',
                suffixStyle: const TextStyle(color: Colors.greenAccent),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Colors.greenAccent.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.greenAccent),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              final height = double.tryParse(controller.text);
              if (height != null && height > 0 && height < 50) {
                await ApiService().recordGrowth(1, height, 'manual');
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {}); // Refresh
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ $height cm kaydedildi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
            child: const Text('Kaydet', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showCalibrationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Row(
          children: [
            Icon(Icons.settings, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Text('Işık Kalibrasyonu', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCalibrationStep(
                '1',
                'Hazırlık',
                'Rafı boşalt, ışıkları aç ve 15 dk bekle.',
                Icons.lightbulb_outline,
              ),
              _buildCalibrationStep(
                '2',
                'Ölçüm Araçları',
                'Telefona lüksmetre uygulaması indir:\n• iOS: "Light Meter"\n• Android: "Lux Meter"',
                Icons.phone_android,
              ),
              _buildCalibrationStep(
                '3',
                'PPFD Ölçümü',
                'Her 5cm\'de lux değerini ölç.\nPPFD = Lux × 0.015\n\nÖrnek: 40,000 lux ≈ 600 PPFD',
                Icons.speed,
              ),
              _buildCalibrationStep(
                '4',
                'Referans Bantları',
                'Rafa her 5cm\'de renkli bant yapıştır:\n🔴 15cm - Tehlike\n🟠 20cm - Uyarı\n🟡 25cm - Dikkat\n🟢 30-35cm - Optimal\n🔵 40cm - Düşük\n⚪ 50cm - Zemin',
                Icons.format_color_fill,
              ),
              const Divider(color: Colors.white24),
              const Text(
                '💡 Detaylı rehber için:',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Text(
                'docs/CALIBRATION_GUIDE.md',
                style: TextStyle(color: Colors.orangeAccent, fontSize: 11),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showPPFDCalibrationWizard();
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            child: const Text('PPFD Kalibre Et',
                style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationStep(
      String num, String title, String desc, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(num,
                  style: const TextStyle(
                      color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(desc,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPPFDCalibrationWizard() {
    final distances = [50, 40, 30, 20, 15];
    final controllers = distances.map((d) => TextEditingController()).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('PPFD Değerlerini Girin',
            style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Her mesafede ölçtüğünüz PPFD değerini girin:',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ...List.generate(distances.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(
                          '${distances[i]} cm:',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: controllers[i],
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: _getDefaultPPFD(distances[i]).toString(),
                            hintStyle:
                                TextStyle(color: Colors.white.withOpacity(0.3)),
                            suffixText: 'PPFD',
                            suffixStyle: const TextStyle(
                                color: Colors.orangeAccent, fontSize: 11),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.2)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              final points = <Map<String, dynamic>>[];
              for (int i = 0; i < distances.length; i++) {
                final ppfd = double.tryParse(controllers[i].text) ??
                    _getDefaultPPFD(distances[i]);
                points.add({
                  'distance_from_light_cm': distances[i],
                  'ppfd': ppfd,
                });
              }

              try {
                // API'ye gönder
                await ApiService().updateLightCalibration(points);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {}); // Refresh
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Kalibrasyon kaydedildi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Hata: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            child: const Text('Kaydet', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  double _getDefaultPPFD(int distance) {
    switch (distance) {
      case 50:
        return 200;
      case 40:
        return 350;
      case 30:
        return 600;
      case 20:
        return 850;
      case 15:
        return 950;
      default:
        return 400;
    }
  }

  Widget _buildEmptyGrowthState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grass,
              color: Colors.greenAccent.withOpacity(0.3), size: 80),
          const SizedBox(height: 16),
          const Text(
            'Henüz büyüme verisi yok',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'AI analizi yapıldıkça bitki yüksekliği\notomatik olarak takip edilecek.',
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeightCard(Map<String, dynamic> data) {
    final height = data['current_height_cm'] ?? 0;
    final stage = data['light_analysis']?['stage_tr'] ?? 'Bilinmiyor';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.greenAccent.withOpacity(0.15),
            Colors.tealAccent.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Cetvel görseli
          Container(
            width: 50,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
            ),
            child: Stack(
              children: [
                // Yükseklik göstergesi
                Positioned(
                  bottom: (height / 30 * 100).clamp(0, 100).toDouble(),
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    color: Colors.greenAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bitki Yüksekliği',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$height',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6, left: 4),
                      child: Text(
                        'cm',
                        style:
                            TextStyle(color: Colors.greenAccent, fontSize: 18),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('🌱 $stage',
                      style: const TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLightCard(Map<String, dynamic> data) {
    final light = data['light_analysis'] ?? {};
    final distanceToLight = light['distance_from_light_cm'] ?? 0;
    final ppfd = light['ppfd'] ?? 0;
    final lightStatus = light['light_status'] ?? 'unknown';
    final warning = light['warning'];

    Color statusColor;
    IconData statusIcon;
    switch (lightStatus) {
      case 'optimal':
        statusColor = Colors.greenAccent;
        statusIcon = Icons.check_circle;
        break;
      case 'excessive':
        statusColor = Colors.redAccent;
        statusIcon = Icons.warning;
        break;
      case 'insufficient':
        statusColor = Colors.orangeAccent;
        statusIcon = Icons.wb_sunny_outlined;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: statusColor, size: 20),
              const SizedBox(width: 8),
              const Text('Işık Durumu',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500)),
              const Spacer(),
              Icon(statusIcon, color: statusColor),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricBox(
                    'Işığa Mesafe', '${distanceToLight.toStringAsFixed(0)} cm'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricBox('PPFD', '${ppfd.toStringAsFixed(0)}'),
              ),
            ],
          ),
          if (warning != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber,
                      color: Colors.redAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(warning,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildGrowthRateCard(Map<String, dynamic> data) {
    final rate24h = data['growth_rate_24h'];
    final rate7d = data['growth_rate_7d'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Colors.blueAccent, size: 20),
              SizedBox(width: 8),
              Text('Büyüme Hızı',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildRateChip(
                    '24 Saat',
                    rate24h != null
                        ? '${rate24h.toStringAsFixed(2)} cm/gün'
                        : '-',
                    Colors.blueAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRateChip(
                    '7 Gün',
                    rate7d != null
                        ? '${rate7d.toStringAsFixed(2)} cm/gün'
                        : '-',
                    Colors.purpleAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRateChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHarvestCard(Map<String, dynamic> data) {
    final days = data['estimated_harvest_days'];

    Color cardColor;
    String message;
    IconData icon;

    if (days == null) {
      cardColor = Colors.grey;
      message = 'Yeterli veri yok';
      icon = Icons.hourglass_empty;
    } else if (days == 0) {
      cardColor = Colors.greenAccent;
      message = 'HASAT ZAMANI! 🎉';
      icon = Icons.celebration;
    } else if (days <= 3) {
      cardColor = Colors.orangeAccent;
      message = '$days gün sonra hasat!';
      icon = Icons.timer;
    } else {
      cardColor = Colors.blueAccent;
      message = 'Tahmini $days gün';
      icon = Icons.calendar_today;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor.withOpacity(0.15), cardColor.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: cardColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hasat Tahmini',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                Text(message,
                    style: TextStyle(
                        color: cardColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (days != null && days > 0)
            Column(
              children: [
                Text('$days',
                    style: TextStyle(
                        color: cardColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                Text('gün',
                    style: TextStyle(
                        color: cardColor.withOpacity(0.7), fontSize: 12)),
              ],
            ),
        ],
      ),
    );
  }
}

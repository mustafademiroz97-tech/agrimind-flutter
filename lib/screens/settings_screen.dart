import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Ayarlar'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Bağlantı Durumu
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            provider.isConnected 
                                ? Icons.wifi 
                                : Icons.wifi_off,
                            color: provider.isConnected 
                                ? Colors.green 
                                : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            provider.isConnected 
                                ? 'Bağlı' 
                                : 'Bağlantı Yok',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: provider.isConnected 
                                  ? Colors.green 
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sunucu: ${ApiService.baseUrl}', // Her zaman doğru URL'i göster
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Sistem Bilgisi
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sistem Bilgisi',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _infoRow('Versiyon', '1.1.0'), // Versiyon güncellendi
                      _infoRow('Backend', 'Raspberry Pi 4'),
                      _infoRow('Kamera', 'Tapo C200 PTZ'),
                      _infoRow('AI Model', 'Gemini 2.5 Flash'),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Hızlı Linkler
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'URL\'ler',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _copyableUrl(context, 'API Sunucusu', ApiService.baseUrl),
                      _copyableUrl(context, 'Video Akışı', '${ApiService.baseUrl}/video_feed'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
  
  Widget _copyableUrl(BuildContext context, String label, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label)),
          Expanded(
            child: Text(
              url, 
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () {
              // Clipboard için
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$label URL kopyalandı')),
              );
            },
          ),
        ],
      ),
    );
  }
}

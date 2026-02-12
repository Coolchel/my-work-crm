import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class FileViewerScreen extends StatelessWidget {
  final String url;
  final String title;

  const FileViewerScreen({
    super.key,
    required this.url,
    required this.title,
  });

  Future<void> _shareFile() async {
    try {
      final response = await http.get(Uri.parse(url));
      final documentDirectory = await getTemporaryDirectory();
      final file = File('${documentDirectory.path}/${url.split('/').last}');
      file.writeAsBytesSync(response.bodyBytes);

      await Share.shareXFiles([XFile(file.path)], text: title);
    } catch (e) {
      debugPrint('Error sharing file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Назад',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareFile,
          ),
        ],
      ),
      body: PhotoView(
        imageProvider: NetworkImage(url),
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(),
        ),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
      ),
    );
  }
}

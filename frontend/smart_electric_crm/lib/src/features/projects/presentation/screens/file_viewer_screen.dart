import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:smart_electric_crm/src/core/constants/api_urls.dart';
import '../dialogs/project_file_share_fallback_dialog.dart';
import '../../services/project_file_save_service.dart';
import '../../services/project_file_share_service.dart';

class FileViewerScreen extends StatelessWidget {
  final String url;
  final String title;
  final VoidCallback? onBackPressed;

  const FileViewerScreen({
    super.key,
    required this.url,
    required this.title,
    this.onBackPressed,
  });

  static final ProjectFileShareService _fileShareService =
      ProjectFileShareService();
  static final ProjectFileSaveService _fileSaveService =
      ProjectFileSaveService();

  Future<void> _shareFile(BuildContext context) async {
    final resolvedUrl = ApiUrls.resolveBackendUrl(url);

    if (kIsWeb) {
      final result = await _fileShareService.shareRemoteFile(
        url: resolvedUrl,
        displayName: title,
      );
      if (!context.mounted || result.isShared || result.isCancelled) {
        return;
      }
      if (result.requiresManualFallback && result.url != null) {
        await showProjectFileShareFallbackDialog(
          context: context,
          url: result.url!,
          displayName: title,
          saveService: _fileSaveService,
          shareService: _fileShareService,
          message: result.message,
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      return;
    }

    try {
      final response = await http.get(Uri.parse(resolvedUrl));
      final documentDirectory = await getTemporaryDirectory();
      final file =
          File('${documentDirectory.path}/${resolvedUrl.split('/').last}');
      file.writeAsBytesSync(response.bodyBytes);

      await Share.shareXFiles([XFile(file.path)], text: title);
    } catch (e) {
      debugPrint('Error sharing file: $e');
    }
  }

  void _handleBack(BuildContext context) {
    onBackPressed?.call();
    if (onBackPressed != null) {
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = ApiUrls.resolveBackendUrl(url);
    final usesCopyLinkShareAction =
        kIsWeb && _fileShareService.usesCopyLinkAsPrimaryAction;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Назад',
          onPressed: () => _handleBack(context),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            tooltip:
                usesCopyLinkShareAction ? 'Скопировать ссылку' : 'Поделиться',
            icon: const Icon(
              kIsWeb ? Icons.link_rounded : Icons.share,
            ),
            onPressed: () => _shareFile(context),
          ),
        ],
      ),
      body: PhotoView(
        imageProvider: NetworkImage(resolvedUrl),
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(),
        ),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
      ),
    );
  }
}

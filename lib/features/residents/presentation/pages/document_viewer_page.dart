import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/app_theme.dart';

class DocumentViewerPage extends StatefulWidget {
  final String title;
  final Future<List<int>> Function() fetchBytes;
  final String fileName;

  const DocumentViewerPage({
    super.key,
    required this.title,
    required this.fetchBytes,
    required this.fileName,
  });

  @override
  State<DocumentViewerPage> createState() => _DocumentViewerPageState();
}

class _DocumentViewerPageState extends State<DocumentViewerPage> {
  bool _isLoading = true;
  String? _localPath;
  String? _error;
  List<int>? _cachedBytes;

  // Sanitized filename (no slashes/spaces) used for temp file
  late final String _safeFileName;

  @override
  void initState() {
    super.initState();
    _safeFileName = widget.fileName
        .replaceAll('/', '_')
        .replaceAll('\\', '_')
        .replaceAll(' ', '_');
    Future.microtask(_downloadFile);
  }

  Future<void> _downloadFile() async {
    try {
      final bytes = await widget.fetchBytes();
      _cachedBytes = bytes;
      final tempDir = await getTemporaryDirectory();
      // Sanitize fileName: backend may return paths like "SKU/RT05/202609/000001.docx"
      // which would be treated as subdirectories. Replace slashes and spaces with underscores.
      final file = File('${tempDir.path}/$_safeFileName');
      await file.writeAsBytes(bytes);
      if (mounted) {
        setState(() {
          _localPath = file.path;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadToFolder() async {
    final bytes = _cachedBytes;
    if (bytes == null) return;

    setState(() => _isLoading = true);
    try {
      final downloadDir = Directory('/storage/emulated/0/Download');
      final String destPath;
      if (await downloadDir.exists()) {
        destPath = '${downloadDir.path}/astina_$_safeFileName';
      } else {
        final extStore = await getExternalStorageDirectory();
        final fallbackDir = Directory('${extStore?.path}/Download');
        if (!await fallbackDir.exists()) {
          await fallbackDir.create(recursive: true);
        }
        destPath = '${fallbackDir.path}/astina_$_safeFileName';
      }
      await File(destPath).writeAsBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tersimpan di $destPath'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title, style: const TextStyle(fontSize: 14)),
        actions: [
          if (!_isLoading && _error == null && _cachedBytes != null)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Unduh ke folder Download',
              onPressed: _downloadToFolder,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Gagal memuat: $_error',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _buildViewer(),
    );
  }

  Widget _buildViewer() {
    final ext = widget.fileName.split('.').last.toLowerCase();
    final isPdf = ext == 'pdf';

    if (isPdf && _localPath != null) {
      return PDFView(
        filePath: _localPath!,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
      );
    }

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.file(
          File(_localPath!),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text(
            'Gagal memuat gambar',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

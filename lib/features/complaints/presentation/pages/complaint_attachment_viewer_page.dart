import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/complaint_model.dart';
import '../../providers/complaint_provider.dart';

class ComplaintAttachmentViewerPage extends ConsumerStatefulWidget {
  final ComplaintAttachment attachment;

  const ComplaintAttachmentViewerPage({super.key, required this.attachment});

  @override
  ConsumerState<ComplaintAttachmentViewerPage> createState() =>
      _ComplaintAttachmentViewerPageState();
}

class _ComplaintAttachmentViewerPageState
    extends ConsumerState<ComplaintAttachmentViewerPage> {
  bool _isLoading = true;
  String? _localPath;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_downloadFile);
  }

  Future<void> _downloadFile() async {
    try {
      final bytes = await ref
          .read(complaintDataSourceProvider)
          .downloadAttachment(widget.attachment.url);
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/${widget.attachment.id}_${widget.attachment.fileName}',
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.attachment.fileName,
          style: const TextStyle(fontSize: 14),
        ),
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
    final isPdf = widget.attachment.mimeType == 'application/pdf';

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

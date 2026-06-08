import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../controllers/hive_service.dart';
import '../models/journal.dart';
import '../widgets/custom_shape.dart';
import 'drawing_canvas_view.dart';

class JournalDetailView extends StatefulWidget {
  final int journalId;
  const JournalDetailView({super.key, required this.journalId});

  @override
  State<JournalDetailView> createState() => _JournalDetailViewState();
}

class _JournalDetailViewState extends State<JournalDetailView> {
  Journal? _journal;

  @override
  void initState() {
    super.initState();
    _loadJournal();
  }

  void _loadJournal() {
    setState(() {
      _journal = HiveService.getJournalById(widget.journalId);
    });
  }

  Future<String?> _pickImageForPage() async {
    // Use native ImagePicker on mobile, fallback to FilePicker on desktop/web.
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final picker = ImagePicker();
      final source = await showModalBottomSheet<ImageSource?>(
        context: context,
        builder: (_) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.of(context).pop(null),
              ),
            ],
          ),
        ),
      );

      if (source == null) return null;
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      return picked?.path;
    }

    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    return result?.files.single.path;
  }

  Future<void> _addImagePage() async {
    final path = await _pickImageForPage();
    if (path == null) return;
    final pages = List<Map<String, dynamic>>.from(
      _journal?.metadata['pages'] ?? [],
    );
    pages.add({
      'id': DateTime.now().millisecondsSinceEpoch,
      'type': 'image',
      'path': path,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    final entryCount =
        (_journal?.metadata['entries'] as int? ?? pages.length) + 1;
    final updated = _journal!.copyWith(
      metadata: {..._journal!.metadata, 'pages': pages, 'entries': entryCount},
    );
    await HiveService.updateJournal(updated);
    _loadJournal();
  }

  Future<void> _addCanvasPage() async {
    final pages = List<Map<String, dynamic>>.from(
      _journal?.metadata['pages'] ?? [],
    );
    final int pageId = DateTime.now().millisecondsSinceEpoch;
    pages.add({
      'id': pageId,
      'type': 'canvas',
      'path': null,
      'style': 'blank',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    final entryCount =
        (_journal?.metadata['entries'] as int? ?? pages.length) + 1;
    final updated = _journal!.copyWith(
      metadata: {..._journal!.metadata, 'pages': pages, 'entries': entryCount},
    );
    await HiveService.updateJournal(updated);
    _loadJournal();
    if (!mounted) return;
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => DrawingCanvasView(
              journalId: widget.journalId,
              pageId: pageId,
              pagePath: null,
            ),
          ),
        )
        .then((_) => _loadJournal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_journal?.title ?? 'Journal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: _journal == null ? null : _exportJournalToPdf,
          ),
        ],
      ),
      body: _journal == null
          ? const Center(child: Text('Journal not found'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _journal!.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _addImagePage,
                            icon: const Icon(Icons.image),
                            label: const Text('Add Photo'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _addCanvasPage,
                            icon: const Icon(Icons.brush),
                            label: const Text('New Drawing'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: _buildPages()),
                ],
              ),
            ),
    );
  }

  Widget _buildPages() {
    final pages = List<Map<String, dynamic>>.from(
      _journal!.metadata['pages'] ?? [],
    );
    if (pages.isEmpty) {
      return const Center(
        child: Text('No pages yet. Add a photo or create a page.'),
      );
    }
    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      itemCount: pages.length,
      itemBuilder: (context, index) {
        final p = pages[index];
        final height = 220.0 + (index % 3) * 40.0;
        return SizedBox(
          height: height,
          child: GestureDetector(
            onTap: () {
              if (p['type'] == 'canvas') {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (_) => DrawingCanvasView(
                          journalId: widget.journalId,
                          pageId: p['id'] as int,
                          pagePath: p['path'] as String?,
                          pageStyle: p['style'] as String?,
                        ),
                      ),
                    )
                    .then((_) => _loadJournal());
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: Text(_journal!.title)),
                      body: Center(
                        child: Image.file(
                          File(p['path'] as String),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                );
              }
            },
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: p['type'] == 'image' && p['path'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(p['path'] as String),
                        fit: BoxFit.cover,
                      ),
                    )
                  : CustomShape(
                      style: _parsePaperStyle(p['style'] as String?),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.brush,
                            size: 38,
                            color: Color(0xFF5C6B7D),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Canvas page',
                            style: TextStyle(
                              color: Color(0xFF5C6B7D),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            p['path'] == null
                                ? 'Unsaved draft'
                                : 'Saved drawing',
                            style: const TextStyle(
                              color: Color(0xFF7B8794),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _parsePaperStyle(p['style'] as String?).label,
                            style: const TextStyle(
                              color: Color(0xFF7B8794),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportJournalToPdf() async {
    if (_journal == null) return;

    final pdf = pw.Document();
    final pages = _journal!.pages;

    if (pages.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add pages before exporting.')),
      );
      return;
    }

    for (final page in pages) {
      final pageType = page['type'] as String? ?? 'page';
      final style = _parsePaperStyle(page['style'] as String?);
      final List<pw.Widget> content = [
        pw.Text(
          'Page ${page['id']}',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.Text('Type: ${pageType.toUpperCase()}'),
        pw.Text('Style: ${style.label}'),
        pw.SizedBox(height: 12),
      ];

      final itemPath = page['path'] as String?;
      if (pageType == 'image' && itemPath != null) {
        final imageFile = File(itemPath);
        if (await imageFile.exists()) {
          final imageBytes = await imageFile.readAsBytes();
          content.add(
            pw.Center(
              child: pw.Image(
                pw.MemoryImage(imageBytes),
                fit: pw.BoxFit.contain,
                width: 450,
              ),
            ),
          );
        } else {
          content.add(pw.Text('Image file not found.'));
        }
      } else if (pageType == 'canvas') {
        if (itemPath != null) {
          content.add(
            pw.Text(
              'Canvas saved at: ${itemPath.split(Platform.pathSeparator).last}',
            ),
          );
        } else {
          content.add(pw.Text('Unsaved canvas page.'));
        }
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Container(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: content,
            ),
          ),
        ),
      );
    }

    final outputDir = await getApplicationDocumentsDirectory();
    final file = File(
      '${outputDir.path}/journal_${_journal!.id}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Journal exported to ${file.path}')));
  }

  PaperStyle _parsePaperStyle(String? style) {
    switch (style) {
      case 'ruled':
        return PaperStyle.ruled;
      case 'grid':
        return PaperStyle.grid;
      case 'dotted':
        return PaperStyle.dotted;
      case 'cream':
        return PaperStyle.cream;
      default:
        return PaperStyle.blank;
    }
  }
}

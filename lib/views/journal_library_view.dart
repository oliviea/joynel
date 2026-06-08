import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../controllers/hive_service.dart';
import '../models/journal.dart';
import 'journal_detail_view.dart';

class JournalLibraryView extends StatefulWidget {
  const JournalLibraryView({super.key});

  @override
  State<JournalLibraryView> createState() => _JournalLibraryViewState();
}

class _JournalLibraryViewState extends State<JournalLibraryView> {
  String _layout = 'grid';
  Color _accent = const Color(0xFF27272a);

  @override
  Widget build(BuildContext context) {
    // Two-column layout: sidebar (left) + main area (right)
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Icon(Icons.book_outlined, size: 28, color: _accent),
                const SizedBox(height: 8),
                const Text(
                  'JRNL',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 24),
                _sidebarButton(Icons.grid_view, 'All'),
                const SizedBox(height: 8),
                _sidebarButton(Icons.bookmark, 'Fav'),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _colorDot(const Color(0xFF27272a)),
                      const SizedBox(width: 6),
                      _colorDot(const Color(0xFF5f6c5a)),
                      const SizedBox(width: 6),
                      _colorDot(const Color(0xFF5c6b7d)),
                      const SizedBox(width: 6),
                      _colorDot(const Color(0xFF9b7a7f)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main column
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  height: 84,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade100),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Good morning, Alex.',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'You have journals.',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          ToggleButtons(
                            isSelected: [
                              _layout == 'grid',
                              _layout == 'masonry',
                              _layout == 'list',
                            ],
                            onPressed: (i) {
                              setState(() {
                                _layout = i == 0
                                    ? 'grid'
                                    : (i == 1 ? 'masonry' : 'list');
                              });
                            },
                            children: const [
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(Icons.grid_view),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(Icons.view_agenda),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(Icons.list),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('New Journal'),
                            onPressed: _createJournalDialog,
                          ),
                          const SizedBox(width: 12),
                          CircleAvatar(
                            backgroundColor: Colors.grey.shade200,
                            child: const Icon(Icons.person),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Content area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _layoutTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(child: _buildJournals()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarButton(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        children: [
          Icon(icon, color: _accent),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _colorDot(Color c) => GestureDetector(
    onTap: () => setState(() => _accent = c),
    child: Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    ),
  );

  String get _layoutTitle {
    switch (_layout) {
      case 'masonry':
        return 'Version 2: Masonry Cards';
      case 'list':
        return 'Version 3: Minimal List';
      default:
        return 'Classic Grid View';
    }
  }

  Widget _buildJournals() {
    return ValueListenableBuilder<Box<Journal>>(
      valueListenable: HiveService.listenable,
      builder: (context, box, _) {
        final journals = box.values.cast<Journal>().toList();
        if (journals.isEmpty) {
          return const Center(child: Text('No journals yet — create one.'));
        }

        if (_layout == 'list') {
          return ListView.builder(
            itemCount: journals.length,
            itemBuilder: (context, index) {
              final j = journals[index];
              return ListTile(
                leading: j.coverPath != null
                    ? Image.file(
                        File(j.coverPath!),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.book),
                title: Text(j.title),
                subtitle: Text('${_journalEntries(j)} entries'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => JournalDetailView(journalId: j.id),
                  ),
                ),
              );
            },
          );
        }

        if (_layout == 'masonry') {
          return MasonryGridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            itemCount: journals.length,
            itemBuilder: (context, index) {
              final j = journals[index];
              final height = 220.0 + (index % 3) * 40.0;
              return SizedBox(height: height, child: _buildJournalCard(j));
            },
          );
        }

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3 / 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: journals.length,
          itemBuilder: (context, index) {
            return _buildJournalCard(journals[index]);
          },
        );
      },
    );
  }

  int _journalEntries(Journal j) {
    return (j.metadata['entries'] as int?) ??
        (j.metadata['pages'] as List?)?.length ??
        0;
  }

  Widget _buildJournalCard(Journal j) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => JournalDetailView(journalId: j.id)),
      ),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: j.coverPath != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Image.file(File(j.coverPath!), fit: BoxFit.cover),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: const Center(child: Icon(Icons.book, size: 48)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    j.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${j.metadata['entries'] ?? 0} entries',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _pickImageForCover() async {
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
    if (result != null && result.files.single.path != null) {
      return result.files.single.path;
    }
    return null;
  }

  Future<void> _createJournalDialog() async {
    final titleCtl = TextEditingController();
    String? pickedPath;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Journal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.image),
              label: const Text('Pick Cover'),
              onPressed: () async {
                final path = await _pickImageForCover();
                if (path != null) setState(() => pickedPath = path);
              },
            ),
            if (pickedPath != null) ...[
              const SizedBox(height: 8),
              Text(
                'Selected: ${pickedPath!.split(Platform.pathSeparator).last}',
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final id = DateTime.now().millisecondsSinceEpoch;
              final journal = Journal(
                id: id,
                title: titleCtl.text.isEmpty ? 'Untitled' : titleCtl.text,
                coverPath: pickedPath,
                metadata: {'entries': 0},
              );
              final navigator = Navigator.of(context);
              await HiveService.addJournal(journal);
              navigator.pop();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

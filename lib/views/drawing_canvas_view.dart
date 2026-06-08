import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pencil_kit/pencil_kit.dart';
import '../controllers/hive_service.dart';
import '../widgets/custom_shape.dart';

class DrawingCanvasView extends StatefulWidget {
  final int journalId;
  final int pageId;
  final String? pagePath;
  final String? pageStyle;

  const DrawingCanvasView({
    super.key,
    required this.journalId,
    required this.pageId,
    this.pagePath,
    this.pageStyle,
  });

  @override
  State<DrawingCanvasView> createState() => _DrawingCanvasViewState();
}

class _DrawingCanvasViewState extends State<DrawingCanvasView> {
  PencilKitController? _controller;
  ToolType _selectedTool = ToolType.pen;
  Color _selectedColor = Colors.black;
  PaperStyle _paperStyle = PaperStyle.blank;
  bool _isAvailable = false;
  bool _hasSaved = false;

  @override
  void initState() {
    super.initState();
    _paperStyle = _parsePaperStyle(widget.pageStyle);
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    if (kIsWeb) {
      setState(() {
        _isAvailable = false;
      });
      return;
    }
    if (Platform.isIOS) {
      final available = await PencilKitUtil.checkAvailable();
      setState(() {
        _isAvailable = available;
      });
    } else {
      setState(() {
        _isAvailable = false;
      });
    }
  }

  Future<void> _loadDrawing(String path) async {
    if (_controller == null) return;
    final file = File(path);
    if (await file.exists()) {
      await _controller!.load(uri: path);
    }
  }

  Future<void> _saveDrawing() async {
    if (_controller == null) return;
    final directory = await getApplicationDocumentsDirectory();
    final path =
        '${directory.path}/journal_${widget.journalId}_page_${widget.pageId}.drawing';
    await _controller!.save(uri: path);
    await _updateJournalPage(path: path, style: _paperStyle);
    setState(() {
      _hasSaved = true;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Canvas saved to journal page')),
    );
  }

  Future<void> _updateJournalPage({String? path, PaperStyle? style}) async {
    final journal = HiveService.getJournalById(widget.journalId);
    if (journal == null) return;
    final pages = List<Map<String, dynamic>>.from(
      journal.metadata['pages'] ?? [],
    );
    final index = pages.indexWhere((page) => page['id'] == widget.pageId);
    if (index == -1) return;
    final updatedPage = Map<String, dynamic>.from(pages[index]);
    if (path != null) {
      updatedPage['path'] = path;
    }
    if (style != null) {
      updatedPage['style'] = style.name;
    }
    pages[index] = updatedPage;
    await HiveService.updateJournal(
      journal.copyWith(metadata: {...journal.metadata, 'pages': pages}),
    );
  }

  Future<void> _setTool(ToolType tool) async {
    setState(() {
      _selectedTool = tool;
    });
    if (_controller == null) return;
    await _controller!.setPKTool(
      toolType: tool,
      width: 2.5,
      color: _selectedColor,
    );
  }

  Future<void> _setColor(Color color) async {
    setState(() {
      _selectedColor = color;
    });
    if (_controller == null) return;
    await _controller!.setPKTool(
      toolType: _selectedTool,
      width: 2.5,
      color: _selectedColor,
    );
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

  Widget _buildPaperStyleSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: PaperStyle.values.map((style) {
          final active = _paperStyle == style;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(style.label),
              avatar: Icon(style.icon, size: 18),
              selected: active,
              selectedColor: Colors.black,
              backgroundColor: Colors.grey.shade100,
              labelStyle: TextStyle(
                color: active ? Colors.white : Colors.black87,
              ),
              onSelected: (_) {
                setState(() {
                  _paperStyle = style;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _undo() async {
    await _controller?.undo();
  }

  Future<void> _redo() async {
    await _controller?.redo();
  }

  void _onPencilKitCreated(PencilKitController controller) {
    _controller = controller;
    _setTool(_selectedTool);
    if (widget.pagePath != null) {
      _loadDrawing(widget.pagePath!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canvas Page'),
        actions: [
          IconButton(onPressed: _undo, icon: const Icon(Icons.undo)),
          IconButton(onPressed: _redo, icon: const Icon(Icons.redo)),
          IconButton(onPressed: _saveDrawing, icon: const Icon(Icons.save)),
        ],
      ),
      body: !_isAvailable
          ? const Center(
              child: Text(
                'PencilKit is available only on iPad/iOS 13+ devices.',
              ),
            )
          : Column(
              children: [
                _buildPaperStyleSelector(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  color: Colors.white,
                  child: Row(
                    children: [
                      _toolButton(ToolType.pen, Icons.brush),
                      const SizedBox(width: 8),
                      _toolButton(ToolType.marker, Icons.sticky_note_2),
                      const SizedBox(width: 8),
                      _toolButton(ToolType.pencil, Icons.mode),
                      const SizedBox(width: 8),
                      _toolButton(
                        ToolType.eraserBitmap,
                        Icons.cleaning_services,
                      ),
                      const SizedBox(width: 16),
                      _colorDot(Colors.black),
                      const SizedBox(width: 8),
                      _colorDot(Colors.deepPurple),
                      const SizedBox(width: 8),
                      _colorDot(Colors.blue),
                      const SizedBox(width: 8),
                      _colorDot(Colors.red),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(0, 0, 0, 0.04),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        children: [
                          CustomShape(
                            style: _paperStyle,
                            padding: EdgeInsets.zero,
                            backgroundColor: const Color(0xFFF8F8FF),
                            child: const SizedBox.expand(),
                          ),
                          PencilKit(
                            backgroundColor: Colors.transparent,
                            drawingPolicy: PencilKitIos14DrawingPolicy.anyInput,
                            isOpaque: false,
                            onPencilKitViewCreated: _onPencilKitCreated,
                            unAvailableFallback: Container(
                              color: Colors.grey.shade100,
                              child: const Center(
                                child: Text(
                                  'PencilKit is not available on this device.',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_hasSaved)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      'Saved successfully',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _toolButton(ToolType tool, IconData icon) {
    final active = _selectedTool == tool;
    return GestureDetector(
      onTap: () => _setTool(tool),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: active ? Colors.black : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: active ? Colors.white : Colors.black87,
          size: 20,
        ),
      ),
    );
  }

  Widget _colorDot(Color color) {
    return GestureDetector(
      onTap: () => _setColor(color),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
      ),
    );
  }
}

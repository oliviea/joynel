import 'package:flutter/material.dart';
import 'controllers/hive_service.dart';
import 'views/journal_library_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: JournalLibraryView());
  }
}

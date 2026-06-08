import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/journal.dart';

class HiveService {
  static late Box<Journal> _journalBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(JournalAdapter());
    _journalBox = await Hive.openBox<Journal>('journals');
  }

  static List<Journal> getAllJournals() {
    return _journalBox.values.cast<Journal>().toList();
  }

  static Box<Journal> get journalBox => _journalBox;

  static ValueListenable<Box<Journal>> get listenable =>
      _journalBox.listenable();

  // _mapToJournal removed; stored objects use the registered adapter

  static Future<void> addJournal(Journal journal) async {
    await _journalBox.put(journal.id, journal);
  }

  static Future<void> deleteJournal(int id) async {
    await _journalBox.delete(id);
  }

  static Future<void> updateJournal(Journal journal) async {
    await _journalBox.put(journal.id, journal);
  }

  static Journal? getJournalById(int id) {
    return _journalBox.get(id);
  }
}

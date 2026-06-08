import 'package:hive/hive.dart';

class Journal {
  final int id;
  final String title;
  final String? coverPath;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  Journal({
    required this.id,
    required this.title,
    this.coverPath,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) : createdAt = createdAt ?? DateTime.now(),
       metadata = metadata ?? {'pages': []};

  List<Map<String, dynamic>> get pages {
    return List<Map<String, dynamic>>.from(metadata['pages'] ?? []);
  }

  int get entryCount {
    return (metadata['entries'] as int?) ?? pages.length;
  }

  Journal copyWith({
    int? id,
    String? title,
    String? coverPath,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return Journal(
      id: id ?? this.id,
      title: title ?? this.title,
      coverPath: coverPath ?? this.coverPath,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? Map<String, dynamic>.from(this.metadata),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'coverPath': coverPath,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'metadata': metadata,
  };

  static Journal fromMap(Map m) => Journal(
    id: m['id'] as int,
    title: m['title'] as String,
    coverPath: m['coverPath'] as String?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int),
    metadata: Map<String, dynamic>.from(m['metadata'] ?? {}),
  );
}

class JournalAdapter extends TypeAdapter<Journal> {
  @override
  final int typeId = 0;

  @override
  Journal read(BinaryReader reader) {
    final id = reader.readInt();
    final title = reader.readString();
    final coverPath = reader.read() as String?;
    final createdAtMillis = reader.readInt();
    final metadata = Map<String, dynamic>.from(reader.read() as Map);
    return Journal(
      id: id,
      title: title,
      coverPath: coverPath,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
      metadata: metadata,
    );
  }

  @override
  void write(BinaryWriter writer, Journal obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.title);
    writer.write(obj.coverPath);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.write(obj.metadata);
  }
}

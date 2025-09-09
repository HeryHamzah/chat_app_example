import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

part 'database.g.dart';

// Tabel key-value sederhana untuk menyimpan snapshot tree sebagai JSON
class KvEntries extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [KvEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<void> put(String key, String value) async {
    await into(
      kvEntries,
    ).insertOnConflictUpdate(KvEntry(key: key, value: value));
  }

  Future<String?> getValue(String key) async {
    final row = await (select(
      kvEntries,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> clearAll() async {
    await delete(kvEntries).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'chat_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

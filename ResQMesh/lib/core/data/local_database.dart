import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/mesh_message.dart';

class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final base = await getDatabasesPath();
    _db = await openDatabase(
      p.join(base, 'resqmesh.db'), version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE messages(
            id TEXT PRIMARY KEY, sender TEXT NOT NULL, body TEXT NOT NULL,
            created_at TEXT NOT NULL, kind TEXT NOT NULL,
            latitude REAL, longitude REAL, delivery_state TEXT NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<void> save(MeshMessage message) async {
    final db = await database;
    await db.insert('messages', message.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<MeshMessage>> all() async {
    final db = await database;
    final rows = await db.query('messages', orderBy: 'created_at DESC', limit: 200);
    return rows.map(MeshMessage.fromMap).toList();
  }
}

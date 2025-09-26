import 'package:hive/hive.dart';

class BaseRepository<T> {
  BaseRepository(this.name) {
    _box = Hive.openBox<T>(name);
  }

  final String name;

  late Future<Box> _box;

  Future<Box> box() async {
    return await _box;
  }

  Future<void> open() async {
    Box box = await _box;
    if (!box.isOpen) {
      _box = Hive.openBox<T>(name);
    }
  }

  Future<int> save(T record) async {
    final box = await _box;
    return await box.add(record);
  }

  Future<List<T>> fetchAll({bool desc = false}) async {
    final box = await _box;
    List<T> list = box.values.cast<T>().toList();
    if (desc) {
      return list.reversed.toList();
    }
    return list;
  }

  Future<T?> get(int id) async {
    final box = await _box;
    final model = box.get(id);
    return model;
  }

  Future<void> deleteAll() async {
    final box = await _box;
    await box.deleteFromDisk();
    await open();
  }

  Future<void> delete(dynamic id) async {
    final box = await _box;
    await box.delete(id);
  }

  Future<Map<dynamic, dynamic>> map() async {
    final box = await _box;
    return box.toMap();
  }

  Future<List<dynamic>> keys() async {
    final box = await _box;
    return box.keys.toList();
  }

  void flush() async {
    final box = await _box;
    box.flush();
  }
}
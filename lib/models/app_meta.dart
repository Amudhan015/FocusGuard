import 'package:hive/hive.dart';

import 'enums.dart';

class AppMeta extends HiveObject {
  AppMeta({
    required this.packageName,
    this.categoryOverride,
    this.isBlocked = false,
    this.blockNote,
    required this.lastUpdated,
  });

  final String packageName;
  AppCategory? categoryOverride;
  bool isBlocked;
  String? blockNote;
  DateTime lastUpdated;
}

class AppMetaAdapter extends TypeAdapter<AppMeta> {
  @override
  final int typeId = 9;

  @override
  AppMeta read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppMeta(
      packageName: fields[0] as String,
      categoryOverride: fields[1] as AppCategory?,
      isBlocked: fields[2] as bool,
      blockNote: fields[3] as String?,
      lastUpdated: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AppMeta obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.packageName)
      ..writeByte(1)
      ..write(obj.categoryOverride)
      ..writeByte(2)
      ..write(obj.isBlocked)
      ..writeByte(3)
      ..write(obj.blockNote)
      ..writeByte(4)
      ..write(obj.lastUpdated);
  }
}


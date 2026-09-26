import 'package:hive/hive.dart';

import 'enums.dart';

class Achievement extends HiveObject {
  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.thresholdValue,
    this.unlockedAt,
  });

  final String id;
  final String title;
  final String description;
  final AchievementType type;
  final int thresholdValue;
  DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null;
}

class AchievementAdapter extends TypeAdapter<Achievement> {
  @override
  final int typeId = 11;

  @override
  Achievement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Achievement(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      type: fields[3] as AchievementType,
      thresholdValue: fields[4] as int,
      unlockedAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Achievement obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.thresholdValue)
      ..writeByte(5)
      ..write(obj.unlockedAt);
  }
}

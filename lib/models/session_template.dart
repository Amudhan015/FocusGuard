import 'package:hive/hive.dart';

import 'enums.dart';

class SessionTemplate extends HiveObject {
  SessionTemplate({
    required this.id,
    required this.name,
    required this.mode,
    required this.focusMinutes,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.sessionsBeforeLongBreak = 4,
    required this.subjectTag,
    this.intentionText,
    required this.createdAt,
  });

  final String id;
  String name;
  SessionMode mode;
  int focusMinutes;
  int shortBreakMinutes;
  int longBreakMinutes;
  int sessionsBeforeLongBreak;
  String subjectTag;
  final String? intentionText;
  final DateTime createdAt;
}

class SessionTemplateAdapter extends TypeAdapter<SessionTemplate> {
  @override
  final int typeId = 8;

  @override
  SessionTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SessionTemplate(
      id: fields[0] as String,
      name: fields[1] as String,
      mode: fields[2] as SessionMode,
      focusMinutes: fields[3] as int,
      shortBreakMinutes: fields[4] as int,
      longBreakMinutes: fields[5] as int,
      sessionsBeforeLongBreak: fields[6] as int,
      subjectTag: fields[7] as String,
      createdAt: fields[8] as DateTime,
      intentionText: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SessionTemplate obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.mode)
      ..writeByte(3)
      ..write(obj.focusMinutes)
      ..writeByte(4)
      ..write(obj.shortBreakMinutes)
      ..writeByte(5)
      ..write(obj.longBreakMinutes)
      ..writeByte(6)
      ..write(obj.sessionsBeforeLongBreak)
      ..writeByte(7)
      ..write(obj.subjectTag)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.intentionText);
  }
}

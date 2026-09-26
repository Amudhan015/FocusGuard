import 'package:hive/hive.dart';

class EscapeAttempt extends HiveObject {
  EscapeAttempt({
    required this.timestamp,
    required this.packageName,
    required this.appName,
  });

  final DateTime timestamp;
  final String packageName;
  final String appName;
}

class EscapeAttemptAdapter extends TypeAdapter<EscapeAttempt> {
  @override
  final int typeId = 5;

  @override
  EscapeAttempt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EscapeAttempt(
      timestamp: fields[0] as DateTime,
      packageName: fields[1] as String,
      appName: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, EscapeAttempt obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.packageName)
      ..writeByte(2)
      ..write(obj.appName);
  }
}

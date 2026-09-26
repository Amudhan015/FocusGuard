import 'package:hive/hive.dart';

class StreakData extends HiveObject {
  StreakData({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    this.freezeUsedForWeekStart,
  });

  int currentStreak;
  int longestStreak;
  DateTime? lastActiveDate;
  DateTime? freezeUsedForWeekStart;
}

class StreakDataAdapter extends TypeAdapter<StreakData> {
  @override
  final int typeId = 10;

  @override
  StreakData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StreakData(
      currentStreak: fields[0] as int,
      longestStreak: fields[1] as int,
      lastActiveDate: fields[2] as DateTime?,
      freezeUsedForWeekStart: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, StreakData obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.currentStreak)
      ..writeByte(1)
      ..write(obj.longestStreak)
      ..writeByte(2)
      ..write(obj.lastActiveDate)
      ..writeByte(3)
      ..write(obj.freezeUsedForWeekStart);
  }
}

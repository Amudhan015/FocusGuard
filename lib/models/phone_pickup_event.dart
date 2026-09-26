import 'package:hive/hive.dart';

class PhonePickupEvent extends HiveObject {
  PhonePickupEvent({required this.timestamp});

  final DateTime timestamp;
}

class PhonePickupEventAdapter extends TypeAdapter<PhonePickupEvent> {
  @override
  final int typeId = 6;

  @override
  PhonePickupEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PhonePickupEvent(timestamp: fields[0] as DateTime);
  }

  @override
  void write(BinaryWriter writer, PhonePickupEvent obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.timestamp);
  }
}

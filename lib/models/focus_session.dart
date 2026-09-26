import 'package:hive/hive.dart';

import 'enums.dart';
import 'escape_attempt.dart';
import 'phone_pickup_event.dart';

class FocusSession extends HiveObject {
  FocusSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.mode,
    required this.plannedDurationMinutes,
    this.actualDurationMinutes = 0,
    required this.subjectTag,
    this.intentionText,
    this.status = SessionStatus.active,
    this.endedEarly = false,
    this.selfRating,
    this.reflectionNote,
    this.photoPath,
    this.isGalleryFallbackPhoto = false,
    this.isDuplicatePhoto = false,
    this.elapsedSecondsInCurrentPhase = 0,
    List<EscapeAttempt>? escapeAttempts,
    List<PhonePickupEvent>? phonePickups,
    this.templateId,
  })  : escapeAttempts = escapeAttempts ?? <EscapeAttempt>[],
        phonePickups = phonePickups ?? <PhonePickupEvent>[];

  final String id;
  final DateTime startTime;
  DateTime? endTime;
  final SessionMode mode;
  final int plannedDurationMinutes;
  int actualDurationMinutes;
  final String subjectTag;
  final String? intentionText;
  SessionStatus status;
  bool endedEarly;
  SelfRating? selfRating;
  String? reflectionNote;
  String? photoPath;
  bool isGalleryFallbackPhoto;
  bool isDuplicatePhoto;
  final List<EscapeAttempt> escapeAttempts;
  final List<PhonePickupEvent> phonePickups;
  final String? templateId;

  bool get isClosed => status == SessionStatus.closed;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'mode': mode.name,
      'plannedDurationMinutes': plannedDurationMinutes,
      'actualDurationMinutes': actualDurationMinutes,
      'subjectTag': subjectTag,
      'intentionText': intentionText,
      'status': status.name,
      'endedEarly': endedEarly,
      'selfRating': selfRating?.name,
      'reflectionNote': reflectionNote,
      'photoPath': photoPath,
      'isGalleryFallbackPhoto': isGalleryFallbackPhoto,
      'isDuplicatePhoto': isDuplicatePhoto,
      'elapsedSecondsInCurrentPhase': elapsedSecondsInCurrentPhase,
      'templateId': templateId,
    };
  }
}

class FocusSessionAdapter extends TypeAdapter<FocusSession> {
  @override
  final int typeId = 7;

  @override
  FocusSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FocusSession(
      id: fields[0] as String,
      startTime: fields[1] as DateTime,
      endTime: fields[2] as DateTime?,
      mode: fields[3] as SessionMode,
      plannedDurationMinutes: fields[4] as int,
      actualDurationMinutes: fields[5] as int,
      subjectTag: fields[6] as String,
      intentionText: fields[7] as String?,
      status: fields[8] as SessionStatus,
      endedEarly: fields[9] as bool,
      selfRating: fields[10] as SelfRating?,
      reflectionNote: fields[11] as String?,
      photoPath: fields[12] as String?,
      isGalleryFallbackPhoto: fields[13] as bool,
      isDuplicatePhoto: fields[14] as bool,
      elapsedSecondsInCurrentPhase: fields.length > 18 ? fields[18] as int : 0,
      escapeAttempts: (fields[15] as List).cast<EscapeAttempt>(),
      phonePickups: (fields[16] as List).cast<PhonePickupEvent>(),
      templateId: fields[17] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FocusSession obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime)
      ..writeByte(3)
      ..write(obj.mode)
      ..writeByte(4)
      ..write(obj.plannedDurationMinutes)
      ..writeByte(5)
      ..write(obj.actualDurationMinutes)
      ..writeByte(6)
      ..write(obj.subjectTag)
      ..writeByte(7)
      ..write(obj.intentionText)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.endedEarly)
      ..writeByte(10)
      ..write(obj.selfRating)
      ..writeByte(11)
      ..write(obj.reflectionNote)
      ..writeByte(12)
      ..write(obj.photoPath)
      ..writeByte(13)
      ..write(obj.isGalleryFallbackPhoto)
      ..writeByte(14)
      ..write(obj.isDuplicatePhoto)
      ..writeByte(15)
      ..write(obj.escapeAttempts)
      ..writeByte(16)
      ..write(obj.phonePickups)
      ..writeByte(17)
      ..write(obj.templateId)
      ..writeByte(18)
      ..write(obj.elapsedSecondsInCurrentPhase);
  }
}

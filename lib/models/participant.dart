import 'package:hive/hive.dart';

class Participant {
  final String id;
  final String name;
  final DateTime checkInTime;

  Participant({
    required this.id,
    required this.name,
    required this.checkInTime,
  });
}

class ParticipantAdapter extends TypeAdapter<Participant> {
  @override
  final int typeId = 1;

  @override
  Participant read(BinaryReader reader) {
    return Participant(
      id: reader.readString(),
      name: reader.readString(),
      checkInTime: DateTime.parse(reader.readString()),
    );
  }

  @override
  void write(BinaryWriter writer, Participant obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.checkInTime.toIso8601String());
  }
}

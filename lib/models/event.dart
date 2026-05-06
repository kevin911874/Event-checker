import 'package:hive/hive.dart';

class Event {
  final String name;
  final DateTime dateTime;
  final int maxCapacity;

  Event({
    required this.name,
    required this.dateTime,
    required this.maxCapacity,
  });

  // Convert to Map for potential JSON serialization/logging
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dateTime': dateTime.toIso8601String(),
      'maxCapacity': maxCapacity,
    };
  }
}

// Manual Hive Adapter for Event so we don't rely on build_runner which might hang
class EventAdapter extends TypeAdapter<Event> {
  @override
  final int typeId = 0;

  @override
  Event read(BinaryReader reader) {
    return Event(
      name: reader.readString(),
      dateTime: DateTime.parse(reader.readString()),
      maxCapacity: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, Event obj) {
    writer.writeString(obj.name);
    writer.writeString(obj.dateTime.toIso8601String());
    writer.writeInt(obj.maxCapacity);
  }
}

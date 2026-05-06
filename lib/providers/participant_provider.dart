import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/participant.dart';

class ParticipantProvider with ChangeNotifier {
  static const String _participantBoxName = 'participantBox';
  List<Participant> _participants = [];
  bool _isLoading = true;

  List<Participant> get participants => _participants;
  int get checkedInCount => _participants.length;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    final box = await Hive.openBox<Participant>(_participantBoxName);
    _participants = box.values.toList();
    
    _isLoading = false;
    notifyListeners();
  }

  // Phase 3 will use this to add participants
  Future<bool> checkInParticipant(String id, String name) async {
    // Check for duplicate
    if (_participants.any((p) => p.id == id)) {
      return false; // Duplicate
    }

    final box = await Hive.openBox<Participant>(_participantBoxName);
    final participant = Participant(
      id: id,
      name: name,
      checkInTime: DateTime.now(),
    );
    
    await box.add(participant);
    _participants.add(participant);
    notifyListeners();
    return true;
  }

  Future<void> clearParticipants() async {
    final box = await Hive.openBox<Participant>(_participantBoxName);
    await box.clear();
    _participants.clear();
    notifyListeners();
  }
}

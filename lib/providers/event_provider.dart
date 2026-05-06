import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/event.dart';

class EventProvider with ChangeNotifier {
  static const String _eventBoxName = 'eventBox';
  Event? _currentEvent;
  bool _isLoading = true;

  Event? get currentEvent => _currentEvent;
  bool get isLoading => _isLoading;
  bool get hasEvent => _currentEvent != null;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    final box = await Hive.openBox<Event>(_eventBoxName);
    if (box.isNotEmpty) {
      _currentEvent = box.getAt(0);
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createEvent(String name, DateTime dateTime, int maxCapacity) async {
    final box = await Hive.openBox<Event>(_eventBoxName);
    
    final newEvent = Event(
      name: name,
      dateTime: dateTime,
      maxCapacity: maxCapacity,
    );
    
    // We only support one active event for this version.
    await box.clear(); 
    await box.add(newEvent);
    
    _currentEvent = newEvent;
    notifyListeners();
  }

  Future<void> clearEvent() async {
    final box = await Hive.openBox<Event>(_eventBoxName);
    await box.clear();
    _currentEvent = null;
    notifyListeners();
  }
}

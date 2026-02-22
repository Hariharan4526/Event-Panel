import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';

class EventProvider with ChangeNotifier {
  final EventService _eventService = EventService();

  List<EventModel> _events = [];
  List<EventModel> _coordinatorEvents = [];
  EventModel? _selectedEvent;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCategory = 'all';

  List<EventModel> get events => _events;
  List<EventModel> get coordinatorEvents => _coordinatorEvents;
  EventModel? get selectedEvent => _selectedEvent;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;

  // Get filtered events by category
  List<EventModel> get filteredEvents {
    if (_selectedCategory == 'all') {
      return _events;
    }
    return _events.where((e) => e.category == _selectedCategory).toList();
  }

  // Set category filter
  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Load published events
  Future<void> loadPublishedEvents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _events = await _eventService.getPublishedEvents();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load coordinator events
  Future<void> loadCoordinatorEvents(String coordinatorId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _coordinatorEvents = await _eventService.getCoordinatorEvents(coordinatorId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search events
  Future<void> searchEvents(String query) async {
    if (query.isEmpty) {
      await loadPublishedEvents();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _events = await _eventService.searchEvents(query);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load event details
  Future<void> loadEventDetails(String eventId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedEvent = await _eventService.getEventById(eventId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create event
  Future<bool> createEvent(Map<String, dynamic> eventData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final event = await _eventService.createEvent(eventData);
      _coordinatorEvents.insert(0, event);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update event
  Future<bool> updateEvent(String eventId, Map<String, dynamic> updates) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedEvent = await _eventService.updateEvent(eventId, updates);

      // Update in coordinator events list
      final index = _coordinatorEvents.indexWhere((e) => e.id == eventId);
      if (index != -1) {
        _coordinatorEvents[index] = updatedEvent;
      }

      // Update selected event if it's the same
      if (_selectedEvent?.id == eventId) {
        _selectedEvent = updatedEvent;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete event
  Future<bool> deleteEvent(String eventId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _eventService.deleteEvent(eventId);
      _coordinatorEvents.removeWhere((e) => e.id == eventId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSelectedEvent() {
    _selectedEvent = null;
    notifyListeners();
  }
}


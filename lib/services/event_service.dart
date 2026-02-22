import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/event_model.dart';

class EventService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all published events
  Future<List<EventModel>> getPublishedEvents() async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.eventsTable)
          .select()
          .eq('status', 'published')
          .order('start_date', ascending: true);

      return (response as List)
          .map((json) => EventModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch events: $e');
    }
  }

  // Get events by category
  Future<List<EventModel>> getEventsByCategory(String category) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.eventsTable)
          .select()
          .eq('status', 'published')
          .eq('category', category)
          .order('start_date', ascending: true);

      return (response as List)
          .map((json) => EventModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch events: $e');
    }
  }

  // Search events
  Future<List<EventModel>> searchEvents(String query) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.eventsTable)
          .select()
          .eq('status', 'published')
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .order('start_date', ascending: true);

      return (response as List)
          .map((json) => EventModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search events: $e');
    }
  }

  // Get event by ID
  Future<EventModel> getEventById(String eventId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.eventsTable)
          .select()
          .eq('id', eventId)
          .single();

      return EventModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch event: $e');
    }
  }

  // Get events created by coordinator
  Future<List<EventModel>> getCoordinatorEvents(String coordinatorId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.eventsTable)
          .select()
          .eq('created_by', coordinatorId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => EventModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch coordinator events: $e');
    }
  }

  // Create event
  Future<EventModel> createEvent(Map<String, dynamic> eventData) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.eventsTable)
          .insert(eventData)
          .select()
          .single();

      return EventModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  // Update event
  Future<EventModel> updateEvent(String eventId, Map<String, dynamic> updates) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.eventsTable)
          .update(updates)
          .eq('id', eventId)
          .select()
          .single();

      return EventModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  // Delete event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _supabase
          .from(SupabaseConfig.eventsTable)
          .delete()
          .eq('id', eventId);
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  // Upload event banner
  Future<String> uploadBanner(File imageFile, String eventId) async {
    try {
      final String fileName = '$eventId-${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage
          .from(SupabaseConfig.eventBannersBucket)
          .upload(fileName, imageFile);

      final String publicUrl = _supabase.storage
          .from(SupabaseConfig.eventBannersBucket)
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload banner: $e');
    }
  }

  // Get event statistics
  Future<Map<String, dynamic>> getEventStats(String eventId) async {
    try {
      // Get registrations count
      final registrationsResponse = await _supabase
          .from(SupabaseConfig.registrationsTable)
          .select('id')
          .eq('event_id', eventId);

      final totalRegistrations = (registrationsResponse as List).length;

      // Get paid registrations
      final paidResponse = await _supabase
          .from(SupabaseConfig.registrationsTable)
          .select('id')
          .eq('event_id', eventId)
          .eq('payment_status', 'completed');

      final paidRegistrations = (paidResponse as List).length;

      // Get total revenue
      final revenueResponse = await _supabase
          .from(SupabaseConfig.registrationsTable)
          .select('amount_paid')
          .eq('event_id', eventId)
          .eq('payment_status', 'completed');

      double totalRevenue = 0;
      for (var reg in revenueResponse) {
        totalRevenue += (reg['amount_paid'] as num).toDouble();
      }

      // Get attendance count
      final attendanceResponse = await _supabase
          .from(SupabaseConfig.attendanceTable)
          .select('id')
          .eq('event_id', eventId);

      final attendanceCount = (attendanceResponse as List).length;

      return {
        'total_registrations': totalRegistrations,
        'paid_registrations': paidRegistrations,
        'total_revenue': totalRevenue,
        'attendance_count': attendanceCount,
        'attendance_rate': paidRegistrations > 0
            ? (attendanceCount / paidRegistrations * 100)
            : 0,
        'no_show_count': paidRegistrations - attendanceCount,
      };
    } catch (e) {
      throw Exception('Failed to fetch event stats: $e');
    }
  }
}


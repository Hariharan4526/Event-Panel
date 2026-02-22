import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../config/supabase_config.dart';
import '../models/registration_model.dart';

class RegistrationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  // Create registration
  Future<RegistrationModel> createRegistration({
    required String userId,
    required String eventId,
    required double amountPaid,
  }) async {
    try {
      // Generate unique QR token
      final qrToken = _uuid.v4();

      print('DEBUG: Creating registration with QR token: $qrToken');
      print('DEBUG: Token length: ${qrToken.length}');

      final registrationData = {
        'user_id': userId,
        'event_id': eventId,
        'payment_status': 'pending',
        'amount_paid': amountPaid,
        'qr_token': qrToken,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from(SupabaseConfig.registrationsTable)
          .insert(registrationData)
          .select()
          .single();

      print('DEBUG: Registration created with ID: ${response['id']}');
      print('DEBUG: Stored QR token: ${response['qr_token']}');

      return RegistrationModel.fromJson(response);
    } catch (e) {
      print('DEBUG: Registration creation error: $e');
      throw Exception('Failed to create registration: $e');
    }
  }

  // Update payment status
  Future<RegistrationModel> updatePaymentStatus({
    required String registrationId,
    required String status,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.registrationsTable)
          .update({'payment_status': status})
          .eq('id', registrationId)
          .select()
          .single();

      return RegistrationModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }

  // Get user registrations
  Future<List<RegistrationModel>> getUserRegistrations(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.registrationsTable)
          .select('''
            *,
            events!inner(
              title,
              start_date,
              venue
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        final registration = RegistrationModel.fromJson(json);
        // Map event data
        if (json['events'] != null) {
          registration.eventTitle = json['events']['title'];
          registration.eventStartDate = DateTime.parse(json['events']['start_date']);
          registration.eventVenue = json['events']['venue'];
        }
        return registration;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch user registrations: $e');
    }
  }

  // Get event registrations (for coordinator)
  Future<List<RegistrationModel>> getEventRegistrations(String eventId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.registrationsTable)
          .select('''
            *,
            users!inner(
              name,
              email
            )
          ''')
          .eq('event_id', eventId)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        final registration = RegistrationModel.fromJson(json);
        // Map user data
        if (json['users'] != null) {
          registration.userName = json['users']['name'];
          registration.userEmail = json['users']['email'];
        }
        return registration;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch event registrations: $e');
    }
  }

  // Get registration by QR token
  Future<RegistrationModel?> getRegistrationByQRToken(String qrToken) async {
    try {
      // Trim whitespace from token
      final cleanToken = qrToken.trim();

      print('DEBUG Service: Looking up QR token: "$cleanToken"');
      print('DEBUG Service: Token length: ${cleanToken.length}');

      final response = await _supabase
          .from(SupabaseConfig.registrationsTable)
          .select('''
            *,
            users!inner(
              name,
              email
            ),
            events!inner(
              title,
              start_date,
              venue
            )
          ''')
          .eq('qr_token', cleanToken)
          .single();

      print('DEBUG Service: Found registration: ${response['id']}');

      final registration = RegistrationModel.fromJson(response);

      // Map user data
      if (response['users'] != null) {
        registration.userName = response['users']['name'];
        registration.userEmail = response['users']['email'];
      }

      // Map event data
      if (response['events'] != null) {
        registration.eventTitle = response['events']['title'];
        registration.eventStartDate = DateTime.parse(response['events']['start_date']);
        registration.eventVenue = response['events']['venue'];
      }

      return registration;
    } catch (e) {
      print('DEBUG Service: QR Lookup Error: $e');
      return null;
    }
  }

  // Check if user is registered for event
  Future<bool> isUserRegistered({
    required String userId,
    required String eventId,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.registrationsTable)
          .select('id')
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Get registration count for event
  Future<int> getEventRegistrationCount(String eventId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.registrationsTable)
          .select('id')
          .eq('event_id', eventId);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }
}


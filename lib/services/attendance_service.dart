import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/attendance_model.dart';

class AttendanceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Mark attendance
  Future<AttendanceModel> markAttendance({
    required String userId,
    required String eventId,
    required String scannedBy,
  }) async {
    try {
      final attendanceData = {
        'user_id': userId,
        'event_id': eventId,
        'scanned_by': scannedBy,
        'scanned_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from(SupabaseConfig.attendanceTable)
          .insert(attendanceData)
          .select()
          .single();

      return AttendanceModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to mark attendance: $e');
    }
  }

  // Check if attendance is already marked
  Future<AttendanceModel?> checkAttendance({
    required String userId,
    required String eventId,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.attendanceTable)
          .select('''
            *,
            users!inner(
              name,
              email
            ),
            events!inner(
              title
            )
          ''')
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .maybeSingle();

      if (response == null) return null;

      final attendance = AttendanceModel.fromJson(response);

      // Map user data
      if (response['users'] != null) {
        attendance.userName = response['users']['name'];
        attendance.userEmail = response['users']['email'];
      }

      // Map event data
      if (response['events'] != null) {
        attendance.eventTitle = response['events']['title'];
      }

      return attendance;
    } catch (e) {
      return null;
    }
  }

  // Get event attendance list
  Future<List<AttendanceModel>> getEventAttendance(String eventId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.attendanceTable)
          .select('''
            *,
            users!inner(
              name,
              email
            )
          ''')
          .eq('event_id', eventId)
          .order('scanned_at', ascending: false);

      return (response as List).map((json) {
        final attendance = AttendanceModel.fromJson(json);

        // Map user data
        if (json['users'] != null) {
          attendance.userName = json['users']['name'];
          attendance.userEmail = json['users']['email'];
        }

        return attendance;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch event attendance: $e');
    }
  }

  // Get user's attendance for an event
  Future<bool> hasUserAttended({
    required String userId,
    required String eventId,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.attendanceTable)
          .select('id')
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Get attendance count for event
  Future<int> getEventAttendanceCount(String eventId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.attendanceTable)
          .select('id')
          .eq('event_id', eventId);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }
}


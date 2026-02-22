import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Get current user ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  // Auth state stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Sign up with email and password
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    String role = 'user',
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Sign up failed - no user returned');
      }

      // Create user profile in users table
      final userProfile = {
        'id': response.user!.id,
        'name': name,
        'email': email,
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from(SupabaseConfig.usersTable)
          .insert(userProfile);

      return UserModel.fromJson(userProfile);
    } on AuthApiException catch (e) {
      // Handle specific Supabase auth errors
      if (e.statusCode == '429') {
        throw Exception(
          'Too many sign up attempts. Please wait a few minutes before trying again, '
          'or use the login form if you already have an account.'
        );
      } else if (e.message.contains('rate limit')) {
        throw Exception(
          'Rate limit exceeded. Please wait a moment and try again.'
        );
      } else if (e.message.contains('already registered')) {
        throw Exception(
          'This email is already registered. Please use the login form instead.'
        );
      }
      throw Exception('Sign up failed: ${e.message}');
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Sign in failed - no user returned');
      }

      // Fetch user profile
      final userData = await _supabase
          .from(SupabaseConfig.usersTable)
          .select()
          .eq('id', response.user!.id)
          .single();

      return UserModel.fromJson(userData);
    } on AuthApiException catch (e) {
      // Handle specific Supabase auth errors
      if (e.message.contains('Invalid login credentials')) {
        throw Exception('Invalid email or password. Please try again.');
      } else if (e.statusCode == '429') {
        throw Exception(
          'Too many login attempts. Please wait a few minutes before trying again.'
        );
      }
      throw Exception('Sign in failed: ${e.message}');
    } catch (e) {
      if (e.toString().contains('Invalid login credentials')) {
        throw Exception('Invalid email or password. Please try again.');
      }
      throw Exception('Sign in failed: $e');
    }
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final userData = await _supabase
          .from(SupabaseConfig.usersTable)
          .select()
          .eq('id', userId)
          .single();

      return UserModel.fromJson(userData);
    } catch (e) {
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // Check if user is coordinator
  Future<bool> isCoordinator() async {
    if (currentUserId == null) return false;

    final userProfile = await getUserProfile(currentUserId!);
    return userProfile?.isCoordinator ?? false;
  }
}


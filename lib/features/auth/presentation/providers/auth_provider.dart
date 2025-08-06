import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/models/models.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authStateProvider = StreamProvider<User?>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return supabase.auth.onAuthStateChange.map((event) => event.session?.user);
});

final currentUserProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;

  final supabase = ref.watch(supabaseProvider);
  final response =
      await supabase.from('user_profiles').select().eq('id', user.id).single();

  return UserProfile.fromJson(response);
});

final cartItemCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(0);

  final supabase = ref.watch(supabaseProvider);
  return supabase
      .from('cart_items')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .map((data) => data.length);
});

final totalClientsProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return 0;

  final supabase = ref.watch(supabaseProvider);
  final response =
      await supabase.from('clients').select('id').eq('user_id', user.id);

  return (response as List).length;
});

final totalQuotesProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return 0;

  final supabase = ref.watch(supabaseProvider);
  final response =
      await supabase.from('quotes').select('id').eq('user_id', user.id);

  return (response as List).length;
});

final totalProductsProvider = FutureProvider<int>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final response = await supabase.from('products').select('id');

  return (response as List).length;
});

final recentQuotesProvider = FutureProvider<List<Quote>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return [];

  final supabase = ref.watch(supabaseProvider);
  final response = await supabase
      .from('quotes')
      .select('*, quote_items(*)')
      .eq('user_id', user.id)
      .order('created_at', ascending: false)
      .limit(5);

  return (response as List).map((json) => Quote.fromJson(json)).toList();
});

final recentSearchesProvider = FutureProvider<List<String>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return [];

  final supabase = ref.watch(supabaseProvider);
  final response = await supabase
      .from('search_history')
      .select('search_term')
      .eq('user_id', user.id)
      .order('created_at', ascending: false)
      .limit(10);

  return (response as List)
      .map((item) => item['search_term'] as String)
      .toList();
});

class AuthService {
  final SupabaseClient _supabase;

  AuthService(this._supabase);

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? company,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'company': company},
    );

    if (response.user != null) {
      // Profile will be created automatically by database trigger
    }

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return AuthService(supabase);
});

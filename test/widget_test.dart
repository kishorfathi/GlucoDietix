import 'package:flutter_test/flutter_test.dart';
import 'package:glucodietix/config/supabase_config.dart';

void main() {
  test('Supabase configuration is set', () {
    expect(SupabaseConfig.supabaseUrl, startsWith('https://'));
    expect(SupabaseConfig.supabaseUrl, contains('supabase.co'));
    expect(SupabaseConfig.supabaseAnonKey.isNotEmpty, isTrue);
    expect(SupabaseConfig.supabaseAnonKey.contains('YOUR_'), isFalse);
  });
}

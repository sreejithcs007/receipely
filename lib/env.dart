import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'https://wajcmhegnifxiuqmxvyx.supabase.co')
  static const String supabaseUrl = _Env.supabaseUrl;

  @EnviedField(
    varName:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndhamNtaGVnbmlmeGl1cW14dnl4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI2NjY0OTUsImV4cCI6MjA5ODI0MjQ5NX0.oGo3PyQ5JO07I0Ok8PESJCa_L0_PbDaY3hwFgkFjroY',
  )
  static const String supabaseAnonKey = _Env.supabaseAnonKey;
}

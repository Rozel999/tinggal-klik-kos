// Build-time backend selection. Credentials come from --dart-define or a local config file.
enum BackendMode { local, supabase, mysql }

class BackendConfig {
  const BackendConfig._();

  static const _name =
      String.fromEnvironment('APP_BACKEND', defaultValue: 'supabase');
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const mysqlApiBaseUrl = String.fromEnvironment('MYSQL_API_BASE_URL');

  static BackendMode get mode => switch (_name.toLowerCase()) {
        'supabase' => BackendMode.supabase,
        'mysql' => BackendMode.mysql,
        _ => BackendMode.local,
      };

  static bool get isConfigured => switch (mode) {
        BackendMode.local => true,
        BackendMode.supabase => supabaseUrl.startsWith('https://') &&
            supabasePublishableKey.startsWith('sb_publishable_'),
        BackendMode.mysql => mysqlApiBaseUrl.startsWith('https://'),
      };

  static String get label => switch (mode) {
        BackendMode.local => 'Local demo',
        BackendMode.supabase => 'Supabase',
        BackendMode.mysql => 'MySQL via REST API',
      };
}

/// Configuration for the Turbo Air app
/// Location: lib/core/config/app_config.dart
class AppConfig {
  // Supabase Configuration from environment variables
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  
  // Edge Function URLs
  static String get emailFunctionUrl => '$supabaseUrl/functions/v1/send-email';
  static String get syncFunctionUrl => '$supabaseUrl/functions/v1/sync-data';
  
  // App Settings
  static const int itemsPerPage = 20;
  static const int maxSearchHistory = 10;
  static const Duration syncInterval = Duration(minutes: 5);
  static const Duration cacheExpiration = Duration(hours: 24);
  
  // Tax Settings
  static const double defaultTaxRate = 8.0;
  
  // File Size Limits
  static const int maxFileSize = 200 * 1024 * 1024; // 200MB
  
  // Categories
  static const Map<String, CategoryInfo> categories = {
    'REACH-IN REFRIGERATION': CategoryInfo(
      icon: '❄️',
      series: ['PRO', 'TSF', 'M3R', 'M3F', 'M3H'],
      types: ['Refrigerators', 'Freezers', 'Dual Temperature'],
    ),
    'FOOD PREP TABLES': CategoryInfo(
      icon: '🥗',
      series: ['PST', 'TST', 'MST', 'TPR'],
      types: ['Sandwich/Salad Prep', 'Pizza Prep'],
    ),
    'UNDERCOUNTER REFRIGERATION': CategoryInfo(
      icon: '📦',
      series: ['MUR', 'PUR', 'EUR'],
      types: ['Refrigerators', 'Freezers'],
    ),
    'WORKTOP REFRIGERATION': CategoryInfo(
      icon: '🔧',
      series: ['TWR', 'PWR'],
      types: ['Refrigerators', 'Freezers'],
    ),
    'GLASS DOOR MERCHANDISERS': CategoryInfo(
      icon: '🥤',
      series: ['TGM', 'TGF'],
      types: ['Refrigerators', 'Freezers'],
    ),
    'DISPLAY CASES': CategoryInfo(
      icon: '🍰',
      series: ['Various'],
      types: ['Open Display', 'Deli Cases', 'Bakery Cases'],
    ),
    'UNDERBAR EQUIPMENT': CategoryInfo(
      icon: '🍺',
      series: ['Various'],
      types: ['Bottle Coolers', 'Beer Dispensers', 'Back Bars'],
    ),
    'MILK COOLERS': CategoryInfo(
      icon: '🥛',
      series: ['TMC', 'TMW'],
      types: ['Milk Coolers'],
    ),
  };
}

class CategoryInfo {
  final String icon;
  final List<String> series;
  final List<String> types;
  
  const CategoryInfo({
    required this.icon,
    required this.series,
    required this.types,
  });
}
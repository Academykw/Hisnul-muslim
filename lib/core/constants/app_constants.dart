class AppConstants {
  AppConstants._();

  static const String appName = 'Deen Azkar';
  static const String packageName = 'com.deen.adkhar';
  
  // Store Links
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=$packageName';
  static const String appleAppStoreUrl = 'https://apps.apple.com/app/idYOUR_APP_ID'; // Replace with real ID
  
  // Share Message
  static const String shareAppMessage = 'Download $appName app for daily duas and adhkar:\n$playStoreUrl';

  // Zakat Configuration
  static const List<String> zakatCurrencies = ['USD', 'GBP', 'EUR', 'SAR', 'AED', 'MYR', 'NGN'];
  static const double zakatRate = 0.025;

  // Firebase Fallbacks
  static const String fallbackInspirationContent = "Indeed, with hardship [will be] ease.";
  static const String fallbackInspirationSource = "Quran 94:6";

  // Method Channels
  static const String adhanAlarmChannel = '$packageName/adhan_alarm';
}

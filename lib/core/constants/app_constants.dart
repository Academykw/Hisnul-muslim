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
  static const List<String> zakatCurrencies = ['USD', 'GBP', 'EUR', 'SAR', 'AED', 'MYR', 'NGN', 'AUD', 'CAD'];
  static const double zakatRate = 0.025;

  // Firebase Fallbacks (Weekly Rotation)
  static const List<Map<String, String>> fallbackInspirations = [
    {
      'content': "Indeed, with hardship [will be] ease.",
      'source': "Quran 94:6",
    },
    {
      'content': "When My servants ask you about Me, I am indeed near.",
      'source': "Quran 2:186",
    },
    {
      'content': "So remember Me; I will remember you.",
      'source': "Quran 2:152",
    },
    {
      'content': "And when you have decided, then rely upon Allah.",
      'source': "Quran 3:159",
    },
    {
      'content': "Unquestionably, by the remembrance of Allah hearts are assured.",
      'source': "Quran 13:28",
    },
    {
      'content': "And Allah would not punish them while they seek forgiveness.",
      'source': "Quran 8:33",
    },
    {
      'content': "Do not despair of the mercy of Allah. Indeed, Allah forgives all sins.",
      'source': "Quran 39:53",
    },
  ];

  static const String fallbackInspirationContent = "Indeed, with hardship [will be] ease.";
  static const String fallbackInspirationSource = "Quran 94:6";

  // Method Channels
  static const String adhanAlarmChannel = '$packageName/adhan_alarm';
}

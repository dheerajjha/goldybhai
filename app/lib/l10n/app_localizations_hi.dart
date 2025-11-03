// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'सोने की कीमत ट्रैकर';

  @override
  String get priceTab => 'कीमत';

  @override
  String get alertsTab => 'अलर्ट';

  @override
  String get gold999WithGst => 'गोल्ड 999 जीएसटी के साथ';

  @override
  String get perKg => '1 किलो';

  @override
  String updatedAgo(String time) {
    return '$time पहले अपडेट किया गया';
  }

  @override
  String get last24Hours => 'पिछला 1 घंटा';

  @override
  String dataPoints(int count) {
    return '$count डेटा पॉइंट्स';
  }

  @override
  String get createAlert => 'अलर्ट बनाएं';

  @override
  String get noAlertsYet => 'अभी तक कोई अलर्ट नहीं';

  @override
  String get createFirstAlert =>
      'जब सोने की कीमत आपके लक्ष्य तक पहुंचे तो सूचना पाने के लिए अपना पहला मूल्य अलर्ट बनाएं।';

  @override
  String get alertMe => 'जब कीमत हो तो मुझे अलर्ट करें';

  @override
  String get above => 'से ऊपर';

  @override
  String get below => 'से नीचे';

  @override
  String get targetPrice => 'लक्ष्य मूल्य';

  @override
  String get enterPrice => 'कीमत दर्ज करें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get create => 'बनाएं';

  @override
  String get delete => 'हटाएं';

  @override
  String get deleteAlert => 'अलर्ट हटाएं';

  @override
  String get deleteAlertConfirm => 'क्या आप वाकई इस अलर्ट को हटाना चाहते हैं?';

  @override
  String get triggered => 'ट्रिगर हुआ';

  @override
  String get active => 'सक्रिय';

  @override
  String get testNotification => 'टेस्ट नोटिफिकेशन';

  @override
  String get testNotificationBody =>
      'यह आपके गोल्ड ट्रैकर बैकएंड से एक टेस्ट पुश नोटिफिकेशन है!';
}

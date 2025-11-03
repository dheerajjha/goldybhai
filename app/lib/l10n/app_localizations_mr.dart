// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appTitle => 'सोन्याचा दर ट्रॅकर';

  @override
  String get priceTab => 'किंमत';

  @override
  String get alertsTab => 'सूचना';

  @override
  String get gold999WithGst => 'गोल्ड 999 जीएसटी सह';

  @override
  String get perKg => '1 किलो';

  @override
  String updatedAgo(String time) {
    return '$time पूर्वी अपडेट केले';
  }

  @override
  String get last24Hours => 'गेला 1 तास';

  @override
  String dataPoints(int count) {
    return '$count डेटा पॉइंट्स';
  }

  @override
  String get createAlert => 'सूचना तयार करा';

  @override
  String get noAlertsYet => 'अद्याप कोणत्याही सूचना नाहीत';

  @override
  String get createFirstAlert =>
      'सोन्याची किंमत तुमच्या लक्ष्यापर्यंत पोहोचल्यावर सूचना मिळविण्यासाठी तुमची पहिली किंमत सूचना तयार करा.';

  @override
  String get alertMe => 'किंमत असेल तेव्हा मला सूचित करा';

  @override
  String get above => 'वर';

  @override
  String get below => 'खाली';

  @override
  String get targetPrice => 'लक्ष्य किंमत';

  @override
  String get enterPrice => 'किंमत प्रविष्ट करा';

  @override
  String get cancel => 'रद्द करा';

  @override
  String get create => 'तयार करा';

  @override
  String get delete => 'हटवा';

  @override
  String get deleteAlert => 'सूचना हटवा';

  @override
  String get deleteAlertConfirm =>
      'तुम्हाला खात्री आहे की तुम्ही ही सूचना हटवू इच्छिता?';

  @override
  String get triggered => 'ट्रिगर झाले';

  @override
  String get active => 'सक्रिय';

  @override
  String get testNotification => 'चाचणी सूचना';

  @override
  String get testNotificationBody =>
      'ही तुमच्या गोल्ड ट्रॅकर बॅकएंडकडून एक चाचणी पुश सूचना आहे!';
}

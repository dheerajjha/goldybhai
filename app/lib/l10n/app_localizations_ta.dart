// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'தங்க விலை டிராக்கர்';

  @override
  String get priceTab => 'விலை';

  @override
  String get alertsTab => 'எச்சரிக்கைகள்';

  @override
  String get gold999WithGst => 'கோல்ட் 999 ஜிஎஸ்டி உடன்';

  @override
  String get perKg => '1 கிலோ';

  @override
  String updatedAgo(String time) {
    return '$time முன் புதுப்பிக்கப்பட்டது';
  }

  @override
  String get last24Hours => 'கடந்த 24 மணி நேரம்';

  @override
  String dataPoints(int count) {
    return '$count தரவு புள்ளிகள்';
  }

  @override
  String get createAlert => 'எச்சரிக்கையை உருவாக்கு';

  @override
  String get noAlertsYet => 'இன்னும் எச்சரிக்கைகள் இல்லை';

  @override
  String get createFirstAlert =>
      'தங்கத்தின் விலை உங்கள் இலக்கை அடையும் போது அறிவிப்பு பெற உங்கள் முதல் விலை எச்சரிக்கையை உருவாக்கவும்.';

  @override
  String get alertMe => 'விலை இருக்கும் போது எனக்கு எச்சரிக்கை செய்யுங்கள்';

  @override
  String get above => 'மேலே';

  @override
  String get below => 'கீழே';

  @override
  String get targetPrice => 'இலக்கு விலை';

  @override
  String get enterPrice => 'விலையை உள்ளிடவும்';

  @override
  String get cancel => 'ரத்து செய்';

  @override
  String get create => 'உருவாக்கு';

  @override
  String get delete => 'நீக்கு';

  @override
  String get deleteAlert => 'எச்சரிக்கையை நீக்கு';

  @override
  String get deleteAlertConfirm =>
      'இந்த எச்சரிக்கையை நிச்சயமாக நீக்க விரும்புகிறீர்களா?';

  @override
  String get triggered => 'தூண்டப்பட்டது';

  @override
  String get active => 'செயலில்';

  @override
  String get testNotification => 'சோதனை அறிவிப்பு';

  @override
  String get testNotificationBody =>
      'இது உங்கள் கோல்ட் டிராக்கர் பின்தளத்திலிருந்து ஒரு சோதனை புஷ் அறிவிப்பு!';
}

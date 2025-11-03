// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Gold Price Tracker';

  @override
  String get priceTab => 'Price';

  @override
  String get alertsTab => 'Alerts';

  @override
  String get gold999WithGst => 'GOLD 999 WITH GST';

  @override
  String get perKg => '1 KG';

  @override
  String updatedAgo(String time) {
    return 'Updated $time ago';
  }

  @override
  String get last24Hours => 'Last 1 Hour';

  @override
  String dataPoints(int count) {
    return '$count data points';
  }

  @override
  String get createAlert => 'Create Alert';

  @override
  String get noAlertsYet => 'No alerts yet';

  @override
  String get createFirstAlert =>
      'Create your first price alert to get notified when gold price reaches your target.';

  @override
  String get alertMe => 'Alert me when price goes';

  @override
  String get above => 'Above';

  @override
  String get below => 'Below';

  @override
  String get targetPrice => 'Target Price';

  @override
  String get enterPrice => 'Enter price';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get delete => 'Delete';

  @override
  String get deleteAlert => 'Delete Alert';

  @override
  String get deleteAlertConfirm =>
      'Are you sure you want to delete this alert?';

  @override
  String get triggered => 'Triggered';

  @override
  String get active => 'Active';

  @override
  String get testNotification => 'Test Notification';

  @override
  String get testNotificationBody =>
      'This is a test push notification from your Gold Tracker backend!';
}

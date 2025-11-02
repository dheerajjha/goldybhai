// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'সোনার দাম ট্র্যাকার';

  @override
  String get priceTab => 'দাম';

  @override
  String get alertsTab => 'সতর্কতা';

  @override
  String get gold999WithGst => 'GOLD 999 WITH GST';

  @override
  String get perKg => '১ কেজি';

  @override
  String updatedAgo(String time) {
    return '$time আগে আপডেট করা হয়েছে';
  }

  @override
  String get last24Hours => 'শেষ ২৪ ঘন্টা';

  @override
  String dataPoints(int count) {
    return '$count ডেটা পয়েন্ট';
  }

  @override
  String get createAlert => 'সতর্কতা তৈরি করুন';

  @override
  String get noAlertsYet => 'এখনও কোনো সতর্কতা নেই';

  @override
  String get createFirstAlert =>
      'সোনার দাম আপনার লক্ষ্যে পৌঁছালে বিজ্ঞপ্তি পেতে আপনার প্রথম দাম সতর্কতা তৈরি করুন।';

  @override
  String get alertMe => 'দাম হলে আমাকে সতর্ক করুন';

  @override
  String get above => 'উপরে';

  @override
  String get below => 'নিচে';

  @override
  String get targetPrice => 'লক্ষ্য মূল্য';

  @override
  String get enterPrice => 'দাম লিখুন';

  @override
  String get cancel => 'বাতিল করুন';

  @override
  String get create => 'তৈরি করুন';

  @override
  String get delete => 'মুছুন';

  @override
  String get deleteAlert => 'সতর্কতা মুছুন';

  @override
  String get deleteAlertConfirm =>
      'আপনি কি নিশ্চিত যে আপনি এই সতর্কতা মুছতে চান?';

  @override
  String get triggered => 'ট্রিগার হয়েছে';

  @override
  String get active => 'সক্রিয়';

  @override
  String get testNotification => 'পরীক্ষা বিজ্ঞপ্তি';

  @override
  String get testNotificationBody =>
      'এটি আপনার গোল্ড ট্র্যাকার ব্যাকএন্ড থেকে একটি পরীক্ষা পুশ বিজ্ঞপ্তি!';
}

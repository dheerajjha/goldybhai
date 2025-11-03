// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Gujarati (`gu`).
class AppLocalizationsGu extends AppLocalizations {
  AppLocalizationsGu([String locale = 'gu']) : super(locale);

  @override
  String get appTitle => 'સોનાની કિંમત ટ્રેકર';

  @override
  String get priceTab => 'કિંમત';

  @override
  String get alertsTab => 'ચેતવણીઓ';

  @override
  String get gold999WithGst => 'ગોલ્ડ 999 જીએસટી સાથે';

  @override
  String get perKg => '1 કિલો';

  @override
  String updatedAgo(String time) {
    return '$time પહેલાં અપડેટ કર્યું';
  }

  @override
  String get last24Hours => 'છેલ્લો 1 કલાક';

  @override
  String dataPoints(int count) {
    return '$count ડેટા પોઇન્ટ્સ';
  }

  @override
  String get createAlert => 'ચેતવણી બનાવો';

  @override
  String get noAlertsYet => 'હજુ સુધી કોઈ ચેતવણી નથી';

  @override
  String get createFirstAlert =>
      'સોનાની કિંમત તમારા લક્ષ્ય સુધી પહોંચે ત્યારે સૂચના મેળવવા માટે તમારી પ્રથમ કિંમત ચેતવણી બનાવો.';

  @override
  String get alertMe => 'કિંમત હોય ત્યારે મને ચેતવણી આપો';

  @override
  String get above => 'ઉપર';

  @override
  String get below => 'નીચે';

  @override
  String get targetPrice => 'લક્ષ્ય કિંમત';

  @override
  String get enterPrice => 'કિંમત દાખલ કરો';

  @override
  String get cancel => 'રદ કરો';

  @override
  String get create => 'બનાવો';

  @override
  String get delete => 'કાઢી નાખો';

  @override
  String get deleteAlert => 'ચેતવણી કાઢી નાખો';

  @override
  String get deleteAlertConfirm =>
      'શું તમે ખરેખર આ ચેતવણી કાઢી નાખવા માંગો છો?';

  @override
  String get triggered => 'ટ્રિગર થયું';

  @override
  String get active => 'સક્રિય';

  @override
  String get testNotification => 'પરીક્ષણ સૂચના';

  @override
  String get testNotificationBody =>
      'આ તમારા ગોલ્ડ ટ્રેકર બેકએન્ડથી એક પરીક્ષણ પુશ સૂચના છે!';
}

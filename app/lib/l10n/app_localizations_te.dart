// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get appTitle => 'బంగారం ధర ట్రాకర్';

  @override
  String get priceTab => 'ధర';

  @override
  String get alertsTab => 'హెచ్చరికలు';

  @override
  String get gold999WithGst => 'గోల్డ్ 999 GST తో';

  @override
  String get perKg => '1 కిలో';

  @override
  String updatedAgo(String time) {
    return '$time క్రితం నవీకరించబడింది';
  }

  @override
  String get last24Hours => 'గత 24 గంటలు';

  @override
  String dataPoints(int count) {
    return '$count డేటా పాయింట్లు';
  }

  @override
  String get createAlert => 'హెచ్చరికను సృష్టించండి';

  @override
  String get noAlertsYet => 'ఇంకా హెచ్చరికలు లేవు';

  @override
  String get createFirstAlert =>
      'బంగారం ధర మీ లక్ష్యాన్ని చేరుకున్నప్పుడు నోటిఫికేషన్ పొందడానికి మీ మొదటి ధర హెచ్చరికను సృష్టించండి.';

  @override
  String get alertMe => 'ధర ఉన్నప్పుడు నాకు హెచ్చరించండి';

  @override
  String get above => 'పైన';

  @override
  String get below => 'క్రింద';

  @override
  String get targetPrice => 'లక్ష్య ధర';

  @override
  String get enterPrice => 'ధరను నమోదు చేయండి';

  @override
  String get cancel => 'రద్దు చేయండి';

  @override
  String get create => 'సృష్టించండి';

  @override
  String get delete => 'తొలగించండి';

  @override
  String get deleteAlert => 'హెచ్చరికను తొలగించండి';

  @override
  String get deleteAlertConfirm =>
      'మీరు ఖచ్చితంగా ఈ హెచ్చరికను తొలగించాలనుకుంటున్నారా?';

  @override
  String get triggered => 'ట్రిగ్గర్ చేయబడింది';

  @override
  String get active => 'చురుకుగా';

  @override
  String get testNotification => 'పరీక్ష నోటిఫికేషన్';

  @override
  String get testNotificationBody =>
      'ఇది మీ గోల్డ్ ట్రాకర్ బ్యాకెండ్ నుండి ఒక పరీక్ష పుష్ నోటిఫికేషన్!';
}

class Preferences {
  final int id;
  final int userId;
  final int refreshInterval;
  final String currency;
  final bool notificationsOn;
  final String theme; // light, dark, system

  Preferences({
    required this.id,
    required this.userId,
    this.refreshInterval = 15,
    this.currency = 'INR',
    this.notificationsOn = true,
    this.theme = 'light',
  });

  factory Preferences.fromJson(Map<String, dynamic> json) {
    return Preferences(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      refreshInterval: json['refresh_interval'] as int? ?? 15,
      currency: json['currency'] as String? ?? 'INR',
      notificationsOn:
          json['notifications_on'] == 1 || json['notifications_on'] == true,
      theme: json['theme'] as String? ?? 'light',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'refreshInterval': refreshInterval,
      'currency': currency,
      'notificationsOn': notificationsOn,
      'theme': theme,
    };
  }

  // Create a copy with updated fields
  Preferences copyWith({
    int? id,
    int? userId,
    int? refreshInterval,
    String? currency,
    bool? notificationsOn,
    String? theme,
  }) {
    return Preferences(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      refreshInterval: refreshInterval ?? this.refreshInterval,
      currency: currency ?? this.currency,
      notificationsOn: notificationsOn ?? this.notificationsOn,
      theme: theme ?? this.theme,
    );
  }
}

import 'package:flutter/foundation.dart' show kIsWeb;

/// Адрес API, заданный при сборке: `--dart-define=API_BASE_URL=https://...`.
///
/// В исходном коде адреса сервера нет. Если параметр не передан, в браузере
/// приложение обращается к `/api` на том же сайте, с которого загружено
/// (так работает размещение за обратным прокси).
const apiBaseUrlDefine = String.fromEnvironment('API_BASE_URL');

/// Адрес по умолчанию в браузере: тот же сайт.
const String kSameOriginApi = '/api';

/// Адрес по умолчанию вне браузера (тесты, консоль): Dio вне веба принимает
/// только полный адрес.
const String kLocalApi = 'http://localhost:8080/api';

/// Адрес, который используется, если при сборке адрес не задан.
String get defaultApiBaseUrl => kIsWeb ? kSameOriginApi : kLocalApi;

/// Итоговый адрес API: параметр сборки без завершающей косой черты либо адрес по умолчанию.
String resolveApiBaseUrl(String define) {
  final value = define.trim();
  if (value.isEmpty) return defaultApiBaseUrl;
  return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
}

final String apiBaseUrl = resolveApiBaseUrl(apiBaseUrlDefine);

/// Секунд без действий пользователя до выхода (по умолчанию три минуты).
const inactivitySeconds = int.fromEnvironment('INACTIVITY_SECONDS', defaultValue: 180);

/// За сколько секунд до выхода показывать предупреждение.
const inactivityWarningSeconds = int.fromEnvironment(
  'INACTIVITY_WARNING_SECONDS',
  defaultValue: 30,
);

/// Предельная длительность сессии в минутах независимо от активности.
const maxSessionMinutes = int.fromEnvironment('SESSION_MAX_MINUTES', defaultValue: 480);

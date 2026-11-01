import 'dart:async';

import 'package:library_app/lazy_screens.dart';

import 'eager_screens.dart';

/// Выполняется перед каждым тестовым файлом. Тестовая машина Dart завершает
/// загрузку лишь первой отложенной библиотеки, остальные зависают, поэтому
/// в тестах разделы подключены сразу. Сама подгрузка проверена в
/// deferred_screen_test.dart и в браузерной сборке.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  lazyScreensOverride = const EagerScreens();
  await testMain();
}

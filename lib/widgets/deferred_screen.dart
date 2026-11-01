import 'package:flutter/material.dart';

import 'state_views.dart';

/// Экран, код которого загружается отдельным файлом при первом открытии.
///
/// Раздел подключается через `import '...' deferred as имя`: при сборке
/// для веба Dart выносит его в отдельную часть, и она скачивается только тогда,
/// когда пользователь действительно открыл раздел. [load] обычно равна
/// `имя.loadLibrary`, а [builder] создаёт экран из подгруженной библиотеки.
class DeferredScreen extends StatefulWidget {
  const DeferredScreen({super.key, required this.title, required this.load, required this.builder});

  /// Заголовок, пока раздел загружается.
  final String title;

  /// Загрузка библиотеки.
  final Future<void> Function() load;

  /// Создание экрана после загрузки.
  final WidgetBuilder builder;

  @override
  State<DeferredScreen> createState() => _DeferredScreenState();
}

class _DeferredScreenState extends State<DeferredScreen> {
  late Future<void> _loading = widget.load();

  void _retry() {
    setState(() {
      _loading = widget.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loading,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && !snapshot.hasError) {
          return widget.builder(context);
        }
        return Scaffold(
          appBar: AppBar(title: Text(widget.title)),
          body: snapshot.hasError
              ? ErrorView(
                  message: 'Не удалось загрузить раздел. Проверьте соединение.',
                  onRetry: _retry,
                )
              : const LoadingView(),
        );
      },
    );
  }
}

// Сравнивает размеры сборок веб-приложения и записывает таблицу в Markdown.
//
// Запуск: dart run tools/measure_size.dart <папка со сборками> [файл отчёта]
//
// В папке лежат подпапки-сборки (например, js-before, js-after, wasm-before,
// wasm-after). Для каждой считается размер до и после сжатия gzip: так файлы
// отдаёт сервер, поэтому по «после сжатия» судят о реальной загрузке.
import 'dart:io';

class Stat {
  Stat(this.raw, this.gzip);
  final int raw;
  final int gzip;
}

Stat _statOf(Iterable<File> files) {
  var raw = 0;
  var zipped = 0;
  for (final file in files) {
    final bytes = file.readAsBytesSync();
    raw += bytes.length;
    zipped += gzip.encode(bytes).length;
  }
  return Stat(raw, zipped);
}

String _kb(int bytes) {
  final value = bytes / 1024;
  return value >= 100 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
}

String _name(File file, Directory root) {
  final path = file.path.substring(root.path.length + 1).replaceAll('\\', '/');
  return path;
}

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Использование: dart run tools/measure_size.dart <папка> [отчёт.md]');
    exit(64);
  }
  final base = Directory(args[0]);
  if (!base.existsSync()) {
    stderr.writeln('Нет папки ${base.path}');
    exit(66);
  }
  final builds = base.listSync().whereType<Directory>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final out = StringBuffer();
  out.writeln(
    '| Сборка | Код при запуске, КБ | Он же после gzip, КБ | '
    'Отложенные части, КБ (gzip) | Всего js/wasm, КБ (gzip) |',
  );
  out.writeln('|---|---:|---:|---:|---:|');

  final details = StringBuffer();
  for (final dir in builds) {
    final files = dir.listSync(recursive: true).whereType<File>().toList();
    bool isCode(File f) {
      final n = _name(f, dir);
      if (n.startsWith('canvaskit/')) return false;
      return n.endsWith('.js') || n.endsWith('.wasm') || n.endsWith('.mjs');
    }

    // Отложенные части называются main.dart.js_1.part.js, main.dart.js_2.part.js
    // (для wasm в имени встречается module).
    bool isPart(File f) => RegExp(r'part|module').hasMatch(_name(f, dir));

    // В wasm-сборке рядом лежит и запасной main.dart.js для старых браузеров.
    // Современный браузер его не скачивает, поэтому в расчёт он не входит.
    final isWasm = dir.uri.pathSegments.where((s) => s.isNotEmpty).last.startsWith('wasm');
    final code = files
        .where(isCode)
        .where((f) => !(isWasm && _name(f, dir) == 'main.dart.js'))
        .toList();
    final parts = code.where(isPart).toList();
    // Запускаемый код: загрузчик и основной файл (js или wasm вместе со вспомогательным mjs).
    final startup = code.where((f) => !isPart(f)).toList();
    final startupStat = _statOf(startup);
    final partsStat = _statOf(parts);
    final allStat = _statOf(code);

    out.writeln(
      '| ${dir.uri.pathSegments.where((s) => s.isNotEmpty).last} | '
      '${_kb(startupStat.raw)} | ${_kb(startupStat.gzip)} | '
      '${parts.isEmpty ? '—' : '${_kb(partsStat.gzip)} (${parts.length} шт.)'} | '
      '${_kb(allStat.gzip)} |',
    );

    details.writeln('\n### ${dir.uri.pathSegments.where((s) => s.isNotEmpty).last}\n');
    details.writeln('| Файл | Размер, КБ | gzip, КБ |');
    details.writeln('|---|---:|---:|');
    code.sort((a, b) => _name(a, dir).compareTo(_name(b, dir)));
    for (final f in code) {
      final s = _statOf([f]);
      details.writeln('| ${_name(f, dir)} | ${_kb(s.raw)} | ${_kb(s.gzip)} |');
    }
    final canvas = files.where((f) => _name(f, dir).startsWith('canvaskit/')).toList();
    if (canvas.isNotEmpty) {
      final s = _statOf(canvas);
      details.writeln(
        '| canvaskit/ (${canvas.length} файлов, с CDN не грузится) | '
        '${_kb(s.raw)} | ${_kb(s.gzip)} |',
      );
    }
    final everything = _statOf(files);
    details.writeln('| **вся папка** | ${_kb(everything.raw)} | ${_kb(everything.gzip)} |');
  }

  final report = '$out\n$details';
  stdout.write(report);
  if (args.length > 1) {
    File(args[1]).writeAsStringSync(report);
    stdout.writeln('\nОтчёт записан в ${args[1]}');
  }
}

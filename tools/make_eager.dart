// Делает из lib/lazy_screens.dart вариант «до оптимизации»: все разделы подключены
// обычными импортами и входят в основной файл, ничего не грузится по требованию.
//
// Нужен только для замера (tools/build-all.bat): результат пишется в копию
// проекта, исходный код приложения не меняется.
//
// Запуск: dart run tools/make_eager.dart <lazy_screens.dart> <куда записать>
import 'dart:io';

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln('Использование: dart run tools/make_eager.dart <вход> <выход>');
    exit(64);
  }
  final source = File(args[0]).readAsStringSync();

  // import '...' deferred as имя;  ->  import '...' as имя;
  final deferredImport = RegExp(r"^(import '[^']+') deferred as (\w+);", multiLine: true);
  // load: имя.loadLibrary,  ->  load: _alreadyLoaded,
  final loadCall = RegExp(r'load: \w+\.loadLibrary,');

  var imports = 0;
  var loads = 0;
  var result = source.replaceAllMapped(deferredImport, (m) {
    imports++;
    return '${m[1]} as ${m[2]};';
  });
  result = result.replaceAllMapped(loadCall, (m) {
    loads++;
    return 'load: _alreadyLoaded,';
  });
  result += '\nFuture<void> _alreadyLoaded() async {}\n';

  if (imports == 0 || imports != loads) {
    stderr.writeln('Не совпало: отложенных импортов $imports, вызовов loadLibrary $loads.');
    exit(1);
  }
  File(args[1]).writeAsStringSync(result);
  stdout.writeln('Готово: отложенных импортов заменено $imports.');
}

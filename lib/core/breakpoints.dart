import 'package:flutter/widgets.dart';

/// Класс ширины окна. Границы взяты из Material 3, но для приложения
/// достаточно трёх: телефон, планшет и компьютер.
enum ScreenSize { compact, medium, expanded }

/// С этой ширины (логических пикселей) окно считается средним: навигация
/// уходит из нижней панели в боковую полосу.
const double kMediumBreakpoint = 600;

/// С этой ширины боковая полоса раскрывается и показывает подписи рядом со значками.
const double kExpandedBreakpoint = 1200;

/// Если списку отведено меньше этой ширины, вместо таблицы показываются карточки.
const double kTableMinWidth = 760;

/// Наибольшая ширина содержимого страницы. На широком мониторе текст,
/// карточки и таблицы не растягиваются на весь экран.
const double kContentMaxWidth = 1280;

/// Класс окна по его ширине. Вынесена из [screenSizeOf], чтобы границы
/// проверялись обычным модульным тестом, без виджетов.
ScreenSize screenSizeForWidth(double width) {
  if (width < kMediumBreakpoint) return ScreenSize.compact;
  if (width < kExpandedBreakpoint) return ScreenSize.medium;
  return ScreenSize.expanded;
}

/// Класс окна в текущий момент. Подписывается только на изменение размера.
ScreenSize screenSizeOf(BuildContext context) {
  return screenSizeForWidth(MediaQuery.sizeOf(context).width);
}

/// Значение, подходящее текущей ширине окна. Не заданный для широкого окна
/// вариант заменяется ближайшим меньшим.
T byScreen<T>(BuildContext context, {required T compact, T? medium, T? expanded}) {
  return pickByScreen(screenSizeOf(context), compact: compact, medium: medium, expanded: expanded);
}

/// Выбор значения по классу окна без обращения к [BuildContext].
T pickByScreen<T>(ScreenSize size, {required T compact, T? medium, T? expanded}) {
  return switch (size) {
    ScreenSize.compact => compact,
    ScreenSize.medium => medium ?? compact,
    ScreenSize.expanded => expanded ?? medium ?? compact,
  };
}

/// Сколько колонок помещается в [width] при минимальной ширине плитки
/// [minTile] и промежутке [spacing]. Всегда не меньше одной.
int gridColumns(double width, {required double minTile, double spacing = 12}) {
  if (width <= 0 || minTile <= 0) return 1;
  final columns = ((width + spacing) / (minTile + spacing)).floor();
  return columns < 1 ? 1 : columns;
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_notifier.dart';
import '../auth/permissions.dart';
import '../core/breakpoints.dart';
import '../state/unsaved_changes.dart';
import 'confirm_dialog.dart';

/// Каркас экранов с меню. Вид меню зависит от ширины окна:
///
/// * до 600: нижняя панель, разделы, которые в неё не поместились, лежат в «Ещё»;
/// * от 600 до 1200: боковая полоса со значками и подписями под ними;
/// * от 1200: раскрытая боковая полоса, подписи стоят рядом со значками.
///
/// Содержимое страницы не шире [kContentMaxWidth] и стоит по центру.
class LibraryScaffold extends StatelessWidget {
  const LibraryScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showBack = false,
    this.backPath = '/',
    this.unsaved,
  });

  final String title;
  final Widget body;
  final bool showBack;
  final String backPath;
  final UnsavedChanges? unsaved;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final items = visibleNavItems(auth.can);
    final size = screenSizeOf(context);
    final path = _currentPath(context);

    void open(String location) {
      guardedNavigate(context, unsaved, () => context.go(location));
    }

    final appBar = AppBar(
      leading: showBack
          ? BackButton(
              onPressed: () => guardedNavigate(context, unsaved, () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(backPath);
                }
              }),
            )
          : null,
      title: Text(title, overflow: TextOverflow.ellipsis),
      actions: [
        if (auth.user != null) _UserMenu(auth: auth, unsaved: unsaved),
        const SizedBox(width: 8),
      ],
    );

    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        key: const ValueKey('page-content'),
        constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
        child: body,
      ),
    );

    if (size == ScreenSize.compact) {
      return Scaffold(
        appBar: appBar,
        body: content,
        bottomNavigationBar: items.length < 2
            ? null
            : _BottomNav(items: items, path: path, onOpen: open),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: Row(
        children: [
          if (items.length >= 2)
            _SideNav(items: items, path: path, extended: size == ScreenSize.expanded, onOpen: open),
          if (items.length >= 2) const VerticalDivider(width: 1),
          Expanded(child: content),
        ],
      ),
    );
  }
}

String _currentPath(BuildContext context) {
  try {
    return GoRouterState.of(context).uri.path;
  } catch (_) {
    // Каркас показан вне маршрутизатора (например, в тесте виджета).
    return '';
  }
}

typedef NavItem = ({IconData icon, String label, String path, Permission? permission});

/// Разделы меню. Раздел виден, если роли разрешена соответствующая операция.
const List<NavItem> kNavItems = [
  (icon: Icons.home, label: 'Главная', path: '/', permission: null),
  (icon: Icons.menu_book, label: 'Книги', path: '/books', permission: Permission.viewCatalog),
  (icon: Icons.people, label: 'Авторы', path: '/authors', permission: Permission.viewCatalog),
  (icon: Icons.category, label: 'Жанры', path: '/genres', permission: Permission.viewCatalog),
  (
    icon: Icons.apartment,
    label: 'Издательства',
    path: '/publishers',
    permission: Permission.viewCatalog,
  ),
  (icon: Icons.badge, label: 'Читатели', path: '/readers', permission: Permission.viewReaders),
  (icon: Icons.assignment, label: 'Выдачи', path: '/loans', permission: Permission.viewAllLoans),
  (
    icon: Icons.bookmarks,
    label: 'Мои выдачи',
    path: '/my/loans',
    permission: Permission.viewOwnLoans,
  ),
  (
    icon: Icons.support_agent,
    label: 'Рабочее место',
    path: '/desk',
    permission: Permission.useDesk,
  ),
  (
    icon: Icons.manage_accounts,
    label: 'Пользователи',
    path: '/admin/users',
    permission: Permission.manageUsers,
  ),
  (
    icon: Icons.bar_chart,
    label: 'Статистика',
    path: '/admin/stats',
    permission: Permission.viewStats,
  ),
];

/// Разделы, доступные роли. [can] отвечает, разрешена ли операция.
List<NavItem> visibleNavItems(bool Function(Permission permission) can) {
  return [
    for (final item in kNavItems)
      if (item.permission == null || can(item.permission!)) item,
  ];
}

/// В каком порядке разделы занимают места в нижней панели. Что не поместилось,
/// уходит в «Ещё».
const List<String> kBottomPriority = [
  '/',
  '/books',
  '/my/loans',
  '/desk',
  '/loans',
  '/admin/stats',
  '/authors',
  '/readers',
  '/admin/users',
  '/genres',
  '/publishers',
];

typedef BottomSplit = ({List<NavItem> primary, List<NavItem> more});

/// Делит разделы между нижней панелью и пунктом «Ещё». Если разделов не больше
/// [slots], «Ещё» не нужен. Порядок внутри каждой части сохраняется.
BottomSplit splitForBottomBar(List<NavItem> items, {int slots = 5}) {
  if (items.length <= slots) return (primary: items, more: const <NavItem>[]);
  int rank(NavItem item) {
    final index = kBottomPriority.indexOf(item.path);
    return index < 0 ? kBottomPriority.length : index;
  }

  final ranked = [...items]
    ..sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      return byRank != 0 ? byRank : items.indexOf(a).compareTo(items.indexOf(b));
    });
  final keep = {for (final item in ranked.take(slots - 1)) item.path};
  return (
    primary: [
      for (final item in items)
        if (keep.contains(item.path)) item,
    ],
    more: [
      for (final item in items)
        if (!keep.contains(item.path)) item,
    ],
  );
}

bool _matches(String itemPath, String path) {
  if (itemPath == '/') return path == '/';
  return path == itemPath || path.startsWith('$itemPath/');
}

/// Номер раздела, к которому относится адрес [path], или null.
int? selectedNavIndex(List<NavItem> items, String path) {
  for (var i = 0; i < items.length; i++) {
    if (_matches(items[i].path, path)) return i;
  }
  return null;
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.items, required this.path, required this.onOpen});

  final List<NavItem> items;
  final String path;
  final ValueChanged<String> onOpen;

  Future<void> _openMore(BuildContext context, List<NavItem> more) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          key: const ValueKey('more-sheet'),
          shrinkWrap: true,
          children: [
            for (final item in more)
              ListTile(
                leading: Icon(item.icon),
                title: Text(item.label),
                selected: _matches(item.path, path),
                onTap: () => Navigator.of(sheetContext).pop(item.path),
              ),
          ],
        ),
      ),
    );
    if (picked != null && context.mounted) onOpen(picked);
  }

  @override
  Widget build(BuildContext context) {
    final split = splitForBottomBar(items);
    final hasMore = split.more.isNotEmpty;
    final primarySelected = selectedNavIndex(split.primary, path);
    final moreSelected = hasMore && selectedNavIndex(split.more, path) != null;
    final selected = moreSelected ? split.primary.length : (primarySelected ?? 0);

    return NavigationBar(
      key: const ValueKey('bottom-nav'),
      selectedIndex: selected,
      onDestinationSelected: (index) {
        if (index < split.primary.length) {
          onOpen(split.primary[index].path);
        } else {
          _openMore(context, split.more);
        }
      },
      destinations: [
        for (final item in split.primary)
          NavigationDestination(icon: Icon(item.icon), label: item.label),
        if (hasMore) const NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Ещё'),
      ],
    );
  }
}

class _SideNav extends StatelessWidget {
  const _SideNav({
    required this.items,
    required this.path,
    required this.extended,
    required this.onOpen,
  });

  final List<NavItem> items;
  final String path;
  final bool extended;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    // Разделов может быть больше, чем помещается по высоте окна: полоса прокручивается.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: NavigationRail(
                key: const ValueKey('side-nav'),
                selectedIndex: selectedNavIndex(items, path),
                onDestinationSelected: (index) => onOpen(items[index].path),
                extended: extended,
                minWidth: 96,
                labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                destinations: [
                  for (final item in items)
                    NavigationRailDestination(icon: Icon(item.icon), label: Text(item.label)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Имя пользователя, его роль и выход.
class _UserMenu extends StatelessWidget {
  const _UserMenu({required this.auth, this.unsaved});

  final AuthNotifier auth;
  final UnsavedChanges? unsaved;

  @override
  Widget build(BuildContext context) {
    final user = auth.user!;
    final showName = MediaQuery.sizeOf(context).width >= 900;
    return PopupMenuButton<String>(
      tooltip: 'Учётная запись',
      key: const ValueKey('user-menu'),
      onSelected: (value) {
        if (value != 'logout') return;
        guardedNavigate(context, unsaved, () async {
          await auth.logout();
          if (context.mounted) context.go('/login');
        });
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(enabled: false, child: Text('${user.fullName}\n${user.role.label}')),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout),
            title: Text('Выйти'),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: !showName
            ? const Icon(Icons.account_circle)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_circle),
                  const SizedBox(width: 6),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: Text(
                          user.fullName,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      Text(user.role.label, style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
      ),
    );
  }
}

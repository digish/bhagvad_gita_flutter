import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../models/shloka_list.dart';
import 'list_detail_screen.dart';
import '../widgets/simple_gradient_background.dart';
import '../theme/app_colors.dart';
import 'package:go_router/go_router.dart';

enum _CollectionRowKind {
  sectionHeader,
  myCollectionsHint,
  sectionGap,
  listCard,
}

class _CollectionRow {
  final _CollectionRowKind kind;
  final String? headerLabel;
  final ShlokaList? list;
  final bool isUserList;

  const _CollectionRow._({
    required this.kind,
    this.headerLabel,
    this.list,
    this.isUserList = false,
  });

  factory _CollectionRow.header(String label) => _CollectionRow._(
        kind: _CollectionRowKind.sectionHeader,
        headerLabel: label,
      );

  factory _CollectionRow.myCollectionsHint() => const _CollectionRow._(
        kind: _CollectionRowKind.myCollectionsHint,
      );

  factory _CollectionRow.gap() => const _CollectionRow._(
        kind: _CollectionRowKind.sectionGap,
      );

  factory _CollectionRow.listCard(ShlokaList list, {required bool isUserList}) =>
      _CollectionRow._(
        kind: _CollectionRowKind.listCard,
        list: list,
        isUserList: isUserList,
      );
}

class UserListsScreen extends StatefulWidget {
  const UserListsScreen({super.key});

  @override
  State<UserListsScreen> createState() => _UserListsScreenState();
}

class _UserListsScreenState extends State<UserListsScreen> {
  ShlokaList? _selectedList;

  static const String _bookmarkAsset = 'assets/images/bookmark.png';

  List<_CollectionRow> _collectionRows(
    List<ShlokaList> userLists,
    List<ShlokaList> predefinedLists,
  ) {
    final rows = <_CollectionRow>[];

    if (userLists.isNotEmpty) {
      rows.add(_CollectionRow.header('My Collections'));
      for (final list in userLists) {
        rows.add(_CollectionRow.listCard(list, isUserList: true));
      }
    } else if (predefinedLists.isNotEmpty) {
      rows.add(_CollectionRow.header('My Collections'));
      rows.add(_CollectionRow.myCollectionsHint());
    }

    if (userLists.isNotEmpty && predefinedLists.isNotEmpty) {
      rows.add(_CollectionRow.gap());
    }

    if (predefinedLists.isNotEmpty) {
      rows.add(_CollectionRow.header('Curated Lists'));
      for (final list in predefinedLists) {
        rows.add(_CollectionRow.listCard(list, isUserList: false));
      }
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWideScreen = width > 700;
    final railPadding = MediaQuery.of(context).padding.left;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        } else {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        }
      },
      child: _buildScaffold(context, isWideScreen, railPadding),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    bool isWideScreen,
    double railPadding,
  ) {
    if (isWideScreen) {
      return Scaffold(
        body: Stack(
          children: [
            const SimpleGradientBackground(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 280 + railPadding,
                  child: Padding(
                    padding: EdgeInsets.only(left: railPadding),
                    child: MediaQuery.removePadding(
                      context: context,
                      removeLeft: true,
                      child: Scaffold(
                        backgroundColor: Colors.transparent,
                        appBar: AppBar(
                          title: const Text('Collections'),
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          centerTitle: true,
                          foregroundColor:
                              Theme.of(context).colorScheme.onSurface,
                          iconTheme: IconThemeData(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        floatingActionButton:
                            _buildNewCollectionFab('add_list_fab_wide'),
                        body: _buildListView(isWideScreen: true),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
                Expanded(
                  child: _selectedList == null
                      ? _buildWidePlaceholder(context)
                      : ClipRRect(
                          child: MediaQuery.removePadding(
                            context: context,
                            removeLeft: true,
                            child: ListDetailScreen(
                              key: ValueKey(_selectedList?.id),
                              list: _selectedList!,
                              isEmbedded: true,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Collections'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: onSurface,
        iconTheme: IconThemeData(color: onSurface),
      ),
      floatingActionButton: _buildNewCollectionFab('add_list_fab_mobile'),
      body: Stack(
        children: [
          const SimpleGradientBackground(),
          _buildListView(isWideScreen: false),
        ],
      ),
    );
  }

  Widget _buildNewCollectionFab(String heroTag) {
    final theme = Theme.of(context);
    return FloatingActionButton.extended(
      heroTag: heroTag,
      onPressed: _createNewList,
      backgroundColor: theme.colorScheme.primaryContainer,
      foregroundColor: theme.colorScheme.onPrimaryContainer,
      icon: const Icon(Icons.add),
      label: const Text('New collection'),
    );
  }

  Widget _buildWidePlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBookmarkOrnament(size: 88),
            const SizedBox(height: 20),
            Text(
              'Choose a collection',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.85),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Select a list on the left to read saved shlokas',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.disabledColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkOrnament({required double size}) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final warmGlow =
        isLight ? const Color(0xFFE8B923) : const Color(0xFFFFE082);

    Widget bookmarkImage() => Image.asset(
          _bookmarkAsset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        );

    return SizedBox(
      width: size,
      height: size,
      child: Transform.rotate(
        angle: 10 * math.pi / 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            bookmarkImage(),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => RadialGradient(
                center: const Alignment(0, -0.15),
                radius: 0.7,
                colors: [
                  warmGlow.withOpacity(isLight ? 0.38 : 0.45),
                  Colors.transparent,
                ],
              ).createShader(bounds),
              child: bookmarkImage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBookmarkOrnament(size: 96),
            const SizedBox(height: 24),
            Text(
              'No collections yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Save verses from any shloka into your own lists, or browse curated themes below.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.disabledColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _createNewList,
              icon: const Icon(Icons.add),
              label: const Text('Create collection'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white70 : Colors.grey[700];

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.1,
          color: color,
        ),
      ),
    );
  }

  Widget _myCollectionsHint(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        'Tap + to save verses from any shloka',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).disabledColor,
              fontStyle: FontStyle.italic,
            ),
      ),
    );
  }

  String _shlokaCountLabel(int count) {
    if (count == 1) return '1 shloka';
    return '$count shlokas';
  }

  InputDecoration _collectionNameInputDecoration() {
    return InputDecoration(
      hintText: 'Collection name',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildListView({required bool isWideScreen}) {
    return Consumer<BookmarkProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final userLists = provider.lists;
        final predefinedLists = provider.predefinedLists;

        if (userLists.isEmpty && predefinedLists.isEmpty) {
          return _buildEmptyState(context);
        }

        final rows = _collectionRows(userLists, predefinedLists);

        if (isWideScreen && _selectedList == null) {
          if (userLists.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedList = userLists.first);
            });
          } else if (predefinedLists.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _selectedList = predefinedLists.first);
              }
            });
          }
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(
            isWideScreen ? 16 : MediaQuery.of(context).padding.left + 16,
            isWideScreen
                ? 16
                : kToolbarHeight + MediaQuery.of(context).padding.top + 16,
            16,
            100,
          ),
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final row = rows[index];
            switch (row.kind) {
              case _CollectionRowKind.sectionHeader:
                return _sectionHeader(context, row.headerLabel!);
              case _CollectionRowKind.myCollectionsHint:
                return _myCollectionsHint(context);
              case _CollectionRowKind.sectionGap:
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(
                    color: Theme.of(context).dividerColor.withOpacity(0.25),
                    height: 1,
                  ),
                );
              case _CollectionRowKind.listCard:
                final list = row.list!;
                return _buildListCard(
                  context,
                  provider,
                  list,
                  isUserList: row.isUserList,
                  isWideScreen: isWideScreen,
                  isSelected: _selectedList?.id == list.id,
                );
            }
          },
        );
      },
    );
  }

  Widget _buildListLeadingOrnament({
    required bool isUserList,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    const gold = Color(0xFFFFD700);

    if (isUserList) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: gold.withValues(alpha: 0.55), width: 1.5),
          color: theme.brightness == Brightness.light
              ? const Color(0xFFFFFBF5)
              : const Color(0xFF353535),
        ),
        padding: const EdgeInsets.all(6),
        child: Image.asset(
          _bookmarkAsset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      );
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: gold.withOpacity(0.55), width: 1.5),
        gradient: RadialGradient(
          colors: [
            Colors.white.withOpacity(isSelected ? 0.95 : 0.85),
            Colors.amber.withOpacity(0.35),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Icon(
        Icons.auto_stories_rounded,
        size: 22,
        color: theme.colorScheme.primary.withOpacity(0.85),
      ),
    );
  }

  Widget _buildListCard(
    BuildContext context,
    BookmarkProvider provider,
    ShlokaList list, {
    required bool isUserList,
    required bool isWideScreen,
    bool isSelected = false,
  }) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>();
    final isLight = theme.brightness == Brightness.light;
    final count = provider.shlokaCountForList(list.id);

    // Opaque warm fill reads cleaner on the gradient than frosted white glass.
    final defaultFill =
        isLight ? const Color(0xFFF7F4EE) : const Color(0xFF2A2A2A);
    final defaultBorder =
        appColors?.cardBorder ??
        (isLight
            ? const Color(0x14000000)
            : Colors.white.withValues(alpha: 0.12));

    final fillColor = isSelected
        ? theme.colorScheme.primaryContainer
        : defaultFill;
    final borderColor =
        isSelected ? theme.colorScheme.primary : defaultBorder;
    final titleColor = isSelected
        ? theme.colorScheme.onPrimaryContainer
        : (appColors?.cardText ?? theme.textTheme.bodyLarge?.color);
    final subtitleColor = isSelected
        ? theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.72)
        : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.75);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: isLight ? 0.06 : 0.25,
              ),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              if (isWideScreen) {
                setState(() {
                  _selectedList = list;
                });
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ListDetailScreen(list: list),
                  ),
                );
              }
            },
            splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              child: Row(
                children: [
                  _buildListLeadingOrnament(
                    isUserList: isUserList,
                    isSelected: isSelected,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          list.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _shlokaCountLabel(count),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isUserList)
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: titleColor?.withValues(alpha: 0.65),
                      ),
                      onSelected: (value) {
                        if (value == 'rename') {
                          _renameList(list);
                        } else if (value == 'delete') {
                          _deleteList(list);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'rename',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Rename'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else if (!isWideScreen)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: titleColor?.withValues(alpha: 0.45),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createNewList() async {
    final controller = TextEditingController();
    final theme = Theme.of(context);
    final String? newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New collection'),
          content: TextField(
            controller: controller,
            decoration: _collectionNameInputDecoration(),
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty) {
      if (mounted) {
        await Provider.of<BookmarkProvider>(
          context,
          listen: false,
        ).createList(newName);
      }
    }
  }

  Future<void> _renameList(ShlokaList list) async {
    final controller = TextEditingController(text: list.name);
    final theme = Theme.of(context);
    final String? newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename collection'),
          content: TextField(
            controller: controller,
            decoration: _collectionNameInputDecoration(),
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty && newName != list.name) {
      if (mounted) {
        await Provider.of<BookmarkProvider>(
          context,
          listen: false,
        ).renameList(list.id, newName);
      }
    }
  }

  Future<void> _deleteList(ShlokaList list) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete collection'),
          content: Text('Are you sure you want to delete "${list.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      if (_selectedList?.id == list.id) {
        if (mounted) setState(() => _selectedList = null);
      }

      if (mounted) {
        await Provider.of<BookmarkProvider>(
          context,
          listen: false,
        ).deleteList(list.id);
      }
    }
  }
}

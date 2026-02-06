import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../models/shloka_list.dart';
import 'list_detail_screen.dart';
import '../widgets/simple_gradient_background.dart';

class UserListsScreen extends StatefulWidget {
  const UserListsScreen({super.key});

  @override
  State<UserListsScreen> createState() => _UserListsScreenState();
}

class _UserListsScreenState extends State<UserListsScreen> {
  // ✨ State for Split View
  ShlokaList? _selectedList;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWideScreen = width > 700;
    final railPadding = MediaQuery.of(context).padding.left; // ✨ Get rail width

    // ✨ On wide screens, if no list is selected, select the first one automatically
    // This is done in a post-frame callback to avoid build-phase setState errors if needed,
    // but doing it lazily in the builder is safer or just letting it be null (showing placeholder).
    // For better UX, let's try to select the first user list or curated list if available.
    // However, doing this inside build can be tricky with providers.
    // Let's keep it simple: if null, show placeholder. Users can tap.

    if (isWideScreen) {
      return Scaffold(
        body: Stack(
          children: [
            const SimpleGradientBackground(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Master Pane (Left)
                SizedBox(
                  width:
                      280 +
                      railPadding, // ✨ Reduced width to give more space to detail pane
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: railPadding,
                    ), // ✨ Shift content right
                    child: MediaQuery.removePadding(
                      context: context,
                      removeLeft:
                          true, // ✨ Prevent inner widgets from seeing rail padding
                      child: Scaffold(
                        backgroundColor: Colors.transparent,
                        appBar: AppBar(
                          title: const Text('Collections'),
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          centerTitle: true,
                        ),
                        floatingActionButton: FloatingActionButton(
                          heroTag: 'add_list_fab_wide',
                          onPressed: _createNewList,
                          child: const Icon(Icons.add),
                        ),
                        body: _buildListView(isWideScreen: true),
                      ),
                    ),
                  ),
                ),
                // Vertical Divider
                Container(
                  width: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
                // 2. Detail Pane (Right)
                Expanded(
                  child: _selectedList == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.format_list_bulleted_rounded,
                                size: 64,
                                color: Theme.of(
                                  context,
                                ).disabledColor.withOpacity(0.2),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Select a list to view details",
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Theme.of(context).disabledColor,
                                    ),
                              ),
                            ],
                          ),
                        )
                      : ClipRRect(
                          // Optional: Clip current detail view
                          child: MediaQuery.removePadding(
                            context: context,
                            removeLeft:
                                true, // ✨ Prevent detail view from adding rail padding again
                            child: ListDetailScreen(
                              key: ValueKey(
                                _selectedList?.id,
                              ), // Force rebuild on change
                              list: _selectedList!,
                              isEmbedded: true, // ✨ Use shared background
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

    // ✨ Mobile Layout (Existing)
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Collections'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_list_fab_mobile',
        onPressed: _createNewList,
        child: const Icon(Icons.add),
      ),
      body: Stack(
        children: [
          const SimpleGradientBackground(),
          _buildListView(isWideScreen: false),
        ],
      ),
    );
  }

  // Refactored ListView builder to be shared
  Widget _buildListView({required bool isWideScreen}) {
    return Consumer<BookmarkProvider>(
      builder: (context, provider, child) {
        final userLists = provider.lists;
        final predefinedLists = provider.predefinedLists;

        if (userLists.isEmpty && predefinedLists.isEmpty) {
          return const Center(child: Text('No lists found.'));
        }

        final totalCount =
            userLists.length +
            predefinedLists.length +
            (predefinedLists.isNotEmpty ? 1 : 0); // +1 for header

        // Auto-select first list on wide screen if nothing selected and lists exist
        // Note: Ideally move this to initState or listener, but simple check here works for "init"
        if (isWideScreen && _selectedList == null) {
          if (userLists.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedList = userLists.first);
            });
          } else if (predefinedLists.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted)
                setState(() => _selectedList = predefinedLists.first);
            });
          }
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(
            // Left padding: only needed on mobile if rail exists, but here we cover split view nicely
            isWideScreen ? 16 : MediaQuery.of(context).padding.left + 16,
            isWideScreen
                ? 16
                : kToolbarHeight + MediaQuery.of(context).padding.top + 16,
            16, // Right padding fixed for master pane
            100, // Space for FAB
          ),
          itemCount: totalCount,
          itemBuilder: (context, index) {
            // 1. User Lists
            if (index < userLists.length) {
              final list = userLists[index];
              return _buildListCard(
                context,
                list,
                isUserList: true,
                isWideScreen: isWideScreen,
                isSelected: _selectedList?.id == list.id,
              );
            }

            // 2. Predefined Lists Header
            if (index == userLists.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  "Curated Lists",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
              );
            }

            // 3. Predefined Lists
            final predefinedIndex = index - (userLists.length + 1);
            final list = predefinedLists[predefinedIndex];
            return _buildListCard(
              context,
              list,
              isUserList: false,
              isWideScreen: isWideScreen,
              isSelected: _selectedList?.id == list.id,
            );
          },
        );
      },
    );
  }

  Widget _buildListCard(
    BuildContext context,
    ShlokaList list, {
    required bool isUserList,
    required bool isWideScreen,
    bool isSelected = false,
  }) {
    final theme = Theme.of(context);

    // Glassmorphism: Use semi-transparent white/black depending on theme context
    // Ideally we check valid theme, but here we can just use white with opacity for a "frosted" look
    // that works on both light/dark backgrounds (or check brightness).
    // Assuming mostly light/colorful backgrounds for now.

    const double blurSigma = 10.0;
    final cardColor = isSelected
        ? theme.colorScheme.primaryContainer.withOpacity(0.5)
        : Colors.white.withOpacity(0.2);

    final borderColor = isSelected
        ? theme.colorScheme.primary.withOpacity(0.3)
        : Colors.white.withOpacity(0.3);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Material(
            color: cardColor, // Semi-transparent
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
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ), // Slightly more padding
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        list.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    if (isUserList)
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: theme.iconTheme.color?.withOpacity(0.7),
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
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createNewList() async {
    final TextEditingController _controller = TextEditingController();
    final String? newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New List'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'List Name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, _controller.text.trim()),
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
    final TextEditingController _controller = TextEditingController(
      text: list.name,
    );
    final String? newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename List'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'List Name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, _controller.text.trim()),
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
          title: const Text('Delete List'),
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
      // ✨ If deleting currently selected list, clear selection
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

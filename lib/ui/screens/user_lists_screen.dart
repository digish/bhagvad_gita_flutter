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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('My Lists'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewList,
        child: const Icon(Icons.add),
      ),
      body: Stack(
        children: [
          const SimpleGradientBackground(),
          Consumer<BookmarkProvider>(
            builder: (context, provider, child) {
              final lists = provider.lists;
              if (lists.isEmpty) {
                return const Center(child: Text('No lists yet. Create one!'));
              }
              return ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  MediaQuery.of(context).padding.left + 16,
                  kToolbarHeight + MediaQuery.of(context).padding.top + 16,
                  16,
                  100, // Space for FAB
                ),
                itemCount: lists.length,
                itemBuilder: (context, index) {
                  final list = lists[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(
                        list.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: PopupMenuButton<String>(
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ListDetailScreen(list: list),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
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
      if (mounted) {
        await Provider.of<BookmarkProvider>(
          context,
          listen: false,
        ).deleteList(list.id);
      }
    }
  }
}

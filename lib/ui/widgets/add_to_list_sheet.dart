import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bookmark_provider.dart';

class AddToListSheet extends StatefulWidget {
  final String chapterNo;
  final String shlokNo;

  const AddToListSheet({
    Key? key,
    required this.chapterNo,
    required this.shlokNo,
  }) : super(key: key);

  @override
  State<AddToListSheet> createState() => _AddToListSheetState();
}

class _AddToListSheetState extends State<AddToListSheet> {
  // Storing which lists are checked
  Set<int> _selectedListIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<BookmarkProvider>(context, listen: false);

    // Ensure lists are loaded
    if (provider.lists.isEmpty) {
      await provider.loadLists();
    }

    // Get current lists for this shloka
    final currentLists = await provider.getListsForShloka(
      widget.chapterNo,
      widget.shlokNo,
    );

    if (mounted) {
      setState(() {
        _selectedListIds = currentLists.toSet();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleList(int listId, bool? value) async {
    final provider = Provider.of<BookmarkProvider>(context, listen: false);
    setState(() {
      if (value == true) {
        _selectedListIds.add(listId);
      } else {
        _selectedListIds.remove(listId);
      }
    });

    if (value == true) {
      await provider.addShlokaToList(listId, widget.chapterNo, widget.shlokNo);
    } else {
      await provider.removeShlokaFromList(
        listId,
        widget.chapterNo,
        widget.shlokNo,
      );
    }
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
      final provider = Provider.of<BookmarkProvider>(context, listen: false);
      await provider.createList(newName);
      // Determine the ID of the new list (it's the last one in the list, or we assume)
      // Since createList reloads the lists, we can try to find it.
      // A better way would be createList returning the ID.
      // But for now, let's just create it. The user can then check it.
      setState(() {
        // Refresh UI to show new list
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final lists = Provider.of<BookmarkProvider>(context).lists;

    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Save to List',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _createNewList,
                  tooltip: 'Create New List',
                ),
              ],
            ),
          ),
          const Divider(),
          if (lists.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No lists created yet.'),
            ),
          ...lists.map((list) {
            final isChecked = _selectedListIds.contains(list.id);
            return CheckboxListTile(
              title: Text(list.name),
              value: isChecked,
              onChanged: (val) => _toggleList(list.id, val),
            );
          }).toList(),
        ],
      ),
    );
  }
}

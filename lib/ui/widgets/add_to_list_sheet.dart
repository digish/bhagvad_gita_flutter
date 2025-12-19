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
    // If loading, show spinner (keep logic)
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final lists = Provider.of<BookmarkProvider>(context).lists;

    // ✨ REWRITE: Exact Copy of ShareOptionsSheet Layout
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? Colors.grey[900]
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            left: false, // Prevent system rail padding issues
            right: false,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Title (Centered, Bold)
                    Text(
                      'Save to List',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Lists
                    if (lists.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'No lists created yet.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      )
                    else
                      ...lists.map((list) {
                        final isChecked = _selectedListIds.contains(list.id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildListRow(list.id, list.name, isChecked),
                        );
                      }).toList(),

                    // "Create New List" Action Row
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildCreateListRow(theme),
                    ),

                    const SizedBox(height: 32),

                    // "Done" Button (Matches Share Button)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          foregroundColor: theme.colorScheme.onPrimaryContainer,
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper for List Item Rows (Matches _buildOptionRow)
  Widget _buildListRow(int listId, String title, bool isSelected) {
    return InkWell(
      onTap: () => _toggleList(listId, !isSelected),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: isSelected,
                onChanged: (v) => _toggleList(listId, v!),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for "Create New List" Row
  Widget _buildCreateListRow(ThemeData theme) {
    return InkWell(
      onTap: _createNewList,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.5),
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.primary.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Icon(Icons.add_rounded, color: theme.colorScheme.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Create New List',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

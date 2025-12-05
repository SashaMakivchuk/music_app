import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/pages/folder_detail_page.dart';
import 'package:music_app/providers/folder_provider.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  void _showCreateFolderDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Folder Name (e.g., Chill Vibes)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(folderControllerProvider).createFolder(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Library')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateFolderDialog(context, ref),
        icon: const Icon(Icons.create_new_folder),
        label: const Text('New Folder'),
        backgroundColor: Colors.deepPurple,
      ),
      body: foldersAsync.when(
        data: (folders) => folders.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.folder_open, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No folders yet.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    TextButton(
                      onPressed: () => _showCreateFolderDialog(context, ref),
                      child: const Text('Create your first folder'),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: folders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final folder = folders[index];
                  return Card(
                    color: Colors.grey[850],
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.folder, color: Colors.deepPurpleAccent),
                      ),
                      title: Text(folder.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${folder.songCount} songs'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.grey),
                        onPressed: () => ref.read(folderControllerProvider).deleteFolder(folder.id),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FolderDetailPage(folderId: folder.id, folderName: folder.name),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
import 'package:chat_app_example/domain/entities/chat_models.dart';
import 'package:chat_app_example/presentation/chat/chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Halaman utama chat dengan tampilan percakapan bercabang
class ChatPage extends ConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ambil state saat ini: tree, loading, input
    final ChatState state = ref.watch(chatControllerProvider);
    // Aksi-aksi dipanggil melalui controller (send, regenerate, switch)
    final controller = ref.read(chatControllerProvider.notifier);

    final ChatTree? tree = state.tree;
    // visibleNodes: node-node pada path aktif (kecuali system)
    final List<ChatNode> visibleNodes = <ChatNode>[];
    if (tree != null) {
      for (final String id in tree.branchPathIds) {
        final ChatNode? node = tree.nodes[id];
        if (node != null && node.message.role != 'system') {
          visibleNodes.add(node);
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Branching Chat')),
      body: Column(
        children: [
          if (state.isLoading) const LinearProgressIndicator(minHeight: 2),
          // Daftar bubble chat yang mengikuti path aktif
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: visibleNodes.length,
              itemBuilder: (context, index) {
                final ChatNode node = visibleNodes[index];
                final bool isAssistant = node.message.role == 'assistant';
                final Alignment alignment = isAssistant
                    ? Alignment.centerLeft
                    : Alignment.centerRight;
                final Color bubble = isAssistant
                    ? Colors.grey.shade200
                    : Theme.of(context).colorScheme.primaryContainer;
                return Column(
                  crossAxisAlignment: isAssistant
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.end,
                  children: [
                    Align(
                      alignment: alignment,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: bubble,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(node.message.content),
                      ),
                    ),
                    // Untuk node assistant, tampilkan kontrol switch branch
                    if (isAssistant)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _BranchSwitcher(
                            node: node,
                            onNext: () => controller.selectSibling(node.id),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Regenerate balasan ini',
                            onPressed: state.isLoading
                                ? null
                                : () => controller.regenerateAt(node.id),
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
          // Input bar di bawah
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      enabled: !state.isLoading,
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: controller.setInput,
                      onSubmitted: (_) => controller.send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: state.isLoading ? null : controller.send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget kecil untuk menampilkan indikator dan tombol ganti branch
class _BranchSwitcher extends ConsumerWidget {
  const _BranchSwitcher({required this.node, this.onNext});

  final ChatNode node; // Node assistant saat ini
  final VoidCallback? onNext; // Aksi untuk pindah ke sibling berikutnya

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tampilkan jumlah branch dan tombol next jika ada saudara
    final String parentId = node.parentId;
    final state = ref.watch(chatControllerProvider);
    final tree = state.tree;
    if (tree == null || parentId.isEmpty) return const SizedBox.shrink();
    final parent = tree.nodes[parentId];
    if (parent == null) return const SizedBox.shrink();
    final int count = parent.childIds.length;
    if (count <= 1) return const SizedBox.shrink();

    final int index = parent.childIds.indexOf(node.id);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Branch ${index + 1} of $count'),
        IconButton(
          icon: const Icon(Icons.swap_horiz),
          onPressed: onNext,
          tooltip: 'Next branch',
        ),
      ],
    );
  }
}

import 'dart:math';

import 'package:chat_app_example/core/utils/uuid.dart';
import 'package:chat_app_example/domain/entities/chat_models.dart';
import 'package:chat_app_example/domain/repositories/chat_repository.dart';

class InMemoryChatRepository implements ChatRepository {
  // Penyimpanan tree percakapan di memori
  ChatTree? _tree;
  // Random untuk membuat variasi jawaban mock
  final Random _random = Random();
  // Menyimpan "lanjutan path" yang pernah dipilih per node assistant,
  // agar ketika kembali ke branch tersebut, tail path dapat dipulihkan.
  final Map<String, List<String>> _savedTailsByAssistantId =
      <String, List<String>>{};

  @override
  Future<ChatTree> getCurrentTree() async {
    // Jika tree belum ada, buat percakapan baru dengan system prompt default.
    _tree ??= await newConversation('You are a helpful assistant.');
    return _tree!;
  }

  @override
  Future<ChatTree> newConversation(String systemPrompt) async {
    // Buat node root (system) sebagai awal tree.
    final String rootId = Uuid.v4();
    final ChatMessage systemMessage = ChatMessage(
      id: rootId,
      parentId: '',
      role: 'system',
      content: systemPrompt,
      createdAt: DateTime.now(),
    );
    final ChatNode rootNode = ChatNode(
      id: rootId,
      parentId: '',
      message: systemMessage,
      childIds: <String>[],
    );
    _tree = ChatTree(
      rootId: rootId,
      nodes: <String, ChatNode>{rootId: rootNode},
      branchPathIds: <String>[rootId],
    );
    return _tree!;
  }

  @override
  Future<ChatTree> sendUserMessage(String content) async {
    final ChatTree tree = await getCurrentTree();
    // Parent id adalah leaf saat ini pada path.
    final String parentId = tree.branchPathIds.last;
    // Buat node user baru di bawah parent.
    final String userId = Uuid.v4();
    final ChatMessage userMessage = ChatMessage(
      id: userId,
      parentId: parentId,
      role: 'user',
      content: content,
      createdAt: DateTime.now(),
    );
    final ChatNode userNode = ChatNode(
      id: userId,
      parentId: parentId,
      message: userMessage,
      childIds: <String>[],
    );

    // Tautkan user node ke parent (tambahkan ke childIds parent)
    final ChatNode parent = tree.nodes[parentId]!;
    final List<String> updatedChildren = List<String>.from(parent.childIds)
      ..add(userId);
    tree.nodes[parentId] = ChatNode(
      id: parent.id,
      parentId: parent.parentId,
      message: parent.message,
      childIds: updatedChildren,
    );
    tree.nodes[userId] = userNode;

    // Path aktif maju ke node user baru.
    tree.branchPathIds.add(userId);

    // Otomatis buat satu jawaban assistant sebagai opsi branch.
    await _createAssistantReply(tree, userId, regenerate: false);
    return tree;
  }

  // Membuat satu jawaban assistant sebagai anak dari parentId (biasanya user node)
  Future<void> _createAssistantReply(
    ChatTree tree,
    String parentId, {
    required bool regenerate,
  }) async {
    final String replyId = Uuid.v4();
    final String content = _mockAssistantReply(
      parentId,
      regenerate: regenerate,
    );
    final ChatMessage reply = ChatMessage(
      id: replyId,
      parentId: parentId,
      role: 'assistant',
      content: content,
      createdAt: DateTime.now(),
    );
    final ChatNode replyNode = ChatNode(
      id: replyId,
      parentId: parentId,
      message: reply,
      childIds: <String>[],
    );

    // Tambahkan sebagai anak baru (menciptakan alternatif branch)
    final ChatNode p = tree.nodes[parentId]!;
    final List<String> newChildren = List<String>.from(p.childIds)
      ..add(replyId);
    tree.nodes[parentId] = ChatNode(
      id: p.id,
      parentId: p.parentId,
      message: p.message,
      childIds: newChildren,
    );
    tree.nodes[replyId] = replyNode;

    // Secara default, pilih balasan baru ini sebagai leaf aktif pada path.
    tree.branchPathIds.add(replyId);
  }

  // Membuat teks jawaban mock agar terlihat berbeda-beda.
  String _mockAssistantReply(String parentId, {required bool regenerate}) {
    final int variant = _random.nextInt(1000);
    final String regenTag = regenerate ? ' (regen)' : '';
    return 'Assistant reply to $parentId #$variant$regenTag';
  }

  // Catatan: regenerateAssistantReply() dihapus karena kini regenerate dilakukan per-bubble.

  @override
  Future<ChatTree> regenerateAssistantAt(String assistantNodeId) async {
    final ChatTree tree = await getCurrentTree();
    final ChatNode? node = tree.nodes[assistantNodeId];
    if (node == null || node.message.role != 'assistant') return tree;
    final String parentId = node.parentId;
    if (parentId.isEmpty) return tree;

    // Temukan posisi parent dan posisi assistant di path.
    final int parentIndexInPath = tree.branchPathIds.indexOf(parentId);
    final int assistantIndexInPath = tree.branchPathIds.indexOf(
      assistantNodeId,
    );

    // Simpan tail path untuk assistant yang saat ini dipilih (jika ada pada path)
    if (assistantIndexInPath >= 0) {
      final List<String> currentTail = List<String>.from(
        tree.branchPathIds.sublist(assistantIndexInPath),
      );
      _savedTailsByAssistantId[assistantNodeId] = currentTail;
    }

    if (parentIndexInPath >= 0) {
      // Potong path setelah parent agar regenerate memilih balasan baru sebagai leaf
      tree.branchPathIds.removeRange(
        parentIndexInPath + 1,
        tree.branchPathIds.length,
      );
    } else {
      // Jika branchPath tidak memuat parent, buat path minimal root->...->parent
      // Sederhana: reset ke hanya parent (kasus langka di mock ini)
      tree.branchPathIds
        ..clear()
        ..addAll(<String>[tree.rootId, parentId]);
    }

    await _createAssistantReply(tree, parentId, regenerate: true);
    return tree;
  }

  @override
  Future<ChatTree> selectSiblingBranch(String nodeId) async {
    final ChatTree tree = await getCurrentTree();
    // nodeId adalah id dari assistant yang sedang aktif pada user parent.
    final ChatNode node = tree.nodes[nodeId]!;
    final String parentId = node.parentId;
    if (parentId.isEmpty) return tree;
    final ChatNode parent = tree.nodes[parentId]!;
    if (parent.childIds.isEmpty) return tree;
    // Cari sibling berikutnya (berputar) dari daftar childIds.
    final int currentIndex = parent.childIds.indexOf(nodeId);
    final int nextIndex =
        ((currentIndex < 0 ? 0 : currentIndex + 1) % parent.childIds.length)
            .toInt();
    final String nextId = parent.childIds[nextIndex];

    // Ganti tail path setelah parent menjadi nextId, sambil menyimpan tail lama.
    final int parentIndexInPath = tree.branchPathIds.indexOf(parentId);
    if (parentIndexInPath >= 0) {
      // Simpan tail untuk assistant yang saat ini aktif agar bisa dipulihkan nanti.
      if (parentIndexInPath + 1 < tree.branchPathIds.length) {
        final String currentAssistantId =
            tree.branchPathIds[parentIndexInPath + 1];
        final List<String> currentTail = List<String>.from(
          tree.branchPathIds.sublist(parentIndexInPath + 1),
        );
        _savedTailsByAssistantId[currentAssistantId] = currentTail;
      }

      // Susun path baru: sampai parent + nextId + tail tersimpan (jika ada).
      final List<String> newPath = List<String>.from(
        tree.branchPathIds.sublist(0, parentIndexInPath + 1),
      )..add(nextId);

      final List<String>? savedTail = _savedTailsByAssistantId[nextId];
      if (savedTail != null && savedTail.isNotEmpty) {
        // Tail yang disimpan biasanya diawali oleh nextId sendiri, hindari duplikasi.
        final List<String> tailWithoutHead = savedTail.first == nextId
            ? savedTail.sublist(1)
            : savedTail;
        newPath.addAll(tailWithoutHead);
      }

      tree.branchPathIds
        ..clear()
        ..addAll(newPath);
    }
    return tree;
  }
}

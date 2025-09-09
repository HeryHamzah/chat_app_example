import 'dart:convert';

import 'package:chat_app_example/data/local/drift/database.dart';
import 'package:chat_app_example/data/repositories/in_memory_chat_repository.dart';
import 'package:chat_app_example/domain/entities/chat_models.dart';
import 'package:chat_app_example/domain/repositories/chat_repository.dart';

// Repository Drift: menyimpan snapshot ChatTree sebagai JSON di database.
// Menggunakan implementasi InMemory sebagai sumber kebenaran saat runtime,
// lalu persist/restore pada setiap perubahan penting.
class LocalDriftChatRepository implements ChatRepository {
  LocalDriftChatRepository(this._db) : _memory = InMemoryChatRepository();

  final AppDatabase _db;
  final InMemoryChatRepository _memory;
  static const String _kSnapshotKey = 'chat_tree_snapshot';

  Future<void> _save(ChatTree tree) async {
    final String jsonStr = jsonEncode(tree.toJson());
    await _db.put(_kSnapshotKey, jsonStr);
  }

  Future<ChatTree?> _load() async {
    final String? jsonStr = await _db.getValue(_kSnapshotKey);
    if (jsonStr == null) return null;
    final Map<String, dynamic> data =
        jsonDecode(jsonStr) as Map<String, dynamic>;
    return ChatTree.fromJson(data);
  }

  @override
  Future<ChatTree> getCurrentTree() async {
    // Muat dari DB jika ada, lalu seed ke memory repo.
    final ChatTree? existing = await _load();
    if (existing != null) {
      // Seed ke memory dengan menimpa state internalnya.
      // Karena InMemory tidak membuka API seed, kita rebuild dengan cara manual:
      // Start a new conversation and then overwrite internals.
      final ChatTree memTree = await _memory.newConversation(
        'You are a helpful assistant.',
      );
      memTree.nodes
        ..clear()
        ..addAll(existing.nodes);
      memTree.branchPathIds
        ..clear()
        ..addAll(existing.branchPathIds);
      return memTree;
    }
    final ChatTree tree = await _memory.getCurrentTree();
    await _save(tree);
    return tree;
  }

  @override
  Future<ChatTree> newConversation(String systemPrompt) async {
    final ChatTree tree = await _memory.newConversation(systemPrompt);
    await _save(tree);
    return tree;
  }

  @override
  Future<ChatTree> sendUserMessage(String content) async {
    final ChatTree tree = await _memory.sendUserMessage(content);
    await _save(tree);
    return tree;
  }

  @override
  Future<ChatTree> regenerateAssistantAt(String assistantNodeId) async {
    final ChatTree tree = await _memory.regenerateAssistantAt(assistantNodeId);
    await _save(tree);
    return tree;
  }

  @override
  Future<ChatTree> selectSiblingBranch(String nodeId) async {
    final ChatTree tree = await _memory.selectSiblingBranch(nodeId);
    await _save(tree);
    return tree;
  }

  @override
  Future<void> clearStorage() async {
    await _db.clearAll();
  }
}

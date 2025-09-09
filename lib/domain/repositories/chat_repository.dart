import 'package:chat_app_example/domain/entities/chat_models.dart';

/// Abstraksi sumber data chat yang mengelola tree percakapan bercabang.
abstract class ChatRepository {
  /// Mengembalikan tree percakapan saat ini, membuat default baru jika belum ada.
  Future<ChatTree> getCurrentTree();

  /// Memulai percakapan baru dengan system prompt sebagai root.
  Future<ChatTree> newConversation(String systemPrompt);

  /// Menambahkan pesan user ke branch aktif dan membuat balasan assistant otomatis.
  Future<ChatTree> sendUserMessage(String content);

  /// Regenerasi balasan untuk node assistant tertentu (membuat sibling baru
  /// untuk parent user yang sama), lalu memilih balasan baru tersebut.
  Future<ChatTree> regenerateAssistantAt(String assistantNodeId);

  /// Berpindah ke saudara (sibling) assistant berikutnya untuk node assistant
  /// yang diberikan, dan memperbarui path branch yang terpilih.
  Future<ChatTree> selectSiblingBranch(String nodeId);

  /// Hapus seluruh penyimpanan lokal yang berkaitan (untuk debugging/Reset).
  Future<void> clearStorage();
}

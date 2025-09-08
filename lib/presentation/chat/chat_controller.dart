import 'package:chat_app_example/domain/entities/chat_models.dart';
import 'package:chat_app_example/domain/repositories/chat_repository.dart';
import 'package:chat_app_example/data/repositories/in_memory_chat_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// State ringan untuk menyimpan tree, status loading, dan input teks saat ini.
class ChatState {
  ChatState({required this.tree, this.isLoading = false, this.input = ''});

  final ChatTree? tree; // Tree percakapan saat ini (bisa null saat init)
  final bool isLoading; // Menandai proses async (kirim, regenerate, switch)
  final String input; // Nilai text field input user

  ChatState copyWith({ChatTree? tree, bool? isLoading, String? input}) {
    return ChatState(
      tree: tree ?? this.tree,
      isLoading: isLoading ?? this.isLoading,
      input: input ?? this.input,
    );
  }
}

// Controller (StateNotifier) untuk mengorkestrasi aksi ke repository
// dan memperbarui state agar UI bereaksi.
class ChatController extends StateNotifier<ChatState> {
  ChatController(this._repo) : super(ChatState(tree: null, isLoading: true)) {
    _init();
  }

  final ChatRepository _repo; // Abstraksi sumber data

  Future<void> _init() async {
    // Muat tree awal dari repository.
    final ChatTree tree = await _repo.getCurrentTree();
    state = state.copyWith(tree: tree, isLoading: false);
  }

  // Update input saat user mengetik.
  void setInput(String value) {
    state = state.copyWith(input: value);
  }

  // Kirim pesan user dan buat balasan assistant sebagai branch baru.
  Future<void> send() async {
    if (state.input.trim().isEmpty) return;
    state = state.copyWith(isLoading: true);
    final ChatTree tree = await _repo.sendUserMessage(state.input.trim());
    state = state.copyWith(tree: tree, isLoading: false, input: '');
  }

  // Regenerasi balasan assistant (membuat saudara baru pada node user terakhir).
  Future<void> regenerate() async {
    state = state.copyWith(isLoading: true);
    final ChatTree tree = await _repo.regenerateAssistantReply();
    state = state.copyWith(tree: tree, isLoading: false);
  }

  // Regenerasi di node assistant tertentu
  Future<void> regenerateAt(String assistantNodeId) async {
    state = state.copyWith(isLoading: true);
    final ChatTree tree = await _repo.regenerateAssistantAt(assistantNodeId);
    state = state.copyWith(tree: tree, isLoading: false);
  }

  // Pilih saudara (branch) assistant berikutnya pada node user saat ini.
  Future<void> selectSibling(String nodeId) async {
    state = state.copyWith(isLoading: true);
    final ChatTree tree = await _repo.selectSiblingBranch(nodeId);
    state = state.copyWith(tree: tree, isLoading: false);
  }
}

// Provider untuk repository agar mudah ditukar (in-memory vs remote)
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return InMemoryChatRepository();
});

// Provider untuk controller agar UI dapat meng-observe state ChatState
final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>(
  (ref) {
    final ChatRepository repo = ref.read(chatRepositoryProvider);
    return ChatController(repo);
  },
);

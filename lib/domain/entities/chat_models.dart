/// Mewakili satu pesan chat dalam tree percakapan.
/// Pesan bisa dikirim oleh 'user', 'assistant', atau 'system'.
class ChatMessage {
  /// Membuat pesan dengan id, tautan parent, peran, konten teks, dan waktu dibuat.
  ChatMessage({
    required this.id,
    required this.parentId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  /// Identitas unik untuk pesan (sekaligus node).
  final String id;

  /// Id pesan/node induk. String kosong berarti ini adalah node root/system.
  final String parentId;

  /// Siapa pengirim pesan: 'user' | 'assistant' | 'system'.
  final String role; // 'user' | 'assistant' | 'system'
  /// Teks mentah yang ditampilkan di UI.
  final String content;

  /// Waktu pembuatan pesan.
  final DateTime createdAt;
}

/// Node dalam tree percakapan yang membungkus [ChatMessage]
/// dan menghubungkan ke nol atau lebih id node anak (kelanjutan/branching).
class ChatNode {
  ChatNode({
    required this.id,
    required this.parentId,
    required this.message,
    List<String>? childIds,
  }) : childIds = childIds ?? <String>[];

  /// Id unik; sama dengan [ChatMessage.id] yang dibungkus.
  final String id;

  /// Id node induk. Kosong jika node ini adalah root/system.
  final String parentId;

  /// Pesan yang dibungkus pada node ini (konten dan peran).
  final ChatMessage message;

  /// Daftar berurutan id node anak (masing-masing adalah alternatif kelanjutan),
  /// membentuk sibling branches.
  final List<String> childIds;
}

/// Seluruh percakapan yang disimpan sebagai struktur tree dengan path terpilih.
class ChatTree {
  ChatTree({
    required this.rootId,
    Map<String, ChatNode>? nodes,
    List<String>? branchPathIds,
  }) : nodes = nodes ?? <String, ChatNode>{},
       branchPathIds = branchPathIds ?? <String>[];

  /// Id node root (pesan system).
  final String rootId;

  /// Indeks semua node berdasarkan id untuk akses dan update O(1).
  final Map<String, ChatNode> nodes;

  /// Jalur branch yang saat ini dipilih dari root ke leaf aktif.
  /// Daftar ini menyimpan urutan id untuk memudahkan rekonstruksi UI
  /// dan perpindahan antar sibling tanpa kehilangan branch lain.
  final List<String> branchPathIds;
}

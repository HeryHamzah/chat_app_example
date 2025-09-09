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

  // --- Serialization helpers ---
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'parentId': parentId,
    'role': role,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };

  static ChatMessage fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      parentId: json['parentId'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
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

  // --- Serialization helpers ---
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'parentId': parentId,
    'message': message.toJson(),
    'childIds': childIds,
  };

  static ChatNode fromJson(Map<String, dynamic> json) {
    return ChatNode(
      id: json['id'] as String,
      parentId: json['parentId'] as String,
      message: ChatMessage.fromJson(json['message'] as Map<String, dynamic>),
      childIds: (json['childIds'] as List<dynamic>).cast<String>(),
    );
  }
}

/// Seluruh percakapan yang disimpan sebagai struktur tree dengan path terpilih.
class ChatTree {
  ChatTree({
    required this.rootId,
    Map<String, ChatNode>? nodes,
    List<String>? branchPathIds,
    Map<String, List<String>>? savedTailsByAssistantId,
  }) : nodes = nodes ?? <String, ChatNode>{},
       branchPathIds = branchPathIds ?? <String>[],
       savedTailsByAssistantId =
           savedTailsByAssistantId ?? <String, List<String>>{};

  /// Id node root (pesan system).
  final String rootId;

  /// Indeks semua node berdasarkan id untuk akses dan update O(1).
  final Map<String, ChatNode> nodes;

  /// Jalur branch yang saat ini dipilih dari root ke leaf aktif.
  /// Daftar ini menyimpan urutan id untuk memudahkan rekonstruksi UI
  /// dan perpindahan antar sibling tanpa kehilangan branch lain.
  final List<String> branchPathIds;

  /// Menyimpan "lanjutan path" yang pernah dipilih per node assistant,
  /// agar ketika kembali ke branch tersebut, tail path dapat dipulihkan.
  final Map<String, List<String>> savedTailsByAssistantId;

  // --- Serialization helpers ---
  Map<String, dynamic> toJson() => <String, dynamic>{
    'rootId': rootId,
    'nodes': nodes.map(
      (String key, ChatNode value) => MapEntry(key, value.toJson()),
    ),
    'branchPathIds': branchPathIds,
    'savedTailsByAssistantId': savedTailsByAssistantId,
  };

  static ChatTree fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> rawNodes = json['nodes'] as Map<String, dynamic>;
    final Map<String, ChatNode> parsedNodes = <String, ChatNode>{
      for (final MapEntry<String, dynamic> e in rawNodes.entries)
        e.key: ChatNode.fromJson(e.value as Map<String, dynamic>),
    };

    // Parse savedTailsByAssistantId dengan backward compatibility
    Map<String, List<String>> savedTails = <String, List<String>>{};
    if (json.containsKey('savedTailsByAssistantId')) {
      final Map<String, dynamic> rawTails =
          json['savedTailsByAssistantId'] as Map<String, dynamic>;
      savedTails = rawTails.map(
        (String key, dynamic value) =>
            MapEntry(key, (value as List<dynamic>).cast<String>()),
      );
    }

    return ChatTree(
      rootId: json['rootId'] as String,
      nodes: parsedNodes,
      branchPathIds: (json['branchPathIds'] as List<dynamic>).cast<String>(),
      savedTailsByAssistantId: savedTails,
    );
  }
}

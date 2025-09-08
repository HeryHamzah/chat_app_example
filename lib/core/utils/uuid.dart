import 'dart:math';

// Util sederhana untuk membuat string id acak ala UUID v4 (bukan standar penuh)
class Uuid {
  static final Random _random = Random();

  // Menghasilkan id unik berbasis waktu + dua angka acak (hex)
  static String v4() {
    final int t = DateTime.now().microsecondsSinceEpoch; // waktu sebagai dasar
    final int r1 = _random.nextInt(1 << 32); // angka acak 32-bit
    final int r2 = _random.nextInt(1 << 32); // angka acak 32-bit
    return '${t.toRadixString(16)}-${r1.toRadixString(16)}-${r2.toRadixString(16)}';
  }
}

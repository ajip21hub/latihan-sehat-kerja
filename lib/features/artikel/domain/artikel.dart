/// Bacaan dari server. Disimpan di drift supaya tetap bisa dibaca offline.
class Artikel {
  const Artikel({
    required this.id,
    required this.judul,
    required this.ringkas,
    required this.isi,
    required this.diperbarui,
  });

  final String id;
  final String judul;
  final String ringkas;
  final String isi;

  /// Milidetik dari server. Dipakai mengurutkan dan mengenali versi.
  final int diperbarui;

  factory Artikel.fromJson(Map<String, dynamic> json) {
    final diperbarui = json['diperbarui'];
    return Artikel(
      id: '${json['id']}',
      judul: '${json['judul']}',
      ringkas: '${json['ringkas']}',
      isi: '${json['isi']}',
      diperbarui: diperbarui is num ? diperbarui.toInt() : 0,
    );
  }
}

class DaftarArtikel {
  const DaftarArtikel({required this.daftar, required this.fromCache});

  final List<Artikel> daftar;
  final bool fromCache;
}

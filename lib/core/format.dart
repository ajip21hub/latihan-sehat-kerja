String rupiah(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  final buffer = StringBuffer(negative ? '-Rp' : 'Rp');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Perkiraan belajar, mengikuti pola publik: saldo kecil lebih cepat diproses.
/// Bukan janji layanan resmi.
int perkiraanHariKerja(int nominal) => nominal <= 10000000 ? 1 : 5;

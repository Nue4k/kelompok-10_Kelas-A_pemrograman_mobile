void main() {
  // ==============================
  // 1. DAFTAR HARGA
  // ==============================

  // Map<String, int> = nama barang dan harga
  Map<String, int> daftarHarga = {
    "Beras": 75000,
    "Minyak": 20000,
    "Gula": 18000,
    "Telur": 30000,
    "Susu": 15000,
    "Roti": 12000,
  };

  // ==============================
  // 2. DAFTAR BELANJAAN
  // ==============================

  // List<String> untuk menyimpan barang yang dibeli
  List<String> daftarBelanjaan = [
    "Beras",
    "Minyak",
    "Gula",
    "Telur",
    "Susu",
  ];

  // ==============================
  // 3. FUNCTION MENGHITUNG TOTAL
  // ==============================

  double hitungTotal(
    List<String> belanjaan,
    Map<String, int> harga,
  ) {
    double total = 0;

    for (String barang in belanjaan) {
      if (harga.containsKey(barang)) {
        total += harga[barang]!;
      }
    }

    return total;
  }

  // ==============================
  // 4. FUNCTION MENENTUKAN DISKON
  // ==============================

  double hitungDiskon(double total) {
    double diskon;

    // Jika total >= 100.000
    if (total >= 100000) {
      diskon = total * 0.10; // Diskon 10%
    } 
    // Jika total >= 50.000
    else if (total >= 50000) {
      diskon = total * 0.05; // Diskon 5%
    } 
    // Jika total < 50.000
    else {
      diskon = 0; // Tidak mendapatkan diskon
    }

    return diskon;
  }

  // ==============================
  // 5. HITUNG TOTAL BELANJA
  // ==============================

  double subtotal = hitungTotal(
    daftarBelanjaan,
    daftarHarga,
  );

  // ==============================
  // 6. HITUNG DISKON
  // ==============================

  double diskon = hitungDiskon(subtotal);

  // ==============================
  // 7. HITUNG TOTAL AKHIR
  // ==============================

  double totalAkhir = subtotal - diskon;

  // ==============================
  // 8. MENAMPILKAN HASIL
  // ==============================

  print("================================");
  print("       STRUK BELANJA");
  print("================================");

  print("Daftar Belanja:");

  for (String barang in daftarBelanjaan) {
    print("- $barang : Rp${daftarHarga[barang]}");
  }

  print("--------------------------------");
  print("Subtotal       : Rp$subtotal");
  print("Diskon         : Rp$diskon");
  print("Total Akhir    : Rp$totalAkhir");
  print("================================");

  // ==============================
  // 9. STATUS DISKON
  // ==============================

  bool mendapatkanDiskon = diskon > 0;

  if (mendapatkanDiskon == true) {
    print("Selamat! Anda mendapatkan diskon.");
  } else {
    print("Anda belum mendapatkan diskon.");
  }

  // Comparison operator tambahan
  if (totalAkhir > 100000) {
    print("Status: Belanja cukup banyak.");
  } else if (totalAkhir == 100000) {
    print("Status: Total belanja tepat Rp100.000.");
  } else {
    print("Status: Belanja di bawah Rp100.000.");
  }
}
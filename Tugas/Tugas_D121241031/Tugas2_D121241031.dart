void main() {
  Map<String, double> daftarHarga = {
    'Laptop': 8000000.0,
    'Mouse': 150000.0,
    'Keyboard': 350000.0,
    'Flashdisk': 85000.0
  };

  Map<String, int> daftarBelanjaan = {
    'Mouse': 2,
    'Keyboard': 1,
    'Flashdisk': 3
  };

  prosesPembayaran(daftarHarga, daftarBelanjaan);
}

void prosesPembayaran(Map<String, double> harga, Map<String, int> belanjaan) {
  double totalBelanja = 0;

  belanjaan.forEach((item, jumlah) {
    if (harga.containsKey(item)) {
      totalBelanja += harga[item]! * jumlah;
    }
  });

  print("Total belanja awal: Rp${totalBelanja}");

  double diskon = 0.0;
  String infoDiskon = "";

  if (totalBelanja >= 1000000) {
    diskon = 0.20; 
    infoDiskon = "20%";
  } else if (totalBelanja >= 500000) {
    diskon = 0.10;
    infoDiskon = "10%";
  } else {
    diskon = 0.0; 
    infoDiskon = "0%";
  }

  double nominalDiskon = totalBelanja * diskon;
  double totalAkhir = totalBelanja - nominalDiskon;

  print("Mendapatkan diskon: $infoDiskon (Rp$nominalDiskon)");
  print("----------------------------------");
  print("Total akhir yang harus dibayar: Rp$totalAkhir");
}
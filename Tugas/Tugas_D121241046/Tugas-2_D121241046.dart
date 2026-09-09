double hitungTotalBelanja(
  List<String> daftarBelanja,
  Map<String, double> harga,
) 
{
  double total = 0;
  for (var barang in daftarBelanja) {
    if (harga.containsKey(barang)) {
      total += harga[barang]!;
    } else {
      print("Peringatan: $barang tidak ditemukan dalam daftar harga.");
    }
  }
  return total;
}

double hitungDiskon(double totalBelanja) {
  if (totalBelanja >= 2500000) {
    return 0.50;
  } else if (totalBelanja >= 75000) {
    return 0.30;
  } else if (totalBelanja >= 25000){
    return 0.10;
  } else {
    return 0.0;
  }
}

void main() {
  Map<String, double> harga = {
    'Beras': 14000,
    'Minyak Goreng': 16000,
    'Telur': 27000,
    'Gula': 16000,
    'Kopi': 12000,
    'Ram DDR5 Sodimm 16GB': 5600000,
  };

  List<String> daftarBelanja = [
    'Beras',
    'Minyak Goreng',
    'Minyak Goreng',
    'Telur',
    'Kopi',
    'Kopi',
    'Ram DDR5 Sodimm 16GB',
  ];

  print("Barang yang dibeli: $daftarBelanja");

  double totalAwal = hitungTotalBelanja(daftarBelanja, harga);
  print("Total Sementara: Rp ${totalAwal.toInt()}");

  double persentaseDiskon = hitungDiskon(totalAwal);
  double nominalDiskon = totalAwal * persentaseDiskon;

  print(
    "Diskon: ${(persentaseDiskon * 100).toInt()}% (Rp ${nominalDiskon.toInt()})",
  );

  double totalAkhir = totalAwal - nominalDiskon;
  print("TOTAL AKHIR: Rp ${totalAkhir.toInt()}");
}

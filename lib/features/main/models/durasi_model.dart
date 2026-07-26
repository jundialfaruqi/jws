class DurasiModel {
  final int adzanImsak;
  final int adzanShuruq;
  final int adzanDhuha;
  
  final int adzanShubuh;
  final int iqomahShubuh;
  final int finalShubuh;
  
  final int adzanDzuhur;
  final int iqomahDzuhur;
  final int finalDzuhur;
  final int jumatSlide;
  
  final int adzanAshar;
  final int iqomahAshar;
  final int finalAshar;
  
  final int adzanMaghrib;
  final int iqomahMaghrib;
  final int finalMaghrib;
  
  final int adzanIsya;
  final int iqomahIsya;
  final int finalIsya;
  
  final int financeScrollSpeed;

  DurasiModel({
    this.adzanImsak = 2,
    this.adzanShuruq = 2,
    this.adzanDhuha = 2,
    this.adzanShubuh = 2,
    this.iqomahShubuh = 2,
    this.finalShubuh = 2,
    this.adzanDzuhur = 2,
    this.iqomahDzuhur = 2,
    this.finalDzuhur = 2,
    this.jumatSlide = 2,
    this.adzanAshar = 2,
    this.iqomahAshar = 2,
    this.finalAshar = 2,
    this.adzanMaghrib = 2,
    this.iqomahMaghrib = 2,
    this.finalMaghrib = 2,
    this.adzanIsya = 2,
    this.iqomahIsya = 2,
    this.finalIsya = 2,
    this.financeScrollSpeed = 0,
  });

  factory DurasiModel.fromJson(Map<String, dynamic> json) {
    return DurasiModel(
      adzanImsak: json['adzan_imsak'] ?? 2,
      adzanShuruq: json['adzan_shuruq'] ?? 2,
      adzanDhuha: json['adzan_dhuha'] ?? 2,
      adzanShubuh: json['adzan_shubuh'] ?? 2,
      iqomahShubuh: json['iqomah_shubuh'] ?? 2,
      finalShubuh: json['final_shubuh'] ?? 2,
      adzanDzuhur: json['adzan_dzuhur'] ?? 2,
      iqomahDzuhur: json['iqomah_dzuhur'] ?? 2,
      finalDzuhur: json['final_dzuhur'] ?? 2,
      jumatSlide: json['jumat_slide'] ?? 2,
      adzanAshar: json['adzan_ashar'] ?? 2,
      iqomahAshar: json['iqomah_ashar'] ?? 2,
      finalAshar: json['final_ashar'] ?? 2,
      adzanMaghrib: json['adzan_maghrib'] ?? 2,
      iqomahMaghrib: json['iqomah_maghrib'] ?? 2,
      finalMaghrib: json['final_maghrib'] ?? 2,
      adzanIsya: json['adzan_isya'] ?? 2,
      iqomahIsya: json['iqomah_isya'] ?? 2,
      finalIsya: json['final_isya'] ?? 2,
      financeScrollSpeed: json['finance_scroll_speed'] ?? 0,
    );
  }
}

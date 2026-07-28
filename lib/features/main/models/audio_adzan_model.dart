class AudioAdzanModel {
  final int? id;
  final String? audioAdzan;
  final String? adzanShubuh;
  final bool status;

  AudioAdzanModel({
    this.id,
    this.audioAdzan,
    this.adzanShubuh,
    this.status = false,
  });

  factory AudioAdzanModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return AudioAdzanModel();
    }
    return AudioAdzanModel(
      id: json['id'],
      audioAdzan: json['audioadzan'],
      adzanShubuh: json['adzanshubuh'],
      status: json['status'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'audioadzan': audioAdzan,
      'adzanshubuh': adzanShubuh,
      'status': status,
    };
  }
}

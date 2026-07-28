class AudioMurotalModel {
  final int? id;
  final String? audio1;
  final String? audio2;
  final String? audio3;
  final bool status;

  AudioMurotalModel({
    this.id,
    this.audio1,
    this.audio2,
    this.audio3,
    this.status = false,
  });

  factory AudioMurotalModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return AudioMurotalModel();
    }
    return AudioMurotalModel(
      id: json['id'],
      audio1: json['audio1'],
      audio2: json['audio2'],
      audio3: json['audio3'],
      status: json['status'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'audio1': audio1,
      'audio2': audio2,
      'audio3': audio3,
      'status': status,
    };
  }
}

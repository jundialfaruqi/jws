class JumbotronVideoItem {
  final int id;
  final String videoUrl;
  final bool hasAudio;
  final int duration;

  JumbotronVideoItem({
    required this.id,
    required this.videoUrl,
    this.hasAudio = false,
    this.duration = 0,
  });

  static bool _parseBool(dynamic val) {
    if (val == null) return false;
    if (val is bool) return val;
    if (val is num) return val == 1;
    if (val is String) {
      final s = val.toLowerCase().trim();
      return s == '1' || s == 'true';
    }
    return false;
  }

  factory JumbotronVideoItem.fromJson(Map<String, dynamic> json) {
    return JumbotronVideoItem(
      id: json['id'] ?? 0,
      videoUrl: json['video_file'] ?? '',
      hasAudio: _parseBool(json['has_audio']),
      duration: json['video_duration'] ?? 0,
    );
  }
}

class SlideModel {
  final int id;
  final bool isActive;
  final String mediaType;
  final String? videoFile;
  final bool hasAudio;
  final int videoDuration;
  final String? slide1;
  final String? slide2;
  final String? slide3;
  final String? slide4;
  final String? slide5;
  final String? slide6;
  final List<JumbotronVideoItem> videos;
  final List<String> allSlides;

  SlideModel({
    required this.id,
    this.isActive = true,
    this.mediaType = 'image',
    this.videoFile,
    this.hasAudio = false,
    this.videoDuration = 0,
    this.slide1,
    this.slide2,
    this.slide3,
    this.slide4,
    this.slide5,
    this.slide6,
    this.videos = const [],
    this.allSlides = const [],
  });

  factory SlideModel.fromJson(Map<String, dynamic> json) {
    List<JumbotronVideoItem> parsedVideos = [];
    if (json['videos'] != null && json['videos'] is List) {
      parsedVideos = (json['videos'] as List)
          .map((v) => JumbotronVideoItem.fromJson(v as Map<String, dynamic>))
          .where((v) => v.videoUrl.isNotEmpty)
          .toList();
    } else if (json['video_file'] != null && (json['video_file'] as String).isNotEmpty) {
      parsedVideos = [
        JumbotronVideoItem(
          id: json['id'] ?? 0,
          videoUrl: json['video_file'],
          hasAudio: JumbotronVideoItem._parseBool(json['has_audio']),
          duration: json['video_duration'] ?? 0,
        ),
      ];
    }

    List<String> parsedSlides = [];
    if (json['all_slides'] != null && json['all_slides'] is List) {
      parsedSlides = (json['all_slides'] as List)
          .map((s) => s.toString())
          .where((s) => s.isNotEmpty)
          .toList();
    } else {
      final legacySlides = [
        json['slide1'],
        json['slide2'],
        json['slide3'],
        json['slide4'],
        json['slide5'],
        json['slide6'],
      ];
      parsedSlides = legacySlides.whereType<String>().where((s) => s.isNotEmpty).toList();
    }

    return SlideModel(
      id: json['id'] ?? 0,
      isActive: json['is_active'] ?? true,
      mediaType: json['media_type'] ?? 'image',
      videoFile: json['video_file'],
      hasAudio: JumbotronVideoItem._parseBool(json['has_audio']),
      videoDuration: json['video_duration'] ?? 0,
      slide1: json['slide1'],
      slide2: json['slide2'],
      slide3: json['slide3'],
      slide4: json['slide4'],
      slide5: json['slide5'],
      slide6: json['slide6'],
      videos: parsedVideos,
      allSlides: parsedSlides,
    );
  }

  // Helper untuk mengecek apakah jumbotron bertipe video atau memiliki daftar video
  bool get isVideo => (mediaType == 'video' && videoFile != null && videoFile!.isNotEmpty) || videos.isNotEmpty;

  // Helper untuk mendapatkan list url gambar yang tidak null
  List<String> get validSlides {
    if (allSlides.isNotEmpty) return allSlides;
    final slides = [slide1, slide2, slide3, slide4, slide5, slide6];
    return slides.whereType<String>().where((s) => s.isNotEmpty).toList();
  }
}

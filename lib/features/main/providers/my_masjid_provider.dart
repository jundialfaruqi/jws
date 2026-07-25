import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/my_masjid_model.dart';
import '../services/my_masjid_service.dart';

final myMasjidProvider = FutureProvider.family<MyMasjidModel, String>((ref, slug) async {
  final service = ref.read(myMasjidServiceProvider);
  return await service.getMyMasjid(slug);
});

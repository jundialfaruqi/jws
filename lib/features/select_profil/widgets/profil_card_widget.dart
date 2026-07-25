import 'package:flutter/material.dart';
import '../models/profil_masjid_model.dart';

class ProfilCardWidget extends StatelessWidget {
  final ProfilMasjidModel profil;
  final VoidCallback onTap;

  const ProfilCardWidget({
    super.key,
    required this.profil,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          profil.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text('Slug: ${profil.slug}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

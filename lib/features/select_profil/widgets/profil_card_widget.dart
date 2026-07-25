import 'package:flutter/material.dart';
import '../models/profil_masjid_model.dart';

class ProfilCardWidget extends StatefulWidget {
  final ProfilMasjidModel profil;
  final VoidCallback onTap;

  const ProfilCardWidget({
    super.key,
    required this.profil,
    required this.onTap,
  });

  @override
  State<ProfilCardWidget> createState() => _ProfilCardWidgetState();
}

class _ProfilCardWidgetState extends State<ProfilCardWidget> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      // Naikkan elevation dan ubah warna background saat item difokuskan via remote
      elevation: _isFocused ? 12 : 2,
      color: _isFocused ? Colors.blue.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // Beri border biru yang tebal agar sangat terlihat di layar TV
        side: BorderSide(
          color: _isFocused ? Colors.blue : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onFocusChange: (hasFocus) {
          setState(() {
            _isFocused = hasFocus;
          });
        },
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.profil.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${widget.profil.slug}',
                      style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

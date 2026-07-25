import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GantiProfilButton extends StatefulWidget {
  const GantiProfilButton({super.key});

  @override
  State<GantiProfilButton> createState() => _GantiProfilButtonState();
}

class _GantiProfilButtonState extends State<GantiProfilButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onFocusChange: (hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
      },
      icon: Icon(
        Icons.swap_horiz, 
        size: 28, 
        color: _isFocused ? Colors.white : Colors.blue.shade900,
      ),
      label: Text(
        'Ganti Profil', 
        style: TextStyle(
          fontSize: 24, 
          color: _isFocused ? Colors.white : Colors.blue.shade900,
        ),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        backgroundColor: _isFocused ? Colors.blue.shade600 : Colors.blue.shade50,
        side: BorderSide(
          color: _isFocused ? Colors.blue.shade900 : Colors.transparent,
          width: 4,
        ),
      ),
      onPressed: () {
        context.goNamed('select_profil');
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'tv/tv_button.dart';

class GantiProfilButton extends StatelessWidget {
  const GantiProfilButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TvButton(
      label: 'Ganti Profil',
      icon: Icons.swap_horiz,
      variant: TvButtonVariant.primary,
      onPressed: () {
        context.goNamed('select_profil');
      },
    );
  }
}

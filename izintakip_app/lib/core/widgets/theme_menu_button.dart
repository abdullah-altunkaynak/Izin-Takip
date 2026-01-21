import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:izintakip_app/core/theme/theme_provider.dart';

class ThemeMenuButton extends ConsumerWidget {
  const ThemeMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeControllerProvider);

    return PopupMenuButton<ThemeMode>(
      icon: Icon(
        mode == ThemeMode.dark
            ? Icons.dark_mode
            : mode == ThemeMode.light
            ? Icons.light_mode
            : Icons.brightness_auto,
      ),
      onSelected: (m) => ref.read(themeControllerProvider.notifier).setMode(m),
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
          value: ThemeMode.system,
          checked: mode == ThemeMode.system,
          child: const Text("Sistem"),
        ),
        CheckedPopupMenuItem(
          value: ThemeMode.light,
          checked: mode == ThemeMode.light,
          child: const Text("Açık"),
        ),
        CheckedPopupMenuItem(
          value: ThemeMode.dark,
          checked: mode == ThemeMode.dark,
          child: const Text("Koyu"),
        ),
      ],
    );
  }
}

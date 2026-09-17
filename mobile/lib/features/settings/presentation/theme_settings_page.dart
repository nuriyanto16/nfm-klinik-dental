import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_theme.dart';

class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeNotifierProvider);
    final notifier = ref.read(themeNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Tema'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Mode Tampilan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Mode Gelap (Dark Mode)'),
            value: themeState.isDarkMode,
            onChanged: (val) {
              notifier.toggleDarkMode(val);
            },
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.getPrimary(themeState.colorTheme),
          ),
          const Divider(height: 32),
          
          const Text(
            'Warna Utama',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: AppThemeColor.values.map((color) {
              final isSelected = themeState.colorTheme == color;
              final colorValue = AppColors.getPrimary(color);
              return GestureDetector(
                onTap: () => notifier.setColorTheme(color),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: colorValue,
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: colorValue.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
          const Divider(height: 32),

          const Text(
            'Jenis Font',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: themeState.fontFamily,
            decoration: const InputDecoration(
              labelText: 'Pilih Font',
            ),
            items: const [
              DropdownMenuItem(value: 'Inter', child: Text('Inter (Modern)')),
              DropdownMenuItem(value: 'Outfit', child: Text('Outfit (Premium)')),
              DropdownMenuItem(value: 'Poppins', child: Text('Poppins (Bulat)')),
              DropdownMenuItem(value: 'Roboto', child: Text('Roboto (Standar)')),
            ],
            onChanged: (val) {
              if (val != null) {
                notifier.setFontFamily(val);
              }
            },
          ),
        ],
      ),
    );
  }
}

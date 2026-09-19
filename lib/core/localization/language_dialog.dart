import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'locale_provider.dart';

void showLanguageDialog(BuildContext context) {
  final provider = context.read<LocaleProvider>();
  final current = provider.locale;

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Language / भाषा चुनें',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _languageOption(
              ctx,
              title: 'English',
              subtitle: 'Default',
              isSelected: current == 'en',
              onTap: () {
                provider.setLocale('en');
                Navigator.pop(ctx);
              },
            ),
            const Divider(height: 1),
            _languageOption(
              ctx,
              title: 'हिंदी (Hindi)',
              subtitle: 'भारतीय किसानों के लिए',
              isSelected: current == 'hi',
              onTap: () {
                provider.setLocale('hi');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _languageOption(
  BuildContext context, {
  required String title,
  required String subtitle,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
    ),
    subtitle: Text(
      subtitle,
      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
    ),
    trailing: isSelected
        ? const Icon(Icons.check_circle, color: Color(0xFF2E7D32))
        : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
    onTap: onTap,
  );
}

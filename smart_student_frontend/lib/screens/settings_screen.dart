import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'package:easy_localization/easy_localization.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showLanguageDialog(BuildContext context, SettingsProvider settings) {
    final currentLang = settings.currentLocale.languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF003B00) : Colors.white,
          title: Text('اختر اللغة', textAlign: TextAlign.right, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF003B00))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('عربي', textAlign: TextAlign.right, style: TextStyle(color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF003B00))),
                onTap: () async {
                  Navigator.pop(ctx);
                  final newLocale = const Locale('ar');
                  await context.setLocale(newLocale);
                  if (context.mounted) {
                    settings.setLocale(newLocale);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تغيير اللغة إلى العربية')),
                    );
                  }
                },
                trailing: currentLang == 'ar'
                    ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                    : null,
              ),
              ListTile(
                title: Text('English', textAlign: TextAlign.right, style: TextStyle(color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF003B00))),
                onTap: () async {
                  Navigator.pop(ctx);
                  final newLocale = const Locale('en');
                  await context.setLocale(newLocale);
                  if (context.mounted) {
                    settings.setLocale(newLocale);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Language changed to English')),
                    );
                  }
                },
                trailing: currentLang == 'en'
                    ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider so the switch reflects real-time state
    final settings = context.watch<SettingsProvider>();
    final langLabel = settings.isArabic ? 'عربي' : 'English';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 16),
            Text(
              'الإعدادات',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF003B00),
              ),
            ),
            const SizedBox(height: 24),

            // ── Language tile ───────────────────────────────────────────────
            _SettingsTile(
              icon: Icons.language_outlined,
              label: 'اللغة',
              isDark: isDark,
              trailing: Text(
                langLabel,
                style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 14),
              ),
              onTap: () => _showLanguageDialog(context, settings),
            ),

            // ── Dark mode tile ──────────────────────────────────────────────
            _SettingsTile(
              icon: Icons.dark_mode_outlined,
              label: 'الوضع الليلي',
              isDark: isDark,
              trailing: Switch(
                value: settings.isDarkMode,
                // Use read() here so toggling doesn't cause a rebuild loop
                onChanged: (_) => context.read<SettingsProvider>().toggleTheme(),
                activeColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDark;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF002200) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF003B00) : const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF003B00),
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: trailing ??
            Icon(Icons.arrow_forward_ios,
                size: 16, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
        onTap: onTap,
      ),
    );
  }
}

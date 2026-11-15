import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_info.dart';
import '../../core/extensions/context_ext.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/app_settings.dart';
import '../../services/ads/admob_service.dart';
import '../../state/settings_controller.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/premium_switch.dart';
import '../../widgets/pressable.dart';
import '../../widgets/screen_scaffold.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SettingsController>();
    final s = ctrl.settings;
    void set(AppSettings n) => ctrl.update(n);

    return ScreenScaffold(
      title: 'Settings',
      showCoins: false,
      child: ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
        const _Section('Audio & Feel'),
        _Group(children: [
          _ToggleRow(icon: Icons.music_note_rounded, label: 'Music', value: s.music, onChanged: (v) => set(s.copyWith(music: v))),
          _ToggleRow(icon: Icons.volume_up_rounded, label: 'Sound Effects', value: s.sfx, onChanged: (v) => set(s.copyWith(sfx: v))),
          _ToggleRow(icon: Icons.vibration_rounded, label: 'Haptics', value: s.haptics, onChanged: (v) => set(s.copyWith(haptics: v))),
          _ToggleRow(
              icon: Icons.notifications_rounded,
              label: 'Notifications',
              subtitle: 'Daily reward reminders',
              value: s.notifications,
              onChanged: (v) => set(s.copyWith(notifications: v))),
        ]),
        const _Section('Display'),
        _Group(children: [
          _RowShell(
            icon: Icons.auto_awesome_rounded,
            label: 'Graphics Quality',
            subtitle: s.graphics == GraphicsQuality.high ? 'Glow, blur and full particles' : 'Battery saver',
            trailing: SegmentedButton<GraphicsQuality>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.primary,
                selectedForegroundColor: AppColors.background,
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.glassBorder),
                visualDensity: VisualDensity.compact,
              ),
              segments: const [
                ButtonSegment(value: GraphicsQuality.low, label: Text('Low')),
                ButtonSegment(value: GraphicsQuality.high, label: Text('High')),
              ],
              selected: {s.graphics},
              onSelectionChanged: (v) {
                context.tapFeedback();
                set(s.copyWith(graphics: v.first));
              },
            ),
          ),
          _ToggleRow(icon: Icons.motion_photos_off_rounded, label: 'Reduce Motion', value: s.reduceMotion, onChanged: (v) => set(s.copyWith(reduceMotion: v))),
          _ToggleRow(
              icon: Icons.highlight_rounded,
              label: 'Highlight Free Arrows',
              subtitle: 'Dims arrows that can\'t move yet',
              value: s.showFreeArrows,
              onChanged: (v) => set(s.copyWith(showFreeArrows: v))),
        ]),
        const _Section('Privacy'),
        _Group(children: [
          _ToggleRow(
              icon: Icons.ads_click_rounded,
              label: 'Personalized Ads',
              subtitle: 'Managed by your consent choices',
              value: s.personalizedAds,
              onChanged: (v) {
                context.read<AdMobService>().personalized = v;
                set(s.copyWith(personalizedAds: v));
              }),
          _ActionRow(
            icon: Icons.privacy_tip_rounded,
            label: 'Privacy Options',
            onTap: () async {
              final ads = context.read<AdMobService>();
              if (await ads.privacyOptionsRequired()) {
                await ads.showPrivacyOptions();
              } else if (context.mounted) {
                context.toast('No privacy choices are required in your region.', icon: Icons.privacy_tip_rounded);
              }
            },
          ),
        ]),
        const _Section('Data'),
        _Group(children: [
          _ActionRow(
            icon: Icons.restart_alt_rounded,
            label: 'Reset Progress',
            color: AppColors.error,
            onTap: () async {
              final ok = await confirmDialog(context,
                  title: 'Reset all progress?',
                  message: 'Levels, stars, coins, skins and achievements will be erased. This cannot be undone.',
                  confirmLabel: 'Reset',
                  icon: Icons.warning_rounded,
                  destructive: true);
              if (ok && context.mounted) {
                await context.progress.resetProgress();
                if (context.mounted) context.toast('Progress reset. Fresh start!', icon: Icons.check_rounded, color: AppColors.success);
              }
            },
          ),
        ]),
        const _Section('About'),
        _Group(children: [
          _ActionRow(
            icon: Icons.info_rounded,
            label: 'About ${AppInfo.shortName}',
            onTap: () => showAppDialog<void>(
              context,
              (ctx) => AppDialog(
                title: AppInfo.shortName,
                message: 'Version ${AppInfo.version}\n${AppInfo.tagline}\nAn original arrow-escape puzzle game.',
                content: const AppLogo(scale: 0.5),
                actions: [_CloseButton(ctx)],
              ),
            ),
          ),
        ]),
        const SizedBox(height: AppSpacing.xl),
      ]),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton(this.ctx);
  final BuildContext ctx;
  @override
  Widget build(BuildContext context) => TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'));
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, AppSpacing.md, 4, AppSpacing.xs),
        child: Text(title.toUpperCase(), style: AppTextStyles.caption.copyWith(letterSpacing: 1.8)),
      );
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SurfaceCard(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const Divider(height: 1, indent: 56, color: AppColors.divider),
          ],
        ]),
      );
}

class _RowShell extends StatelessWidget {
  const _RowShell({required this.icon, required this.label, required this.trailing, this.subtitle, this.color = AppColors.textSecondary});
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget trailing;
  final Color color;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: Row(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(label, style: AppTextStyles.subheading.copyWith(color: color == AppColors.error ? AppColors.error : AppColors.textPrimary)),
                if (subtitle != null) Text(subtitle!, style: AppTextStyles.caption),
              ]),
            ),
            trailing,
          ]),
        ),
      );
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.icon, required this.label, required this.value, required this.onChanged, this.subtitle});
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => _RowShell(
        icon: icon,
        label: label,
        subtitle: subtitle,
        trailing: PremiumSwitch(value: value, onChanged: onChanged, semanticLabel: label),
      );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.icon, required this.label, required this.onTap, this.color = AppColors.textSecondary});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        pressedScale: 0.98,
        semanticLabel: label,
        child: _RowShell(icon: icon, label: label, color: color, trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted)),
      );
}

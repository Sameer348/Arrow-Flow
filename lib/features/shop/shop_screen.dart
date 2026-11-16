import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/context_ext.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../game/arrows/arrow_renderer.dart';
import '../../models/booster.dart';
import '../../models/cosmetics.dart';
import '../../models/direction.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/audio/audio_service.dart';
import '../../state/progress_controller.dart';
import '../../widgets/badges.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/pressable.dart';
import '../../widgets/screen_scaffold.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this, initialIndex: widget.initialTab);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Shop',
      showBanner: true,
      child: Column(children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: TabBar(
            controller: _tabs,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(AppRadius.sm)),
            labelColor: AppColors.background,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: AppTextStyles.label.copyWith(fontWeight: FontWeight.w800),
            labelPadding: EdgeInsets.zero,
            onTap: (_) => context.tapFeedback(),
            tabs: const [Tab(text: 'Boosters'), Tab(text: 'Skins'), Tab(text: 'Themes'), Tab(text: 'Special')],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: TabBarView(controller: _tabs, children: const [_BoostersTab(), _SkinsTab(), _ThemesTab(), _SpecialTab()]),
        ),
      ]),
    );
  }
}

int _columns(BuildContext context) => (MediaQuery.sizeOf(context).width / 180).floor().clamp(2, 4);

// -------------------------------------------------------------------- Boosters

class _BoostersTab extends StatelessWidget {
  const _BoostersTab();

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: Booster.values.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final b = Booster.values[i];
        return _ShopCard(
          child: Row(children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: b.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: b.color.withValues(alpha: 0.35)),
              ),
              child: Icon(b.icon, color: b.color, size: 28),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b.label, style: AppTextStyles.subheading),
                const SizedBox(height: 2),
                Text(b.description, style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Text('Owned: ${progress.boosterCount(b)}', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              ]),
            ),
            _PriceButton(
              price: b.price,
              onTap: () {
                if (progress.buyBooster(b)) {
                  context.services.audio.play(Sfx.coin);
                  showRewardPopup(context, '+1 ${b.label}', b.icon, color: b.color);
                } else {
                  _notEnough(context);
                }
              },
            ),
          ]),
        );
      },
    );
  }
}

// ----------------------------------------------------------------------- Skins

class _SkinsTab extends StatelessWidget {
  const _SkinsTab();

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _columns(context),
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.82,
      ),
      itemCount: ArrowSkin.all.length,
      itemBuilder: (context, i) {
        final s = ArrowSkin.all[i];
        final owned = progress.ownsSkin(s.id);
        final selected = progress.progress.selectedSkin == s.id;
        return _CosmeticCard(
          name: s.name,
          rarity: s.rarity,
          price: s.price,
          owned: owned,
          selected: selected,
          preview: _ArrowPreview(colors: s.resolveColors(progress.theme), glow: s.resolveGlow(progress.theme)),
          onTap: () {
            if (owned) {
              progress.selectSkin(s.id);
            } else {
              _buy(context, s.name, s.price, () {
                final ok = progress.buySkin(s);
                if (ok) context.services.analytics.log(AnalyticsEvent.skinUnlocked, {'skin': s.id});
                return ok;
              });
            }
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------- Themes

class _ThemesTab extends StatelessWidget {
  const _ThemesTab();

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _columns(context),
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.82,
      ),
      itemCount: GameTheme.all.length,
      itemBuilder: (context, i) {
        final t = GameTheme.all[i];
        final owned = progress.ownsTheme(t.id);
        return _CosmeticCard(
          name: t.name,
          rarity: t.rarity,
          price: t.price,
          owned: owned,
          selected: progress.progress.selectedTheme == t.id,
          preview: _ThemePreview(theme: t),
          onTap: () {
            if (owned) {
              progress.selectTheme(t.id);
            } else {
              _buy(context, t.name, t.price, () => progress.buyTheme(t));
            }
          },
        );
      },
    );
  }
}

// --------------------------------------------------------------------- Special

class _SpecialTab extends StatelessWidget {
  const _SpecialTab();

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();
    return ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
      _SpecialCard(
        icon: Icons.play_circle_fill_rounded,
        color: AppColors.violet,
        title: 'Free Coins',
        subtitle: 'Watch a short video for 50 coins.',
        action: 'Watch',
        onTap: () async {
          final ok = await rewardedFlow(context, placement: 'shop_coins', rewardLabel: '50 Coins', icon: Icons.monetization_on_rounded);
          if (ok) progress.addCoins(50);
        },
      ),
      const SizedBox(height: AppSpacing.sm),
      _SpecialCard(
        icon: Icons.inventory_2_rounded,
        color: AppColors.primary,
        title: 'Starter Bundle',
        subtitle: '3 Hints · 3 Undos · 1 Hammer · 1 Shuffle',
        price: 300,
        onTap: () => _buy(context, 'Starter Bundle', 300, () {
          if (!progress.trySpend(300)) return false;
          progress
            ..addBooster(Booster.hint, 3)
            ..addBooster(Booster.undo, 3)
            ..addBooster(Booster.hammer)
            ..addBooster(Booster.shuffle);
          return true;
        }),
      ),
      const SizedBox(height: AppSpacing.sm),
      _SpecialCard(
        icon: Icons.casino_rounded,
        color: AppColors.warning,
        title: 'Mystery Skin',
        subtitle: 'A random skin you don\'t own yet.',
        price: 450,
        onTap: () {
          final locked = ArrowSkin.all.where((s) => !progress.ownsSkin(s.id)).toList();
          if (locked.isEmpty) {
            context.toast('You own every skin already!', icon: Icons.emoji_events_rounded, color: AppColors.warning);
            return;
          }
          _buy(context, 'Mystery Skin', 450, () {
            if (!progress.trySpend(450)) return false;
            final pick = locked[DateTime.now().millisecond % locked.length];
            progress.grantSkin(pick.id);
            showRewardPopup(context, pick.name, Icons.auto_awesome_rounded, color: pick.rarity.color);
            return true;
          }, silent: true);
        },
      ),
    ]);
  }
}

// --------------------------------------------------------------------- Helpers

void _notEnough(BuildContext context) {
  context.services.haptics.subtle();
  context.toast('Not enough coins yet — clear levels to earn more!', icon: Icons.monetization_on_rounded, color: AppColors.warning);
}

Future<void> _buy(BuildContext context, String name, int price, bool Function() purchase, {bool silent = false}) async {
  final progress = context.progress;
  if (progress.coins < price) return _notEnough(context);
  final ok = await confirmDialog(context,
      title: 'Buy $name?', message: 'This costs $price coins.', confirmLabel: 'Buy for $price', icon: Icons.shopping_bag_rounded, color: AppColors.warning);
  if (!ok || !context.mounted) return;
  if (purchase()) {
    context.services.audio.play(Sfx.coin);
    context.services.haptics.medium();
    if (!silent) showRewardPopup(context, '$name unlocked', Icons.check_circle_rounded);
  } else {
    _notEnough(context);
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: AppGradients.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: child,
      );
}

class _PriceButton extends StatelessWidget {
  const _PriceButton({required this.price, required this.onTap});
  final int price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.45)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const CoinIcon(size: 18),
            const SizedBox(width: 6),
            Text('$price', style: AppTextStyles.label.copyWith(color: AppColors.warning, fontWeight: FontWeight.w800)),
          ]),
        ),
      );
}

class _CosmeticCard extends StatelessWidget {
  const _CosmeticCard({
    required this.name,
    required this.rarity,
    required this.price,
    required this.owned,
    required this.selected,
    required this.preview,
    required this.onTap,
  });

  final String name;
  final CosmeticRarity rarity;
  final int price;
  final bool owned;
  final bool selected;
  final Widget preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: '$name${selected ? ', selected' : owned ? ', owned' : ', $price coins'}',
      child: AnimatedContainer(
        duration: AppDurations.normal,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          gradient: AppGradients.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: selected ? AppColors.primary : AppColors.glassBorder, width: selected ? 2 : 1),
          boxShadow: selected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 18)] : null,
        ),
        child: Column(children: [
          Expanded(
            child: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.md), child: SizedBox.expand(child: preview)),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(name, style: AppTextStyles.subheading, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(rarity.label, style: AppTextStyles.caption.copyWith(color: rarity.color, fontSize: 11), maxLines: 1),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 30,
            child: selected
                ? const TagChip(label: 'Equipped', color: AppColors.primary, icon: Icons.check_rounded)
                : owned
                    ? const TagChip(label: 'Tap to use', color: AppColors.success, icon: Icons.check_circle_outline_rounded)
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        const CoinIcon(size: 18),
                        const SizedBox(width: 6),
                        Text('$price', style: AppTextStyles.label.copyWith(color: AppColors.warning, fontWeight: FontWeight.w800)),
                      ]),
          ),
        ]),
      ),
    );
  }
}

class _ArrowPreview extends StatelessWidget {
  const _ArrowPreview({required this.colors, required this.glow, this.background});
  final List<Color> colors;
  final Color glow;
  final List<Color>? background;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _ArrowPreviewPainter(colors, glow, background));
}

class _ArrowPreviewPainter extends CustomPainter {
  _ArrowPreviewPainter(this.colors, this.glow, this.background);
  final List<Color> colors;
  final Color glow;
  final List<Color>? background;
  static final _r = ArrowRenderer();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: background ?? const [AppColors.boardTop, AppColors.boardBottom])
              .createShader(rect));
    final cell = size.shortestSide / 3.2;
    _r.draw(canvas,
        head: Offset(size.width / 2 + cell * 0.7, size.height / 2),
        direction: Direction.right,
        length: 2,
        cell: cell,
        colors: colors,
        glowColor: glow,
        glow: 0.6);
  }

  @override
  bool shouldRepaint(_ArrowPreviewPainter old) => old.colors != colors || old.background != background;
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.theme});
  final GameTheme theme;

  @override
  Widget build(BuildContext context) => _ArrowPreview(
        colors: [theme.arrowStart, theme.arrowEnd],
        glow: theme.accent,
        background: [theme.boardTop, theme.background.last],
      );
}

class _SpecialCard extends StatelessWidget {
  const _SpecialCard({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap, this.price, this.action});
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int? price;
  final String? action;

  @override
  Widget build(BuildContext context) => _ShopCard(
        child: Row(children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.15), border: Border.all(color: color.withValues(alpha: 0.4))),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppTextStyles.subheading),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTextStyles.caption),
            ]),
          ),
          if (price != null)
            _PriceButton(price: price!, onTap: onTap)
          else
            Pressable(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(gradient: AppGradients.premium, borderRadius: BorderRadius.circular(20)),
                child: Text(action ?? 'Get', style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
        ]),
      );
}

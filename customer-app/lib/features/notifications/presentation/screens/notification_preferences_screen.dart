import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/notifications/data/notifications_repository.dart';
import 'package:sapbaq/features/notifications/presentation/bloc/notification_preferences_cubit.dart';
import 'package:sapbaq/features/settings/presentation/widgets/settings_option_tile.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Notification preferences — four category toggles. Each flip is applied
/// optimistically and persisted via PATCH; the backend then mutes that
/// category server-side.
class NotificationPreferencesScreen extends StatelessWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (context) =>
          NotificationPreferencesCubit(context.read<NotificationsRepository>())
            ..load(),
      child: Scaffold(
        appBar: AppBar(
          title: TextCustom.subheading(text: l10n.notificationPrefsTitle),
        ),
        body: BlocConsumer<NotificationPreferencesCubit,
            NotificationPreferencesState>(
          listenWhen: (a, b) => b.message != null && a.message != b.message,
          listener: (context, state) =>
              ShowMessage.error(context, state.message!),
          builder: (context, state) {
            if (state.status == LoadStatus.loading) {
              return const LoadingView();
            }
            if (state.status == LoadStatus.failure) {
              return ErrorView(
                message: state.message ?? l10n.comingSoon,
                retryLabel: l10n.retry,
                onRetry: () =>
                    context.read<NotificationPreferencesCubit>().load(),
              );
            }
            final p = state.prefs;
            final cubit = context.read<NotificationPreferencesCubit>();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SettingsOptionGroup(
                  children: [
                    _PrefSwitch(
                      icon: Icons.receipt_long_outlined,
                      label: l10n.notifOrderUpdates,
                      value: p.orderUpdates,
                      onChanged: (v) => cubit.toggle('order_updates', v),
                    ),
                    _PrefSwitch(
                      icon: Icons.star_outline_rounded,
                      label: l10n.notifReviews,
                      value: p.reviews,
                      onChanged: (v) => cubit.toggle('reviews', v),
                    ),
                    _PrefSwitch(
                      icon: Icons.card_giftcard_rounded,
                      label: l10n.notifGifts,
                      value: p.gifts,
                      onChanged: (v) => cubit.toggle('gifts', v),
                    ),
                    _PrefSwitch(
                      icon: Icons.local_offer_outlined,
                      label: l10n.notifPromotions,
                      value: p.promotions,
                      onChanged: (v) => cubit.toggle('promotions', v),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PrefSwitch extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrefSwitch({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colors.primaryTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: context.colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextCustom(
              text: label,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: context.colors.primary,
          ),
        ],
      ),
    );
  }
}

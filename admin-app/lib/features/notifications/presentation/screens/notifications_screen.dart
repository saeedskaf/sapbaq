import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/app/router/app_routes.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/utils/date_format.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/floating_nav_bar.dart';
import 'package:sapbaq_admin/core/widgets/state_views.dart';
import 'package:sapbaq_admin/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq_admin/features/notifications/data/models/app_notification.dart';
import 'package:sapbaq_admin/features/notifications/data/notifications_repository.dart';
import 'package:sapbaq_admin/features/notifications/presentation/bloc/notifications_cubit.dart';
import 'package:sapbaq_admin/features/shared/presentation/app_card.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Notification inbox, shared by both roles. A tap deep-links to the relevant
/// order (admin) or destination (driver) when the payload carries an id.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  void _onTap(BuildContext context, AppNotification n) {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;
    if (user.isAdmin && n.orderId != null) {
      context.pushNamed(
        AppRoutes.adminOrderDetailName,
        pathParameters: {'id': '${n.orderId}'},
      );
    } else if (user.isDriver && n.destinationId != null) {
      context.pushNamed(
        AppRoutes.driverDestinationName,
        pathParameters: {'id': '${n.destinationId}'},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (context) =>
          NotificationsCubit(context.read<NotificationsRepository>())..load(),
      child: Scaffold(
        appBar: AppBar(
          title: TextCustom.subheading(text: l10n.notificationsTitle),
        ),
        body: BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, state) {
            if (state.status == LoadStatus.loading) {
              return const LoadingView();
            }
            if (state.status == LoadStatus.failure) {
              return ErrorView(
                message: state.message ?? l10n.genericError,
                retryLabel: l10n.retry,
                onRetry: () => context.read<NotificationsCubit>().load(),
              );
            }
            if (state.items.isEmpty) {
              return EmptyView(
                message: l10n.emptyNotifications,
                icon: Icons.notifications_none_rounded,
              );
            }
            return RefreshIndicator(
              color: ColorsCustom.primary,
              onRefresh: () => context.read<NotificationsCubit>().load(),
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  floatingNavBarClearance(context),
                ),
                itemCount: state.items.length,
                itemBuilder: (context, i) => _NotificationTile(
                  notification: state.items[i],
                  onTap: () => _onTap(context, state.items[i]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  IconData get _icon {
    if (notification.type.contains('reject')) return Icons.cancel_outlined;
    if (notification.type.contains('assigned')) {
      return Icons.assignment_ind_outlined;
    }
    if (notification.type.contains('created')) return Icons.add_box_outlined;
    return Icons.notifications_none_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: ColorsCustom.secondaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: ColorsCustom.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextCustom(
                  text: notification.title,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                TextCustom(
                  text: notification.body,
                  fontSize: 13,
                  color: ColorsCustom.textSecondary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (notification.createdAt != null) ...[
                  const SizedBox(height: 6),
                  TextCustom.caption(
                    text: formatShortDate(notification.createdAt),
                    fontSize: 11,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

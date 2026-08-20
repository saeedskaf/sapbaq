import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/notifications/notification_deep_link.dart';
import 'package:sapbaq_admin/core/notifications/push_notification_service.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/utils/date_format.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/floating_nav_bar.dart';
import 'package:sapbaq_admin/core/widgets/state_views.dart';
import 'package:sapbaq_admin/features/notifications/data/models/app_notification.dart';
import 'package:sapbaq_admin/features/notifications/data/notifications_repository.dart';
import 'package:sapbaq_admin/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq_admin/features/notifications/presentation/bloc/notifications_badge_cubit.dart';
import 'package:sapbaq_admin/features/notifications/presentation/bloc/notifications_cubit.dart';
import 'package:sapbaq_admin/features/shared/presentation/app_card.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Notification inbox, shared by both roles. A tap deep-links to the relevant
/// screen (order, destination, approval, or escalation) via the ids in the
/// payload (§14).
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  void _onTap(BuildContext context, AppNotification n) {
    // Reading is a side effect of opening it — mark read (optimistic) as we
    // navigate, which also trims the standing nav badge.
    context.read<NotificationsCubit>().markRead(n.id);
    // The same row points at a different screen per role — an imam's
    // maintenance update opens «بلاغاتي», a staff member's opens the case in
    // the operations center (deep-link contract §B.1).
    final user = context.read<AuthBloc>().state.user;
    final route = resolveNotificationRoute(
      n.type,
      audience: audienceForRole(
        isMosqueRep: user?.isMosqueRep ?? false,
        isServiceHandler: user?.isServiceHandler ?? false,
      ),
      orderId: n.orderId,
      destinationId: n.destinationId,
      approvalId: n.approvalId,
      escalationId: n.escalationId,
      maintenanceCaseId: n.maintenanceCaseId,
      equipmentRequestId: n.equipmentRequestId,
      waterFlagId: n.waterFlagId,
      contributionId: n.contributionId,
    );
    if (route == null) return;
    context.pushNamed(
      route.name,
      pathParameters: route.pathParameters,
      queryParameters: route.queryParameters,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (context) => NotificationsCubit(
        context.read<NotificationsRepository>(),
        // Live inbox: a foreground push merges its row in on arrival.
        pushData: context.read<PushNotificationService>().onForegroundData,
      )..load(),
      child: BlocListener<NotificationsCubit, NotificationsState>(
        // Keep the standing nav badge in step with what the inbox learned from
        // the server (load / mark-read / mark-all).
        listenWhen: (a, b) => a.unreadCount != b.unreadCount,
        listener: (context, state) =>
            context.read<NotificationsBadgeCubit>().setCount(state.unreadCount),
        child: Scaffold(
          appBar: AppBar(
            title: TextCustom.subheading(text: l10n.notificationsTitle),
            actions: [
              BlocBuilder<NotificationsCubit, NotificationsState>(
                buildWhen: (a, b) => a.unreadCount != b.unreadCount,
                builder: (context, state) {
                  if (state.unreadCount == 0) return const SizedBox.shrink();
                  return TextButton(
                    onPressed: () =>
                        context.read<NotificationsCubit>().markAllRead(),
                    child: TextCustom(
                      text: l10n.markAllRead,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.colors.primary,
                    ),
                  );
                },
              ),
            ],
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
              final cubit = context.read<NotificationsCubit>();
              return RefreshIndicator(
                color: context.colors.primary,
                onRefresh: cubit.load,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (scroll) {
                    // Near the bottom → fetch the next page (T5). The cubit
                    // ignores the call while loading or after the last page.
                    if (scroll.metrics.pixels >=
                        scroll.metrics.maxScrollExtent - 320) {
                      cubit.loadMore();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      floatingNavBarClearance(context),
                    ),
                    // One extra row for the trailing loader when more pages exist.
                    itemCount: state.items.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= state.items.length) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: context.colors.primary,
                              ),
                            ),
                          ),
                        );
                      }
                      return _NotificationTile(
                        notification: state.items[i],
                        onTap: () => _onTap(context, state.items[i]),
                      );
                    },
                  ),
                ),
              );
            },
          ),
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
    // Every row carries both languages, so a switch re-renders without a
    // refetch — this inbox is a shell tab that survives the trip to the
    // language screen (the server resolved `title`/`body` at fetch time).
    final lang = Localizations.localeOf(context).languageCode;
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
            decoration: BoxDecoration(
              color: context.colors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: context.colors.textSecondary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextCustom(
                  text: notification.titleFor(lang),
                  fontSize: 14,
                  // Unread rows read heavier; read rows settle back.
                  fontWeight: notification.read
                      ? FontWeight.w600
                      : FontWeight.w800,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Bodies are now multi-line — second line carries the order
                // code + mosque name (FLUTTER_TASKS item 15); don't clip it.
                TextCustom(
                  text: notification.bodyFor(lang),
                  fontSize: 13,
                  color: context.colors.textSecondary,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                if (notification.createdAt != null) ...[
                  const SizedBox(height: 6),
                  TextCustom.caption(
                    text: formatShortDateTime(notification.createdAt),
                    fontSize: 11,
                  ),
                ],
              ],
            ),
          ),
          // An unread dot — the quiet signal that pairs with the heavier title.
          if (!notification.read) ...[
            const SizedBox(width: 8),
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: context.colors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

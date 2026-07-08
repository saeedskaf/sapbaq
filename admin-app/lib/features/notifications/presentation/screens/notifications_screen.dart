import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/notifications/notification_deep_link.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/utils/date_format.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/floating_nav_bar.dart';
import 'package:sapbaq_admin/core/widgets/state_views.dart';
import 'package:sapbaq_admin/features/notifications/data/models/app_notification.dart';
import 'package:sapbaq_admin/features/notifications/data/notifications_repository.dart';
import 'package:sapbaq_admin/features/notifications/presentation/bloc/notifications_cubit.dart';
import 'package:sapbaq_admin/features/shared/presentation/app_card.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Notification inbox, shared by both roles. A tap deep-links to the relevant
/// screen (order, destination, approval, or escalation) via the ids in the
/// payload (§14).
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  void _onTap(BuildContext context, AppNotification n) {
    final route = resolveNotificationRoute(
      n.type,
      orderId: n.orderId,
      destinationId: n.destinationId,
      approvalId: n.approvalId,
      escalationId: n.escalationId,
    );
    if (route == null) return;
    context.pushNamed(route.name, pathParameters: route.pathParameters);
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
            final cubit = context.read<NotificationsCubit>();
            return RefreshIndicator(
              color: ColorsCustom.primary,
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
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: ColorsCustom.primary,
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
                // Bodies are now multi-line — second line carries the order
                // code + mosque name (FLUTTER_TASKS item 15); don't clip it.
                TextCustom(
                  text: notification.body,
                  fontSize: 13,
                  color: ColorsCustom.textSecondary,
                  maxLines: 4,
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/notifications/notification_deep_link.dart';
import 'package:sapbaq/core/notifications/push_notification_service.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/date_format.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/notifications/data/models/app_notification.dart';
import 'package:sapbaq/features/notifications/data/notifications_repository.dart';
import 'package:sapbaq/features/notifications/presentation/bloc/notifications_badge_cubit.dart';
import 'package:sapbaq/features/notifications/presentation/bloc/notifications_cubit.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// The notification inbox (opened from the home bell). Each item deep-links to
/// its order when one is attached.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

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
        // Keep the home-screen bell badge in step with the inbox.
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
              switch (state.status) {
                case LoadStatus.initial:
                case LoadStatus.loading:
                  return const LoadingView();
                case LoadStatus.failure:
                  return ErrorView(
                    message: state.message ?? l10n.comingSoon,
                    retryLabel: l10n.retry,
                    onRetry: () => context.read<NotificationsCubit>().load(),
                  );
                case LoadStatus.success:
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
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        physics: const AlwaysScrollableScrollPhysics(),
                        // One extra row for the trailing loader when more pages
                        // remain.
                        itemCount: state.items.length + (state.hasMore ? 1 : 0),
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          if (i >= state.items.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
                          return _NotificationTile(item: state.items[i]);
                        },
                      ),
                    ),
                  );
              }
            },
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification item;
  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final date = formatShortDateTime(item.createdAt);
    // Every row carries both languages, so a switch re-renders without a
    // refetch (the server resolved `title`/`body` for the fetch's language).
    final lang = Localizations.localeOf(context).languageCode;
    // Resolve where this notification points (order / support ticket / inbox).
    // Don't make the tile tappable when it only resolves to this same inbox.
    final route = resolveNotificationRoute(
      item.type,
      orderId: item.orderId,
      ticketId: item.ticketId,
      contributionId: item.contributionId,
      equipmentRequestId: item.equipmentRequestId,
    );
    final tappable = route != null && route.name != AppRoutes.notificationsName;
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Any tap marks the row read (trimming the bell badge); it also
        // navigates when the row deep-links somewhere other than this inbox.
        onTap: () {
          context.read<NotificationsCubit>().markRead(item.id);
          if (tappable) {
            context.pushNamed(
              route.name,
              pathParameters: route.pathParameters,
              queryParameters: route.queryParameters,
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.colors.border, width: 0.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: context.colors.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (!item.read) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: context.colors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: TextCustom(
                            text: item.titleFor(lang),
                            fontSize: 15,
                            // Unread rows read heavier; read rows settle back.
                            fontWeight: item.read
                                ? FontWeight.w600
                                : FontWeight.w800,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (date.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          TextCustom(
                            text: date,
                            fontSize: 11,
                            color: context.colors.textHint,
                          ),
                        ],
                      ],
                    ),
                    if (item.bodyFor(lang).isNotEmpty) ...[
                      TextCustom(
                        text: item.bodyFor(lang),
                        fontSize: 13,
                        color: context.colors.textSecondary,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

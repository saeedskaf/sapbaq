import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/mosques/presentation/bloc/favorites_cubit.dart';
import 'package:sapbaq/features/mosques/presentation/widgets/mosque_card.dart';
import 'package:sapbaq/features/mosques/presentation/widgets/mosque_favorite_button.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// "Favorite mosques" — the user's saved mosques, each with an unfavorite
/// heart. Reads the app-wide [FavoritesCubit] and refreshes on entry.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<FavoritesCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: TextCustom.subheading(text: l10n.favoritesTitle)),
      body: BlocConsumer<FavoritesCubit, FavoritesState>(
        listenWhen: (a, b) => b.message != null && a.message != b.message,
        listener: (context, state) => ShowMessage.error(context, state.message!),
        builder: (context, state) {
          if (state.status == LoadStatus.loading && state.mosques.isEmpty) {
            return const LoadingView();
          }
          if (state.status == LoadStatus.failure && state.mosques.isEmpty) {
            return ErrorView(
              message: state.message ?? l10n.comingSoon,
              retryLabel: l10n.retry,
              onRetry: () => context.read<FavoritesCubit>().load(),
            );
          }
          if (state.mosques.isEmpty) {
            return EmptyView(
              message: l10n.emptyFavorites,
              icon: Icons.favorite_border_rounded,
            );
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            itemCount: state.mosques.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final mosque = state.mosques[i];
              return MosqueCard(
                mosque: mosque,
                onTap: () => context.pushNamed(
                  AppRoutes.mosqueDetailName,
                  pathParameters: {'id': '${mosque.id}'},
                ),
                trailing: MosqueFavoriteButton(mosque: mosque),
              );
            },
          );
        },
      ),
    );
  }
}

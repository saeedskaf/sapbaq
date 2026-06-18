import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/auth/auth_guard.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/features/mosques/data/models/mosque.dart';
import 'package:sapbaq/features/mosques/presentation/bloc/favorites_cubit.dart';

/// Heart toggle for a mosque. Reflects the app-wide [FavoritesCubit] and
/// toggles on tap (prompting login for guests).
class MosqueFavoriteButton extends StatelessWidget {
  final Mosque mosque;
  final double size;

  const MosqueFavoriteButton({super.key, required this.mosque, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoritesCubit, FavoritesState>(
      buildWhen: (a, b) =>
          a.ids.contains(mosque.id) != b.ids.contains(mosque.id),
      builder: (context, state) {
        final isFavorite = state.ids.contains(mosque.id);
        return IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () {
            if (ensureAuthenticated(context)) {
              context.read<FavoritesCubit>().toggle(mosque);
            }
          },
          icon: Icon(
            isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: isFavorite
                ? Theme.of(context).colorScheme.error
                : context.colors.textHint,
            size: size,
          ),
        );
      },
    );
  }
}

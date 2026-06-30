import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/floating_nav_bar.dart';
import 'package:sapbaq_admin/features/auth/data/models/user.dart';
import 'package:sapbaq_admin/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq_admin/features/shared/presentation/app_card.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Shared profile tab: an identity header, then a logout action.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: TextCustom.subheading(text: l10n.profileTitle)),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              floatingNavBarClearance(context),
            ),
            children: [
              _IdentityCard(user: user),
              const SizedBox(height: 16),
              _LogoutTile(
                onTap: () =>
                    context.read<AuthBloc>().add(const AuthLogoutRequested()),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final User? user;
  const _IdentityCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final u = user;
    final name = u?.fullName ?? '';
    final phone = u?.phone ?? '';
    final role = u?.roleDisplay ?? '';
    final governorate = u?.governorate?.name ?? '';

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: ColorsCustom.secondaryLight,
              shape: BoxShape.circle,
            ),
            child: name.isEmpty
                ? const Icon(
                    Icons.person_rounded,
                    size: 30,
                    color: ColorsCustom.primary,
                  )
                : TextCustom(
                    text: name.characters.first,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: ColorsCustom.primary,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextCustom(
                  text: name.isEmpty ? 'مستخدم' : name,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (role.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  TextCustom(
                    text: governorate.isEmpty ? role : '$role · $governorate',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ColorsCustom.primary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  TextCustom(
                    text: phone,
                    fontSize: 13,
                    color: ColorsCustom.textSecondary,
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

class _LogoutTile extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ColorsCustom.error.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: ColorsCustom.error,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextCustom(
              text: l10n.logout,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: ColorsCustom.error,
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: ColorsCustom.textHint,
            size: 22,
          ),
        ],
      ),
    );
  }
}

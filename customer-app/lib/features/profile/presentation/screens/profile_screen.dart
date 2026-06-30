import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/core/network/session_manager.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/form_validators.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_form_field.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';
import 'package:sapbaq/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq/features/support/presentation/bloc/support_unread_cubit.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// "حسابي" tab — a clean settings-style screen: a compact identity header
/// at the top, then content grouped into bordered "tile cards" with hairline
/// dividers between rows. Destructive actions (logout / delete account)
/// live in their own group at the bottom.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _editProfile(
    BuildContext context,
    String currentName,
    String currentEmail,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      // Present on the root navigator so the sheet sits above the floating nav
      // bar and cart bar (which live in the shell scaffold) instead of behind.
      useRootNavigator: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditProfileSheet(
        initialName: currentName,
        initialEmail: currentEmail,
      ),
    );
    if (updated == true && context.mounted) {
      ShowMessage.success(context, l10n.profileUpdated);
    }
  }

  void _confirmDeleteAccount(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _DeleteAccountSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: TextCustom(
          text: l10n.profileTitle,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: context.colors.textPrimary,
        ),
        iconTheme: IconThemeData(color: context.colors.textPrimary),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state.status == AuthStatus.guest) {
            return const _GuestProfileView();
          }
          final name = state.user?.fullName ?? '';
          final phone = state.user?.phone ?? '';
          final email = state.user?.email ?? '';
          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              4,
              16,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            children: [
              _IdentityCard(
                name: name,
                phone: phone,
                email: email,
                onEdit: () => _editProfile(context, name, email),
              ),
              const SizedBox(height: 22),
              _SectionLabel(l10n.accountSection),
              const SizedBox(height: 8),
              _TilesGroup(
                tiles: [
                  // _TileData(
                  //   icon: Icons.location_on_outlined,
                  //   label: l10n.addressesTitle,
                  //   onTap: () => context.pushNamed(AppRoutes.addressesName),
                  // ),
                  _TileData(
                    icon: Icons.favorite_border_rounded,
                    label: l10n.favoritesTitle,
                    onTap: () => context.pushNamed(AppRoutes.favoritesName),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _SectionLabel(l10n.settingsSection),
              const SizedBox(height: 8),
              _TilesGroup(
                tiles: [
                  _TileData(
                    icon: Icons.language_rounded,
                    label: l10n.languageTitle,
                    onTap: () => context.pushNamed(AppRoutes.languageName),
                  ),
                  _TileData(
                    icon: Icons.brightness_6_outlined,
                    label: l10n.appearanceTitle,
                    onTap: () => context.pushNamed(AppRoutes.appearanceName),
                  ),
                  _TileData(
                    icon: Icons.notifications_none_rounded,
                    label: l10n.notificationPrefsTitle,
                    onTap: () =>
                        context.pushNamed(AppRoutes.notificationPrefsName),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _SectionLabel(l10n.profileHelpSection),
              const SizedBox(height: 8),
              _TilesGroup(
                tiles: [
                  _TileData(
                    icon: Icons.help_outline_rounded,
                    label: l10n.profileFaq,
                    onTap: () => context.pushNamed(AppRoutes.faqName),
                  ),
                  _TileData(
                    icon: Icons.headset_mic_outlined,
                    label: l10n.profileContact,
                    onTap: () => context.pushNamed(AppRoutes.contactName),
                  ),
                  _TileData(
                    icon: Icons.info_outline_rounded,
                    label: l10n.profileAbout,
                    onTap: () => context.pushNamed(AppRoutes.aboutName),
                  ),
                  _TileData(
                    icon: Icons.privacy_tip_outlined,
                    label: l10n.profilePrivacy,
                    onTap: () => context.pushNamed(AppRoutes.privacyName),
                  ),
                  _TileData(
                    icon: Icons.description_outlined,
                    label: l10n.profileTerms,
                    onTap: () => context.pushNamed(AppRoutes.termsName),
                  ),
                  _TileData(
                    icon: Icons.support_agent_outlined,
                    label: l10n.supportTitle,
                    onTap: () => context.pushNamed(AppRoutes.supportName),
                    trailing: const _SupportBadge(),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _TilesGroup(
                tiles: [
                  _TileData(
                    icon: Icons.logout_rounded,
                    label: l10n.logout,
                    destructive: true,
                    onTap: () => context.read<AuthBloc>().add(
                      const AuthLogoutRequested(),
                    ),
                  ),
                  _TileData(
                    icon: Icons.delete_outline_rounded,
                    label: l10n.deleteAccount,
                    destructive: true,
                    onTap: () => _confirmDeleteAccount(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }
}

/// Compact identity card at the top of the profile: avatar (initial or icon),
/// name + phone, and a circular edit-name button on the trailing edge.
class _IdentityCard extends StatelessWidget {
  final String name;
  final String phone;
  final String email;
  final VoidCallback onEdit;

  const _IdentityCard({
    required this.name,
    required this.phone,
    required this.email,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: name.isEmpty
                ? Icon(
                    Icons.person_rounded,
                    size: 30,
                    color: context.colors.primary,
                  )
                : TextCustom(
                    text: name.characters.first,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: context.colors.primary,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextCustom(
                  text: name.isEmpty ? l10n.defaultUserName : name,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: context.colors.textPrimary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  TextCustom(
                    text: phone,
                    fontSize: 13,
                    color: context.colors.textSecondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  TextCustom(
                    text: email,
                    fontSize: 13,
                    color: context.colors.textSecondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: context.colors.surfaceVariant,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onEdit,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: context.colors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small section header — uppercase-feeling caption that introduces a tile
/// group, mirrored to a tiny RTL-friendly indent.
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 6),
      child: TextCustom(
        text: text,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: context.colors.textHint,
      ),
    );
  }
}

/// Data record for one row in a [_TilesGroup].
class _TileData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  /// Optional widget shown just before the trailing chevron (e.g. a badge).
  final Widget? trailing;

  const _TileData({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
    this.trailing,
  });
}

/// A bordered surface card that holds a list of profile tiles separated by
/// hairline dividers — keeps related actions visually grouped.
class _TilesGroup extends StatelessWidget {
  final List<_TileData> tiles;

  const _TilesGroup({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.border, width: 1),
      ),
      child: Column(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            _ProfileTile(data: tiles[i]),
            if (i < tiles.length - 1)
              Padding(
                padding: EdgeInsetsDirectional.only(start: 64),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: context.colors.border,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// A single profile row: an icon chip on the leading edge, the label, and a
/// directional chevron on the trailing edge. Destructive rows tint the icon
/// chip + text red.
class _ProfileTile extends StatelessWidget {
  final _TileData data;

  const _ProfileTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final fg = data.destructive
        ? ColorsCustom.error
        : context.colors.textPrimary;
    final iconFg = data.destructive
        ? ColorsCustom.error
        : context.colors.primary;
    final iconBg = data.destructive
        ? ColorsCustom.error.withValues(alpha: 0.10)
        : context.colors.primaryTint;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: iconFg, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextCustom(
                  text: data.label,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: fg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (data.trailing != null) ...[
                data.trailing!,
                const SizedBox(width: 8),
              ],
              Icon(
                Icons.chevron_right_rounded,
                color: context.colors.textHint,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Edit-name sheet
// ────────────────────────────────────────────────────────────────────────────

/// Bottom sheet to edit the user's name and email. Pops `true` on success so
/// the caller can surface a confirmation on the profile scaffold.
class _EditProfileSheet extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  const _EditProfileSheet({
    required this.initialName,
    required this.initialEmail,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController = TextEditingController(
    text: widget.initialName,
  );
  late final TextEditingController _emailController = TextEditingController(
    text: widget.initialEmail,
  );
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final navigator = Navigator.of(context);
    final repo = context.read<AuthRepository>();
    final authBloc = context.read<AuthBloc>();

    setState(() => _busy = true);
    try {
      await repo.updateProfile(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
      );
      authBloc.add(const AuthUserRefreshed());
      if (!mounted) return;
      navigator.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ShowMessage.error(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final validators = FormValidators(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextCustom.subheading(text: l10n.editProfile),
            const SizedBox(height: 16),
            FormFieldCustom(
              controller: _nameController,
              label: l10n.fullNameLabel,
              validator: validators.fullNameValidator,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            FormFieldCustom(
              controller: _emailController,
              label: l10n.emailLabel,
              keyboardType: TextInputType.emailAddress,
              validator: validators.emailValidator,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 20),
            ButtonCustom.primary(
              text: l10n.saveButton,
              isLoading: _busy,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Delete-account sheet
// ────────────────────────────────────────────────────────────────────────────

/// Bottom sheet for permanent account deletion. Requires the user's password
/// (the backend's second confirmation on top of the JWT). Performs the deletion
/// itself; on success the session change redirects to login.
class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet();

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _busy = false;
  String? _serverError;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final navigator = Navigator.of(context);
    final repo = context.read<AuthRepository>();
    setState(() => _busy = true);
    try {
      await repo.deleteAccount(password: _passwordController.text);
      if (mounted) navigator.pop();
      // Session is now unauthenticated → the router redirects to login.
    } on ApiException catch (e) {
      if (!mounted) return;
      final fieldError = e.fieldError('password');
      setState(() {
        _busy = false;
        _serverError = fieldError;
      });
      if (fieldError != null) {
        _formKey.currentState?.validate();
      } else {
        ShowMessage.error(context, e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(
                  Icons.delete_outline_rounded,
                  color: ColorsCustom.error,
                  size: 24,
                ),
                const SizedBox(width: 8),
                TextCustom.subheading(
                  text: l10n.deleteAccount,
                  color: ColorsCustom.error,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextCustom(
              text: l10n.deleteAccountConfirmBody,
              fontSize: 14,
              color: context.colors.textSecondary,
            ),
            const SizedBox(height: 12),
            _DeleteBullet(text: l10n.deleteAccountWhatRemoved),
            const SizedBox(height: 6),
            _DeleteBullet(text: l10n.deleteAccountWhatKept),
            const SizedBox(height: 18),
            FormFieldCustom(
              controller: _passwordController,
              label: l10n.passwordLabel,
              isPassword: true,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                if (_serverError != null) setState(() => _serverError = null);
              },
              onSubmitted: (_) => _delete(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.passwordRequired;
                }
                return _serverError;
              },
            ),
            const SizedBox(height: 20),
            ButtonCustom(
              text: l10n.deleteAccountConfirm,
              color: ColorsCustom.error,
              textColor: ColorsCustom.textOnPrimary,
              isLoading: _busy,
              onPressed: _delete,
            ),
            const SizedBox(height: 10),
            ButtonCustom.secondary(
              text: l10n.cancelButton,
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteBullet extends StatelessWidget {
  final String text;
  const _DeleteBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 7),
          child: Icon(Icons.circle, size: 5, color: context.colors.textHint),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextCustom(
            text: text,
            fontSize: 13,
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Guest profile view
// ────────────────────────────────────────────────────────────────────────────

/// Profile tab for a guest: a sign-in / create-account hero card plus the
/// public info pages (guests can still read About / Contact / Privacy /
/// Terms / FAQ).
class _GuestProfileView extends StatelessWidget {
  const _GuestProfileView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        4,
        16,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: ColorsCustom.brandGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ColorsCustom.textOnPrimary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: ColorsCustom.textOnPrimary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              TextCustom.heading(
                text: l10n.guestWelcomeTitle,
                color: ColorsCustom.textOnPrimary,
                fontSize: 20,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              TextCustom(
                text: l10n.guestWelcomeDesc,
                color: context.colors.primaryTint,
                fontSize: 14,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              ButtonCustom(
                text: l10n.loginButton,
                color: context.colors.surface,
                textColor: context.colors.primary,
                onPressed: () => context.pushNamed(AppRoutes.loginName),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => context.pushNamed(AppRoutes.signupName),
                child: TextCustom(
                  text: l10n.createAccountLink,
                  color: ColorsCustom.textOnPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _SectionLabel(l10n.settingsSection),
        const SizedBox(height: 8),
        _TilesGroup(
          tiles: [
            _TileData(
              icon: Icons.language_rounded,
              label: l10n.languageTitle,
              onTap: () => context.pushNamed(AppRoutes.languageName),
            ),
            _TileData(
              icon: Icons.brightness_6_outlined,
              label: l10n.appearanceTitle,
              onTap: () => context.pushNamed(AppRoutes.appearanceName),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _SectionLabel(l10n.profileHelpSection),
        const SizedBox(height: 8),
        _TilesGroup(
          tiles: [
            _TileData(
              icon: Icons.help_outline_rounded,
              label: l10n.profileFaq,
              onTap: () => context.pushNamed(AppRoutes.faqName),
            ),
            _TileData(
              icon: Icons.headset_mic_outlined,
              label: l10n.profileContact,
              onTap: () => context.pushNamed(AppRoutes.contactName),
            ),
            _TileData(
              icon: Icons.info_outline_rounded,
              label: l10n.profileAbout,
              onTap: () => context.pushNamed(AppRoutes.aboutName),
            ),
            _TileData(
              icon: Icons.privacy_tip_outlined,
              label: l10n.profilePrivacy,
              onTap: () => context.pushNamed(AppRoutes.privacyName),
            ),
            _TileData(
              icon: Icons.description_outlined,
              label: l10n.profileTerms,
              onTap: () => context.pushNamed(AppRoutes.termsName),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// Red count badge on the Support row, fed by the app-wide [SupportUnreadCubit].
class _SupportBadge extends StatelessWidget {
  const _SupportBadge();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SupportUnreadCubit, int>(
      builder: (context, count) {
        if (count <= 0) return const SizedBox.shrink();
        return Container(
          constraints: const BoxConstraints(minWidth: 20),
          height: 20,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ColorsCustom.error,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextCustom(
            text: '$count',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        );
      },
    );
  }
}

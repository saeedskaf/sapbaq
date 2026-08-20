import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/message_dialog.dart';
import 'package:sapbaq_admin/features/mosques/presentation/widgets/mosque_browse_sheet.dart';
import 'package:sapbaq_admin/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// The mosque a direct-provision form is being filed for.
typedef PickedMosque = ({int id, String name});

/// A bold field label above an input, matching [FormFieldCustom]'s own label.
class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
    child: TextCustom(text: text, fontSize: 14, fontWeight: FontWeight.w700),
  );
}

/// The mosque picker as a form field: shows the chosen mosque (or a hint) and
/// opens the shared governorate → area → mosque browser on tap.
///
/// A regional manager's browser is pinned to his own governorate — filing for a
/// mosque outside it is refused server-side with a 403, so it should never be
/// offered in the first place. A global admin (no governorate of his own)
/// browses all of them.
class MosqueField extends StatelessWidget {
  final PickedMosque? value;
  final ValueChanged<PickedMosque> onChanged;
  final bool enabled;

  const MosqueField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  Future<void> _pick(BuildContext context) async {
    final governorate = context.read<AuthBloc>().state.user?.governorate?.name;
    final picked = await showMosqueBrowseSheet(
      context,
      pinnedGovernorate: governorate,
    );
    if (picked != null) onChanged((id: picked.id, name: picked.name));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chosen = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(l10n.dpMosque),
        InkWell(
          onTap: enabled ? () => _pick(context) : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: context.colors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.colors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.mosque_outlined, color: context.colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: TextCustom(
                    text: chosen?.name ?? l10n.chooseMosque,
                    fontSize: 14,
                    fontWeight: chosen == null
                        ? FontWeight.w500
                        : FontWeight.w700,
                    color: chosen == null
                        ? context.colors.textHint
                        : context.colors.textPrimary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: context.colors.textHint,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The `+` shortcut a queue screen carries so a manager can raise that queue's
/// need without going back through the hub. Renders nothing for roles that
/// can't provision directly. [onCreated] runs only when a need was actually
/// created, so the queue refreshes and the new row is there.
class DirectProvisionFab extends StatelessWidget {
  final String routeName;
  final String tooltip;
  final VoidCallback onCreated;

  const DirectProvisionFab({
    super.key,
    required this.routeName,
    required this.tooltip,
    required this.onCreated,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    if (user?.canProvisionDirect != true) return const SizedBox.shrink();
    return FloatingActionButton(
      tooltip: tooltip,
      backgroundColor: context.colors.primaryFill,
      onPressed: () async {
        final created = await context.pushNamed<Object?>(routeName);
        if (created == true) onCreated();
      },
      child: Icon(
        Icons.add_rounded,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}

/// A capped grid of picked photos with camera/gallery add tiles. Images are
/// downscaled on capture so uploads stay under the server's 5MB per-file cap.
class PhotoPickerField extends StatelessWidget {
  final List<String> paths;
  final int maxPhotos;
  final bool enabled;
  final ValueChanged<String> onAdd;
  final ValueChanged<int> onRemove;
  final String label;
  final String hint;

  const PhotoPickerField({
    super.key,
    required this.paths,
    required this.onAdd,
    required this.onRemove,
    required this.label,
    required this.hint,
    this.maxPhotos = 5,
    this.enabled = true,
  });

  Future<void> _add(BuildContext context, ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    if (paths.length >= maxPhotos) {
      ShowMessage.info(context, l10n.mtPhotosMax(maxPhotos));
      return;
    }
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1600,
      );
      if (file != null) onAdd(file.path);
    } catch (_) {
      if (context.mounted) ShowMessage.error(context, l10n.pickFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = enabled && paths.length < maxPhotos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FieldLabel(label),
            const SizedBox(width: 8),
            TextCustom(
              text: hint,
              fontSize: 12,
              color: context.colors.textHint,
            ),
          ],
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < paths.length; i++)
              _Thumb(
                path: paths[i],
                onRemove: enabled ? () => onRemove(i) : null,
              ),
            if (canAdd) ...[
              _AddTile(
                icon: Icons.photo_camera_rounded,
                onTap: () => _add(context, ImageSource.camera),
              ),
              _AddTile(
                icon: Icons.photo_library_rounded,
                onTap: () => _add(context, ImageSource.gallery),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  final String path;
  final VoidCallback? onRemove;
  const _Thumb({required this.path, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(path),
            width: 76,
            height: 76,
            fit: BoxFit.cover,
          ),
        ),
        if (onRemove != null)
          PositionedDirectional(
            top: -6,
            end: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: ColorsCustom.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.surface, width: 1.5),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: ColorsCustom.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AddTile({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: context.colors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.border, width: 0.8),
        ),
        child: Icon(icon, color: context.colors.textSecondary, size: 26),
      ),
    );
  }
}

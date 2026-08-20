import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/utils/media_url.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/in_app_media.dart';
import 'package:sapbaq_admin/features/shared/data/models/delivery_proof.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';

/// A delivery-proof strip for one destination (or order-level): a small header
/// and a horizontal row of tappable thumbnails, followed by the handler's
/// upload-time note(s). Images open in the in-app zoom viewer; videos and audio
/// play in the in-app player. Shared by the admin order detail and the driver
/// destination detail so both see identical proofs and notes.
class DeliveryProofStrip extends StatelessWidget {
  final List<DeliveryProof> proofs;
  const DeliveryProofStrip({super.key, required this.proofs});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_rounded,
                size: 16,
                color: context.colors.primary,
              ),
              const SizedBox(width: 6),
              TextCustom(
                text: l10n.deliveryProofs,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.colors.primary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: proofs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) =>
                  _ProofThumb(proof: proofs[i], siblings: proofs),
            ),
          ),
          // The handler's note written at upload time (FLUTTER_TASKS item 6),
          // shown once per distinct note so it also covers video/audio proofs.
          for (final note in {
            for (final p in proofs)
              if (p.note.trim().isNotEmpty) p.note.trim(),
          }) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.sticky_note_2_outlined,
                  size: 14,
                  color: context.colors.textHint,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextCustom(
                    text: note,
                    fontSize: 12.5,
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProofThumb extends StatelessWidget {
  final DeliveryProof proof;

  /// The whole strip this thumb belongs to: a tapped photo opens as one
  /// swipeable set, so a reviewer flips through the delivery's photos in the
  /// viewer instead of closing it after each one.
  final List<DeliveryProof> siblings;

  const _ProofThumb({required this.proof, required this.siblings});

  void _open(BuildContext context) {
    if (proof.isImage) {
      // No captions: the note belongs to the whole delivery (there can be
      // several photos) and is already shown once in the proofs section, so we
      // don't repeat it over each image.
      final photos = siblings.where((p) => p.isImage).toList();
      openInAppImageGallery(
        context,
        urls: [for (final p in photos) p.file],
        initialIndex: photos.indexOf(proof),
      );
    } else {
      // Video and audio both play in the in-app player.
      openInAppVideo(context, proof.file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = resolveMediaUrl(proof.file);
    return GestureDetector(
      onTap: url == null ? null : () => _open(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (proof.isImage && url != null)
                Image.network(
                  url,
                  fit: BoxFit.cover,
                  // Camera-sized uploads in an 80px tile — decode to the tile.
                  cacheWidth: (80 * MediaQuery.devicePixelRatioOf(context))
                      .round(),
                  errorBuilder: (_, _, _) =>
                      const _ProofPlaceholder(icon: Icons.image_outlined),
                )
              else if (proof.isVideo)
                const _ProofPlaceholder(icon: Icons.videocam_rounded)
              else
                const _ProofPlaceholder(icon: Icons.audiotrack_rounded),
              if (!proof.isImage) const Center(child: _PlayDot()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tinted box with a media-type icon, behind videos/audio and image fallbacks.
class _ProofPlaceholder extends StatelessWidget {
  final IconData icon;
  const _ProofPlaceholder({required this.icon});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colors.surfaceVariant,
      child: Icon(icon, color: context.colors.textHint, size: 28),
    );
  }
}

/// Small play badge centered on a video/audio thumbnail.
class _PlayDot extends StatelessWidget {
  const _PlayDot();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: ColorsCustom.scrim,
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: EdgeInsets.all(5),
        child: Icon(
          Icons.play_arrow_rounded,
          color: ColorsCustom.white,
          size: 20,
        ),
      ),
    );
  }
}

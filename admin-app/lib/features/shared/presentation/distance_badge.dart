import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/location/location_for_role.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/utils/distance.dart';
import 'package:sapbaq_admin/core/utils/maps_launcher.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/message_dialog.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// How far the row's mosque is from the user, shown only on a queue that came
/// back sorted nearest-first.
///
/// Three states, per the sorting doc §7:
/// - a distance → "1.5 كم";
/// - no distance but we did send a position → the mosque has no coordinates,
///   so say so (the server puts those rows last);
/// - the queue isn't sorted at all → nothing, which is the office roles' case.
class DistanceBadge extends StatelessWidget {
  final double? distanceKm;

  /// Whether the list this row belongs to was sorted by distance.
  final bool sorted;

  /// Renders "أقرب وجهة: 1.5 كم" instead of the bare distance — for an order
  /// row, where the number is its nearest destination, not the row itself.
  final bool nearestOfMany;

  const DistanceBadge({
    super.key,
    required this.distanceKm,
    required this.sorted,
    this.nearestOfMany = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!sorted) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final km = distanceKm;
    final unknown = km == null;
    final formatted = unknown ? '' : formatDistanceKm(km);
    if (!unknown && formatted.isEmpty) return const SizedBox.shrink();

    final label = unknown
        ? l10n.locUnavailable
        : (nearestOfMany
              ? l10n.locNearestDestination(formatted)
              : l10n.locDistanceKm(formatted));
    final color = unknown ? context.colors.textHint : context.colors.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          unknown ? Icons.location_off_outlined : Icons.near_me_rounded,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        TextCustom(
          text: label,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ],
    );
  }
}

/// A compact "directions" button that opens a mosque's ready-made `maps_url`
/// in the device's maps app. Renders nothing when the mosque has no link.
class DirectionsButton extends StatelessWidget {
  final String? mapsUrl;
  const DirectionsButton({super.key, required this.mapsUrl});

  @override
  Widget build(BuildContext context) {
    final url = mapsUrl;
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      tooltip: l10n.locDirections,
      visualDensity: VisualDensity.compact,
      icon: Icon(
        Icons.directions_rounded,
        size: 20,
        color: context.colors.primary,
      ),
      onPressed: () async {
        final opened = await openMapsUrl(url);
        if (!opened && context.mounted) {
          ShowMessage.error(context, l10n.noLocation);
        }
      },
    );
  }
}

/// The one-line note under a queue's filter bar telling the user why the order
/// looks the way it does — and, when the permission is blocked, how to fix it.
/// Says "straight-line estimate" once here instead of on every row (§7.4).
class NearestFirstHint extends StatelessWidget {
  final bool sorted;

  const NearestFirstHint({super.key, required this.sorted});

  @override
  Widget build(BuildContext context) {
    // Only a field role can be "blocked" — for everyone else there was never a
    // prompt, so there's nothing to explain and nothing to enable.
    final service = sorted ? null : locationForRole(context);
    final blocked = service?.isBlocked ?? false;
    if (!sorted && !blocked) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final text = sorted ? l10n.locSortedByDistance : l10n.locEnableHint;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        onTap: sorted ? null : service?.openSettings,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            Icon(
              sorted ? Icons.near_me_rounded : Icons.location_disabled_rounded,
              size: 14,
              color: context.colors.textHint,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextCustom(
                text: text,
                fontSize: 11.5,
                color: context.colors.textHint,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

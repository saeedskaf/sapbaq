import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/cart/data/models/donation_destination.dart';
import 'package:sapbaq/features/mosques/data/models/mosque.dart';
import 'package:sapbaq/features/mosques/data/mosques_repository.dart';
import 'package:sapbaq/features/mosques/presentation/bloc/mosque_detail_cubit.dart';
import 'package:sapbaq/features/mosques/presentation/widgets/mosque_favorite_button.dart';
import 'package:sapbaq/features/mosques/presentation/widgets/mosque_marker_icon.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Mosque details — clean and simple: a header (mosque glyph + name + area), a
/// rounded map preview as the visual anchor, then a single flat info card
/// (address + notes). A favorite heart sits in the app bar and the bottom CTA
/// opens the products flow with this mosque as the destination.
class MosqueDetailScreen extends StatelessWidget {
  final int mosqueId;

  const MosqueDetailScreen({super.key, required this.mosqueId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (context) =>
          MosqueDetailCubit(context.read<MosquesRepository>())..load(mosqueId),
      child: Scaffold(
        backgroundColor: context.colors.background,
        appBar: AppBar(
          backgroundColor: context.colors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: [
            BlocBuilder<MosqueDetailCubit, MosqueDetailState>(
              builder: (context, state) {
                final mosque = state.mosque;
                if (mosque == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 4),
                  child: MosqueFavoriteButton(mosque: mosque, size: 24),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<MosqueDetailCubit, MosqueDetailState>(
          builder: (context, state) {
            switch (state.status) {
              case LoadStatus.initial:
              case LoadStatus.loading:
                return const LoadingView();
              case LoadStatus.failure:
                return ErrorView(
                  message: state.message ?? l10n.comingSoon,
                  retryLabel: l10n.retry,
                  onRetry: () =>
                      context.read<MosqueDetailCubit>().load(mosqueId),
                );
              case LoadStatus.success:
                return _MosqueDetailBody(mosque: state.mosque!);
            }
          },
        ),
        bottomNavigationBar: BlocBuilder<MosqueDetailCubit, MosqueDetailState>(
          builder: (context, state) {
            if (state.status != LoadStatus.success) {
              return const SizedBox.shrink();
            }
            final mosque = state.mosque!;
            return SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: ButtonCustom.primary(
                text: l10n.donateToThisMosque,
                icon: const Icon(Icons.water_drop_rounded, size: 20),
                onPressed: () => context.pushNamed(
                  AppRoutes.productsName,
                  extra: DonationDestination.mosque(
                    mosqueId: mosque.id,
                    label: mosque.name,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MosqueDetailBody extends StatelessWidget {
  final Mosque mosque;
  const _MosqueDetailBody({required this.mosque});

  @override
  Widget build(BuildContext context) {
    final hasAddress = mosque.address.isNotEmpty;
    final hasNotes = (mosque.notes ?? '').isNotEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(mosque: mosque),
          if (mosque.hasLocation) ...[
            const SizedBox(height: 24),
            _MapPreview(mosque: mosque),
          ],
          if (hasAddress || hasNotes) ...[
            const SizedBox(height: 20),
            _InfoCard(mosque: mosque),
          ],
        ],
      ),
    );
  }
}

/// Title block: a tinted mosque glyph (the visual anchor now that there's no
/// photo), the name, and the area on a line with a location pin.
class _Header extends StatelessWidget {
  final Mosque mosque;
  const _Header({required this.mosque});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 58,
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.colors.primaryTint,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            Icons.mosque_rounded,
            size: 30,
            color: context.colors.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextCustom(
                text: mosque.name,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: context.colors.textPrimary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (mosque.area.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 15,
                      color: context.colors.primary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: TextCustom(
                        text: mosque.area,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: context.colors.primary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A single flat card grouping the textual details (address, notes), each as an
/// icon + label + value row, divided by a hairline.
class _InfoCard extends StatelessWidget {
  final Mosque mosque;
  const _InfoCard({required this.mosque});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasAddress = mosque.address.isNotEmpty;
    final notes = mosque.notes ?? '';
    final hasNotes = notes.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.border, width: 0.6),
      ),
      child: Column(
        children: [
          if (hasAddress)
            _InfoTile(
              icon: Icons.location_on_rounded,
              label: l10n.addressLabel,
              value: mosque.address,
            ),
          if (hasAddress && hasNotes)
            Divider(height: 1, color: context.colors.border),
          if (hasNotes)
            _InfoTile(
              icon: Icons.sticky_note_2_outlined,
              label: l10n.notesLabel,
              value: notes,
            ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colors.primaryTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: context.colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextCustom(
                  text: label,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textHint,
                ),
                const SizedBox(height: 3),
                TextCustom(
                  text: value,
                  fontSize: 14.5,
                  color: context.colors.textPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A rounded, non-interactive map centered on the mosque — the screen's visual
/// anchor. Tapping it opens the full mosques map focused here.
class _MapPreview extends StatefulWidget {
  final Mosque mosque;
  const _MapPreview({required this.mosque});

  @override
  State<_MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<_MapPreview> {
  BitmapDescriptor? _icon;

  @override
  void initState() {
    super.initState();
    // Defer the bitmap build until we have the device pixel ratio (available
    // once the widget tree is laid out).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ratio = MediaQuery.of(context).devicePixelRatio;
      final icon = await MosqueMarkerIcon.build(devicePixelRatio: ratio);
      if (mounted) setState(() => _icon = icon);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mosque = widget.mosque;
    return GestureDetector(
      onTap: () => context.goNamed(
        AppRoutes.mosquesName,
        queryParameters: {
          'lat': '${mosque.latitude}',
          'lng': '${mosque.longitude}',
        },
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 220,
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(mosque.latitude!, mosque.longitude!),
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: MarkerId('${mosque.id}'),
                        position: LatLng(mosque.latitude!, mosque.longitude!),
                        icon: _icon ?? BitmapDescriptor.defaultMarker,
                        anchor: const Offset(0.5, 0.5),
                      ),
                    },
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                ),
              ),
              PositionedDirectional(
                bottom: 10,
                end: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.open_in_full_rounded,
                        size: 14,
                        color: context.colors.primary,
                      ),
                      const SizedBox(width: 6),
                      TextCustom(
                        text: l10n.viewOnMap,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.colors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

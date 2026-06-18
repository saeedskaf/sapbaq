import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/cart/data/models/donation_destination.dart';
import 'package:sapbaq/features/mosques/data/models/mosque.dart';
import 'package:sapbaq/features/mosques/data/mosques_repository.dart';
import 'package:sapbaq/features/mosques/presentation/bloc/mosque_detail_cubit.dart';
import 'package:sapbaq/features/mosques/presentation/widgets/mosque_marker_icon.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Mosque details: a compact rounded image (when available), the name + area
/// chip, an address card, and a tappable map preview. The bottom CTA opens
/// the products flow with this mosque as the destination.
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
                icon: const Icon(
                  Icons.water_drop_rounded,
                  color: ColorsCustom.textOnPrimary,
                  size: 20,
                ),
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
    final hasImage = mosque.image != null && mosque.image!.isNotEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasImage) ...[
            _CoverImage(url: mosque.image!),
            const SizedBox(height: 20),
          ],
          _HeaderCard(mosque: mosque),
          if (mosque.address.isNotEmpty || mosque.area.isNotEmpty) ...[
            const SizedBox(height: 14),
            _AddressCard(area: mosque.area, address: mosque.address),
          ],
          if (mosque.hasLocation) ...[
            const SizedBox(height: 14),
            _MapCard(mosque: mosque),
          ],
        ],
      ),
    );
  }
}

/// A compact rounded image card — sized to suggest "this is what the mosque
/// looks like" without dominating the page.
class _CoverImage extends StatelessWidget {
  final String url;
  const _CoverImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : ColoredBox(color: context.colors.surfaceVariant),
          errorBuilder: (_, _, _) => ColoredBox(
            color: context.colors.surfaceVariant,
            child: Icon(
              Icons.mosque_rounded,
              size: 56,
              color: context.colors.textHint,
            ),
          ),
        ),
      ),
    );
  }
}

/// Mosque name on its own — large, centered card with nothing else competing
/// for attention.
class _HeaderCard extends StatelessWidget {
  final Mosque mosque;
  const _HeaderCard({required this.mosque});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextCustom(
        text: mosque.name,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: context.colors.textPrimary,
      ),
    );
  }
}

/// Section card with an icon-chip header and arbitrary body content. Used
/// for the address and the map preview so every section feels consistent.
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.primaryTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: context.colors.primary),
              ),
              const SizedBox(width: 10),
              TextCustom(
                text: title,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: context.colors.textPrimary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final String area;
  final String address;
  const _AddressCard({required this.area, required this.address});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _SectionCard(
      icon: Icons.location_on_rounded,
      title: l10n.addressLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (area.isNotEmpty)
            TextCustom(
              text: area,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.colors.primary,
            ),
          if (area.isNotEmpty && address.isNotEmpty)
            const SizedBox(height: 6),
          if (address.isNotEmpty)
            TextCustom(
              text: address,
              fontSize: 15,
              color: context.colors.textPrimary,
            ),
        ],
      ),
    );
  }
}

/// Section card containing a non-interactive map preview centered on the
/// mosque. Tapping the whole card opens the full mosques map focused here.
class _MapCard extends StatefulWidget {
  final Mosque mosque;
  const _MapCard({required this.mosque});

  @override
  State<_MapCard> createState() => _MapCardState();
}

class _MapCardState extends State<_MapCard> {
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
    return _SectionCard(
      icon: Icons.map_rounded,
      title: l10n.locationLabel,
      child: GestureDetector(
        onTap: () => context.goNamed(
          AppRoutes.mosquesName,
          queryParameters: {
            'lat': '${mosque.latitude}',
            'lng': '${mosque.longitude}',
          },
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 200,
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
                          position: LatLng(
                            mosque.latitude!,
                            mosque.longitude!,
                          ),
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
      ),
    );
  }
}

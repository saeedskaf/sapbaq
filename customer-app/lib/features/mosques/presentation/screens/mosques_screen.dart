import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_form_field.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/floating_nav_bar.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/cart/data/models/donation_destination.dart';
import 'package:sapbaq/features/mosques/data/models/mosque.dart';
import 'package:sapbaq/features/mosques/data/mosques_repository.dart';
import 'package:sapbaq/features/mosques/presentation/bloc/mosques_cubit.dart';
import 'package:sapbaq/features/mosques/presentation/widgets/mosque_card.dart';
import 'package:sapbaq/features/mosques/presentation/widgets/mosque_favorite_button.dart';
import 'package:sapbaq/features/mosques/presentation/widgets/mosque_filter_sheet.dart';
import 'package:sapbaq/features/mosques/presentation/widgets/mosque_marker_icon.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

class MosquesScreen extends StatefulWidget {
  /// When provided (e.g. opened from a mosque's detail page), the Map tab opens
  /// centered on these coordinates.
  final double? focusLat;
  final double? focusLng;

  const MosquesScreen({super.key, this.focusLat, this.focusLng});

  @override
  State<MosquesScreen> createState() => _MosquesScreenState();
}

class _MosquesScreenState extends State<MosquesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  LatLng? _mapFocus;

  bool get _hasFocus => widget.focusLat != null && widget.focusLng != null;

  @override
  void initState() {
    super.initState();
    // Start on the Map tab when a focus target was passed in.
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _hasFocus ? 1 : 0,
    );
    if (_hasFocus) _mapFocus = LatLng(widget.focusLat!, widget.focusLng!);
  }

  @override
  void didUpdateWidget(MosquesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-focus if the screen is already alive and a new target arrives.
    if (_hasFocus &&
        (widget.focusLat != oldWidget.focusLat ||
            widget.focusLng != oldWidget.focusLng)) {
      setState(() => _mapFocus = LatLng(widget.focusLat!, widget.focusLng!));
      _tabController.animateTo(1);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = context.read<MosquesRepository>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => MosquesListCubit(repo)..load()),
        BlocProvider(create: (_) => MosquesMapCubit(repo)..load()),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: TextCustom.subheading(text: l10n.navMosques),
          bottom: TabBar(
            controller: _tabController,
            labelColor: context.colors.primary,
            unselectedLabelColor: context.colors.textSecondary,
            indicatorColor: context.colors.primary,
            tabs: [
              Tab(
                text: l10n.mosquesListTab,
                icon: const Icon(Icons.list_rounded),
              ),
              Tab(
                text: l10n.mosquesMapTab,
                icon: const Icon(Icons.map_outlined),
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            const _MosquesListView(),
            _MosquesMapView(focus: _mapFocus),
          ],
        ),
      ),
    );
  }
}

/// Filter button beside the mosque search — opens the cascading filter sheet
/// and tints when any governorate/area/block filter is active.
class _FilterButton extends StatelessWidget {
  const _FilterButton();

  Future<void> _open(BuildContext context, MosquesListCubit cubit) async {
    final selection = await showMosqueFilterSheet(
      context,
      repo: context.read<MosquesRepository>(),
      governorate: cubit.governorate,
      area: cubit.area,
      block: cubit.block,
    );
    if (selection != null) {
      cubit.applyFilters(
        governorate: selection.governorate,
        area: selection.area,
        block: selection.block,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MosquesListCubit, MosquesState>(
      builder: (context, _) {
        final cubit = context.read<MosquesListCubit>();
        final active = cubit.hasActiveFilters;
        return Material(
          color: active
              ? context.colors.primary
              : context.colors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _open(context, cubit),
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(
                Icons.tune_rounded,
                color: active
                    ? context.colors.onPrimary
                    : context.colors.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MosquesListView extends StatefulWidget {
  const _MosquesListView();

  @override
  State<_MosquesListView> createState() => _MosquesListViewState();
}

class _MosquesListViewState extends State<_MosquesListView>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {}); // refresh the clear button
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<MosquesListCubit>().search(query);
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    context.read<MosquesListCubit>().search('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: FormFieldCustom(
                  controller: _searchController,
                  hintText: l10n.searchMosqueHint,
                  isRequired: false,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: _clearSearch,
                        )
                      : null,
                  onChanged: _onSearchChanged,
                ),
              ),
              const SizedBox(width: 8),
              const _FilterButton(),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<MosquesListCubit, MosquesState>(
            builder: (context, state) {
              switch (state.status) {
                case LoadStatus.initial:
                case LoadStatus.loading:
                  return const LoadingView();
                case LoadStatus.failure:
                  return ErrorView(
                    message: state.message ?? l10n.comingSoon,
                    retryLabel: l10n.retry,
                    onRetry: () => context.read<MosquesListCubit>().load(),
                  );
                case LoadStatus.success:
                  if (state.mosques.isEmpty) {
                    final filtered =
                        _searchController.text.trim().isNotEmpty ||
                        context.read<MosquesListCubit>().hasActiveFilters;
                    return EmptyView(
                      message: filtered
                          ? l10n.noSearchResults
                          : l10n.emptyMosques,
                      icon: filtered
                          ? Icons.search_off_rounded
                          : Icons.mosque_outlined,
                    );
                  }
                  return RefreshIndicator(
                    color: Theme.of(context).colorScheme.primary,
                    onRefresh: () => context.read<MosquesListCubit>().load(),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification.metrics.pixels >=
                            notification.metrics.maxScrollExtent - 400) {
                          context.read<MosquesListCubit>().loadMore();
                        }
                        return false;
                      },
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          floatingNavBarClearance(context),
                        ),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount:
                            state.mosques.length + (state.loadingMore ? 1 : 0),
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index >= state.mosques.length) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: context.colors.primary,
                                ),
                              ),
                            );
                          }
                          final mosque = state.mosques[index];
                          return MosqueCard(
                            mosque: mosque,
                            onTap: () => context.pushNamed(
                              AppRoutes.mosqueDetailName,
                              pathParameters: {'id': '${mosque.id}'},
                            ),
                            trailing: MosqueFavoriteButton(mosque: mosque),
                          );
                        },
                      ),
                    ),
                  );
              }
            },
          ),
        ),
      ],
    );
  }
}

class _MosquesMapView extends StatefulWidget {
  /// When set, the camera centers on this mosque (opened from a detail page).
  final LatLng? focus;
  const _MosquesMapView({this.focus});

  @override
  State<_MosquesMapView> createState() => _MosquesMapViewState();
}

class _MosquesMapViewState extends State<_MosquesMapView>
    with AutomaticKeepAliveClientMixin {
  // Kuwait City — initial camera target.
  static const CameraPosition _initial = CameraPosition(
    target: LatLng(29.3759, 47.9774),
    zoom: 10,
  );
  static const ClusterManagerId _clusterId = ClusterManagerId('mosques');
  static const double _focusZoom = 16;
  // At/above this zoom, show name labels for the mosques in view; below it,
  // show numbered clusters (1,125 labels at once would be unreadable + slow).
  static const double _labelZoom = 15;
  static const int _maxLabels = 80;

  GoogleMapController? _controller;
  double _devicePixelRatio = 3;

  List<Mosque> _located = const [];
  Set<Marker> _markers = {};
  bool _showingLabels = false;
  int _rebuildSeq = 0;
  final Map<int, BitmapDescriptor> _labelCache = {};
  // The shared green mosque pin used at the clustered zoom level. Loaded once
  // (async) after the map mounts so we don't block the first frame.
  BitmapDescriptor? _mosquePin;

  // Group nearby mosques into numbered bubbles (used below the label zoom).
  late final ClusterManager _clusterManager = ClusterManager(
    clusterManagerId: _clusterId,
    onClusterTap: _onClusterTap,
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Seed from the cubit's current data so markers survive a State rebuild
    // even when the cubit doesn't re-emit (e.g. returning via a deep link).
    _located = context
        .read<MosquesMapCubit>()
        .state
        .mosques
        .where((m) => m.hasLocation)
        .toList();
  }

  @override
  void didUpdateWidget(_MosquesMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final focus = widget.focus;
    if (focus != null && focus != oldWidget.focus) {
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(focus, _focusZoom));
    }
  }

  /// A pin/label tap opens a quick sheet (name + details + donate/details).
  Future<void> _showMosqueSheet(Mosque mosque) async {
    final action = await showModalBottomSheet<_SheetAction>(
      context: context,
      useRootNavigator:
          true, // float above the bottom nav bar (scrim covers it)
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MosqueSheet(mosque: mosque),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _SheetAction.donate:
        context.pushNamed(
          AppRoutes.productsName,
          extra: DonationDestination.mosque(
            mosqueId: mosque.id,
            label: mosque.name,
          ),
        );
      case _SheetAction.details:
        context.pushNamed(
          AppRoutes.mosqueDetailName,
          pathParameters: {'id': '${mosque.id}'},
        );
    }
  }

  Future<void> _onClusterTap(Cluster cluster) async {
    final controller = _controller;
    if (controller == null) return;
    // Zoom in toward the cluster so it breaks apart into smaller groups/pins.
    final zoom = await controller.getZoomLevel();
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(cluster.position, zoom + 2),
    );
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _controller = controller;
    // Load the green mosque pin before the first marker pass so clustered
    // pins render as mosques rather than flashing red on the first frame.
    _mosquePin ??= await MosqueMarkerIcon.build(
      devicePixelRatio: _devicePixelRatio,
    );
    if (!mounted) return;
    await _rebuildMarkers(widget.focus != null ? _focusZoom : _initial.zoom);
  }

  Future<void> _onCameraIdle() async {
    final controller = _controller;
    if (controller == null) return;
    final zoom = await controller.getZoomLevel();
    if (mounted) await _rebuildMarkers(zoom);
  }

  /// Below [_labelZoom]: clustered pins. At/above it: name labels for the
  /// mosques currently in view (capped at [_maxLabels]). Tapping either opens
  /// the mosque detail.
  Future<void> _rebuildMarkers(double zoom) async {
    final seq = ++_rebuildSeq;

    if (zoom < _labelZoom) {
      if (!_showingLabels && _markers.isNotEmpty) return; // already clustered
      _showingLabels = false;
      final pin = _mosquePin;
      final markers = {
        for (final m in _located)
          Marker(
            markerId: MarkerId('${m.id}'),
            clusterManagerId: _clusterId,
            position: LatLng(m.latitude!, m.longitude!),
            icon: pin ?? BitmapDescriptor.defaultMarker,
            anchor: const Offset(0.5, 0.5),
            onTap: () => _showMosqueSheet(m),
          ),
      };
      if (mounted && seq == _rebuildSeq) setState(() => _markers = markers);
      return;
    }

    final controller = _controller;
    if (controller == null) return;
    final bounds = await controller.getVisibleRegion();
    if (!mounted || seq != _rebuildSeq) return;

    final visible = _located
        .where((m) => bounds.contains(LatLng(m.latitude!, m.longitude!)))
        .take(_maxLabels)
        .toList();

    final markers = <Marker>{};
    for (final m in visible) {
      final icon = await _labelIcon(m);
      if (!mounted || seq != _rebuildSeq) return;
      markers.add(
        Marker(
          markerId: MarkerId('${m.id}'),
          position: LatLng(m.latitude!, m.longitude!),
          icon: icon,
          anchor: const Offset(0.5, 1),
          onTap: () => _showMosqueSheet(m),
        ),
      );
    }
    _showingLabels = true;
    if (mounted && seq == _rebuildSeq) setState(() => _markers = markers);
  }

  Future<BitmapDescriptor> _labelIcon(Mosque m) async {
    return _labelCache[m.id] ??= await _buildLabel(m.name);
  }

  /// Render a rounded name pill to a marker bitmap (Arabic, RTL).
  Future<BitmapDescriptor> _buildLabel(String name) async {
    final r = _devicePixelRatio;
    final tp = TextPainter(
      text: TextSpan(
        text: name,
        style: TextStyle(
          color: ColorsCustom.textPrimary,
          fontSize: 13 * r,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.rtl,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 200 * r);

    final hPad = 10 * r;
    final vPad = 6 * r;
    final w = tp.width + hPad * 2;
    final h = tp.height + vPad * 2;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(13 * r),
    );
    canvas.drawRRect(rect, Paint()..color = Colors.white);
    canvas.drawRRect(
      rect,
      Paint()
        ..color = ColorsCustom.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * r,
    );
    tp.paint(canvas, Offset(hPad, vPad));

    final image = await recorder.endRecording().toImage(w.ceil(), h.ceil());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      data!.buffer.asUint8List(),
      imagePixelRatio: r,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    final l10n = AppLocalizations.of(context)!;
    _devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    return BlocConsumer<MosquesMapCubit, MosquesState>(
      listenWhen: (a, b) => a.mosques != b.mosques,
      listener: (context, state) {
        _located = state.mosques.where((m) => m.hasLocation).toList();
        _showingLabels = false;
        _markers = {};
        _controller?.getZoomLevel().then((z) {
          if (mounted) _rebuildMarkers(z);
        });
      },
      builder: (context, state) {
        switch (state.status) {
          case LoadStatus.initial:
          case LoadStatus.loading:
            return const LoadingView();
          case LoadStatus.failure:
            return ErrorView(
              message: state.message ?? l10n.comingSoon,
              retryLabel: l10n.retry,
              onRetry: () => context.read<MosquesMapCubit>().load(),
            );
          case LoadStatus.success:
            return GoogleMap(
              initialCameraPosition: widget.focus != null
                  ? CameraPosition(target: widget.focus!, zoom: _focusZoom)
                  : _initial,
              markers: _markers,
              clusterManagers: {_clusterManager},
              onMapCreated: _onMapCreated,
              onCameraIdle: _onCameraIdle,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              // The map sits inside a TabBarView (a PageView); without this it
              // never wins the pan/zoom gestures from the parent scrollable.
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(
                  EagerGestureRecognizer.new,
                ),
              },
            );
        }
      },
    );
  }
}

enum _SheetAction { donate, details }

/// Quick mosque sheet shown when a pin/label is tapped: name + area + address
/// (address fetched on open), with donate / view-details actions.
class _MosqueSheet extends StatefulWidget {
  final Mosque mosque;
  const _MosqueSheet({required this.mosque});

  @override
  State<_MosqueSheet> createState() => _MosqueSheetState();
}

class _MosqueSheetState extends State<_MosqueSheet> {
  Mosque? _full;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final full = await context.read<MosquesRepository>().fetchMosque(
        widget.mosque.id,
      );
      if (mounted) setState(() => _full = full);
    } catch (_) {
      // Keep the basic info from the marker if the detail fetch fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final m = _full ?? widget.mosque;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: context.colors.primaryTint,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mosque_rounded,
                      color: context.colors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextCustom.subheading(
                          text: m.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (m.area.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          TextCustom(
                            text: m.area,
                            fontSize: 13,
                            color: context.colors.textSecondary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (m.address.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 20,
                      color: context.colors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextCustom(
                        text: m.address,
                        fontSize: 14,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              TextCustom(
                text: l10n.donateMosquePrompt,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(height: 12),
              ButtonCustom.primary(
                text: l10n.donateToThisMosque,
                icon: const Icon(
                  Icons.volunteer_activism_rounded,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context, _SheetAction.donate),
              ),
              const SizedBox(height: 10),
              ButtonCustom.secondary(
                text: l10n.viewMosqueDetails,
                onPressed: () => Navigator.pop(context, _SheetAction.details),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/widgets/custom_button.dart';
import 'package:sapbaq_admin/core/widgets/custom_form_field.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/message_dialog.dart';
import 'package:sapbaq_admin/core/widgets/state_views.dart';
import 'package:sapbaq_admin/features/rep/data/models/rep_models.dart';
import 'package:sapbaq_admin/features/rep/data/rep_repository.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Maintenance report (rep): pick the unit BY CODE from the mosque's registry
/// (never typed — spec §5), choose an issue type, describe when "other". The
/// server blocks a unit that already has an open case.
class RepReportFormScreen extends StatefulWidget {
  const RepReportFormScreen({super.key});

  @override
  State<RepReportFormScreen> createState() => _RepReportFormScreenState();
}

class _RepReportFormScreenState extends State<RepReportFormScreen> {
  static const _issueTypes = [
    'FILTER_CHANGE',
    'NOT_WORKING',
    'LEAKING',
    'OTHER',
  ];

  List<RepEquipmentUnit> _units = const [];
  bool _loading = true;
  String? _error;

  RepEquipmentUnit? _unit;
  String _issueType = _issueTypes.first;
  final _descriptionController = TextEditingController();
  bool _busy = false;

  /// Optional diagnostic photos (server caps at 5; jpg/png/webp; ≤5MB each).
  static const _maxPhotos = 5;
  final _picker = ImagePicker();
  final List<XFile> _photos = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final units = await context.read<RepRepository>().equipment();
      if (!mounted) return;
      setState(() {
        _units = units;
        _unit = units.isEmpty ? null : units.first;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _addPhoto(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    if (_photos.length >= _maxPhotos) {
      ShowMessage.info(context, l10n.repMaxPhotos);
      return;
    }
    try {
      // Downscale + recompress on capture so uploads stay under the 5MB cap.
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1600,
      );
      if (file != null && mounted) setState(() => _photos.add(file));
    } catch (_) {
      if (mounted) ShowMessage.error(context, l10n.pickFailed);
    }
  }

  String _issueLabel(AppLocalizations l10n, String type) => switch (type) {
    'FILTER_CHANGE' => l10n.repIssueFilterChange,
    'NOT_WORKING' => l10n.repIssueNotWorking,
    'LEAKING' => l10n.repIssueLeaking,
    _ => l10n.repIssueOther,
  };

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final unit = _unit;
    if (unit == null) return;
    final description = _descriptionController.text.trim();
    if (_issueType == 'OTHER' && description.isEmpty) {
      ShowMessage.error(context, l10n.repIssueOtherNeedsDesc);
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<RepRepository>().reportMaintenance(
        equipmentId: unit.id,
        issueType: _issueType,
        description: description,
        photoPaths: _photos.map((x) => x.path).toList(),
      );
      if (!mounted) return;
      ShowMessage.success(context, l10n.repReportSent);
      context.pop();
    } on ApiException catch (e) {
      // e.g. the unit already has an open case (spec §8).
      if (mounted) ShowMessage.error(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: TextCustom.subheading(text: l10n.repReportMaintenance),
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
          ? ErrorView(message: _error!, retryLabel: l10n.retry, onRetry: _load)
          : _units.isEmpty
          ? EmptyView(message: l10n.repNoUnits, icon: Icons.qr_code_2_rounded)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextCustom(
                  text: l10n.repPickUnit,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<RepEquipmentUnit>(
                  initialValue: _unit,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  items: [
                    for (final unit in _units)
                      DropdownMenuItem(
                        value: unit,
                        child: TextCustom(
                          text: unit.typeName.isEmpty
                              ? unit.code
                              : '${unit.typeName} — ${unit.code}',
                          fontSize: 14,
                          maxLines: 1,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _unit = v),
                ),
                const SizedBox(height: 20),
                TextCustom(
                  text: l10n.repIssueType,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final type in _issueTypes)
                      ChoiceChip(
                        label: TextCustom(
                          text: _issueLabel(l10n, type),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _issueType == type
                              ? ColorsCustom.textOnPrimary
                              : context.colors.textPrimary,
                        ),
                        selected: _issueType == type,
                        selectedColor: context.colors.primary,
                        onSelected: (_) => setState(() => _issueType = type),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                FormFieldCustom(
                  controller: _descriptionController,
                  label: l10n.repIssueDescription,
                  isRequired: _issueType == 'OTHER',
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                _PhotosField(
                  photos: _photos,
                  maxPhotos: _maxPhotos,
                  enabled: !_busy,
                  onAddCamera: () => _addPhoto(ImageSource.camera),
                  onAddGallery: () => _addPhoto(ImageSource.gallery),
                  onRemove: (i) => setState(() => _photos.removeAt(i)),
                ),
                const SizedBox(height: 24),
                ButtonCustom.primary(
                  text: l10n.repReportSubmit,
                  isLoading: _busy,
                  onPressed: _busy ? null : _submit,
                ),
              ],
            ),
    );
  }
}

/// Optional diagnostic-photo picker: a thumbnail grid with per-item removal and
/// camera/gallery add tiles, capped at [maxPhotos].
class _PhotosField extends StatelessWidget {
  final List<XFile> photos;
  final int maxPhotos;
  final bool enabled;
  final VoidCallback onAddCamera;
  final VoidCallback onAddGallery;
  final ValueChanged<int> onRemove;

  const _PhotosField({
    required this.photos,
    required this.maxPhotos,
    required this.enabled,
    required this.onAddCamera,
    required this.onAddGallery,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canAdd = enabled && photos.length < maxPhotos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TextCustom(
              text: l10n.repPhotos,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(width: 8),
            TextCustom(
              text: l10n.repPhotosHint,
              fontSize: 12,
              color: context.colors.textHint,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < photos.length; i++)
              _Thumb(
                file: File(photos[i].path),
                onRemove: enabled ? () => onRemove(i) : null,
              ),
            if (canAdd) ...[
              _AddTile(icon: Icons.photo_camera_rounded, onTap: onAddCamera),
              _AddTile(icon: Icons.photo_library_rounded, onTap: onAddGallery),
            ],
          ],
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  final File file;
  final VoidCallback? onRemove;
  const _Thumb({required this.file, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(file, width: 76, height: 76, fit: BoxFit.cover),
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

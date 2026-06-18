import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/widgets/custom_button.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/message_dialog.dart';
import 'package:sapbaq_admin/features/driver/data/driver_repository.dart';
import 'package:sapbaq_admin/features/driver/presentation/bloc/upload_proof_cubit.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

bool _isVideoPath(String path) {
  final p = path.toLowerCase();
  return p.endsWith('.mp4') ||
      p.endsWith('.mov') ||
      p.endsWith('.m4v') ||
      p.endsWith('.avi');
}

class UploadProofScreen extends StatelessWidget {
  final int destinationId;
  const UploadProofScreen({super.key, required this.destinationId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          UploadProofCubit(context.read<DriverRepository>(), destinationId),
      child: const _UploadProofView(),
    );
  }
}

class _UploadProofView extends StatefulWidget {
  const _UploadProofView();

  @override
  State<_UploadProofView> createState() => _UploadProofViewState();
}

class _UploadProofViewState extends State<_UploadProofView> {
  final _picker = ImagePicker();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 70);
      if (file != null && mounted) {
        context.read<UploadProofCubit>().addFile(file.path);
      }
    } catch (_) {
      if (mounted) {
        ShowMessage.error(context, AppLocalizations.of(context)!.pickFailed);
      }
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final file = await _picker.pickVideo(source: source);
      if (file != null && mounted) {
        context.read<UploadProofCubit>().addFile(file.path);
      }
    } catch (_) {
      if (mounted) {
        ShowMessage.error(context, AppLocalizations.of(context)!.pickFailed);
      }
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<UploadProofCubit>();
    if (!cubit.state.hasFiles) {
      ShowMessage.info(context, l10n.noProofSelected);
      return;
    }
    final ok = await cubit.submit(note: _noteController.text.trim());
    if (ok && mounted) {
      ShowMessage.success(context, l10n.proofUploaded);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: TextCustom.subheading(text: l10n.proofTitle)),
      body: BlocBuilder<UploadProofCubit, UploadProofState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              TextCustom.body(
                text: l10n.proofHint,
                color: ColorsCustom.textSecondary,
                fontSize: 14,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.photo_camera_outlined,
                      label: l10n.takePhoto,
                      onTap: () => _pickImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.photo_library_outlined,
                      label: l10n.fromGallery,
                      onTap: () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.videocam_outlined,
                      label: l10n.addVideo,
                      onTap: () => _pickVideo(ImageSource.camera),
                    ),
                  ),
                ],
              ),
              if (state.hasFiles) ...[
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final path in state.files)
                      _ProofThumb(
                        path: path,
                        onRemove: () =>
                            context.read<UploadProofCubit>().removeFile(path),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(hintText: l10n.proofNoteHint),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<UploadProofCubit, UploadProofState>(
        builder: (context, state) => SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ButtonCustom.primary(
            text: l10n.uploadAndFinish,
            isLoading: state.submitting,
            enabled: state.hasFiles,
            onPressed: _submit,
          ),
        ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorsCustom.surfaceVariant,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: ColorsCustom.primary, size: 26),
              const SizedBox(height: 8),
              TextCustom(
                text: label,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: ColorsCustom.textSecondary,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProofThumb extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;
  const _ProofThumb({required this.path, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final isVideo = _isVideoPath(path);
    return Stack(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: ColorsCustom.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColorsCustom.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: isVideo
              ? const Center(
                  child: Icon(
                    Icons.play_circle_outline_rounded,
                    color: ColorsCustom.primary,
                    size: 34,
                  ),
                )
              : Image.file(File(path), fit: BoxFit.cover),
        ),
        PositionedDirectional(
          top: 2,
          end: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: ColorsCustom.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/features/driver/data/driver_repository.dart';

class UploadProofState extends Equatable {
  final List<String> files; // local file paths to upload
  final bool submitting;
  final String? message;

  const UploadProofState({
    this.files = const [],
    this.submitting = false,
    this.message,
  });

  bool get hasFiles => files.isNotEmpty;

  UploadProofState copyWith({
    List<String>? files,
    bool? submitting,
    String? message,
  }) {
    return UploadProofState(
      files: files ?? this.files,
      submitting: submitting ?? this.submitting,
      message: message,
    );
  }

  @override
  List<Object?> get props => [files, submitting, message];
}

/// Collects one or more proof files (photos/videos) and uploads them — one API
/// call per file. The first successful upload flips the destination to
/// DELIVERED.
class UploadProofCubit extends Cubit<UploadProofState> {
  final DriverRepository _repo;
  final int destinationId;

  UploadProofCubit(this._repo, this.destinationId)
      : super(const UploadProofState());

  void addFile(String path) {
    if (state.files.contains(path)) return;
    emit(state.copyWith(files: [...state.files, path]));
  }

  void removeFile(String path) {
    emit(state.copyWith(files: state.files.where((p) => p != path).toList()));
  }

  /// Uploads every picked file sequentially. Returns true once all succeed.
  Future<bool> submit({String note = ''}) async {
    if (state.files.isEmpty) return false;
    emit(state.copyWith(submitting: true, message: null));
    try {
      for (final path in state.files) {
        await _repo.uploadProof(destinationId, filePath: path, note: note);
      }
      emit(state.copyWith(submitting: false));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(submitting: false, message: e.message));
      return false;
    }
  }
}

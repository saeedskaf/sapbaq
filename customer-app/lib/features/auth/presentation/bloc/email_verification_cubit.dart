import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';
import 'package:sapbaq/features/auth/data/models/otp_send_meta.dart';

/// Two-step email verification: type the address, then confirm the mailed code.
enum EmailStep { enterEmail, enterCode }

/// What a send attempt produced. The two answers are independent: a throttled
/// attempt sends nothing yet still names a wait, and a rejected address names
/// neither — so the screen must not infer one from the other.
typedef EmailSendOutcome = ({bool sent, int cooldown});

const EmailSendOutcome _nothingSent = (sent: false, cooldown: 0);

class EmailVerificationState extends Equatable {
  final EmailStep step;
  final bool busy;

  /// The address being verified, **as the server stored it** (it lower-cases
  /// the domain) — set once the code is requested.
  final String? email;

  /// Set when the code is confirmed → the screen pops back to the profile.
  final bool verified;

  /// General failure, shown as a message.
  final String? message;

  /// Field-level failure, shown under the email input.
  final String? emailError;

  const EmailVerificationState({
    this.step = EmailStep.enterEmail,
    this.busy = false,
    this.email,
    this.verified = false,
    this.message,
    this.emailError,
  });

  EmailVerificationState copyWith({
    EmailStep? step,
    bool? busy,
    String? email,
    bool? verified,
    String? message,
    String? emailError,
  }) {
    return EmailVerificationState(
      step: step ?? this.step,
      busy: busy ?? this.busy,
      email: email ?? this.email,
      verified: verified ?? this.verified,
      // Transient by design: a message/field error is consumed on the emit that
      // carries it, so re-submitting starts clean.
      message: message,
      emailError: emailError,
    );
  }

  @override
  List<Object?> get props => [
    step,
    busy,
    email,
    verified,
    message,
    emailError,
  ];
}

/// Verifying (or changing) the account email — the only path that writes a
/// *verified* address; `PATCH /auth/me/` ignores the field.
///
/// Errors branch on `error.code`, not on the status alone: one `400` carries
/// five cases, three of which keep the user where they are while two send them
/// back to the address step (FLUTTER_EMAIL_VERIFY_CHANGE_2026-08-19 §4).
class EmailVerificationCubit extends Cubit<EmailVerificationState> {
  final AuthRepository _repo;
  EmailVerificationCubit(this._repo) : super(const EmailVerificationState());

  /// Send a code to [email]. Reports whether one actually went out and how long
  /// the account must wait before the next send (the server's escalating
  /// backoff, or its `retry_after` when the attempt was too soon).
  Future<EmailSendOutcome> requestCode({required String email}) async {
    if (state.busy) return _nothingSent;
    emit(state.copyWith(busy: true, emailError: null, message: null));
    try {
      final (stored, meta) = await _repo.requestEmailCode(email: email);
      // The screen may have been popped while this was in flight; the cubit
      // goes with it, and emitting into a closed one throws.
      if (isClosed) return _nothingSent;
      emit(
        state.copyWith(busy: false, step: EmailStep.enterCode, email: stored),
      );
      return (sent: true, cooldown: meta.resendAvailableIn);
    } on ApiException catch (e) {
      if (isClosed) return _nothingSent;
      // Sent too soon. The cooldown belongs to the *account*, so this lands
      // even on an address typed for the first time — the screen keeps
      // counting down rather than pretending the button is live.
      if (e.isThrottled) {
        emit(state.copyWith(busy: false, message: e.message));
        return (sent: false, cooldown: e.retryAfter ?? kOtpDefaultResendSeconds);
      }
      switch (e.code) {
        // All three are complaints about the address itself, and all three are
        // fixed in the field — so they belong under it, not in a message that
        // floats away. ("Not an email" is a typo; "belongs to another account"
        // and "already verified" are not, and retyping the same value would
        // just repeat them.)
        case 'email_taken':
        case 'email_already_verified':
          emit(state.copyWith(busy: false, emailError: e.message));
        case 'invalid':
          emit(
            state.copyWith(
              busy: false,
              emailError: e.fieldError('email') ?? e.message,
            ),
          );
        // Network / unknown: nothing about the address to point at.
        default:
          emit(state.copyWith(busy: false, message: e.message));
      }
      return _nothingSent;
    } catch (_) {
      // Whatever `guardApi` could not normalize (a parse or cast failure).
      // Unhandled, it would leave the form latched in its busy state forever.
      if (!isClosed) {
        emit(
          state.copyWith(busy: false, message: ApiException.unexpected().message),
        );
      }
      return _nothingSent;
    }
  }

  /// Resend to the same address (the code step's "send a new code").
  Future<EmailSendOutcome> resend() async {
    final email = state.email;
    if (email == null) return _nothingSent;
    return requestCode(email: email);
  }

  /// Confirm [code] for the address the code was issued to. On success the
  /// cached user is updated from the response (it is the full `/auth/me/`
  /// object) and [EmailVerificationState.verified] flips.
  Future<void> verify({required String code}) async {
    final email = state.email;
    // The code is single-use: a second in-flight confirmation would spend it,
    // then report `otp_not_found` and bounce a user who had just succeeded.
    if (email == null || state.busy) return;
    emit(state.copyWith(busy: true, message: null));
    try {
      await _repo.verifyEmail(email: email, code: code);
      if (isClosed) return;
      emit(state.copyWith(busy: false, verified: true));
    } on ApiException catch (e) {
      if (isClosed) return;
      switch (e.code) {
        // No live code for this address any more — a newer send invalidated it,
        // it was already spent, or another account took the address first.
        // Nothing on the code step can fix that.
        case 'otp_not_found':
        case 'email_taken':
          emit(
            state.copyWith(
              busy: false,
              step: EmailStep.enterEmail,
              message: e.message,
            ),
          );
        // Wrong / dead code: stay put. The screen clears the input, and the
        // resend button opens as soon as the account's cooldown ends.
        default:
          emit(state.copyWith(busy: false, message: e.message));
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(busy: false, message: ApiException.unexpected().message),
        );
      }
    }
  }

  /// Return to the address step to correct a mistyped address.
  void editEmail() => emit(state.copyWith(step: EmailStep.enterEmail));
}

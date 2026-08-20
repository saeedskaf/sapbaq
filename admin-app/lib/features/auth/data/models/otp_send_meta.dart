/// The default resend wait (seconds) when the server omits `resend_available_in`
/// — matches the backend's first-step default (`OTP_RESEND_DEFAULT_SECONDS`).
const int kOtpDefaultResendSeconds = 30;

/// Metadata returned by the rep OTP send endpoint: how long until the next
/// resend is allowed (the server computes the escalating backoff — the app just
/// mirrors the number) and how long the code stays valid.
class OtpSendMeta {
  final int resendAvailableIn;
  final int? codeExpiresIn;

  const OtpSendMeta({
    this.resendAvailableIn = kOtpDefaultResendSeconds,
    this.codeExpiresIn,
  });

  factory OtpSendMeta.fromJson(Object? data) {
    if (data is Map) {
      final m = Map<String, dynamic>.from(data);
      final resend = (m['resend_available_in'] as num?)?.toInt();
      return OtpSendMeta(
        resendAvailableIn: resend ?? kOtpDefaultResendSeconds,
        codeExpiresIn: (m['code_expires_in'] as num?)?.toInt(),
      );
    }
    return const OtpSendMeta();
  }
}

import 'package:flutter/material.dart';
import 'package:sapbaq/core/config/environment.dart';
import 'package:sapbaq/core/payments/payment_activity.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/confirm_sheet.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/features/orders/data/models/payment.dart';
import 'package:sapbaq/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// How the customer left the hosted payment page.
///
/// This is a *hint*, not a verdict: the real outcome always comes from
/// `POST /payments/confirm/`, which re-queries the gateway. Treating the
/// return URL as the answer would let a customer fake a payment by navigating,
/// and would break the moment the gateway changes its return path.
enum PaymentReturn { callback, error, closed }

/// Hosts the MyFatoorah payment page and closes itself when the gateway sends
/// the customer back (FLUTTER_PAYMENTS_MYFATOORAH §3).
///
/// The page inside belongs to the gateway and cannot be restyled, so everything
/// around it does the work instead: the amount and what it buys sit above the
/// page in our own type and colour, so the customer never faces an unlabelled
/// browser asking for a card number. That framing is not decoration — it is the
/// difference between "some website wants my card" and "I am paying Sapbaq
/// 25 KWD for this order".
///
/// Two paths still leave through the gateway's own domain — KNET, which must
/// collect a PIN on its network's page, and a bank's 3-D Secure challenge — so
/// this screen stays part of the flow no matter how much of the card entry
/// moves in-app later.
class PaymentWebViewScreen extends StatefulWidget {
  /// The attempt being paid. Carries the hosted-page URL plus the amount and
  /// the id of whatever is being paid for, which is all the header needs.
  final Payment payment;

  /// How many mosques this single payment settles. Shown only above one — for
  /// one destination there is nothing to say, and a "1 mosque" badge is noise.
  final int destinationCount;

  const PaymentWebViewScreen({
    super.key,
    required this.payment,
    this.destinationCount = 0,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;

  /// A navigation is in progress. Drives the hairline progress bar.
  bool _loading = true;

  /// Nothing has rendered yet. Drives the skeleton, which only covers the very
  /// first load — after that the page is visible and a full-bleed placeholder
  /// would hide work the customer is in the middle of.
  bool _firstLoad = true;

  String _host = '';
  bool _backgroundApplied = false;

  /// Set as soon as a return URL is seen, so the pop happens once even if the
  /// page fires several navigations on its way out.
  PaymentReturn? _resolved;

  @override
  void initState() {
    super.initState();
    // Deep-links are parked while this is up: a notification tapped mid-payment
    // is the one exit no confirmation sheet can guard.
    PaymentActivity.begin();
    // Bank OTPs arrive by SMS, and reading one takes longer than the screen
    // timeout. Letting the device lock here suspends the page mid-payment.
    WakelockPlus.enable();

    _host = Uri.tryParse(widget.payment.redirectUrl)?.host ?? '';
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // Deliberately no `addJavaScriptChannel`: the gateway's page needs its
      // own scripts to run, but it must never get a handle into our code.
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final outcome = _classify(request.url);
            if (outcome != null) {
              _finish(outcome);
              return NavigationDecision.prevent;
            }
            // A bank's 3-D Secure step can hand off to its own app through a
            // custom scheme, and some pages carry `tel:` / `mailto:` links.
            // A WebView cannot load any of those: left to itself it fails to a
            // blank page with the payment half-finished, which is the classic
            // "the payment screen went white" report. Hand them to the OS and
            // keep the payment page alive underneath to receive the return.
            if (!_isWebUrl(request.url)) {
              _openExternally(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (url) {
            if (!mounted) return;
            setState(() {
              _loading = true;
              _host = Uri.tryParse(url)?.host ?? _host;
            });
          },
          onPageFinished: (_) => _stopLoading(),
          // Some gateway steps move within a page rather than navigating, which
          // never reaches onNavigationRequest. This is the second net under the
          // return URLs — missing one leaves the customer staring at a finished
          // payment page waiting for something to happen.
          onUrlChange: (change) {
            final url = change.url;
            if (url == null) return;
            final outcome = _classify(url);
            if (outcome != null) {
              _finish(outcome);
              return;
            }
            if (mounted) {
              setState(() => _host = Uri.tryParse(url)?.host ?? _host);
            }
          },
          // A 4xx/5xx on the payment page itself leaves the customer on a dead
          // page; without this the spinner would also run forever on top of it.
          onHttpError: (_) => _stopLoading(),
          // A failed subresource shouldn't strand the customer on a blank page;
          // the outer flow still confirms, so just stop the spinner.
          onWebResourceError: (_) => _stopLoading(),
        ),
      )
      ..loadRequest(Uri.parse(widget.payment.redirectUrl));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The gateway page paints white. Without this the first frame flashes white
    // inside a dark-themed app, every single time.
    if (!_backgroundApplied) {
      _backgroundApplied = true;
      _controller.setBackgroundColor(context.colors.surface);
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    PaymentActivity.end();
    super.dispose();
  }

  void _stopLoading() {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _firstLoad = false;
    });
  }

  static bool _isWebUrl(String url) {
    final scheme = Uri.tryParse(url)?.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https' || scheme == 'about';
  }

  Future<void> _openExternally(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Nothing installed to handle it. Swallowing this is the point: the
      // payment page stays exactly where it was instead of dying on an
      // unloadable scheme, and the customer can carry on or use another method.
    }
  }

  /// Recognises the gateway's return, or null while the customer is still on
  /// the payment page.
  PaymentReturn? _classify(String url) {
    bool matches(String configured) =>
        configured.isNotEmpty && url.startsWith(configured);

    if (matches(Environment.payErrorUrl)) return PaymentReturn.error;
    if (matches(Environment.payCallbackUrl)) return PaymentReturn.callback;

    // Fallback for a return URL that no longer matches: the gateway sends the
    // customer back to our own `/pay/…` route and nowhere else on our host.
    //
    // The path check carries real weight. Treating *any* link to our host as
    // the return — as this used to — closes the page the moment the customer
    // taps a merchant logo, a terms link, or a "back to store" button on the
    // gateway's page, and we then confirm a payment that was never made and
    // show a failure for it.
    final apiHost = Uri.tryParse(Environment.baseUrl)?.host;
    final parsed = Uri.tryParse(url);
    if (apiHost != null &&
        apiHost.isNotEmpty &&
        parsed != null &&
        parsed.host == apiHost &&
        parsed.path.startsWith('/pay/')) {
      return PaymentReturn.callback;
    }
    return null;
  }

  void _finish(PaymentReturn outcome) {
    if (_resolved != null || !mounted) return;
    _resolved = outcome;
    Navigator.of(context).pop(outcome);
  }

  /// Leaving mid-payment may abandon a charge the gateway already took, so ask
  /// first — but never block: the outer flow confirms either way.
  Future<bool> _confirmLeave() async {
    final l10n = AppLocalizations.of(context)!;
    return ConfirmSheet.ask(
      context,
      title: l10n.payCancelTitle,
      body: l10n.payCancelBody,
      icon: Icons.exit_to_app_rounded,
      // Not destructive: an already-taken charge is still verified either way.
      danger: false,
      confirmLabel: l10n.payLeave,
      cancelLabel: l10n.payKeepGoing,
      // This sheet is a guard, not a request. Emphasising "leave" — the filled
      // brand-coloured button, nearest the thumb — was inviting the very exit
      // the sheet exists to prevent.
      invertEmphasis: true,
    );
  }

  Future<void> _requestLeave() async {
    if (await _confirmLeave()) _finish(PaymentReturn.closed);
  }

  /// What the money buys, so the header is never just a bare number. Read off
  /// the attempt itself — exactly one of the three ids is set.
  String _purpose(AppLocalizations l10n) {
    final payment = widget.payment;
    if (payment.orderId != null) return l10n.payForOrder(payment.orderId!);
    if (payment.contributionId != null) return l10n.payForContribution;
    if (payment.equipmentOrderId != null) return l10n.payForEquipment;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // A back gesture goes through the same "are you sure" as the ✕.
        await _requestLeave();
      },
      child: Scaffold(
        backgroundColor: colors.surface,
        body: Column(
          children: [
            _Header(
              amount: l10n.priceKwd(widget.payment.amount),
              purpose: _purpose(l10n),
              host: _host,
              loading: _loading,
              scope: widget.destinationCount > 1
                  ? l10n.mosquesCount(widget.destinationCount)
                  : null,
              onClose: _requestLeave,
            ),
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_firstLoad)
                    Positioned.fill(
                      child: ColoredBox(
                        color: colors.surface,
                        child: const _PageSkeleton(),
                      ),
                    ),
                ],
              ),
            ),
            _TrustBar(note: l10n.paySecureNote),
          ],
        ),
      ),
    );
  }
}

/// The amount, what it buys, and where the card is going — the three things a
/// customer needs before typing a card number, and none of which the gateway's
/// own page shows in our language or our type.
class _Header extends StatelessWidget {
  final String amount;
  final String purpose;
  final String host;
  final bool loading;

  /// What the one amount covers — «٣ مساجد» — when it spans more than one
  /// destination; null otherwise.
  final String? scope;
  final VoidCallback onClose;

  const _Header({
    required this.amount,
    required this.purpose,
    required this.host,
    required this.loading,
    required this.scope,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors.surface,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        color: colors.textSecondary,
                        onPressed: onClose,
                      ),
                      const Spacer(),
                      // The host, so the customer can see for themselves that
                      // the card is going to the payment provider's domain.
                      if (host.isNotEmpty)
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_rounded,
                                size: 12,
                                color: colors.textHint,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: TextCustom(
                                  text: host,
                                  fontSize: 11,
                                  color: colors.textHint,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (scope != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surfaceVariant,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: TextCustom(
                              text: scope!,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        TextCustom(
                          text: amount,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                        if (purpose.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          TextCustom(
                            text: purpose,
                            fontSize: 13,
                            color: colors.textSecondary,
                            maxLines: 1,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 2,
            child: loading
                ? const LinearProgressIndicator(minHeight: 2)
                : ColoredBox(color: colors.border, child: const SizedBox()),
          ),
        ],
      ),
    );
  }
}

/// Shown only until the gateway's page first paints. A branded placeholder
/// reads as "our app is working" where a blank white rectangle reads as
/// "something broke" — and this page routinely takes a second or three.
class _PageSkeleton extends StatefulWidget {
  const _PageSkeleton();

  @override
  State<_PageSkeleton> createState() => _PageSkeletonState();
}

class _PageSkeletonState extends State<_PageSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
    lowerBound: 0.45,
    upperBound: 1,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Widget _bar(BuildContext context, double widthFactor, double height) =>
      FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: widthFactor,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: context.colors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _pulse,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bar(context, 0.4, 14),
            const SizedBox(height: 20),
            _bar(context, 1, 48),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _bar(context, 1, 48)),
                const SizedBox(width: 12),
                Expanded(child: _bar(context, 1, 48)),
              ],
            ),
            const SizedBox(height: 12),
            _bar(context, 1, 48),
            const SizedBox(height: 28),
            _bar(context, 1, 52),
          ],
        ),
      ),
    );
  }
}

class _TrustBar extends StatelessWidget {
  final String note;
  const _TrustBar({required this.note});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_rounded, size: 13, color: colors.textHint),
              const SizedBox(width: 6),
              Flexible(
                child: TextCustom(
                  text: note,
                  fontSize: 12,
                  color: colors.textHint,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sapbaq/core/config/environment.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// What the embedded page reported back.
enum CardSurfaceEvent {
  /// The card was handed to the gateway's session. Nothing was charged — that
  /// is the server's job, with `POST /payments/execute/`.
  collected,

  /// Validation failed, or the gateway refused the details.
  failed,

  /// The customer picked a method that finishes on the gateway's own page —
  /// KNET being the one that matters here. **No card was collected**, so this
  /// must never be mistaken for [collected]: charging a session with no card on
  /// it earns a rejection that reads to the customer like their card failed.
  redirect,
}

/// One message from the page's bridge.
///
/// A class rather than a bare event because [redirect] carries the address the
/// gateway wants the customer at next, and dropping it costs a whole extra
/// round trip: without the URL the only way on is to ask for a fresh invoice
/// and make the customer pick their method a second time.
class CardSurfaceReport {
  final CardSurfaceEvent event;

  /// The page's own wording on failure. Null when it didn't say.
  final String? message;

  /// Where a hosted method continues — set on [redirect] only, and empty if the
  /// page ever omits it.
  final String url;

  const CardSurfaceReport(this.event, {this.message, this.url = ''});

  /// Whether this redirect can be followed as-is.
  ///
  /// Checked, not assumed. The page is ours but this address is not — it comes
  /// from the gateway, through a bridge, and ends up in `Uri.parse` and a
  /// webview. Anything that isn't plain https falls back to asking our own
  /// server for a hosted page, which costs a round trip and risks nothing.
  bool get isFollowable =>
      url.isNotEmpty && (Uri.tryParse(url)?.isScheme('https') ?? false);
}

/// Drives a [PaymentCardSurface] from the sheet that owns it: the pay button
/// lives outside the surface, so something has to reach in and submit.
class PaymentCardController {
  Future<void> Function()? _submitNew;
  Future<void> Function(String token)? _submitSaved;

  bool get isReady => _submitNew != null;

  /// Hand the typed card to the session.
  Future<void> submitNewCard() async => _submitNew?.call();

  /// Charge a saved card. The token travels; the security code does not — the
  /// customer types it into the gateway's own field inside the surface, and the
  /// gateway reads it from there. It never passes through Dart.
  Future<void> submitSavedCard(String token) async => _submitSaved?.call(token);

  void _detach() {
    _submitNew = null;
    _submitSaved = null;
  }
}

/// The only place in the app where card details are entered.
///
/// It is a [WebView] pointed at **our own** page — served from our domain,
/// styled by us, containing nothing but MyFatoorah's card fields. The card goes
/// straight from those fields to the gateway; it never reaches Dart, never
/// reaches our server, and never appears in a log. That is what keeps PCI scope
/// with the gateway, and it is why this is a browser rather than Flutter text
/// fields, which would look nicer and cost us a compliance audit.
///
/// Why a page of ours rather than the gateway's own hosted page: the gateway's
/// page charges the card itself. Ours only *collects* it, leaving the charge to
/// our server, which reads the amount from its own records. A device can be
/// rewritten; a server-held amount cannot.
///
/// ### The JavaScript channel
///
/// The payment webview that hosts KNET and 3-D Secure deliberately exposes no
/// channel — it renders a page we do not control. This one does, because the
/// page *is* ours and the channel is how it answers. The rule is "no channel
/// with a page we don't own", not "no channels".
///
/// Even so the channel carries no card data: the page reports only that
/// collection succeeded or failed. We do not want the number and would not read
/// it if it were sent.
class PaymentCardSurface extends StatefulWidget {
  final String sessionId;
  final String countryCode;

  /// The language the **session** was created in — not the app's current
  /// locale. The gateway fixes its fields' language at session creation and
  /// cannot switch afterwards, so this is the only value that matches what the
  /// customer will actually see inside the frame.
  final String language;

  /// True for a new card (full card form), false for a saved one.
  ///
  /// A saved card is not "nothing to type": the gateway renders its own CVV
  /// input and reads the code straight from it, so this surface stays on screen
  /// either way — just far shorter.
  final bool showFields;

  final PaymentCardController controller;

  /// Fires once the page has handed the card to the session, when it couldn't,
  /// or when the customer picked a method that finishes elsewhere.
  final void Function(CardSurfaceReport report) onEvent;

  const PaymentCardSurface({
    super.key,
    required this.sessionId,
    required this.countryCode,
    required this.language,
    required this.controller,
    required this.onEvent,
    this.showFields = true,
  });

  @override
  State<PaymentCardSurface> createState() => _PaymentCardSurfaceState();
}

class _PaymentCardSurfaceState extends State<PaymentCardSurface> {
  late final WebViewController _web;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('SapbaqBridge', onMessageReceived: _onMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          // Allow https and block everything else.
          //
          // The tighter "only our own URL" rule looks safer and is not: the
          // gateway's library renders the card inputs in an iframe on *its*
          // domain, and on Android subframe loads come through here too. That
          // rule would have blocked the card fields from ever appearing — the
          // one thing this widget exists to show.
          //
          // What still can't happen is what the rule was for: a non-https
          // scheme, which is how a page hands off to another app.
          onNavigationRequest: (request) => request.url.startsWith('https://')
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      );
    widget.controller._submitNew = _submitNew;
    widget.controller._submitSaved = _submitSaved;
  }

  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _web.setBackgroundColor(context.colors.surface);
    // Loaded here, not in `build`: the URL carries our language and theme, so
    // it needs a context — but starting a page load from `build` means doing it
    // again on every rebuild the sheet triggers.
    if (!_loaded) {
      _loaded = true;
      _load();
    }
  }

  @override
  void dispose() {
    widget.controller._detach();
    super.dispose();
  }

  void _load() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // The session's language, falling back to the app's only if the server
    // didn't say. Using the app's locale directly would let the page's own
    // direction and copy disagree with the fields inside it — an Arabic frame
    // around English inputs — whenever the language changed between opening the
    // sheet and the session being created.
    final lang = widget.language.trim().isNotEmpty
        ? widget.language.trim().toLowerCase()
        : Localizations.localeOf(context).languageCode;
    final uri = Uri.parse(Environment.payEmbedUrl).replace(
      queryParameters: {
        'session_id': widget.sessionId,
        // Required by the gateway's CVV setup — without it the saved-card field
        // silently fails to render at all.
        'country': widget.countryCode,
        'lang': lang,
        'theme': isDark ? 'dark' : 'light',
        'mode': widget.showFields ? 'new' : 'saved',
      },
    );
    _web.loadRequest(uri);
  }

  void _onMessage(JavaScriptMessage message) {
    Map<String, dynamic> payload;
    try {
      payload = Map<String, dynamic>.from(jsonDecode(message.message) as Map);
    } catch (_) {
      // Unparseable is not "collected" — anything we don't understand is a
      // failure, never a success. Guessing the other way charges people.
      widget.onEvent(const CardSurfaceReport(CardSurfaceEvent.failed));
      return;
    }
    final event = (payload['event'] ?? '').toString();
    final text = (payload['message'] as String?)?.trim();
    // Anything unrecognised is a failure, never a success — guessing the other
    // way charges people.
    final kind = switch (event) {
      'collected' => CardSurfaceEvent.collected,
      'redirect' => CardSurfaceEvent.redirect,
      _ => CardSurfaceEvent.failed,
    };
    widget.onEvent(
      CardSurfaceReport(
        kind,
        message: text == null || text.isEmpty ? null : text,
        // `hosted_method` rides along on the same message and is deliberately
        // ignored: it names KNET or a wallet for the page's own logging, and
        // the URL already says where to go.
        url: (payload['url'] ?? '').toString().trim(),
      ),
    );
  }

  Future<void> _submitNew() =>
      _web.runJavaScript('window.sapbaqSubmit && window.sapbaqSubmit();');

  Future<void> _submitSaved(String token) => _web.runJavaScript(
    'window.sapbaqSubmitSaved && '
    'window.sapbaqSubmitSaved(${jsonEncode(token)});',
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(controller: _web),
        // No spinner over a collapsed surface: there is nothing to wait for and
        // a one-pixel strip of it would just flicker.
        if (_loading && widget.showFields)
          Positioned.fill(
            child: ColoredBox(
              color: context.colors.surface,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

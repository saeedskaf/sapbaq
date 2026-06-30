import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/constants/app_assets.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/info/data/content_repository.dart';
import 'package:sapbaq/features/info/data/models/contact_info.dart';
import 'package:sapbaq/features/info/info_content.dart';
import 'package:sapbaq/features/info/presentation/bloc/content_cubit.dart';
import 'package:sapbaq/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shared scaffold for the static info pages: an app bar title over a padded,
/// scrollable body.
class _InfoPage extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _InfoPage({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: TextCustom.subheading(text: title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: children,
      ),
    );
  }
}

/// A heading + paragraph block, used by the privacy and terms pages.
class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextCustom(
            text: title,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.colors.primary,
          ),
          const SizedBox(height: 8),
          TextCustom(
            text: body,
            fontSize: 14,
            color: context.colors.textSecondary,
          ),
        ],
      ),
    );
  }
}

/// A CMS-backed page (`/content/{slug}/`). Privacy/terms/about render the page
/// `body` (+ optional sub-sections); FAQ renders `sections` as an accordion of
/// question/answer pairs. Content is bilingual (follows the active language).
class _CmsPage extends StatelessWidget {
  final String slug;
  final String title;
  final bool isFaq;
  const _CmsPage({required this.slug, required this.title, this.isFaq = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (context) =>
          ContentCubit(context.read<ContentRepository>(), slug)..load(),
      child: Scaffold(
        appBar: AppBar(title: TextCustom.subheading(text: title)),
        body: BlocBuilder<ContentCubit, ContentState>(
          builder: (context, state) {
            if (state.status == LoadStatus.initial ||
                state.status == LoadStatus.loading) {
              return const LoadingView();
            }
            // Content comes from the CMS. If it isn't published yet (missing or
            // empty), show a simple message instead of an error.
            final page = state.page;
            final empty =
                page == null ||
                (page.body.trim().isEmpty && page.sections.isEmpty);
            if (empty) {
              return EmptyView(
                message: l10n.comingSoon,
                icon: Icons.description_outlined,
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: isFaq
                  ? [
                      for (final s in page.sections)
                        _FaqItem(question: s.title, answer: s.body),
                    ]
                  : [
                      if (page.body.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: TextCustom(
                            text: page.body,
                            fontSize: 14,
                            color: context.colors.textSecondary,
                          ),
                        ),
                      for (final s in page.sections)
                        _Section(title: s.title, body: s.body),
                    ],
            );
          },
        ),
      ),
    );
  }
}

/// About — a branded header (logo + name + version) over the CMS `about` body.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logo = isDark ? AppAssets.logoFullOnDark : AppAssets.logoFullOnLight;
    return BlocProvider(
      create: (context) =>
          ContentCubit(context.read<ContentRepository>(), 'about')..load(),
      child: Scaffold(
        appBar: AppBar(title: TextCustom.subheading(text: l10n.profileAbout)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Center(
              child: Column(
                children: [
                  Image.asset(logo, height: 72),
                  const SizedBox(height: 16),
                  TextCustom.subheading(text: l10n.appName),
                  const SizedBox(height: 4),
                  // Read the real build version from the platform; fall back to
                  // the bundled constant until it resolves.
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) => TextCustom.caption(
                      text: l10n.versionLabel(
                        snapshot.data?.version ?? InfoContent.appVersion,
                      ),
                      color: context.colors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            BlocBuilder<ContentCubit, ContentState>(
              builder: (context, state) {
                // The branded header above always shows; the CMS `about` body is
                // rendered only when it's been published.
                final page = state.page;
                if (page == null) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (page.body.trim().isNotEmpty)
                      TextCustom(
                        text: page.body,
                        fontSize: 14,
                        color: context.colors.textSecondary,
                      ),
                    if (page.body.trim().isNotEmpty && page.sections.isNotEmpty)
                      const SizedBox(height: 20),
                    for (final s in page.sections)
                      _Section(title: s.title, body: s.body),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Contact us — support details come from the backend (`GET /content/contact/`);
/// built-in defaults are shown until it responds (and if it has no entry), so
/// the user can always reach support.
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  late final Future<ContactInfo> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ContentRepository>().fetchContact();
  }

  Future<void> _launch(Uri uri) async {
    final l10n = AppLocalizations.of(context)!;
    bool ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok && mounted) {
      ShowMessage.error(context, l10n.cannotOpenFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _InfoPage(
      title: l10n.profileContact,
      children: [
        TextCustom(
          text: l10n.contactIntro,
          fontSize: 14,
          color: context.colors.textSecondary,
        ),
        const SizedBox(height: 20),
        FutureBuilder<ContactInfo>(
          future: _future,
          builder: (context, snapshot) {
            // Backend value when available; built-in fallback otherwise.
            final info = snapshot.data ?? const ContactInfo.fallback();
            final waDigits = info.whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (info.hasPhone) ...[
                  _ContactRow(
                    icon: Icons.call_outlined,
                    label: l10n.contactCall,
                    value: info.phone,
                    onTap: () => _launch(Uri(scheme: 'tel', path: info.phone)),
                  ),
                  const SizedBox(height: 12),
                ],
                if (info.hasWhatsapp) ...[
                  _ContactRow(
                    icon: Icons.chat_outlined,
                    label: l10n.contactWhatsapp,
                    value: info.whatsapp,
                    onTap: () => _launch(Uri.parse('https://wa.me/$waDigits')),
                  ),
                  const SizedBox(height: 12),
                ],
                if (info.hasEmail)
                  _ContactRow(
                    icon: Icons.mail_outline_rounded,
                    label: l10n.contactEmail,
                    value: info.email,
                    onTap: () =>
                        _launch(Uri(scheme: 'mailto', path: info.email)),
                  ),
                // if (info.address.isNotEmpty) ...[
                //   const SizedBox(height: 16),
                //   _ContactMeta(
                //     icon: Icons.location_on_outlined,
                //     text: info.address,
                //   ),
                // ],
                // if (info.workingHours.isNotEmpty) ...[
                //   const SizedBox(height: 10),
                //   _ContactMeta(
                //     icon: Icons.schedule_outlined,
                //     text: info.workingHours,
                //   ),
                // ],
              ],
            );
          },
        ),
      ],
    );
  }
}

/// A muted icon + text line for non-tappable contact details (address, hours).
class _ContactMeta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ContactMeta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: context.colors.textHint),
        const SizedBox(width: 10),
        Expanded(
          child: TextCustom(
            text: text,
            fontSize: 13.5,
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.colors.border, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.primaryTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: context.colors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextCustom(
                      text: label,
                      fontSize: 13,
                      color: context.colors.textSecondary,
                    ),
                    const SizedBox(height: 2),
                    TextCustom(
                      text: value,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.colors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _CmsPage(slug: 'privacy', title: l10n.profilePrivacy);
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _CmsPage(slug: 'terms', title: l10n.profileTerms);
  }
}

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _CmsPage(slug: 'faq', title: l10n.profileFaq, isFaq: true);
  }
}

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.border, width: 0.5),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              iconColor: context.colors.primary,
              collapsedIconColor: context.colors.textHint,
              shape: const Border(),
              collapsedShape: const Border(),
              title: TextCustom(
                text: question,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextCustom(
                    text: answer,
                    fontSize: 13,
                    color: context.colors.textSecondary,
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

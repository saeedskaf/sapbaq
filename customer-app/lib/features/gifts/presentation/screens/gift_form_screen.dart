import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/media_url.dart';
import 'package:sapbaq/core/utils/form_validators.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_form_field.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:sapbaq/features/gifts/data/gifts_repository.dart';
import 'package:sapbaq/features/gifts/data/models/gift.dart';
import 'package:sapbaq/features/gifts/data/models/gift_category.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Attach / replace the cart's gift (إهداء) on a single screen: pick a category
/// (defaults to عام) which drives the template picker, then fill in the names +
/// WhatsApp number. Pass [existing] to edit. The relation is inferred
/// server-side from the chosen template's category.
class GiftFormScreen extends StatefulWidget {
  final Gift? existing;

  const GiftFormScreen({super.key, this.existing});

  @override
  State<GiftFormScreen> createState() => _GiftFormScreenState();
}

class _GiftFormScreenState extends State<GiftFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dedicatedController = TextEditingController();
  final _senderController = TextEditingController();

  LoadStatus _categoriesStatus = LoadStatus.loading;
  List<GiftCategory> _categories = const [];
  GiftCategory? _selectedCategory;

  LoadStatus _templatesStatus = LoadStatus.loading;
  List<GiftTemplate> _templates = const [];
  int? _selectedTemplateId;

  String _phone = '';
  String? _phoneError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _dedicatedController.text = existing.dedicatedToName;
      _senderController.text = existing.senderName;
      _selectedTemplateId = existing.template?.id;
      _phone = existing.notifyPhone;
    }
    _loadCategories();
  }

  @override
  void dispose() {
    _dedicatedController.dispose();
    _senderController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _categoriesStatus = LoadStatus.loading);
    try {
      final categories = await context.read<GiftsRepository>().fetchCategories();
      if (!mounted) return;
      final initial = _initialCategory(categories);
      setState(() {
        _categories = categories;
        _selectedCategory = initial;
        _categoriesStatus = LoadStatus.success;
      });
      if (initial != null) {
        await _loadTemplates(initial.id);
      } else {
        setState(() => _templatesStatus = LoadStatus.success);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _categoriesStatus = LoadStatus.failure);
    }
  }

  /// Editing → the gift's template category; otherwise عام (GENERAL); else first.
  GiftCategory? _initialCategory(List<GiftCategory> categories) {
    final existingCategoryId = widget.existing?.template?.categoryId;
    for (final c in categories) {
      if (existingCategoryId != null && c.id == existingCategoryId) return c;
    }
    for (final c in categories) {
      if (c.relationType == 'GENERAL') return c;
    }
    return categories.isEmpty ? null : categories.first;
  }

  Future<void> _loadTemplates(int categoryId) async {
    setState(() => _templatesStatus = LoadStatus.loading);
    try {
      final templates = await context
          .read<GiftsRepository>()
          .fetchCategoryTemplates(categoryId);
      // Ignore a response that arrives after the user switched category again.
      if (!mounted || _selectedCategory?.id != categoryId) return;
      setState(() {
        _templates = templates;
        _templatesStatus = LoadStatus.success;
        if (!templates.any((t) => t.id == _selectedTemplateId)) {
          _selectedTemplateId = templates.isEmpty ? null : templates.first.id;
        }
      });
    } catch (_) {
      if (!mounted || _selectedCategory?.id != categoryId) return;
      setState(() => _templatesStatus = LoadStatus.failure);
    }
  }

  void _onCategorySelected(GiftCategory category) {
    if (category.id == _selectedCategory?.id) return;
    setState(() {
      _selectedCategory = category;
      _selectedTemplateId = null;
    });
    _loadTemplates(category.id);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final cart = context.read<CartCubit>();
    setState(() => _phoneError = _phone.isEmpty ? l10n.phoneRequired : null);
    final formOk = _formKey.currentState?.validate() ?? false;
    if (_selectedTemplateId == null) {
      ShowMessage.error(context, l10n.chooseTemplate);
      return;
    }
    if (!formOk || _phoneError != null) return;

    setState(() => _busy = true);
    final ok = await cart.attachGift(
      dedicatedToName: _dedicatedController.text.trim(),
      senderName: _senderController.text.trim(),
      notifyPhone: _phone,
      templateId: _selectedTemplateId!,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      ShowMessage.success(context, l10n.giftAdded);
      context.pop();
    } else {
      ShowMessage.error(context, cart.state.message ?? l10n.comingSoon);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final validators = FormValidators(context);
    final title = widget.existing != null
        ? l10n.editGiftTitle
        : l10n.giftFormTitle;

    return Scaffold(
      appBar: AppBar(title: TextCustom.subheading(text: title)),
      body: switch (_categoriesStatus) {
        LoadStatus.initial || LoadStatus.loading => const LoadingView(),
        LoadStatus.failure => ErrorView(
          message: l10n.comingSoon,
          retryLabel: l10n.retry,
          onRetry: _loadCategories,
        ),
        LoadStatus.success => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextCustom(
                text: l10n.chooseGiftCategory,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in _categories)
                    ChoiceChip(
                      label: TextCustom(
                        text: category.name,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _selectedCategory?.id == category.id
                            ? ColorsCustom.textOnPrimary
                            : context.colors.textSecondary,
                      ),
                      selected: _selectedCategory?.id == category.id,
                      showCheckmark: false,
                      selectedColor: context.colors.primary,
                      backgroundColor: context.colors.surfaceVariant,
                      side: BorderSide.none,
                      onSelected: (_) => _onCategorySelected(category),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              TextCustom(
                text: l10n.chooseTemplate,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(height: 10),
              _TemplatePicker(
                status: _templatesStatus,
                templates: _templates,
                selectedId: _selectedTemplateId,
                onSelect: (id) => setState(() => _selectedTemplateId = id),
                onRetry: () {
                  final id = _selectedCategory?.id;
                  if (id != null) _loadTemplates(id);
                },
              ),
              const SizedBox(height: 20),
              FormFieldCustom(
                controller: _dedicatedController,
                label: l10n.dedicatedToLabel,
                hintText: l10n.dedicatedToHint,
                validator: validators.requiredValidator,
              ),
              const SizedBox(height: 18),
              FormFieldCustom(
                controller: _senderController,
                label: l10n.senderNameLabel,
                validator: validators.requiredValidator,
              ),
              const SizedBox(height: 18),
              PhoneFieldCustom(
                label: l10n.whatsappLabel,
                initialValue: widget.existing?.notifyPhone,
                errorText: _phoneError,
                onChanged: (p) => _phone = p.completeNumber,
              ),
            ],
          ),
        ),
      },
      bottomNavigationBar: _categoriesStatus == LoadStatus.success
          ? SafeArea(
              minimum: const EdgeInsets.all(16),
              child: ButtonCustom.primary(
                text: l10n.saveGift,
                isLoading: _busy,
                onPressed: _submit,
              ),
            )
          : null,
    );
  }
}

/// The template strip for the selected category — handles its own
/// loading/empty/error so switching category doesn't blank the whole screen.
class _TemplatePicker extends StatelessWidget {
  final LoadStatus status;
  final List<GiftTemplate> templates;
  final int? selectedId;
  final ValueChanged<int> onSelect;
  final VoidCallback onRetry;

  const _TemplatePicker({
    required this.status,
    required this.templates,
    required this.selectedId,
    required this.onSelect,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 128,
      child: switch (status) {
        LoadStatus.initial || LoadStatus.loading => Center(
          child: CircularProgressIndicator(color: context.colors.primary),
        ),
        LoadStatus.failure => Center(
          child: TextButton(
            onPressed: onRetry,
            child: TextCustom(
              text: l10n.retry,
              fontWeight: FontWeight.w600,
              color: context.colors.primary,
            ),
          ),
        ),
        LoadStatus.success when templates.isEmpty => Center(
          child: TextCustom(
            text: l10n.noTemplatesInCategory,
            fontSize: 13,
            color: context.colors.textSecondary,
          ),
        ),
        LoadStatus.success => ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: templates.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, i) {
            final t = templates[i];
            return _TemplateCard(
              template: t,
              selected: t.id == selectedId,
              onTap: () => onSelect(t.id),
            );
          },
        ),
      },
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final GiftTemplate template;
  final bool selected;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final url = resolveMediaUrl(template.image);
    return GestureDetector(
      onTap: () {
        onTap();
        if (url != null) _showTemplatePreview(context, template, url);
      },
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? context.colors.primary : context.colors.border,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (url == null)
                    ColoredBox(
                      color: context.colors.surfaceVariant,
                      child: Icon(
                        Icons.card_giftcard_rounded,
                        color: context.colors.primary,
                      ),
                    )
                  else
                    Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: context.colors.surfaceVariant,
                        child: Icon(
                          Icons.card_giftcard_rounded,
                          color: context.colors.primary,
                        ),
                      ),
                    ),
                  if (url != null)
                    const PositionedDirectional(
                      top: 6,
                      end: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(3),
                          child: Icon(
                            Icons.zoom_in_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: TextCustom(
                text: template.label,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen, pinch-to-zoom preview of a template's artwork.
void _showTemplatePreview(BuildContext context, GiftTemplate template, String url) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.9),
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ),
          Flexible(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => AspectRatio(
                    aspectRatio: 1,
                    child: ColoredBox(
                      color: context.colors.surfaceVariant,
                      child: Icon(
                        Icons.card_giftcard_rounded,
                        color: context.colors.primary,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (template.label.isNotEmpty) ...[
            const SizedBox(height: 12),
            TextCustom(
              text: template.label,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    ),
  );
}

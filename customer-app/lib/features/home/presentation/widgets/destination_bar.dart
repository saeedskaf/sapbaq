import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/most_needed_badge.dart';
import 'package:sapbaq/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:sapbaq/features/cart/presentation/widgets/destination_picker_sheet.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// The storefront's persistent destination context — the "deliver to" bar of
/// delivery apps, repurposed: «أهدِ إلى: مسجد النور ▾». Every add-to-cart goes
/// to this destination's cart (find-or-create), so switching it mid-browse is
/// how parallel carts for different mosques get built.
class DestinationBar extends StatelessWidget {
  const DestinationBar({super.key});

  Future<void> _pick(BuildContext context) async {
    final picked = await showDestinationPicker(context);
    if (picked != null && context.mounted) {
      context.read<CartCubit>().selectDestination(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<CartCubit, CartState>(
      buildWhen: (a, b) => a.currentDestination != b.currentDestination,
      builder: (context, state) {
        final dest = state.currentDestination;
        return Material(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _pick(context),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.border, width: 0.8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.colors.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        dest == null
                            ? Icons.add_location_alt_outlined
                            : (dest.isMostNeeded
                                  ? Icons.volunteer_activism_rounded
                                  : Icons.mosque_rounded),
                        size: 20,
                        color: context.colors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextCustom(
                            text: l10n.destBarTitle,
                            fontSize: 11.5,
                            color: context.colors.textSecondary,
                          ),
                          const SizedBox(height: 1),
                          Row(
                            children: [
                              Flexible(
                                child: TextCustom(
                                  // Always the mosque's own name — the bar
                                  // never shows "الأكثر حاجة" in its place.
                                  text: dest?.label ?? l10n.destBarChoose,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: dest == null
                                      ? context.colors.primary
                                      : context.colors.textPrimary,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (dest?.isMostNeeded ?? false) ...[
                                const SizedBox(width: 6),
                                const MostNeededBadge(),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: context.colors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Payment landed. The primary action leads to what was just created — the
/// order itself ([orderId] from a single-cart payment) or «طلباتي» after
/// «ادفع الكل» (several orders, no single id to open) — with home as the
/// quiet secondary exit.
class OrderSuccessScreen extends StatelessWidget {
  final int? orderId;

  const OrderSuccessScreen({super.key, this.orderId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                    color: ColorsCustom.brandMint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 64,
                    color: ColorsCustom.onMint,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              TextCustom.heading(
                text: l10n.orderSuccessTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextCustom.body(
                text: l10n.orderSuccessDesc,
                color: context.colors.textSecondary,
                fontSize: 15,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              ButtonCustom.primary(
                text: orderId == null ? l10n.viewMyOrders : l10n.viewOrder,
                onPressed: () {
                  if (orderId == null) {
                    context.goNamed(AppRoutes.ordersName);
                  } else {
                    context.goNamed(
                      AppRoutes.orderDetailName,
                      pathParameters: {'id': '$orderId'},
                    );
                  }
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => context.goNamed(AppRoutes.homeName),
                child: TextCustom(
                  text: l10n.backToHome,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

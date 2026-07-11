import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/app/router/go_router_refresh_stream.dart';
import 'package:sapbaq/core/network/session_manager.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/features/addresses/data/models/address.dart';
import 'package:sapbaq/features/addresses/presentation/screens/address_form_screen.dart';
import 'package:sapbaq/features/addresses/presentation/screens/addresses_screen.dart';
import 'package:sapbaq/features/app_shell/presentation/app_shell.dart';
import 'package:sapbaq/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq/features/auth/presentation/screens/device_trust_screen.dart';
import 'package:sapbaq/features/auth/presentation/screens/forgot_passcode_screen.dart';
import 'package:sapbaq/features/auth/presentation/screens/lock_screen.dart';
import 'package:sapbaq/features/auth/presentation/screens/login_screen.dart';
import 'package:sapbaq/features/auth/presentation/screens/otp_screen.dart';
import 'package:sapbaq/features/auth/presentation/screens/passcode_login_screen.dart';
import 'package:sapbaq/features/auth/presentation/screens/phone_verification_screen.dart';
import 'package:sapbaq/features/auth/presentation/screens/profile_completion_screen.dart';
import 'package:sapbaq/features/auth/presentation/screens/set_passcode_screen.dart';
import 'package:sapbaq/features/auth/presentation/screens/splash_screen.dart';
import 'package:sapbaq/features/auth/presentation/screens/trusted_devices_screen.dart';
import 'package:sapbaq/features/cart/data/models/donation_destination.dart';
import 'package:sapbaq/features/cart/presentation/screens/cart_screen.dart';
import 'package:sapbaq/features/cart/presentation/screens/checkout_screen.dart';
import 'package:sapbaq/features/cart/presentation/screens/order_success_screen.dart';
import 'package:sapbaq/features/gifts/data/models/gift.dart';
import 'package:sapbaq/features/gifts/presentation/screens/gift_form_screen.dart';
import 'package:sapbaq/features/home/presentation/screens/home_screen.dart';
import 'package:sapbaq/features/info/presentation/screens/info_screens.dart';
import 'package:sapbaq/features/mosques/presentation/screens/favorites_screen.dart';
import 'package:sapbaq/features/mosques/presentation/screens/mosque_detail_screen.dart';
import 'package:sapbaq/features/mosques/presentation/screens/mosques_screen.dart';
import 'package:sapbaq/features/notifications/presentation/screens/notification_preferences_screen.dart';
import 'package:sapbaq/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:sapbaq/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:sapbaq/features/orders/presentation/screens/orders_screen.dart';
import 'package:sapbaq/features/products/presentation/screens/product_detail_screen.dart';
import 'package:sapbaq/features/products/presentation/screens/products_screen.dart';
import 'package:sapbaq/features/profile/presentation/screens/profile_screen.dart';
import 'package:sapbaq/features/settings/presentation/screens/appearance_screen.dart';
import 'package:sapbaq/features/settings/presentation/screens/language_screen.dart';
import 'package:sapbaq/features/showcase/presentation/screens/showcase_screen.dart';
import 'package:sapbaq/features/support/presentation/screens/new_ticket_screen.dart';
import 'package:sapbaq/features/support/presentation/screens/support_screen.dart';
import 'package:sapbaq/features/support/presentation/screens/ticket_detail_screen.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Resolves the donation destination passed via `extra`, defaulting to the
/// most-needed pool (e.g. on a cold deep link where `extra` is absent).
DonationDestination _destinationOf(BuildContext context, GoRouterState state) {
  final extra = state.extra;
  if (extra is DonationDestination) return extra;
  return DonationDestination.mostNeeded(
    label: AppLocalizations.of(context)!.mostNeededShort,
  );
}

/// Account-bound destinations a guest can't open (pushed full-screen routes).
/// The Orders and Profile *tabs* stay reachable — they render a guest prompt
/// in-place instead of redirecting, to keep the shell's indexed stack intact.
bool _isGuestBlocked(String location) {
  return location == AppRoutes.cart ||
      location == AppRoutes.checkout ||
      location == AppRoutes.orderSuccess ||
      location == AppRoutes.giftForm ||
      location == AppRoutes.notifications ||
      location == AppRoutes.notificationPrefs ||
      location == AppRoutes.addresses ||
      location == AppRoutes.addressForm ||
      location == AppRoutes.favorites ||
      location == AppRoutes.trustedDevices ||
      location == AppRoutes.support ||
      location == AppRoutes.newTicket ||
      location.startsWith('/ticket/') ||
      location.startsWith('/order/');
}

/// Builds the app router. Redirects are driven by [AuthBloc] state:
/// unknown → splash, unauthenticated → auth flow, completingProfile/
/// settingPasscode → onboarding, locked → unlock, guest → shell (account flows
/// gated), authenticated → shell.
GoRouter createRouter(AuthBloc authBloc) {
  // Pre-session sign-in screens (status still unauthenticated until a session
  // is issued at the end of the flow).
  const authLocations = {
    AppRoutes.login,
    AppRoutes.otp,
    AppRoutes.passcodeLogin,
    AppRoutes.deviceTrust,
    AppRoutes.forgotPasscode,
  };
  // Session present but not yet usable (finishing onboarding).
  const onboardingLocations = {
    AppRoutes.verifyPhone,
    AppRoutes.completeProfile,
    AppRoutes.setPasscode,
  };

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final status = authBloc.state.status;
      final location = state.matchedLocation;
      final atSplash = location == AppRoutes.splash;
      final atLock = location == AppRoutes.lock;
      final inAuthFlow = authLocations.contains(location);
      final inOnboarding = onboardingLocations.contains(location);

      if (status == AuthStatus.unknown) {
        return atSplash ? null : AppRoutes.splash;
      }
      if (status == AuthStatus.completingProfile) {
        // Signed in but not usable yet: verify a phone (if missing) then
        // complete the profile. Keep the user inside this flow.
        final needsPhone = authBloc.state.user?.phone == null;
        final target = needsPhone
            ? AppRoutes.verifyPhone
            : AppRoutes.completeProfile;
        if (location != AppRoutes.verifyPhone &&
            location != AppRoutes.completeProfile) {
          return target;
        }
        // Phone now verified → advance from the phone step to profile.
        if (!needsPhone && location == AppRoutes.verifyPhone) {
          return AppRoutes.completeProfile;
        }
        return null;
      }
      if (status == AuthStatus.settingPasscode) {
        return location == AppRoutes.setPasscode ? null : AppRoutes.setPasscode;
      }
      if (status == AuthStatus.locked) {
        // Unlock screen — but allow passcode recovery to be opened over it.
        if (atLock || location == AppRoutes.forgotPasscode) return null;
        return AppRoutes.lock;
      }
      if (status == AuthStatus.unauthenticated) {
        return inAuthFlow ? null : AppRoutes.login;
      }
      if (status == AuthStatus.guest) {
        if (atSplash) return AppRoutes.home;
        // Guests browse freely and may open the auth screens to sign in; only
        // the account-bound flows are off-limits.
        if (_isGuestBlocked(location)) return AppRoutes.login;
        return null;
      }
      // authenticated
      if (atSplash || atLock || inAuthFlow || inOnboarding) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        name: AppRoutes.otpName,
        builder: (_, state) => OtpScreen(
          phone: state.uri.queryParameters['phone'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.passcodeLogin,
        name: AppRoutes.passcodeLoginName,
        builder: (_, state) => PasscodeLoginScreen(
          phone: state.uri.queryParameters['phone'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.deviceTrust,
        name: AppRoutes.deviceTrustName,
        builder: (_, state) => DeviceTrustScreen(
          phone: state.uri.queryParameters['phone'] ?? '',
          passcode: state.extra as String? ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPasscode,
        name: AppRoutes.forgotPasscodeName,
        builder: (_, state) => ForgotPasscodeScreen(
          phone: state.uri.queryParameters['phone'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.lock,
        name: AppRoutes.lockName,
        builder: (_, _) => const LockScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyPhone,
        name: AppRoutes.verifyPhoneName,
        builder: (_, _) => const PhoneVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.completeProfile,
        name: AppRoutes.completeProfileName,
        builder: (_, _) => const ProfileCompletionScreen(),
      ),
      GoRoute(
        path: AppRoutes.setPasscode,
        name: AppRoutes.setPasscodeName,
        builder: (_, _) => const SetPasscodeScreen(),
      ),
      // Donation flow + detail screens — full-screen over the shell (pushed).
      GoRoute(
        path: AppRoutes.products,
        name: AppRoutes.productsName,
        builder: (context, state) =>
            ProductsScreen(destination: _destinationOf(context, state)),
      ),
      GoRoute(
        path: AppRoutes.productDetail,
        name: AppRoutes.productDetailName,
        builder: (context, state) => ProductDetailScreen(
          productId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          destination: _destinationOf(context, state),
        ),
      ),
      GoRoute(
        path: AppRoutes.mosqueDetail,
        name: AppRoutes.mosqueDetailName,
        builder: (_, state) => MosqueDetailScreen(
          mosqueId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: AppRoutes.cart,
        name: AppRoutes.cartName,
        builder: (_, _) => const CartScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        name: AppRoutes.checkoutName,
        builder: (_, _) => const CheckoutScreen(),
      ),
      GoRoute(
        path: AppRoutes.orderSuccess,
        name: AppRoutes.orderSuccessName,
        builder: (_, _) => const OrderSuccessScreen(),
      ),
      GoRoute(
        path: AppRoutes.giftForm,
        name: AppRoutes.giftFormName,
        builder: (_, state) => GiftFormScreen(existing: state.extra as Gift?),
      ),
      GoRoute(
        path: AppRoutes.orderDetail,
        name: AppRoutes.orderDetailName,
        builder: (_, state) => OrderDetailScreen(
          orderId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: AppRoutes.notificationsName,
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.about,
        name: AppRoutes.aboutName,
        builder: (_, _) => const AboutScreen(),
      ),
      GoRoute(
        path: AppRoutes.contact,
        name: AppRoutes.contactName,
        builder: (_, _) => const ContactScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        name: AppRoutes.privacyName,
        builder: (_, _) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: AppRoutes.terms,
        name: AppRoutes.termsName,
        builder: (_, _) => const TermsScreen(),
      ),
      GoRoute(
        path: AppRoutes.faq,
        name: AppRoutes.faqName,
        builder: (_, _) => const FaqScreen(),
      ),
      // Profile + settings — full-screen over the shell. Profile now lives in
      // the top corner of Home (not the bottom dock), opened as a pushed route.
      GoRoute(
        path: AppRoutes.profile,
        name: AppRoutes.profileName,
        builder: (_, _) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.appearance,
        name: AppRoutes.appearanceName,
        builder: (_, _) => const AppearanceScreen(),
      ),
      GoRoute(
        path: AppRoutes.language,
        name: AppRoutes.languageName,
        builder: (_, _) => const LanguageScreen(),
      ),
      GoRoute(
        path: AppRoutes.notificationPrefs,
        name: AppRoutes.notificationPrefsName,
        builder: (_, _) => const NotificationPreferencesScreen(),
      ),
      GoRoute(
        path: AppRoutes.addresses,
        name: AppRoutes.addressesName,
        builder: (_, _) => const AddressesScreen(),
      ),
      GoRoute(
        path: AppRoutes.addressForm,
        name: AppRoutes.addressFormName,
        builder: (_, state) =>
            AddressFormScreen(existing: state.extra as Address?),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        name: AppRoutes.favoritesName,
        builder: (_, _) => const FavoritesScreen(),
      ),
      GoRoute(
        path: AppRoutes.trustedDevices,
        name: AppRoutes.trustedDevicesName,
        builder: (_, _) => const TrustedDevicesScreen(),
      ),
      GoRoute(
        path: AppRoutes.support,
        name: AppRoutes.supportName,
        builder: (_, _) => const SupportScreen(),
      ),
      GoRoute(
        path: AppRoutes.newTicket,
        name: AppRoutes.newTicketName,
        builder: (_, _) => const NewTicketScreen(),
      ),
      GoRoute(
        path: AppRoutes.ticketDetail,
        name: AppRoutes.ticketDetailName,
        builder: (_, state) => TicketDetailScreen(
          ticketId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          // Home tab — products + product detail
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: AppRoutes.homeName,
                builder: (_, _) => const HomeScreen(),
              ),
            ],
          ),
          // Mosques tab (list + map)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.mosques,
                name: AppRoutes.mosquesName,
                builder: (_, state) {
                  final q = state.uri.queryParameters;
                  return MosquesScreen(
                    focusLat: double.tryParse(q['lat'] ?? ''),
                    focusLng: double.tryParse(q['lng'] ?? ''),
                  );
                },
              ),
            ],
          ),
          // Media (showcase) tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.media,
                name: AppRoutes.mediaName,
                builder: (_, _) => const ShowcaseScreen(),
              ),
            ],
          ),
          // Orders tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.orders,
                name: AppRoutes.ordersName,
                builder: (_, _) => const OrdersScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: TextCustom.subheading(text: state.error?.toString() ?? '404'),
      ),
    ),
  );
}

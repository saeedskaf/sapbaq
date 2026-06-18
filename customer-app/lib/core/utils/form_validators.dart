import 'package:flutter/material.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Localized, reusable form validators.
///
/// Construct with a [BuildContext] so messages resolve through [AppLocalizations]:
/// `final validators = FormValidators(context);`
///
/// Scope is intentionally limited to auth + generic fields. Add feature-specific
/// validators (orders, support, etc.) alongside their screens as requirements land.
class FormValidators {
  final BuildContext context;

  FormValidators(this.context);

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  // --- auth ---

  String? phoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return l10n.phoneRequired;
    }
    final cleanPhone = value.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.length < 8) {
      return l10n.phoneTooShort;
    }
    if (cleanPhone.length > 15) {
      return l10n.phoneTooLong;
    }
    if (!RegExp(r'^\+?[0-9]+$').hasMatch(cleanPhone)) {
      return l10n.phoneOnlyNumbers;
    }
    return null;
  }

  String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return l10n.passwordRequired;
    }
    if (value.length < 8) {
      return l10n.passwordTooShort;
    }
    return null;
  }

  String? passwordMatchValidator(String password, String? value) {
    if (value == null || value.isEmpty) {
      return l10n.confirmPasswordRequired;
    }
    if (value != password) {
      return l10n.passwordsNotMatch;
    }
    return null;
  }

  String? fullNameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return l10n.fullNameRequired;
    }
    if (value.trim().length < 3) {
      return l10n.fullNameTooShort;
    }
    if (value.length > 100) {
      return l10n.fullNameTooLong;
    }
    return null;
  }

  String? otpValidator(String? value) {
    if (value == null || value.isEmpty) {
      return l10n.otpRequired;
    }
    if (value.length != 6) {
      return l10n.otpInvalid;
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return l10n.otpOnlyNumbers;
    }
    return null;
  }

  // --- general ---

  String? requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return l10n.fieldRequired;
    }
    return null;
  }

  String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email is optional unless combined with requiredValidator.
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return l10n.emailInvalid;
    }
    return null;
  }

  // --- helpers ---

  String? Function(String?) combineValidators(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) {
          return result;
        }
      }
      return null;
    };
  }
}

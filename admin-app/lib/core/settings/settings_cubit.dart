import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/settings/settings_service.dart';

/// App-wide UI preferences: theme mode + locale. Persisted via
/// [SettingsService]; the active language is mirrored into [languageCode] so
/// the networking layer can stamp `Accept-Language` on every request.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    required SettingsService service,
    required ValueNotifier<String> languageCode,
  }) : _service = service,
       _languageCode = languageCode,
       super(
         SettingsState(themeMode: service.themeMode, locale: service.locale),
       );

  final SettingsService _service;
  final ValueNotifier<String> _languageCode;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == state.themeMode) return;
    emit(state.copyWith(themeMode: mode));
    await _service.setThemeMode(mode);
  }

  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode == state.locale.languageCode) return;
    emit(state.copyWith(locale: locale));
    // Drive the API language immediately so subsequent requests return
    // localized errors + bilingual fields in the newly selected language.
    _languageCode.value = locale.languageCode;
    await _service.setLocale(locale);
  }
}

class SettingsState extends Equatable {
  const SettingsState({required this.themeMode, required this.locale});

  final ThemeMode themeMode;
  final Locale locale;

  SettingsState copyWith({ThemeMode? themeMode, Locale? locale}) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }

  @override
  List<Object?> get props => [themeMode, locale];
}

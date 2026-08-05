import 'package:equatable/equatable.dart';

/// Persisted UI preferences (single row): the customer's theme-mode and
/// locale choices.
///
/// Stored as stable **codes** — `ThemeMode.name` (`'light'`/`'dark'`/
/// `'system'`) and the BCP-47 locale tag (`'en'`/`'ar'`) — so this entity
/// stays pure Dart and the presentation layer owns the code <-> widget-type
/// mapping. Null fields mean "not chosen yet" (fall back to system / en).
class UiPrefs extends Equatable {
  const UiPrefs({this.themeModeCode, this.localeCode});

  final String? themeModeCode;
  final String? localeCode;

  bool get isEmpty => themeModeCode == null && localeCode == null;

  UiPrefs copyWith({String? themeModeCode, String? localeCode}) => UiPrefs(
        themeModeCode: themeModeCode ?? this.themeModeCode,
        localeCode: localeCode ?? this.localeCode,
      );

  @override
  List<Object?> get props => [themeModeCode, localeCode];
}

import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// A data model representing a supported application theme.
class CustomTheme {
  /// The user-friendly name of the theme (e.g., 'Dark Mode').
  final String name;

  /// The actual Flutter [ThemeData] object.
  final ThemeData themeData;

  CustomTheme(this.name, this.themeData);
}

//
// --- Cubit ---
//

class ThemeBloc extends Cubit<ThemeState> {
  final SharedPrefHelper prefHelper;

  ThemeBloc({required this.prefHelper}) : super(ThemeState(theme: Core.get<Config>().themes.first));

  int getThemeIndex() {
    return prefHelper.getThemeIndex();
  }

  void getTheme() async {
    var themeIndex = prefHelper.getThemeIndex();
    emit(ThemeState(theme: Core.get<Config>().themes.elementAt(themeIndex)));
  }

  Future setTheme(int themeIndex) async {
    await prefHelper.saveThemeIndex(themeIndex);
    emit(ThemeState(theme: Core.get<Config>().themes.elementAt(themeIndex)));
  }
}

//
// --- States ---
//

class ThemeState extends Equatable {
  final CustomTheme theme;

  const ThemeState({required this.theme});

  @override
  List<Object> get props => [theme];
}

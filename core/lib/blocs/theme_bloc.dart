import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class CustomTheme {
  final String name;
  final ThemeData themeData;

  CustomTheme(this.name, this.themeData);
}

class ThemeBloc extends Cubit<ThemeState> {
  final SharedPrefHelper prefHelper;

  ThemeBloc({required this.prefHelper})
    : super(ThemeState(theme: Core.get<Config>().themes.first));

  int getThemeIndex() {
    return prefHelper.getThemeIndex();
  }

  void getTheme() async {
    var themeIndex = prefHelper.getThemeIndex();
    var themeModeIndex = prefHelper.getThemeModeIndex();
    emit(ThemeState(
      theme: Core.get<Config>().themes.elementAt(themeIndex),
      themeMode: ThemeMode.values[themeModeIndex],
    ));
  }

  Future setTheme(int themeIndex) async {
    await prefHelper.saveThemeIndex(themeIndex);
    emit(ThemeState(
      theme: Core.get<Config>().themes.elementAt(themeIndex),
      themeMode: state.themeMode,
    ));
  }

  Future setThemeMode(ThemeMode mode) async {
    await prefHelper.saveThemeModeIndex(mode.index);
    emit(ThemeState(theme: state.theme, themeMode: mode));
  }
}

class ThemeState extends Equatable {
  final CustomTheme theme;
  final ThemeMode themeMode;

  const ThemeState({required this.theme, this.themeMode = ThemeMode.light});

  @override
  List<Object> get props => [theme, themeMode];
}

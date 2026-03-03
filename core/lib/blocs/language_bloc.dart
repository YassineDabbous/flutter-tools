import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// A data model representing a supported application language.
class CustomLang {
  /// The user-friendly name of the language (e.g., 'English').
  final String name;

  /// The [Locale] data used for system localization.
  final Locale data;

  const CustomLang(this.name, this.data);
}

//
// --- Cubit ---
//

class LanguageBloc extends Cubit<LanguageState> {
  final SharedPrefHelper prefHelper;

  static Iterable<CustomLang> get languages => Core.get<Config>().supportedLocales;

  LanguageBloc({required this.prefHelper}) : super(const LanguageState(lang: 0));

  void getLang() {
    var lang = prefHelper.getLanguageIndex();
    emit(LanguageState(lang: lang));
  }

  Future setLang(int lang) async {
    logUI.debug('set new lang ${languages.elementAt(lang)}');
    await prefHelper.saveLanguageIndex(lang);
    Core.get<I>().refresh();
    emit(LanguageState(lang: lang));
  }
}

//
// --- States ---
//

class LanguageState extends Equatable {
  final int lang;
  const LanguageState({required this.lang});

  CustomLang getLocale() {
    return LanguageBloc.languages.elementAt(lang);
  }

  @override
  List<int> get props => [lang];
}

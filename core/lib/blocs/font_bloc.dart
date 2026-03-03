import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

class FontBloc extends Cubit<FontState> {
  static const int defaultSize = 16;
  final SharedPrefHelper prefHelper;
  FontBloc({required this.prefHelper}) : super(const FontState(size: FontBloc.defaultSize));

  Future<void> getFont() async {
    var size = prefHelper.getFontSize();
    emit(FontState(size: size == 0 ? defaultSize : size));
  }

  Future setFont(int size) async {
    logUI.debug('set new size $size');
    await prefHelper.saveFontSize(size);
    emit(FontState(size: size));
  }
}

//
// --- States ---
//

class FontState extends Equatable {
  final int size;
  const FontState({required this.size});

  @override
  List<Object> get props => [size];
}

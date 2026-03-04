import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

/// Standard cart item model.
class CartItem<T> extends Equatable {
  final T product;
  final int quantity;

  const CartItem({required this.product, this.quantity = 1});

  CartItem<T> copyWith({T? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [product, quantity];
}

/// Standard cart state.
class CartState<T> extends Equatable {
  final List<CartItem<T>> items;
  const CartState({this.items = const []});

  double get totalCount => items.fold(0, (sum, item) => sum + item.quantity);

  @override
  List<Object?> get props => [items];
}

/// Base Cubit for cart management.
abstract class BaseCartCubit<T> extends Cubit<CartState<T>> {
  BaseCartCubit() : super(const CartState());

  void addItem(T product, {int quantity = 1}) {
    final List<CartItem<T>> updatedItems = List.from(state.items);
    final index = updatedItems.indexWhere((item) => (item.product as dynamic).id == (product as dynamic).id);

    if (index != -1) {
      updatedItems[index] = updatedItems[index].copyWith(
        quantity: updatedItems[index].quantity + quantity,
      );
    } else {
      updatedItems.add(CartItem(product: product, quantity: quantity));
    }

    emit(CartState(items: updatedItems));
  }

  void removeItem(int productId) {
    final updatedItems = state.items.where((item) => (item.product as dynamic).id != productId).toList();
    emit(CartState(items: updatedItems));
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final updatedItems = state.items.map((item) {
      if ((item.product as dynamic).id == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
    emit(CartState(items: updatedItems));
  }

  void clear() => emit(const CartState());
}

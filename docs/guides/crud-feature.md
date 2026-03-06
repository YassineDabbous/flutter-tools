# Guide: Building a CRUD Feature

This guide walks through creating a complete CRUD feature (e.g., Products) from model definition to UI, using the SDK packages.

---

## Prerequisites

Ensure you have these packages in your `pubspec.yaml`:

```yaml
dependencies:
  core:
    path: ../packages/core
  skeleton:
    path: ../packages/skeleton
  concrete:
    path: ../packages/concrete
  laravel_provider:             # or supabase_provider
    path: ../packages/laravel_provider
```

---

## Step 1: Define Your Models

### Data Model

```dart
// models/product.dart
import 'package:skeleton/skeleton.dart';

class Product extends BaseModel<int> {
  @override final int id;
  final String name;
  final double price;
  final String? imageUrl;

  @override String get label => name;

  Product({required this.id, required this.name, required this.price, this.imageUrl});

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'],
    name: json['name'],
    price: (json['price'] as num).toDouble(),
    imageUrl: json['image_url'],
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'price': price, 'image_url': imageUrl,
  };
}
```

### Edit Request

```dart
// models/product_request.dart
import 'package:skeleton/skeleton.dart';

class ProductRequest extends SuperModel<ProductRequest> {
  String? name;
  double? price;

  @override
  Map<String, dynamic> toJson() => {'name': name, 'price': price};

  @override
  ProductRequest fromJson(Map<String, dynamic> json) =>
    ProductRequest()..name = json['name']..price = (json['price'] as num?)?.toDouble();
}
```

### Search Filter

```dart
// models/product_filter.dart
import 'package:skeleton/skeleton.dart';

class ProductFilter extends SuperModel<ProductFilter> {
  String? search;
  double? minPrice;

  @override
  Map<String, dynamic> toJson() => {'search': search, 'min_price': minPrice};

  @override
  ProductFilter fromJson(Map<String, dynamic> json) =>
    ProductFilter()..search = json['search']..minPrice = (json['min_price'] as num?)?.toDouble();
}
```

---

## Step 2: Implement the API Service

### With Laravel Provider

```dart
// api/product_api_service.dart
import 'package:dio/dio.dart';
import 'package:laravel_provider/laravel_provider.dart';
import '../models/product.dart';
import '../models/product_request.dart';
import '../models/product_filter.dart';

class ProductApiServiceImpl
    extends LaravelApiService<Product, ProductRequest, ProductFilter, int> {
  final Dio _dio;

  ProductApiServiceImpl(this._dio);

  @override
  Future<ApiResponse<Product>> show({required int id, ProductFilter? params}) =>
    handle(() async {
      final response = await _dio.get('/products/$id');
      return BasicResponse<Product>.fromJson(
        response.data, (json) => Product.fromJson(json as Map<String, dynamic>),
      );
    });

  @override
  Future<ApiResponse<int>> create(ProductRequest request) =>
    handle(() async {
      final response = await _dio.post('/products', data: request.toJson());
      return BasicResponse<int>.fromJson(response.data, (json) => json as int);
    });

  @override
  Future<ApiResponse<int>> update({required int id, required ProductRequest request}) =>
    handle(() async {
      final response = await _dio.put('/products/$id', data: request.toJson());
      return BasicResponse<int>.fromJson(response.data, (json) => json as int);
    });

  @override
  Future<ApiResponse<int>> delete({required int id, ProductFilter? params}) =>
    handle(() async {
      final response = await _dio.delete('/products/$id');
      return BasicResponse<int>.fromJson(response.data, (json) => json as int);
    });

  @override
  Future<ApiResponse<PaginatedResponse<Product>>> paging({
    required int page, required ProductFilter request,
  }) => handle(() async {
    final response = await _dio.get('/products', queryParameters: {
      'page': page, ...request.toJson()..removeWhere((k, v) => v == null),
    });
    return BasicResponse<PaginatedResponse<Product>>.fromJson(
      response.data,
      (json) => LaravelPaginationResponse<Product>.fromJson(
        json, (item) => Product.fromJson(item as Map<String, dynamic>),
      ),
    );
  });

  @override
  Future<ApiResponse<List<Product>>> all({required ProductFilter request}) =>
    throw UnimplementedError();

  @override
  Future<ApiResponse<Product>> showForEdit({required int id, ProductFilter? params}) =>
    show(id: id, params: params);

  @override
  Future<ApiResponse<PaginatedResponse<Product>>> pagingCustomPath({
    required String path, required int page, required ProductFilter request,
  }) => throw UnimplementedError();

  @override
  Future<ApiResponse> manageRelations({required int id, required dynamic request}) =>
    throw UnimplementedError();
}
```

---

## Step 3: Create the BLoC / Cubit

### CRUD Cubit (single resource)

```dart
// blocs/product_cubit.dart
import 'package:skeleton/skeleton.dart';
import '../api/product_api_service.dart';
import '../models/product.dart';
import '../models/product_request.dart';
import '../models/product_filter.dart';

class ProductCubit
    extends MyBaseBloc<ProductApiServiceImpl, ProductState>
    with CrudBloc<ProductApiServiceImpl, ProductState, Product, ProductRequest, ProductFilter, int>,
         AutoCrudBloc<ProductApiServiceImpl, ProductState, Product, ProductRequest, ProductFilter, int> {

  ProductCubit() : super(bs: ProductState());
}

// States
class ProductState extends MyBaseState<ProductState>
    with CrudState<ProductState, Product, int> {

  @override ProductState get initial => ProductState();
  @override ProductState get loading => ProductLoadingState();
  @override ProductState loaded({required Product data}) => ProductLoadedState(data);
  @override ProductState get saving => ProductSavingState();
  @override ProductState saved({required int id}) => ProductSavedState(id);
  @override ProductState get deleting => ProductDeletingState();
  @override ProductState deleted({required int id}) => ProductDeletedState(id);
  @override ProductState error({required String error, int code = 0}) => ProductErrorState(error);
  @override ProductState validation(Map<String, dynamic> bag) => ProductValidationState(bag);
}

class ProductLoadingState extends ProductState {}
class ProductLoadedState extends ProductState {
  final Product data;
  ProductLoadedState(this.data);
  @override List<Object> get props => [data];
}
class ProductSavingState extends ProductState {}
class ProductSavedState extends ProductState {
  final int id;
  ProductSavedState(this.id);
}
class ProductDeletingState extends ProductState {}
class ProductDeletedState extends ProductState {
  final int id;
  ProductDeletedState(this.id);
}
class ProductErrorState extends ProductState {
  final String message;
  ProductErrorState(this.message);
}
class ProductValidationState extends ProductState {
  final Map<String, dynamic> bag;
  ProductValidationState(this.bag);
}
```

### Pagination Cubit (list)

```dart
// blocs/product_list_cubit.dart
class ProductListCubit
    extends MyBaseBloc<ProductApiServiceImpl, ProductListState>
    with PaginationBloc<ProductApiServiceImpl, ProductListState, Product, ProductFilter>,
         LaravelPaginationBloc<ProductApiServiceImpl, ProductListState, Product, ProductFilter, int> {

  ProductListCubit() : super(bs: ProductListState());

  @override
  ProductFilter defaultFilter() => ProductFilter();
}

// Define ProductListState with PaginationState mixin...
```

---

## Step 4: Create the Controller & Maker

### Controller (for list screens)

```dart
// controllers/product_controller.dart
import 'package:skeleton/skeleton.dart';
import '../models/product.dart';
import '../models/product_filter.dart';

class ProductController extends BaseController<ProductFilter, Product, int> {
  ProductController({ProductFilter? filter, ProductFilter? fixed})
      : super(type: 'product', filter: filter, fixed: fixed);

  @override
  ProductFilter get newInstance => ProductFilter();
}
```

### Maker (for edit forms)

```dart
// controllers/product_maker.dart
import 'package:skeleton/skeleton.dart';
import '../models/product.dart';
import '../models/product_request.dart';

class ProductMaker extends BaseMaker<Product, ProductRequest, int> {
  ProductMaker({Product? model, ProductRequest? request})
      : super(model: model, request: request);

  @override
  ProductRequest jsonToRequest(Map<String, dynamic> json) =>
      ProductRequest()..name = json['name']..price = (json['price'] as num?)?.toDouble();

  @override
  ProductRequest get newInstance => ProductRequest();
}
```

---

## Step 5: Register in DI

```dart
// In your AppRegistrar or ModuleConfig:
class ProductModule extends ModuleConfig {
  @override
  void register(Injector i) {
    i.addSingleton<ProductApiServiceImpl>(() => ProductApiServiceImpl(dio));
    i.addSingleton<ProductListCubit>(() => ProductListCubit());
  }

  @override
  List<Widget> get providers => [
    BlocProvider<ProductListCubit>(create: (_) => Core.get<ProductListCubit>()),
  ];
}
```

---

## Step 6: Build the UI

### List Screen

```dart
class ProductListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductListCubit, ProductListState>(
      builder: (context, state) {
        if (state is ProductListPageLoadingState) {
          return Center(child: CircularProgressIndicator());
        }
        if (state is ProductListPageLoadedState) {
          return ListView.builder(
            itemCount: state.data.length,
            itemBuilder: (context, index) {
              final product = state.data[index];
              return ListTile(
                title: Text(product.name),
                subtitle: Text('\$${product.price}'),
                onTap: () => Navigator.pushNamed(context, '/products/${product.id}'),
              );
            },
          );
        }
        return EmptyState(message: 'No products');
      },
    );
  }
}
```

### Edit Form

```dart
class ProductEditForm extends EditForm<Product, ProductRequest, ProductMaker, int> {
  const ProductEditForm({required super.maker});

  @override
  State<ProductEditForm> createState() => _ProductEditFormState();
}

class _ProductEditFormState extends State<ProductEditForm>
    with FormHandler<Product, ProductRequest, ProductMaker, int> {

  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  @override
  void fillForm() {
    nameCtrl.text = widget.maker.form.name ?? '';
    priceCtrl.text = widget.maker.form.price?.toString() ?? '';
  }

  @override
  void fillMaker() {
    widget.maker.form.name = nameCtrl.text;
    widget.maker.form.price = double.tryParse(priceCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formkey,
      child: Column(children: [
        TextFormField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Name')),
        TextFormField(controller: priceCtrl, decoration: InputDecoration(labelText: 'Price')),
      ]),
    );
  }
}
```

---

## Summary

| Layer | Class | Purpose |
|-------|-------|---------|
| **Model** | `Product` | Data model |
| **Request** | `ProductRequest` | Create/Update payload |
| **Filter** | `ProductFilter` | Search parameters |
| **API** | `ProductApiServiceImpl` | HTTP calls |
| **BLoC** | `ProductCubit` / `ProductListCubit` | State management |
| **Controller** | `ProductController` | List filter/selection state |
| **Maker** | `ProductMaker` | Form state bridge |
| **UI** | `ProductListScreen` / `ProductEditForm` | Widgets |

# Building a CRUD Feature

> End-to-end walkthrough for implementing a complete CRUD feature using the Caky packages. We'll build a "Product" feature as an example.

---

## What You'll Create

| File | Layer | Purpose |
|------|-------|---------|
| `product.dart` | Model | Data model (JSON deserialization) |
| `product_request.dart` | Request | Create/update payload (JSON serialization) |
| `product_filter.dart` | Filter | Search/query parameters |
| `product_api.dart` | API | Retrofit HTTP service |
| `product_cubit.dart` | BLoC | State management |
| `product_state.dart` | State | BLoC state definitions |
| `product_maker.dart` | Maker | Model ↔ Request bridge |
| `product_controller.dart` | Controller | Filter & selection manager |
| `product_form.dart` | UI | Create/edit form |
| `product_filter_form.dart` | UI | Search filter form |
| `product_list_screen.dart` | UI | List screen with pagination |
| `product_editor_screen.dart` | UI | Create/edit screen |

---

## Step 1: Define the Model

```dart
// product.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:skeleton/skeleton.dart';

part 'product.g.dart';

@JsonSerializable()
class Product extends BaseModel {
  final int id;
  final String title;
  final String? description;
  final double price;

  @JsonKey(name: 'category_id')
  final int? categoryId;

  @JsonKey(name: 'created_at')
  final String? createdAt;

  Product({
    required this.id,
    required this.title,
    this.description,
    required this.price,
    this.categoryId,
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ProductToJson(this);
}
```

## Step 2: Define the Request

```dart
// product_request.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:skeleton/skeleton.dart';
import 'package:core/core.dart';

part 'product_request.g.dart';

@JsonSerializable(includeIfNull: false)
class ProductRequest extends SuperModel<ProductRequest> {
  String? title;
  String? description;
  double? price;

  @JsonKey(name: 'category_id')
  int? categoryId;

  // File upload support
  @FileFieldConverter(name: 'image', type: FileType.IMAGE)
  FileField? image;

  ProductRequest({this.title, this.description, this.price, this.categoryId, this.image});

  @override
  ProductRequest fromJson(Map<String, dynamic> json) =>
      _$ProductRequestFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ProductRequestToJson(this);
}
```

## Step 3: Define the Filter

```dart
// product_filter.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:skeleton/skeleton.dart';

part 'product_filter.g.dart';

@JsonSerializable(includeIfNull: false)
class ProductFilter extends DynamicQueryRequest<ProductFilter> {
  String? title;

  @JsonKey(name: 'category_id')
  int? categoryId;

  @JsonKey(name: 'price_min')
  double? priceMin;

  @JsonKey(name: 'price_max')
  double? priceMax;

  ProductFilter({
    this.title,
    this.categoryId,
    this.priceMin,
    this.priceMax,
    super.fields,
    super.sort,
    super.perPage,
  });

  @override
  ProductFilter fromJson(Map<String, dynamic> json) =>
      _$ProductFilterFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ProductFilterToJson(this);
}
```

## Step 4: Define the API Service

```dart
// product_api.dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:core/core.dart';
import 'package:skeleton/skeleton.dart';

part 'product_api.g.dart';

@RestApi(baseUrl: '/products')
abstract class ProductApiService extends BaseApiService<Product, ProductRequest, ProductFilter> {
  factory ProductApiService(Dio dio, {String? baseUrl}) = _ProductApiService;

  factory ProductApiService.instance() =>
      ProductApiService(Core.get<BaseDio>().dio, baseUrl: Core.get<Config>().baseUrl);

  @override
  @GET('/{id}')
  Future<BasicResponse<Product>> show({
    @Path('id') required int id,
    @Queries() ProductFilter? params,
  });

  @override
  @GET('')
  Future<BasicResponse<PaginationResponse<Product>>> paging({
    @Query('page') required int page,
    @Queries() required ProductFilter request,
  });

  @override
  @POST('')
  Future<BasicResponse<int>> create(@Body() ProductRequest request);

  @override
  @PUT('/{id}')
  Future<BasicResponse<int>> update({
    @Path('id') required int id,
    @Body() required ProductRequest request,
  });

  @override
  @DELETE('/{id}')
  Future<BasicResponse<int>> delete({
    @Path('id') required int id,
    @Queries() ProductFilter? params,
  });
}
```

## Step 5: Define the BLoC

```dart
// product_cubit.dart
import 'package:skeleton/skeleton.dart';

part 'product_state.dart';

class ProductCubit extends MyBaseBloc<ProductApiService, ProductState>
    with
        CrudBloc<ProductApiService, ProductState, Product, ProductRequest, ProductFilter>,
        PaginationBloc<ProductApiService, ProductState, Product, ProductFilter> {

  ProductCubit() : super(bs: ProductState());

  @override
  ProductFilter defaultFilter() => ProductFilter(perPage: 20);

  @override
  Future<Product> one({required int id, ProductFilter? params}) async =>
      (await handle(http().show(id: id, params: params)))!;

  @override
  Future<int> save({required int id, required ProductRequest request}) async =>
      (await handle(
        id != 0
          ? http().update(id: id, request: request)
          : http().create(request),
      ))!;

  @override
  Future destroy({required int id, ProductFilter? params}) async =>
      await handle(http().delete(id: id, params: params));

  @override
  Future<PaginationResponse<Product>> load() async =>
      (await handle(http().paging(page: page, request: filter)))!;
}
```

```dart
// product_state.dart
part of 'product_cubit.dart';

class ProductState extends MyBaseState<dynamic>
    with CrudState<dynamic, Product>, PaginationState<dynamic, Product> {

  @override
  get initial => ProductInitialState();
  @override
  error({required String error, int code = 0}) => ProductErrorState(error);
  @override
  validation(Map<String, dynamic> bag) => ProductValidationState(bag);

  // Crud states
  @override
  get loading => ProductLoadingState();
  @override
  loaded({required Product data}) => ProductLoadedState(data);
  @override
  get saving => ProductSavingState();
  @override
  saved({required int id}) => ProductSavedState(id);
  @override
  get deleting => ProductDeletingState();
  @override
  deleted({required int id}) => ProductDeletedState(id);

  // Pagination states
  @override
  get pageLoading => ProductPageLoadingState();
  @override
  pageLoaded({required List<Product> data, required bool maxReached, required int nextPage}) =>
      ProductPageLoadedState(data, maxReached, nextPage);
}

// Define your actual state classes...
class ProductInitialState extends ProductState {}
class ProductLoadingState extends ProductState {}
class ProductLoadedState extends ProductState {
  final Product data;
  ProductLoadedState(this.data);
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
class ProductPageLoadingState extends ProductState {}
class ProductPageLoadedState extends ProductState {
  final List<Product> data;
  final bool maxReached;
  final int nextPage;
  ProductPageLoadedState(this.data, this.maxReached, this.nextPage);
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

## Step 6: Define the Maker & Controller

```dart
// product_maker.dart
import 'package:skeleton/skeleton.dart';

class ProductMaker extends BaseMaker<Product, ProductRequest> {
  ProductMaker({super.model, super.request, super.fixed});

  @override
  ProductRequest get newInstance => ProductRequest();
}
```

```dart
// product_controller.dart
import 'package:skeleton/skeleton.dart';

class ProductController extends BaseController<ProductFilter, Product> {
  ProductController({super.filter, super.fixed})
      : super(type: 'product');

  @override
  ProductFilter get newInstance => ProductFilter();
}
```

## Step 7: Build the Edit Form

```dart
// product_form.dart
import 'package:flutter/material.dart';
import 'package:skeleton/skeleton.dart';

class ProductFormWidget extends EditForm<Product, ProductRequest, ProductMaker> {
  const ProductFormWidget({super.key, required super.maker, super.validation});

  @override
  State createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductFormWidget>
    with FormHandler<Product, ProductRequest, ProductMaker> {

  final titleCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  @override
  void fillForm() {
    titleCtrl.text = widget.maker.form.title ?? '';
    priceCtrl.text = widget.maker.form.price?.toString() ?? '';
  }

  @override
  void fillMaker() {
    widget.maker.form.title = titleCtrl.text;
    widget.maker.form.price = double.tryParse(priceCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formkey,
      child: Column(children: [
        if (isVisibleField('title'))
          TextFormField(
            controller: titleCtrl,
            decoration: InputDecoration(
              labelText: 'Title',
              errorText: validation?['title'],
            ),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
        if (isVisibleField('price'))
          TextFormField(
            controller: priceCtrl,
            decoration: InputDecoration(
              labelText: 'Price',
              errorText: validation?['price'],
            ),
            keyboardType: TextInputType.number,
          ),
      ]),
    );
  }
}
```

## Step 8: Build the Editor Screen

```dart
// product_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:concrete/concrete.dart';
import 'package:skeleton/skeleton.dart';

class ProductEditorScreen extends StatefulWidget {
  final Product? product; // null for create, non-null for edit
  const ProductEditorScreen({super.key, this.product});
  @override
  State createState() => _ProductEditorState();
}

class _ProductEditorState extends ControlledState<ProductEditorScreen, ProductCubit>
    with EditorHandler<Product, ProductRequest, ProductMaker, ProductEditorScreen, ProductCubit> {

  @override
  void initState() {
    maker = ProductMaker(model: widget.product);
    super.initState();
  }

  @override
  void save() {
    store.updateOrCreate(id: maker.id, request: maker.request);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(maker.id == 0 ? 'Create Product' : 'Edit Product'),
        actions: [
          IconButton(icon: Icon(Icons.save), onPressed: send),
        ],
      ),
      body: BlocProvider(
        create: (_) => store,
        child: BlocListener<ProductCubit, ProductState>(
          listener: (context, state) {
            if (state is ProductSavedState) {
              showSnackBar(context, 'Saved!');
              Core.nav.pop(state.id);
            } else if (state is ProductErrorState) {
              showSnackBar(context, state.message);
            }
          },
          child: BlocBuilder<ProductCubit, ProductState>(
            builder: (context, state) {
              return SingleChildScrollView(
                padding: Edges.lg,
                child: ProductFormWidget(
                  maker: maker,
                  validation: state is ProductValidationState ? state.bag : null,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
```

## Step 9: Build the List Screen

```dart
// product_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';
import 'package:concrete/concrete.dart';
import 'package:skeleton/skeleton.dart';

class ProductListScreen extends StatefulWidget {
  @override
  State createState() => _ProductListState();
}

class _ProductListState extends ControlledState<ProductListScreen, ProductCubit> {
  final controller = ProductController();

  @override
  void initState() {
    super.initState();
    store.refresh(); // Load first page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Products')),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          final id = await Core.nav.push('/products/create');
          if (id != null) store.refreshPage();
        },
      ),
      body: BlocProvider(
        create: (_) => store,
        child: BlocBuilder<ProductCubit, ProductState>(
          builder: (context, state) {
            if (state is ProductPageLoadingState) {
              return Center(child: CircularProgressIndicator());
            }
            if (state is ProductErrorState) {
              return Center(child: Message.error(message: state.message));
            }
            if (state is ProductPageLoadedState) {
              return ListView.builder(
                itemCount: state.data.length + 1,
                itemBuilder: (context, index) {
                  if (index == state.data.length) {
                    return state.maxReached
                        ? SizedBox()
                        : LoadMoreWidget(onLoadMore: () => store.loadNext());
                  }
                  final product = state.data[index];
                  return ListTile(
                    title: Text(product.title),
                    subtitle: Text(product.price.dinar),
                    onTap: () => Core.nav.push('/products/${product.id}'),
                  );
                },
              );
            }
            return SizedBox();
          },
        ),
      ),
    );
  }
}
```

## Step 10: Register in Your Registrar

```dart
Core.i.add<ProductApiService>(() => ProductApiService.instance());
Core.i.add<ProductCubit>(() => ProductCubit());
```

## Step 11: Generate Code

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates the `.g.dart` files for:
- JSON serialization (`product.g.dart`, `product_request.g.dart`, `product_filter.g.dart`)
- Retrofit API client (`product_api.g.dart`)

---

## Data Flow Summary

```
User Action → Widget → Cubit Method → API Service → HTTP → Server
                ↕            ↕             ↕
           BLoC State    handle()     BasicResponse
                ↕            ↕             ↕
           UI Update   mapErrorToState  Exception
```

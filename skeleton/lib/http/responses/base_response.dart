import 'package:json_annotation/json_annotation.dart';
part 'base_response.g.dart';

@JsonSerializable(genericArgumentFactories: true, createToJson: false)
class BasicResponse<T> {
  final int? code;
  final String? message;
  final String? error;
  final Map<String, dynamic>? validation;
  final T? data;

  BasicResponse({this.code, this.message, this.error, this.validation, this.data});

  factory BasicResponse.fromJson(dynamic json, T Function(dynamic json) fromJsonT) {
    return _$BasicResponseFromJson(json!, fromJsonT);
  }
  static BasicResponse? tryParse(dynamic json) {
    try {
      return BasicResponse.fromJson(json, (json) => null);
    } catch (e) {
      return null;
    }
  }
}

@JsonSerializable(genericArgumentFactories: true, createToJson: false)
class PaginationResponse<T> {
  List<T>? data;
  int? total;
  int? perPage;
  // int? currentPage;
  // String? firstPageUrl;
  // int? from;
  // int? lastPage;
  // String? lastPageUrl;
  // List<Link>? links;
  // String? nextPageUrl;
  // String? path;
  // String? prevPageUrl;
  // int? to;

  PaginationResponse({
    this.data,
    this.total,
    this.perPage,
    // this.currentPage,
    // this.firstPageUrl,
    // this.from,
    // this.lastPage,
    // this.lastPageUrl,
    // this.links,
    // this.nextPageUrl,
    // this.path,
    // this.prevPageUrl,
    // this.to,
  });

  factory PaginationResponse.fromJson(dynamic json, T Function(dynamic json) fromJsonT) {
    return _$PaginationResponseFromJson<T>(json, fromJsonT);
  }
}

// class Link {
//   String? url;
//   String? label;
//   bool? active;

//   Link({this.url, this.label, this.active});

//   Link.fromJson(Map<String, dynamic> json) {
//     url = json['url'];
//     label = json['label'];
//     active = json['active'];
//   }
// }

import 'dart:convert';

class CategoryResponseModel {
  final bool status;
  final String message;
  final List<Category> data;

  CategoryResponseModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory CategoryResponseModel.fromJson(String str) =>
      CategoryResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory CategoryResponseModel.fromMap(Map<String, dynamic> json) =>
      CategoryResponseModel(
        status: json["status"],
        message: json["message"],
        data: List<Category>.from(json["data"].map((x) => Category.fromMap(x))),
      );

  Map<String, dynamic> toMap() => {
        "status": status,
        "message": message,
        "data": List<dynamic>.from(data.map((x) => x.toMap())),
      };
}

class Category {
  final int id;
  final String name;
  final int shopId;

  Category({
    required this.id,
    required this.name,
    required this.shopId,
  });

  factory Category.fromJson(String str) => Category.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Category.fromMap(Map<String, dynamic> json) => Category(
        id: json["id"],
        name: json["name"],
        shopId: json["shop_id"],
      );

  factory Category.fromLocal(Map<String, dynamic> json) => Category(
        id: json["category_id"],
        name: json["name"],
        shopId: json["shop_id"],
      );

  Map<String, dynamic> toMap() => {
        "category_id": id,
        "name": name,
        "shop_id": shopId,
      };

  @override
  String toString() => name;
}

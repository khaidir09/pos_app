import 'dart:convert';

class AuthResponseModel {
  final User user;
  final String token;

  AuthResponseModel({
    required this.user,
    required this.token,
  });

  factory AuthResponseModel.fromJson(String str) =>
      AuthResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory AuthResponseModel.fromMap(Map<String, dynamic> json) =>
      AuthResponseModel(
        user: User.fromMap(json["user"]),
        token: json["token"],
      );

  Map<String, dynamic> toMap() => {
        "user": user.toMap(),
        "token": token,
      };
}

class User {
  final int id;
  final String name;
  final String email;
  final String phone;
  final int? shopId;
  final ShopModel? shop;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.shopId,
    required this.shop,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(String str) => User.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory User.fromMap(Map<String, dynamic> json) => User(
        id: json["id"],
        name: json["name"],
        email: json["email"],
        phone: json["phone"] ?? '',
        shopId: json["shop_id"],
        shop: json["shop"] != null ? ShopModel.fromMap(json["shop"]) : null,
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
        "email": email,
        "phone": phone,
        "shop_id": shopId,
        "shop": shop?.toMap(),
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
      };
}

class ShopModel {
  final int id;
  final String namaToko;
  final String alamat;
  final String logo;
  final String email;
  final String nomorHp;

  ShopModel({
    required this.id,
    required this.namaToko,
    required this.alamat,
    required this.email,
    required this.nomorHp,
    this.logo = '',
  });

  factory ShopModel.fromJson(String str) => ShopModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ShopModel.fromMap(Map<String, dynamic> json) => ShopModel(
        id: json["id"],
        namaToko: json["nama_toko"],
        alamat: json["alamat"],
        logo: json["logo"] ?? '',
        email: json["email"],
        nomorHp: json["nomor_hp"],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "nama_toko": namaToko,
        "alamat": alamat,
        "logo": logo,
        "email": email,
        "nomor_hp": nomorHp,
      };
}

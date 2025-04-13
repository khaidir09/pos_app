import 'package:flutter_pos_app/core/constants/variables.dart';
import 'package:flutter_pos_app/data/models/response/auth_response_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthLocalDatasource {
  Future<void> saveAuthData(AuthResponseModel authResponseModel) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_data', authResponseModel.toJson());
  }

  Future<void> removeAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_data');
  }

  Future<AuthResponseModel> getAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final authData = prefs.getString('auth_data');

    return AuthResponseModel.fromJson(authData!);
  }

  Future<bool> isAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final authData = prefs.getString('auth_data');

    return authData != null;
  }

  Future<void> saveMidtransServerKey(String serverKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_key', serverKey);
  }

  //get midtrans server key
  Future<String> getMitransServerKey() async {
    final prefs = await SharedPreferences.getInstance();
    final serverKey = prefs.getString('server_key');
    return serverKey ?? '';
  }

  Future<void> savePrinter(String printer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('printer', printer);
  }

  Future<String> getPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final printer = prefs.getString('printer');
    return printer ?? '';
  }

  Future<String> getShopName() async {
    final prefs = await SharedPreferences.getInstance();
    final authData = prefs.getString('auth_data');

    if (authData != null) {
      try {
        final authModel = AuthResponseModel.fromJson(authData);
        return authModel.user.shop?.namaToko ?? 'Toko Saya';
      } catch (e) {
        return 'Toko Saya'; // Default value jika error
      }
    }
    return 'Toko Saya'; // Default value jika belum login
  }

  Future<Map<String, String>> getShopInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final authData = prefs.getString('auth_data');

    if (authData != null) {
      try {
        final authModel = AuthResponseModel.fromJson(authData);
        return {
          'nama_toko': authModel.user.shop?.namaToko ?? 'Toko Saya',
          'alamat': authModel.user.shop?.alamat ??
              'Alamat belum diatur', // Ganti dengan field alamat jika ada
        };
      } catch (e) {
        return {
          'name': 'Toko Saya',
          'address': 'Alamat belum diatur',
        };
      }
    }
    return {
      'name': 'Toko Saya',
      'address': 'Alamat belum diatur',
    };
  }

  Future<String> getShopLogoUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final authData = prefs.getString('auth_data');

    if (authData != null) {
      try {
        final authModel = AuthResponseModel.fromJson(authData);
        final logo = authModel.user.shop?.logo ?? '';
        if (logo.isNotEmpty) {
          return '${Variables.shopLogoUrl}/$logo'; // Sesuaikan path jika perlu
        }
      } catch (e) {
        // Logging optional
      }
    }
    return 'assets/images/logo.png'; // fallback logo
  }
}

import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

class UserServices {
  Future<List<Map>> fetchUserMockData(String urlAddress) async {
    bool isError = false;
    String error;

    final response = await http
        .get(Uri.parse(urlAddress))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      log("fetchUserMockData statusCode: 200 | ${response.body}");

      List<Map> data = (json.decode(response.body) as List)
          .map((item) => item as Map)
          .toList();
      return data;
    } else {
      log("Failed to fetchUserMockData ${response.body}");
      throw Exception(response.statusCode.toString());
    }
  }
}

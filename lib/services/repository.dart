import 'package:mqtt_test/services/user_services.dart';

class Repository {
  final serServices = UserServices();

  // MONITORING
  Future<List<Map>> getMockUserData(String urlAddress) =>
      serServices.fetchUserMockData(
        urlAddress,
      );
}

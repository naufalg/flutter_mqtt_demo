import 'dart:developer';

import 'package:rxdart/rxdart.dart';

import '../services/repository.dart';

class UserBloc {
  final _repository = Repository();
  final _mockUserDataFetcher = BehaviorSubject<List<Map>>();

  // List<String> monitoringTypes;

  Stream<List<Map>> get getMockUserDataStream => _mockUserDataFetcher.stream;

  List<Map> get typesValue => _mockUserDataFetcher.value;

  Future getMockUserData(String urlAddress) async {
    bool isError = false;
    String error;
    List<Map> mockUserFetchData = await _repository
        .getMockUserData(urlAddress)
        .timeout(Duration(seconds: 10))
        .catchError((e) {
      isError = true;
      error = e.toString();
      if (e.toString().toLowerCase().contains("timeout")) {
        error = "timeout";
      }
      log("getMockUserDataError: " + error);
    });
    if (isError) {
      log("error getMockUserData " + error.toString());

      _mockUserDataFetcher.sink.addError(error);
    } else {
      log("getMockUserData no error");

      _mockUserDataFetcher.sink.add(mockUserFetchData);
    }
  }

  disposeNetwork() {
    _mockUserDataFetcher.close();
  }

  nullifyStream() {
    _mockUserDataFetcher.sink.add(null);
  }
}

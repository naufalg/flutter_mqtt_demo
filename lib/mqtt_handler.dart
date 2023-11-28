import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_test/constant/constant.dart';

import 'bloc/bloc.dart';

class MqttHandler with ChangeNotifier {
  final ValueNotifier<String> data = ValueNotifier<String>("");

  MqttServerClient client;

  Future<Object> connect({
    int port,
    String host,
    String clientId,
    Function toggleConnected,
    Function toggleDisonnected,
    Function toggleSubscribed,
    Function toggleUnsubscribed,
    Function setMessage,
  }) async {
    client = MqttServerClient.withPort(host, clientId, port);

    client.logging(on: true);
    client.onConnected =
        () => onConnected(toggleConnected, host, port, clientId);
    client.onDisconnected = () => onDisconnected(
          toggleDisonnected: toggleDisonnected,
          toggleUnsubscribed: toggleUnsubscribed,
          host: host,
          port: port,
          clientId: client,
        );
    client.onUnsubscribed = onUnsubscribed;
    client.onSubscribed = onSubscribed;
    client.onSubscribeFail = onSubscribeFail;
    client.pongCallback = pong;
    client.keepAlivePeriod = 60;
    client.logging(on: true);

    client.setProtocolV311();

    final connMessage = MqttConnectMessage()
        .withWillTopic('willtopic')
        .withWillMessage('Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    log('MQTT_LOGS::Mosquitto client connecting....');

    client.connectionMessage = connMessage;
    try {
      await client.connect();
    } catch (e) {
      log('Exception: $e');
      client.disconnect();
    }

    if (client.connectionStatus.state == MqttConnectionState.connected) {
      log('MQTT_LOGS::Mosquitto client connected');
      toggleConnected();
    } else {
      log('MQTT_LOGS::ERROR Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');
      client.disconnect();
      toggleDisonnected();
      return -1;
    }

    const topic = 'test/msi';
    log('MQTT_LOGS::Subscribing to the $topic topic');

    client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      String decodeMessage = Utf8Decoder().convert(pt.codeUnits);

      log("MQTTClientWrapper::GOT A NEW MESSAGE $decodeMessage");

      data.value = decodeMessage;
      notifyListeners();
      log('MQTT_LOGS:: New data arrived: topic is <${c[0].topic}>, payload is $pt');
      setMessage(pt);
      handleMessage(pt);
    });

    return client;
  }

  void onConnected(toggleConnected, host, port, clientId) {
    toggleConnected();
    Fluttertoast.showToast(
        msg: 'Connected to $host port $port, as $clientId',
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.green.shade200,
        fontSize: 16.0);
    log('MQTT_LOGS:: Connected');
  }

  void onDisconnected(
      {toggleDisonnected, toggleUnsubscribed, host, port, clientId}) {
    Fluttertoast.showToast(
        msg: 'Disconnected from $host port $port, as $clientId',
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.grey,
        fontSize: 16.0);
    toggleDisonnected();
    toggleUnsubscribed();
    log('MQTT_LOGS:: Disconnected');
  }

  void onSubscribed(String topic) {
    Fluttertoast.showToast(
        msg: 'Subscribed to $topic',
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.green.shade200,
        fontSize: 16.0);
    log('MQTT_LOGS:: Subscribed topic: $topic');
  }

  void onSubscribeFail(String topic) {
    log('MQTT_LOGS:: Failed to subscribe $topic');
  }

  void onUnsubscribed(String topic) {
    Fluttertoast.showToast(
        msg: 'Unsubscribed from $topic',
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.green.shade200,
        fontSize: 16.0);
    log('MQTT_LOGS:: Unsubscribed topic: $topic');
  }

  void pong() {
    log('MQTT_LOGS:: Ping response client callback invoked');
  }

  void publishMessage(String message) {
    const pubTopic = 'test/msi';
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      client.publishMessage(pubTopic, MqttQos.atMostOnce, builder.payload);
    }
  }

  subscribeToTopic({String topic, Function toggleSubscribed}) {
    log('subscribe topic: $topic');
    client.subscribe(topic, MqttQos.atMostOnce);
    toggleSubscribed();
  }

  unsubscribeFromTopic({String topic, Function toggleUnsubscribed}) {
    log('unsubscribe topic: $topic');
    client.unsubscribe(topic);
    toggleUnsubscribed();
  }

  disconnectFromHost({
    Function toggleDisonnected,
  }) {
    client.disconnect();
    toggleDisonnected();
  }

  handleMessage(String message) {
    log('handleMessage: $message');

    switch (message) {
      case 'refresh user':
        bloc.userBloc.getMockUserData('${urlConstant.mockApiUrl}/users');
        break;
      default:
    }
  }
}

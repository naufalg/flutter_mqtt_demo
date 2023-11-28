import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
// import 'package:mqtt_client/mqtt_client.dart';
// import 'package:mqtt_client/mqtt_server_client.dart';
// import 'package:mqtt_test/main.dart';
import 'package:mqtt_test/mqtt_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// import '../bloc/bloc.dart';

SharedPreferences prefs;

class MessageScreen extends StatefulWidget {
  const MessageScreen({
    Key key,
  }) : super(key: key);

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final mqttHandler = MqttHandler();
  final _connectionFormKey = GlobalKey<FormState>();
  final _subscribeFormKey = GlobalKey<FormState>();

  bool isConnected = false;
  bool isSubscribed = false;
  final hostTextController = TextEditingController();
  final portTextController = TextEditingController();
  final clientIdTextController = TextEditingController();

  Map<String, dynamic> mqttData = {
    'host': '',
    'port': 0,
    'clientId': '',
  };
  String subscribeTopic = '';
  String messageReceived = 'Waiting New Message...';

  _toggleConnected() {
    setState(() => isConnected = true);
  }

  _toggleDisonnected() {
    setState(() => isConnected = false);
  }

  _toggleSubscribed() {
    setState(() => isSubscribed = true);
  }

  _toggleUnSubscribed() {
    setState(() => isSubscribed = false);
    setState(() => messageReceived = 'Waiting New Message...');
  }

  void getSharedPref() async {
    log('sharedPrefs Loaded!');
    prefs = await SharedPreferences.getInstance();
    log('mappedForm: ${json.decode(prefs.getString('mappedForm'))}' ?? 'null');
    setState(() {
      Map mappedForm = json.decode(prefs.getString('mappedForm'));
      hostTextController.text = mappedForm['host'];
      portTextController.text = mappedForm['port'].toString();
      clientIdTextController.text = mappedForm['clientId'];
    });
  }

  @override
  void initState() {
    super.initState();
    getSharedPref();
  }

  setMessage(newMessage) {
    log('setMessage: $newMessage');
    setState(() {
      messageReceived = newMessage;
    });
  }

  List<Widget> generateUserView(List<Map> userData) {
    List<Widget> usersWidget = [];
    for (var el in userData) {
      usersWidget.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(el['name']),
          Text(el['message']),
        ],
      ));
    }
    return usersWidget;
  }

  @override
  Widget build(BuildContext context) {
    log('isConnected: $isConnected | isSubscribed: $isSubscribed');
    var deviceSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MQTT Testing'),
      ),
      body: SafeArea(
          child: SingleChildScrollView(
        child: SizedBox(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(30),
                child: Form(
                  key: _connectionFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        enabled: !isConnected,
                        controller: hostTextController,
                        decoration: const InputDecoration(
                          labelText: 'Host Server',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter Host Server';
                          }
                          return null;
                        },
                        onSaved: (newValue) {
                          mqttData['host'] = newValue;
                        },
                      ),
                      TextFormField(
                        enabled: !isConnected,
                        controller: portTextController,
                        decoration: const InputDecoration(
                          labelText: 'Port',
                        ),
                        onSaved: (newValue) {
                          mqttData['port'] = int.parse(newValue);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter Port';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        enabled: !isConnected,
                        controller: clientIdTextController,
                        decoration: const InputDecoration(
                          labelText: 'Client ID',
                        ),
                        onSaved: (newValue) {
                          mqttData['clientId'] = newValue;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter Client ID';
                          }
                          return null;
                        },
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: ElevatedButton(
                              onPressed: isConnected
                                  ? null
                                  : () async {
                                      _connectionFormKey.currentState.save();
                                      log('press connect');
                                      if (_connectionFormKey.currentState
                                          .validate()) {
                                        log('mqttData: $mqttData');

                                        prefs.setString('mappedForm',
                                            json.encode(mqttData));

                                        mqttHandler.connect(
                                          clientId: mqttData['clientId'],
                                          port: mqttData['port'],
                                          host: mqttData['host'],
                                          toggleConnected: _toggleConnected,
                                          toggleDisonnected: _toggleDisonnected,
                                          toggleSubscribed: _toggleSubscribed,
                                          toggleUnsubscribed:
                                              _toggleUnSubscribed,
                                          setMessage: setMessage,
                                        );
                                      }
                                    },
                              child: const Text('Connect'),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              onPressed: !isConnected
                                  ? null
                                  : () async {
                                      _connectionFormKey.currentState.save();
                                      log('press disconnect');
                                      if (_connectionFormKey.currentState
                                          .validate()) {
                                        mqttHandler.disconnectFromHost(
                                            toggleDisonnected:
                                                _toggleDisonnected);
                                      }
                                    },
                              child: const Text('Disconnect'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              isConnected
                  ? Form(
                      key: _subscribeFormKey,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Column(
                          children: [
                            TextFormField(
                              enabled: !isSubscribed,
                              // controller: hostTextController,
                              decoration: const InputDecoration(
                                labelText: 'Topic',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter Topic';
                                }
                                return null;
                              },
                              onSaved: (newValue) {
                                subscribeTopic = newValue;
                              },
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16.0),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: isSubscribed
                                        ? Colors.red
                                        : Colors.green),
                                onPressed: isSubscribed
                                    ? () {
                                        mqttHandler.unsubscribeFromTopic(
                                          topic: subscribeTopic,
                                          toggleUnsubscribed:
                                              _toggleUnSubscribed,
                                        );
                                      }
                                    : () {
                                        _subscribeFormKey.currentState.save();
                                        log('press subscribe');
                                        if (_subscribeFormKey.currentState
                                            .validate()) {
                                          log('subscribeTopic: $subscribeTopic');

                                          mqttHandler.subscribeToTopic(
                                            topic: subscribeTopic,
                                            toggleSubscribed: _toggleSubscribed,
                                          );
                                        }
                                      },
                                child:
                                    Text(isSubscribed ? 'Unsub' : 'Subscribe'),
                              ),
                            ),
                          ],
                        ),
                      ))
                  : Container(),
              !isSubscribed || !isConnected
                  ? Container()
                  : Center(
                      child: Column(
                      children: [
                        const Text(
                          'Message:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          messageReceived,
                          style: TextStyle(
                            // fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    )),

              // isConnected && isSubscribed
              //     ? StreamBuilder<List<Map>>(
              //         stream: bloc.userBloc.getMockUserDataStream,
              //         builder: (context, snapshot) {
              //           if (snapshot.hasError ||
              //               snapshot.connectionState == ConnectionState.done) {
              //             log("hasData error");
              //             return InkWell(
              //               child: SizedBox(
              //                   height: deviceSize.height * 0.3,
              //                   child: Text('error')),
              //               // onTap: () => initDashboard()
              //             );
              //           }
              //           if (snapshot.connectionState ==
              //               ConnectionState.waiting) {
              //             return Container();
              //           }
              //           if (snapshot.hasData) {
              //             List<Map> usersData = snapshot.data;
              //             log('snapshot.hasData: ${snapshot.data}');
              //             bool isPageLoading = (snapshot.connectionState !=
              //                     ConnectionState.done &&
              //                 !snapshot.hasData);

              //             return Column(children: generateUserView(usersData));
              //           }
              //           return const CircularProgressIndicator();
              //         },
              //       )
              //     : Container(),
              // StreamBuilder<List<MqttReceivedMessage<MqttMessage>>>(
              //     stream:
              //         mqttHandler.client.updates, // Receive MQTT updates
              //     builder: (context, snapshot) {
              //       if (snapshot.hasError ||
              //           snapshot.connectionState == ConnectionState.done) {
              //         log("hasData error");
              //         return InkWell(
              //             child: SizedBox(
              //                 height: deviceSize.height * 0.3,
              //                 child: Card(
              //                     shape: RoundedRectangleBorder(
              //                         borderRadius:
              //                             BorderRadius.circular(20)),
              //                     elevation: 5,
              //                     child: const Text('error'))));
              //         // onTap: () => initDashboard());
              //       }
              //       // if (!snapshot.hasData) {
              //       //   return Center(
              //       //       child: Column(
              //       //     children: [
              //       //       const Text('Message:'),
              //       //       Text(messageReceived),
              //       //     ],
              //       //   ));
              //       // }
              //       // final updates = snapshot.data;
              //       // final latestUpdate = updates.last.payload.toString();

              //       // log('latestUpdate: ${latestUpdate}');
              //       return Center(
              //           child: Column(
              //         children: [
              //           const Text(
              //             'Message:',
              //             style: TextStyle(
              //                 fontWeight: FontWeight.bold, fontSize: 18),
              //           ),
              //           Text(
              //             messageReceived,
              //             style: TextStyle(
              //               // fontWeight: FontWeight.bold,
              //               fontSize: 22,
              //             ),
              //           ),
              //         ],
              //       ));
              //     },
              //   ),
            ],
          ),
        ),
      )),
    );
  }
}

// Copyright 2019 The Sponge authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';
import 'package:sponge_client_dart/sponge_client_dart.dart';
import 'package:sponge_flutter_api/sponge_flutter_api.dart';
import 'package:sponge_remote_mobile/mobile_compatibility.dart';

class MobileApplicationService extends FlutterApplicationService<
    MobileSpongeService, FlutterApplicationSettings> {
  MobileApplicationService() {
    typeGuiProvider = MobileDefaultTypeGuiProvider();
  }

  static final Logger _logger = Logger('MobileApplicationService');
  FlutterLocalNotificationsPlugin _localNotificationsPlugin;
  final int _eventNotificationId = 1;

  @override
  Future<void> init() async {
    await super.init();

    await _initLocalNotifications();
  }

  Future<void> _initLocalNotifications() async {
    _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await _localNotificationsPlugin.initialize(
      InitializationSettings(
          AndroidInitializationSettings('@mipmap/ic_launcher'),
          IOSInitializationSettings()),
      onSelectNotification: _onSelectNotification,
    );
  }

  Future _onSelectNotification(String payload) async {
    try {
      _logger.info('Notification tapped: $payload');

      // Show the event handler action.
      await showEventHandlerActionById(mainBuildContext, payload);

      // The show the event list.
      await showDistinctScreen(mainBuildContext, DefaultRoutes.EVENTS);
    } catch (e) {
      _logger.severe('Notification plugin error', e);
    }
  }

  @override
  Future<void> closeSpongeService() async {
    await super.closeSpongeService();
    await _localNotificationsPlugin?.cancelAll();
  }

  @override
  Future<void> showEventNotification(EventData eventData) async {
    // Get details on if the app was launched via a notification
    // var notificationAppLaunchDetails =
    // await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    var label = eventData.event.label ?? eventData.type.label;
    var message = eventData.event.description ??
        eventData.type.description ??
        label ??
        eventData.event.name;
    await _localNotificationsPlugin.show(
      _eventNotificationId,
      label ?? 'Sponge',
      message,
      NotificationDetails(
          AndroidNotificationDetails(
            'sponge',
            'Sponge',
            'Sponge channel',
            ticker: message,
            enableVibration: false,
          ),
          IOSNotificationDetails()),
      payload: eventData.event.id,
    );
  }

  @override
  Future<void> clearEventNotifications() async {
    // TODO cancel(_eventNotificationId) causes application crashes in a release mode (on Samsung Galaxy S7).
    await _localNotificationsPlugin.cancelAll();
  }

  @override
  Future<MobileSpongeService> createSpongeService(
    SpongeConnection connection,
    TypeConverter typeConverter,
    FeatureConverter featureConverter,
  ) async =>
      MobileSpongeService(
        connection,
        typeConverter,
        featureConverter,
        typeGuiProvider,
      );
}

class MobileSpongeService extends FlutterSpongeService {
  MobileSpongeService(SpongeConnection connection, TypeConverter typeConverter,
      FeatureConverter featureConverter, TypeGuiProvider typeGuiProvider)
      : super(connection, typeConverter, featureConverter, typeGuiProvider);

  // @override
  // SpongeGrpcClient createSpongeGrpcClient(
  //     SpongeRestClient client, SpongeConnection connection) {
  //   return DefaultSpongeGrpcClient(client);
  // }
}

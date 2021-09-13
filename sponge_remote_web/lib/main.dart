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

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'dart:html' as html;
import 'dart:convert';
import 'package:pedantic/pedantic.dart';
import 'package:sponge_client_dart/sponge_client_dart.dart';
import 'package:sponge_flutter_api/sponge_flutter_api.dart';
import 'package:sponge_remote/sponge_remote.dart';
import 'package:sponge_remote_web/logger_configuration.dart';
import 'package:sponge_remote_web/web_application_service.dart';

// TODO [Entrypoint] Web entrypoints. Draft - Under construction!

const String ENTRYPOINT_SPONGE_REMOTE = 'spongeRemote';
const String ENTRYPOINT_ACTION_CALL = 'actionCall';

void main() async {
  final Logger _logger = Logger('main');

  try {
    configLogger();

    WidgetsFlutterBinding.ensureInitialized();

    var service = WebApplicationService();
    await service.init();

    String entrypoint = ENTRYPOINT_SPONGE_REMOTE;

    final Map<String, String> params =
        Uri.parse(html.window.location.href).queryParameters;

    if (params.isNotEmpty) {
      // TODO sessionID, subsessionID in cookies?
      entrypoint = params['entrypoint'] ?? entrypoint;
      final connection = params['connection'] as String;

      Map<String, dynamic> connectionConfiguration =
          json.decode(utf8.decode(base64.decode(connection)));

      final action = params['action'];

      var cookie = html.document.cookie;

      print('params: $params');
      print('cookie: $cookie');
      print('connection: $connectionConfiguration');

      const connectionName = 'connection';

      var url = connectionConfiguration['url'];

      // TODO ClientConfigurationDecorator
      service.spongeService.additionalClientConfiguration =
          SpongeClientConfiguration(
        url,
        //httpHeaders: {''}
      );

      unawaited(service.setConnections(<SpongeConnection>[
        SpongeConnection(
          name: connectionName,
          url: url,
        ),
      ], connectionName));
    }

    switch (entrypoint) {
      case ENTRYPOINT_SPONGE_REMOTE:
        runApp(
          SpongeRemoteApp(
            service: service,
            guiFactory: SpongeGuiFactory(
              onCreateDrawer: (_) => AppDrawer(),
              onCreateRoutes: () => {
                DefaultRoutes.ACTIONS: (context) => ActionsPage(),
                DefaultRoutes.EVENTS: (context) => EventsPage(),
                DefaultRoutes.CONNECTIONS: (context) => ConnectionsPage(),
                DefaultRoutes.SETTINGS: (context) => SettingsPage(),
              },
            ),
          ),
        );
        break;
      // case ENTRYPOINT_ACTION_CALL:
      //   // TODO Setup connection.
      //   runApp(
      //     ActionCallApp(
      //       service: service,
      //       actionName: action,
      //     ),
      //   );
      //   break;
      default:
        runApp(
          MaterialApp(
            title: APPLICATION_NAME,
            home: Center(
              child: NotificationPanelWidget(
                notification: 'Unsupported entrypoint: $entrypoint',
                type: NotificationPanelType.error,
              ),
            ),
            debugShowCheckedModeBanner: false,
          ),
        );
    }
  } catch (e) {
    _logger.severe('Error in main', e, StackTrace.current);
  }
}

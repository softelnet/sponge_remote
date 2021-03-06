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
import 'package:sponge_flutter_api/sponge_flutter_api.dart';
import 'package:sponge_remote/sponge_remote.dart';
import 'package:sponge_remote_web/logger_configuration.dart';
import 'package:sponge_remote_web/web_application_service.dart';

void main() async {
  final Logger _logger = Logger('main');

  try {
    configLogger();

    WidgetsFlutterBinding.ensureInitialized();

    var service = WebApplicationService();
    await service.init();

    runApp(SpongeRemoteApp(
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
    ));
  } catch (e) {
    _logger.severe('Error in main', e, StackTrace.current);
  }
}

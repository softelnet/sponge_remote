// Copyright 2018 The Sponge authors.
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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sponge_flutter_api/sponge_flutter_api.dart';
import 'package:sponge_remote/sponge_remote.dart';
import 'package:sponge_remote_mobile/logger_configuration.dart';
import 'package:sponge_remote_mobile/mobile_application_service.dart';
import 'package:sponge_remote_mobile/network_utils.dart';

void main() async {
  configLogger();

  runApp(SpongeRemoteApp(
    service: MobileApplicationService(),
    guiFactory: SpongeGuiFactory(
      onCreateDrawer: (_) => AppDrawer(),
      onCreateConnectionsPageMenuItems: (_) => [
        ConnectionsPageMenuItemConfiguration(
          value: 'searchServices',
          itemBuilder: (_, context) => PopupMenuItem<String>(
            value: 'searchServices',
            child: IconTextPopupMenuItemWidget(
              icon: Icons.search,
              text: 'Find new nearby services',
            ),
          ),
          onSelected: onFindAndAddServices,
        ),
      ],
      onCreateRoutes: () => {
        DefaultRoutes.ACTIONS: (context) => ActionsPage(
              onGetNetworkStatus: getNetworkStatus,
            ),
        DefaultRoutes.EVENTS: (context) => EventsPage(),
        DefaultRoutes.CONNECTIONS: (context) => ConnectionsPage(
              onGetNetworkStatus: getNetworkStatus,
            ),
        DefaultRoutes.SETTINGS: (context) => SettingsPage(),
      },
      onCreateNetworkImage: (String src) => CachedNetworkImage(
        imageUrl: src,
        placeholder: (context, url) => const CircularProgressIndicator(),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      ),
    ),
  ));
}

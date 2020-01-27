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

import 'package:flutter/material.dart';
import 'package:sponge_flutter_api/sponge_flutter_api.dart';
import 'package:sponge_remote/src/about_dialog.dart';
import 'package:sponge_remote/src/application_constants.dart';

class AppDrawer extends StatelessWidget {
  AppDrawer({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ApplicationService service = ApplicationProvider.of(context).service;

    var connectionName = service.spongeService?.connection?.name;

    final iconColor = getSecondaryColor(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DefaultDrawerHeader(applicationName: APPLICATION_NAME),
          if (connectionName != null)
            ListTile(
              title: Align(
                child: Chip(
                  label: Text('$connectionName'),
                ),
                alignment: Alignment.centerRight,
              ),
              dense: true,
            ),
          ListTile(
            leading: Icon(Icons.directions_run, color: iconColor),
            title: Text('Actions'),
            onTap: () async =>
                showDistinctScreen(context, DefaultRoutes.ACTIONS),
          ),
          FutureBuilder<bool>(
            future: service.spongeService?.isGrpcEnabled(),
            builder: (context, snapshot) {
              return ListTile(
                leading: Icon(Icons.event, color: iconColor),
                title: Text('Events'),
                enabled: snapshot.hasData && snapshot.data,
                onTap: () async =>
                    showDistinctScreen(context, DefaultRoutes.EVENTS),
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.cloud, color: iconColor),
            title: Text('Connections'),
            onTap: () async =>
                showChildScreen(context, DefaultRoutes.CONNECTIONS),
          ),
          ListTile(
            leading: Icon(Icons.settings, color: iconColor),
            title: Text('Settings'),
            onTap: () async => showChildScreen(context, DefaultRoutes.SETTINGS),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.info, color: iconColor),
            title: Text('About'),
            onTap: () async => await showAboutAppDialog(context),
          ),
        ],
      ),
    );
  }
}

// Copyright 2020 The Sponge authors.
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

import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sponge_flutter_api/sponge_flutter_api.dart';
import 'package:sponge_remote_mobile/service_discovery.dart';

Future<void> onFindAndAddServices(
    BuildContext context, ConnectionsPresenter connectionsPresenter) async {
  var networkStatus = await getNetworkStatus();
  
  if (networkStatus?.isLocal ?? false) {
    if (Platform.isAndroid) {
      var status = await Permission.location.status;
      if (status.isUndetermined || status.isDenied || status.isRestricted) {
        if (!(await Permission.location.request().isGranted)) {
          return;
        }
      }
    }

    await findAndAddServices(connectionsPresenter);
  } else {
    await showWarningDialog(
        context, 'Local service discovery requires WiFi turned on.');
  }
}

Future<void> findAndAddServices(
    ConnectionsPresenter connectionsPresenter) async {
  try {
    connectionsPresenter.refresh(() => connectionsPresenter.busy = true);

    var timeout = Duration(
        seconds: FlutterApplicationService.of(connectionsPresenter.service)
            .settings
            .serviceDiscoveryTimeout);

    await for (var discoveredService in discoverServices(timeout: timeout)) {
      if (!connectionsPresenter.isBound) {
        return;
      }

      bool alreadyHasConnection = connectionsPresenter.connections.any(
          (connection) =>
              connection.url?.toLowerCase() ==
                  discoveredService.url?.toLowerCase() &&
              connection.network?.toLowerCase() ==
                  discoveredService.network?.toLowerCase());
      if (!alreadyHasConnection) {
        // Add a suffix if the name already exists.
        var name = discoveredService.name;
        var counter = 2;
        while (connectionsPresenter.connections
            .any((connection) => connection.name == discoveredService.name)) {
          discoveredService.name = '$name $counter';
          counter++;
        }

        if (connectionsPresenter.isBound) {
          await connectionsPresenter.addConnections([
            SpongeConnection(
              name: discoveredService.name,
              url: discoveredService.url,
              anonymous: true,
              network: discoveredService.network,
            )
          ]);

          connectionsPresenter.refresh();
        }
      }
    }
  } finally {
    if (connectionsPresenter.isBound) {
      connectionsPresenter.refresh(() => connectionsPresenter.busy = false);
    }
  }
}

Future<NetworkStatus> getNetworkStatus() async {
  final connectivity = Connectivity();

  switch (await connectivity.checkConnectivity()) {
    case ConnectivityResult.wifi:
      return NetworkStatus(await connectivity.getWifiName(), true);
    case ConnectivityResult.mobile:
    case ConnectivityResult.none:
      return NetworkStatus(null, false);
    default:
      return null;
  }
}

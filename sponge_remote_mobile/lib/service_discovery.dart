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

import 'dart:convert';

import 'package:connectivity/connectivity.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:sponge_client_dart/sponge_client_dart.dart';

class DiscoveredService {
  DiscoveredService({
    @required this.domainName,
    @required this.uuid,
    @required this.name,
    @required this.url,
    this.network,
  });

  String domainName;
  String uuid;
  String name;
  String url;
  String network;
}

Stream<DiscoveredService> discoverServices(
    {Duration timeout = const Duration(seconds: 5)}) async* {
  final _logger = Logger('discoverServices');

  var services = <String, DiscoveredService>{};

  final connectivity = Connectivity();

  if (await connectivity.checkConnectivity() != ConnectivityResult.wifi) {
    return;
  }

  var wifiName = await connectivity.getWifiName();

  final client = MDnsClient();

  // Start the client with default options.
  await client.start();

  try {
    // Get the PTR recod for the service.
    await for (PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer(
            SpongeClientConstants.SERVICE_DISCOVERY_TYPE),
        timeout: timeout)) {
      _logger.fine('Found PTR ${ptr.domainName}');

      await for (TxtResourceRecord txt in client.lookup<TxtResourceRecord>(
          ResourceRecordQuery.text(ptr.domainName),
          timeout: timeout)) {
        var properties = await _readServiceProperties(txt.text);

        var uuid =
            properties[SpongeClientConstants.SERVICE_DISCOVERY_PROPERTY_UUID];
        var name =
            properties[SpongeClientConstants.SERVICE_DISCOVERY_PROPERTY_NAME];
        var url =
            properties[SpongeClientConstants.SERVICE_DISCOVERY_PROPERTY_URL];

        if ((uuid?.isNotEmpty ?? false) &&
            (name?.isNotEmpty ?? false) &&
            (url?.isNotEmpty ?? false)) {
          var newService = DiscoveredService(
            domainName: ptr.domainName,
            uuid: uuid,
            name: name,
            url: url,
            network: wifiName,
          );

          if (!services.containsKey(newService.uuid)) {
            services[newService.uuid] = newService;

            _logger.fine(
                'Found service \'${newService.name}\' at ${newService.url}');

            yield newService;
          }
        }
      }
    }
  } finally {
    client.stop();
  }
}

Future<Map<String, String>> _readServiceProperties(String text) async {
  var properties = <String, String>{};

  if (text?.isNotEmpty ?? true) {
    await Stream.value(text)
        .transform(LineSplitter())
        .map((line) => line?.trim())
        .where((line) => line?.isNotEmpty ?? false)
        .forEach((line) {
      var separatorIndex = line.indexOf('=');
      if (separatorIndex > 0 && separatorIndex < line.length - 1) {
        var key = line.substring(0, separatorIndex);
        var value = line.substring(separatorIndex + 1);

        properties[key] = value;
      }
    });
  }

  return properties;
}

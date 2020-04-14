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

import 'dart:io';
import 'dart:typed_data';

import 'package:sponge_client_dart/sponge_client_dart.dart';
import 'package:sponge_flutter_api/sponge_flutter_api.dart';
import 'package:sponge_remote_mobile/logger_configuration.dart';
import 'package:test/test.dart';

/// This integration tests require sponge-examples-project-demo-service running on the localhost.
void main() {
  configLogger();

  var connection = SpongeConnection(
    name: 'connection',
    url: 'http://localhost:8888',
    anonymous: true,
  );

  var actionName = 'DigitsPredict';

  Future<SpongeService> _createSpongeService() async {
    var service = SpongeService(connection);
    await service.open();

    return service;
  }

  Future<void> run(Future<void> Function(SpongeService service) onRun) async {
    var service = await _createSpongeService();
    try {
      await onRun?.call(service);
    } finally {
      await service.close();
    }
  }

  group('SpongeService demo integration', () {
    test('version', () async {
      await run((service) async {
        expect(await service.getVersion(), isNotNull);
      });
    });
    test('getActions', () async {
      await run((service) async {
        expect(await service.getActions(), isNotEmpty);
      });
    });

    test('getAction metadata', () async {
      await run((service) async {
        ActionData actionData = await service.getAction(actionName);
        expect(actionData.actionMeta.name, equals(actionName));
        expect(actionData.actionMeta.args.length, equals(1));
        expect(actionData.actionMeta.args[0] is BinaryType, isTrue);
        expect(actionData.actionMeta.result is IntegerType, isTrue);
      });
    });

    test('action call', () async {
      await run((service) async {
        ActionData actionData = await service.getAction(actionName);
        var response = await service.callAction(actionData.actionMeta, args: [
          Uint8List.fromList(await File('test/resources/5_0.png').readAsBytes())
        ]);

        expect(response.result, equals(5));
      });
    });

    test('test connection', () async {
      await run((service) async {
        expect(await service.getVersion(),
            equals(await SpongeService.testConnection(connection)));
      });
    });
  });

  group('SpongeService state', () {
    test('properties', () async {
      await run((service) async {
        expect(service.connection.isSame(connection), isTrue);
        expect(service.connected, isTrue);
      });
    });

    test('getCachedAction', () async {
      await run((service) async {
        expect(service.getCachedAction(actionName, required: false), isNull);
        await service.getAction(actionName);

        var actionData = service.getCachedAction(actionName, required: false);
        expect(actionData, isNotNull);
        expect(actionData.actionMeta.name, equals(actionName));
      });
    });

    test('clearActions', () async {
      await run((service) async {
        await service.getActions();
        expect(service.getCachedAction(actionName, required: false), isNotNull);

        await service.clearActions();
        expect(service.getCachedAction(actionName, required: false), isNull);
      });
    });
  });
}

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

import 'package:sponge_client_dart/sponge_client_dart.dart';
import 'package:sponge_flutter_api/sponge_flutter_api.dart';
import 'package:sponge_grpc_client_dart/sponge_grpc_client_dart_web.dart';

class WebApplicationService extends FlutterApplicationService<WebSpongeService,
    FlutterApplicationSettings> {
  @override
  Future<WebSpongeService> createSpongeService(
          SpongeConnection connection,
          TypeConverter typeConverter,
          FeatureConverter featureConverter) async =>
      WebSpongeService(
          connection, typeConverter, featureConverter, typeGuiProvider);
}

class WebSpongeService extends FlutterSpongeService {
  WebSpongeService(SpongeConnection connection, TypeConverter typeConverter,
      FeatureConverter featureConverter, TypeGuiProvider typeGuiProvider)
      : super(connection, typeConverter, featureConverter, typeGuiProvider);

  @override
  SpongeGrpcClient createSpongeGrpcClient(
      SpongeRestClient client, SpongeConnection connection) {
    return WebSpongeGrpcClient(client);
  }
}

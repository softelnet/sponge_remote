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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http_parser/http_parser.dart';
import 'package:open_file/open_file.dart';

import 'package:sponge_client_dart/sponge_client_dart.dart';
import 'package:sponge_flutter_api/sponge_flutter_api.dart';

class MobileDefaultTypeGuiProvider extends DefaultTypeGuiProvider {
  MobileDefaultTypeGuiProvider() {
    registerAll({
      DataTypeKind.BINARY: (type) => MobileBinaryTypeGuiProvider(type),
    });
  }
}

class MobileBinaryTypeGuiProvider extends BinaryTypeGuiProvider {
  MobileBinaryTypeGuiProvider(DataType type) : super(type);

  @override
  Widget doCreateExtendedViewer(TypeViewerContext viewerContext) {
    if (viewerContext.value == null) {
      return null;
    }

    var mimeType = getMimeType(viewerContext) ?? '';

    if (mimeType.isNotEmpty) {
      if (ApplicationProvider.of(viewerContext.context)
              .service
              .settings
              .useInternalViewers &&
          mimeType.startsWith('image/')) {
        return ImageViewPage(
            name: viewerContext.typeLabel,
            imageData: viewerContext.value,
            onSave: () async {
              // if (!(await SimplePermissions.checkPermission(
              //     Permission.WriteExternalStorage))) {
              //   var status = await SimplePermissions.requestPermission(
              //       Permission.WriteExternalStorage);
              //   if (status != PermissionStatus.authorized) {
              //     return;
              //   }
              // }
              Directory dir = await getApplicationDocumentsDirectory();
              return (await _saveFile(viewerContext, mimeType, dir)).path;
            });
      } else {
        // Async.
        _launchExternalViewer(viewerContext, mimeType)
            .catchError((e) => handleError(viewerContext.context, e));
      }
    }

    return null;
  }

  Future<File> _saveFile(
      TypeViewerContext viewerContext, String mimeType, Directory dir) async {
    String filename = viewerContext.features[Features.TYPE_FILENAME];

    if (filename == null) {
      var mimeSubtype = MediaType.parse(mimeType).subtype;
      filename = '${DateTime.now().microsecondsSinceEpoch}.$mimeSubtype';
    }

    var file = File('${dir.path}/$filename')
      ..writeAsBytesSync(viewerContext.value, flush: true);

    return file;
  }

  Future<void> _launchExternalViewer(
      TypeViewerContext viewerContext, String mimeType) async {
    var file =
        await _saveFile(viewerContext, mimeType, await getTemporaryDirectory());

    await OpenFile.open(file.path);
  }
}

// Copyright 2021 The Sponge authors.
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

import 'dart:html' as html;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:pedantic/pedantic.dart';
import 'package:sponge_client_dart/sponge_client_dart.dart';
import 'package:sponge_flutter_api/sponge_flutter_api.dart';

// TODO [Entrypoint] Web entrypoints. Draft - Under construction!

class WebDefaultTypeGuiProviderRegistry extends DefaultTypeGuiProviderRegistry {
  WebDefaultTypeGuiProviderRegistry() {
    registerAll({
      DataTypeKind.OUTPUT_STREAM: (type) =>
          WebOutputStreamTypeGuiProvider(type),
    });
  }
}

class WebOutputStreamTypeGuiProvider extends OutputStreamTypeGuiProvider {
  WebOutputStreamTypeGuiProvider(DataType type) : super(type);

  @override
  Widget createCompactViewer(TypeViewerContext viewerContext) {
    return InkResponse(
      onTap: () => downloadFile(viewerContext.value as ClientOutputStreamValue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (viewerContext.typeLabel != null) Text(viewerContext.typeLabel),
          if (viewerContext.typeLabel != null)
            Container(
              margin: const EdgeInsets.all(2.0),
            ),
          Center(child: _createCompactViewerDataWidget(viewerContext)),
        ],
      ),
    );
  }

  Future downloadFile(ClientOutputStreamValue streamValue) async {
    var bytes = await streamValue.stream
        .expand((element) => element)
        .toList(); // !!!! No streaming!
    final blob = html.Blob([bytes]); //streamValue.stream]); //[res.bodyBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = streamValue.filename;
    //html.document.body.children.add(anchor);

    anchor.click();

    //html.document.body.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  Widget _createCompactViewerDataWidget(TypeViewerContext viewerContext) {
    var streamValue = viewerContext.value as ClientOutputStreamValue;

    var mimeType = streamValue.contentType ?? '';

    // if (mimeType.startsWith('image/')) {
    //   _compactViewerThumbnailCache ??=
    //       createThumbnail(viewerContext.value, 100);

    //   return Image.memory(_compactViewerThumbnailCache);
    // }

    if (viewerContext.value == null) {
      return Text('None',
          style: DefaultTextStyle.of(viewerContext.context)
              .style
              .apply(fontSizeFactor: 1.5));
    }

    return getIcon(
      viewerContext.context,
      viewerContext.service,
      Features.getIcon(viewerContext.features),
      orIconData: () => Icons.insert_drive_file,
      forcedSize: 50,
    );
  }
}

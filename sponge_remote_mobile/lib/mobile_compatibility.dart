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
import 'package:pedantic/pedantic.dart';

import 'package:sponge_client_dart/sponge_client_dart.dart';
import 'package:sponge_flutter_api/sponge_flutter_api.dart';
import 'package:sponge_remote_mobile/src/geo_map_controller.dart';
import 'package:sponge_remote_mobile/src/geo_map_page.dart';
import 'package:sponge_remote_mobile/src/geo_map_widget.dart';

class MobileDefaultTypeGuiProviderRegistry
    extends DefaultTypeGuiProviderRegistry {
  MobileDefaultTypeGuiProviderRegistry() {
    registerAll({
      DataTypeKind.BINARY: (type) => MobileBinaryTypeGuiProvider(type),
      DataTypeKind.LIST: (type) => MobileListTypeGuiProvider(type),
    });
  }
}

class MobileBinaryTypeGuiProvider extends BinaryTypeGuiProvider {
  MobileBinaryTypeGuiProvider(DataType type) : super(type);

  @override
  Widget createExtendedViewer(TypeViewerContext viewerContext) {
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

/// Supports geo maps.
class MobileListTypeGuiProvider extends ListTypeGuiProvider {
  MobileListTypeGuiProvider(DataType type) : super(type);

  static const ADDITIONAL_DATA_KEY_CENTER = 'map.center';
  static const ADDITIONAL_DATA_KEY_ZOOM = 'map.zoom';
  static const ADDITIONAL_DATA_KEY_VISIBLE_LAYERS = 'map.visibleLayers';

  @override
  Widget createEditor(TypeEditorContext editorContext) {
    var geoMap = Features.getGeoMap(editorContext.features);

    if (geoMap == null) {
      return null;
    }

    if (editorContext.isThisRootRecordSingleLeadingField) {
      var controller = _createGeoMapController(geoMap, editorContext, false);
      return GeoMapContainer(
        geoMapController: controller,
        onRefresh: () async {
          await _onMapRefresh(controller);
          await editorContext.callbacks.onRefresh();
        },
      );
    } else {
      var label = editorContext.getDecorationLabel();

      return FlatButton.icon(
        key: Key('open-map'),
        color: Theme.of(editorContext.context).primaryColor,
        textColor: Colors.white,
        label: Text(label?.toUpperCase() ?? 'MAP'),
        icon: Icon(
          Icons.map,
          color: getIconColor(editorContext.context),
        ),
        onPressed: () async {
          await Navigator.push(
            editorContext.context,
            createPageRoute(
              editorContext.context,
              builder: (context) => GeoMapPage(
                title: label ?? 'Map',
                geoMapController:
                    _createGeoMapController(geoMap, editorContext, true),
              ),
            ),
          );
        },
      );
    }
  }

  GeoMapController _createGeoMapController(
      GeoMap geoMap, UiContext uiContext, bool enableFullScreen) {
    var service = uiContext.service;

    return GeoMapController(
      geoMap: geoMap,
      uiContext: uiContext,
      enableClusterMarkers: service.settings.mapEnableClusterMarkers,
      enableMarkerBadges: service.settings.mapEnableMarkerBadges,
      enableCurrentLocation: service.settings.mapEnableCurrentLocation,
      followCurrentLocation: service.settings.mapFollowCurrentLocation,
      fullScreen: service.settings.mapFullScreen,
      initialCenter: uiContext.callbacks.getAdditionalData(
          uiContext.qualifiedType, ADDITIONAL_DATA_KEY_CENTER),
      initialZoom: uiContext.callbacks
          .getAdditionalData(uiContext.qualifiedType, ADDITIONAL_DATA_KEY_ZOOM),
      initialVisibleLayers: uiContext.callbacks.getAdditionalData(
          uiContext.qualifiedType, ADDITIONAL_DATA_KEY_VISIBLE_LAYERS),
      onMapClose: _onMapClose,
      enableFullScreen: enableFullScreen,
    );
  }

  void _onMapClose(GeoMapController controller) {
    _saveMapState(controller);
    unawaited(_saveMapStateAsync(controller));
  }

  Future<void> _onMapRefresh(GeoMapController controller) async {
    _saveMapState(controller);
    await _saveMapStateAsync(controller);
  }

  void _saveMapState(GeoMapController controller) {
    var uiContext = controller.uiContext;

    uiContext.callbacks.setAdditionalData(
        uiContext.qualifiedType, ADDITIONAL_DATA_KEY_CENTER, controller.center);
    uiContext.callbacks.setAdditionalData(
        uiContext.qualifiedType, ADDITIONAL_DATA_KEY_ZOOM, controller.zoom);
    uiContext.callbacks.setAdditionalData(uiContext.qualifiedType,
        ADDITIONAL_DATA_KEY_VISIBLE_LAYERS, controller.visibleLayers);
  }

  Future<void> _saveMapStateAsync(GeoMapController controller) async {
    var service = controller.uiContext.service;

    await service.settings
        .setMapEnableClusterMarkers(controller.enableClusterMarkers);
    await service.settings
        .setMapEnableMarkerBadges(controller.enableMarkerBadges);
    await service.settings
        .setMapEnableCurrentLocation(controller.enableCurrentLocation);
    await service.settings
        .setMapFollowCurrentLocation(controller.followCurrentLocation);
    await service.settings.setMapFullScreen(controller.fullScreen);
  }
}

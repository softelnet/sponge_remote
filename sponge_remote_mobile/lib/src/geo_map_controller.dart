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

import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:sponge_client_dart/sponge_client_dart.dart';
import 'package:sponge_flutter_api/sponge_flutter_api.dart';
// TODO Uncomment for FlutterMap 0.9.0.
import 'package:proj4dart/proj4dart.dart' as proj4;

typedef OnMapCloseCallback = void Function(GeoMapController geoMapController);

class GeoMapController {
  GeoMapController({
    @required GeoMap geoMap,
    @required this.uiContext,
    this.fabOpacity = 0.85,
    this.fabSize = 50,
    this.fabMargin = 10,
    this.markerWidth = 30,
    this.markerHeight = 30,
    bool enableClusterMarkers = true,
    bool enableMarkerBadges = false,
    bool enableCurrentLocation = true,
    bool followCurrentLocation = false,
    bool fullScreen = false,
    LatLng initialCenter,
    double initialZoom,
    List<bool> initialVisibleLayers,
    this.showMarkerMenuHeader = true,
    this.onMapClose,
    this.enableFullScreen = false,
  })  : assert(geoMap != null),
        assert(uiContext != null),
        assert(enableClusterMarkers != null),
        assert(enableMarkerBadges != null),
        assert(enableCurrentLocation != null),
        assert(followCurrentLocation != null),
        assert(fullScreen != null),
        assert(showMarkerMenuHeader != null),
        assert(enableFullScreen != null),
        _geoMap = geoMap,
        enableClusterMarkers = enableClusterMarkers,
        enableMarkerBadges = enableMarkerBadges,
        enableCurrentLocation = enableCurrentLocation,
        followCurrentLocation = followCurrentLocation,
        fullScreen = fullScreen {
    _layers = List.of(geoMap.layers ?? [], growable: true);
    // Add a data layer if not configured explicitly.
    if (!_layers.any((layer) => layer is GeoMarkerLayer)) {
      _layers.add(GeoMarkerLayer(label: uiContext.safeTypeLabel));
    }

    _markerLayerLookupMap = {
      for (var layer in _layers.whereType<GeoMarkerLayer>()) layer.name: layer
    };

    _setup(
      initialCenter: initialCenter,
      initialZoom: initialZoom,
      initialVisibleLayers: initialVisibleLayers,
    );
  }

  final GeoMap _geoMap;
  final UiContext uiContext;

  // Settings for a specific map.
  LatLng initialCenter;
  double initialZoom;
  List<bool> visibleLayers;

  // Settings for all maps.
  bool enableClusterMarkers;
  bool enableMarkerBadges;
  bool enableCurrentLocation;
  bool followCurrentLocation;
  bool fullScreen;

  double fabOpacity;
  double fabSize;
  double fabMargin;
  double markerWidth;
  double markerHeight;

  bool showMarkerMenuHeader;

  OnMapCloseCallback onMapClose;
  final bool enableFullScreen;

  double get minZoom => _geoMap.minZoom;
  double get maxZoom => _geoMap.maxZoom;

  List<GeoLayer> _layers;
  List<GeoLayer> get layers => _layers;

  Map<String, GeoLayer> _markerLayerLookupMap;

  LatLng center;
  double zoom;

  GeoCrs get crs => _geoMap.crs;

  MapController _mapController;

  void bindMapController(MapController mapController) =>
      _mapController = mapController;

  List get data => (uiContext.value as List) ?? [];

  String getTopVisibleLayerAttribution() {
    String attribution;

    _layers.asMap().forEach((index, layer) {
      if (visibleLayers[index] && layer.features != null) {
        attribution ??= layer.features[Features.GEO_ATTRIBUTION];
      }
    });

    return attribution;
  }

  String get attribution =>
      getTopVisibleLayerAttribution() ??
      _geoMap.features[Features.GEO_ATTRIBUTION];

  Color get backgroundColor => string2color(_geoMap.features[Features.COLOR]);

  void _setup({
    @required LatLng initialCenter,
    @required double initialZoom,
    @required List<bool> initialVisibleLayers,
  }) {
    visibleLayers = (initialVisibleLayers != null &&
            initialVisibleLayers.length == _layers.length)
        ? initialVisibleLayers
        : _layers
            .map((layer) => Features.getBool(layer?.features, Features.VISIBLE,
                orElse: () => true))
            .toList();

    this.initialCenter = initialCenter ??
        (_geoMap.center?.latitude != null && _geoMap.center?.longitude != null
            ? LatLng(_geoMap.center.latitude, _geoMap.center.longitude)
            : _findDataPosition());

    this.initialZoom = initialZoom ?? _geoMap.zoom ?? 13;

    center = initialCenter;
    zoom = initialZoom;
  }

  GeoPosition getElementGeoPositionByIndex(int index) =>
      getElementGeoPosition(data[index]);

  GeoPosition getElementGeoPosition(dynamic element) {
    if (!(element is AnnotatedValue)) {
      return null;
    }

    var geoPosition = Features.getGeoPosition(element.features);
    if (geoPosition?.latitude == null || geoPosition?.longitude == null) {
      return null;
    }

    return geoPosition;
  }

  LatLng _findDataPosition() {
    var layerVisibility = _getLayerVisibility();

    var geoPosition = data
        .where((element) =>
            layerVisibility[element.features[Features.GEO_LAYER_NAME]])
        .map(getElementGeoPosition)
        .firstWhere((geoPosition) => geoPosition != null, orElse: () => null);
    if (geoPosition?.latitude != null && geoPosition?.longitude != null) {
      return LatLng(geoPosition.latitude, geoPosition.longitude);
    }

    return null;
  }

  void moveToData() {
    var dataPosition = _findDataPosition();
    if (dataPosition != null) {
      _mapController.move(dataPosition, zoom);
    }
  }

  LayerOptions _createBaseLayer(GeoLayer layer) {
    if (layer is GeoTileLayer && layer.urlTemplate != null) {
      return TileLayerOptions(
        urlTemplate: layer.urlTemplate,
        additionalOptions: layer.options,
        subdomains: layer.subdomains ?? [],
        tms: Features.getBool(layer.features, Features.GEO_TMS,
            orElse: () => false),
        opacity: Features.getDouble(layer.features, Features.OPACITY,
            orElse: () => 1.0),
        backgroundColor: Colors.transparent,
      );
    } else if (layer is GeoWmsLayer && layer.baseUrl != null) {
      // TODO Uncomment for FlutterMap 0.9.0.
      return TileLayerOptions(
        wmsOptions: WMSTileLayerOptions(
          baseUrl: layer.baseUrl,
          layers: layer.layers ?? [],
          styles: layer.styles ?? [],
          format: layer.format ?? 'image/png',
          version: layer.version ?? '1.1.1',
          transparent: layer.transparent ?? true,
          crs: GeoMapController.createCrs(layer.crs) ?? const Epsg3857(),
          otherParameters: layer.otherParameters ?? {},
        ),
        opacity: Features.getDouble(layer.features, Features.OPACITY,
            orElse: () => 1.0),
        backgroundColor: Colors.transparent,
      );
    }

    return null;
  }

  List<LayerOptions> createBaseLayers() {
    var layerOptions = <LayerOptions>[];

    layers.asMap().forEach((index, layer) {
      if (visibleLayers[index]) {
        var uiLayer = _createBaseLayer(layer);
        if (uiLayer != null) {
          layerOptions.add(uiLayer);
        }
      }
    });

    return layerOptions;
  }

  Map<String, bool> _getLayerVisibility() {
    var layerVisibility = <String, bool>{};
    _layers.asMap().forEach((index, layer) {
      layerVisibility[layer.name] = visibleLayers[index];
    });

    return layerVisibility;
  }

  List<Marker> createMarkers(FlutterApplicationService service,
      SubActionsController subActionsController) {
    var markers = <Marker>[];

    var layerVisibility = _getLayerVisibility();
    var list = data;

    var badgeColor = getPrimaryDarkerColor(uiContext.context).withOpacity(0.75);

    for (int i = 0; i < list.length; i++) {
      var element = list[i];

      var geoPosition = getElementGeoPositionByIndex(i);

      if (geoPosition == null) {
        continue;
      }

      var layerName = element.features[Features.GEO_LAYER_NAME];

      // Best effort for a default layer icon.
      var iconInfo = Features.getIcon(element.features) ??
          Features.getIcon(_markerLayerLookupMap[layerName]?.features);

      var iconData = getIconData(service, iconInfo?.name) ?? MdiIcons.marker;
      var iconColor = string2color(iconInfo?.color) ??
          getPrimaryDarkerColor(uiContext.context);
      var iconSize = iconInfo?.size;
      var icon = Icon(iconData, color: iconColor, size: iconSize);
      var label = element.valueLabel;

      if (layerVisibility[layerName]) {
        markers.add(
          Marker(
            width: iconSize ?? markerWidth,
            height: iconSize ?? markerHeight,
            point: LatLng(geoPosition.latitude, geoPosition.longitude),
            builder: (ctx) {
              return SubActionsWidget.forListElement(
                uiContext,
                service.spongeService,
                key: Key('map-element-$i'),
                controller: subActionsController,
                element: element,
                index: i,
                parentType: uiContext.qualifiedType.type,
                parentValue: uiContext.callbacks
                    .getRawValue(uiContext.qualifiedType.path),
                menuIcon: enableMarkerBadges
                    ? Badge(
                        child: icon,
                        badgeContent: Text(label),
                        shape: BadgeShape.square,
                        badgeColor: badgeColor,
                      )
                    : icon,
                header: showMarkerMenuHeader ? Text(label) : null,
                tooltip: label,
              );
            },
          ),
        );
      }
    }

    return markers;
  }

  void reset() {
    _setup(
      initialCenter: null,
      initialZoom: null,
      initialVisibleLayers: null,
    );

    _mapController.move(initialCenter, initialZoom);
  }

  Widget buildMenuIcon(BuildContext context) => Opacity(
        opacity: fabOpacity,
        child: SizedBox(
          child: FloatingActionButton(
            heroTag: 'fabMenu',
            onPressed: null,
            child: Icon(getPopupMenuIconData(context)),
          ),
          width: fabSize,
          height: fabSize,
        ),
      );

  void toggleLayerVisibility(int index) {
    visibleLayers[index] = !visibleLayers[index];

    // TODO Doesn't work in FlutterMap 0.9.0.

    // Hide other layers in the same group if the layer has became visible.
    if (visibleLayers[index]) {
      var group = _layers[index]?.features[Features.GROUP];
      if (group != null) {
        for (var i = 0; i < layers.length; i++) {
          if (i != index && _layers[i]?.features[Features.GROUP] == group) {
            visibleLayers[i] = false;
          }
        }
      }
    }
  }

  Widget buildMenu(BuildContext context, VoidCallback onRefresh,
      {Widget icon}) {
    var layerItems = <CheckedPopupMenuItem<int>>[];
    layers.asMap().forEach((index, layer) => layerItems.add(
          CheckedPopupMenuItem<int>(
            key: Key('map-menu-layer-$index'),
            value: index,
            child: Text(layer.label ?? layer.name ?? 'Layer ${index + 1}'),
            checked: visibleLayers[index],
          ),
        ));

    return PopupMenuButton<Object>(
      key: Key('map-menu'),
      onSelected: (value) {
        if (value == 'enableClusterMarkers') {
          enableClusterMarkers = !enableClusterMarkers;
        } else if (value == 'enableMarkerBadges') {
          enableMarkerBadges = !enableMarkerBadges;
        } else if (value == 'moveToData') {
          moveToData();
        } else if (value == 'enableCurrentLocation') {
          enableCurrentLocation = !enableCurrentLocation;
        } else if (value == 'followCurrentLocation') {
          followCurrentLocation = !followCurrentLocation;
        } else if (value == 'reset') {
          reset();
        } else if (value == 'fullScreen') {
          fullScreen = !fullScreen;
        } else if (value is int) {
          toggleLayerVisibility(value);
        }

        onRefresh?.call();
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          key: Key('map-menu-enableClusterMarkers'),
          value: 'enableClusterMarkers',
          child: IconTextPopupMenuItemWidget(
            icon: MdiIcons.mapMarker,
            text: 'Cluster data markers',
            isOn: enableClusterMarkers,
          ),
        ),
        PopupMenuItem<String>(
          key: Key('map-menu-enableMarkerBadges'),
          value: 'enableMarkerBadges',
          child: IconTextPopupMenuItemWidget(
            icon: MdiIcons.label,
            text: 'Show marker badges',
            isOn: enableMarkerBadges,
          ),
        ),
        PopupMenuItem<String>(
          key: Key('map-menu-moveToData'),
          value: 'moveToData',
          child: const IconTextPopupMenuItemWidget(
            icon: Icons.list,
            text: 'Move to data',
          ),
        ),
        PopupMenuItem<String>(
          key: Key('map-menu-enableCurrentLocation'),
          value: 'enableCurrentLocation',
          child: IconTextPopupMenuItemWidget(
            icon: MdiIcons.crosshairsGps,
            text: 'Show current location (experimental)',
            isOn: enableCurrentLocation,
          ),
        ),
        PopupMenuItem<String>(
          key: Key('map-menu-followCurrentLocation'),
          value: 'followCurrentLocation',
          child: IconTextPopupMenuItemWidget(
            icon: MdiIcons.locationEnter,
            text: 'Follow current location',
            isOn: followCurrentLocation,
          ),
          enabled: enableCurrentLocation,
        ),
        const PopupMenuItem<String>(
          key: Key('map-menu-reset'),
          value: 'reset',
          child: IconTextPopupMenuItemWidget(
            icon: Icons.restore,
            text: 'Reset map',
          ),
        ),
        if (enableFullScreen)
          PopupMenuItem<String>(
            key: Key('map-menu-fullScreen'),
            value: 'fullScreen',
            child: IconTextPopupMenuItemWidget(
              icon: Icons.fullscreen,
              text: 'Full screen',
              isOn: fullScreen,
            ),
          ),
        if (layerItems.isNotEmpty) const PopupMenuDivider(),
        ...layerItems,
      ],
      padding: EdgeInsets.zero,
      icon: icon,
    );
  }

  static final _predefinedCrsCodeMap = {
    Epsg3857().code: Epsg3857(),
    Epsg4326().code: Epsg4326(),
  };

  static final _predefinedResolutions = <double>[
    32768,
    16384,
    8192,
    4096,
    2048,
    1024,
    512,
    256,
    128
  ];

  static Crs createCrs(GeoCrs geoCrs) {
    if (geoCrs?.code == null) {
      return null;
    }

    if (geoCrs.projection == null) {
      var crs = _predefinedCrsCodeMap[geoCrs.code];
      if (crs != null) {
        return crs;
      }
    }

    // TODO Uncomment for FlutterMap 0.9.0.
    var projection = proj4.Projection(geoCrs.code);
    if (projection == null) {
      Validate.isTrue(geoCrs.projection != null,
          'A projection definition must be specified for ${geoCrs.code}');

      projection = proj4.Projection.add(geoCrs.code, geoCrs.projection);
    }

    return Proj4Crs.fromFactory(
      code: geoCrs.code,
      proj4Projection: projection,
      resolutions: geoCrs.resolutions ?? _predefinedResolutions,
    );
  }
}

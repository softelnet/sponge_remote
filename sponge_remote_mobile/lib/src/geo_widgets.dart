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

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong/latlong.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:sponge_client_dart/sponge_client_dart.dart';
import 'package:sponge_flutter_api/sponge_flutter_api.dart';
import 'package:user_location/user_location.dart';

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
    bool enableCurrentLocation = true,
    bool followCurrentLocation = false,
    bool fullScreen = false,
  })  : assert(geoMap != null),
        assert(uiContext != null),
        assert(enableClusterMarkers != null),
        assert(enableCurrentLocation != null),
        assert(followCurrentLocation != null),
        assert(fullScreen != null),
        _geoMap = geoMap,
        enableClusterMarkers = enableClusterMarkers,
        enableCurrentLocation = enableCurrentLocation,
        followCurrentLocation = followCurrentLocation,
        fullScreen = fullScreen {
    _layers = List.of(geoMap.layers ?? [], growable: true);
    // Add a data layer if not configured explicitly.
    if (!_layers.any((layer) => layer is GeoMarkerLayer)) {
      _layers.add(GeoMarkerLayer(label: uiContext.safeTypeLabel));
    }

    visibleLayers = List.filled(_layers.length, true, growable: true);

    center = geoMap.center?.latitude != null && geoMap.center?.longitude != null
        ? LatLng(geoMap.center.latitude, geoMap.center.longitude)
        : _findDataPosition();
    zoom = geoMap.zoom ?? 13;
  }

  final GeoMap _geoMap;
  final UiContext uiContext;

  // Settings for a specific map.
  LatLng center;
  double zoom;
  List<bool> visibleLayers;

  // Settings for all maps.
  bool enableClusterMarkers;
  bool enableCurrentLocation;
  bool followCurrentLocation;
  bool fullScreen;

  double fabOpacity;
  double fabSize;
  double fabMargin;
  double markerWidth;
  double markerHeight;

  double get minZoom => _geoMap.minZoom;
  double get maxZoom => _geoMap.maxZoom;

  List<GeoLayer> _layers;
  List<GeoLayer> get layers => _layers;
  String get attribution => _geoMap.features[Features.GEO_ATTRIBUTION];

  final mapController = MapController();

  List get data => (uiContext.value as List) ?? [];

  GeoPosition getElementGeoPositionByIndex(int index) =>
      getElementGeoPosition(data[index]);

  GeoPosition getElementGeoPosition(dynamic element) {
    if (!(element is AnnotatedValue)) {
      return null;
    }

    // TODO Convert JSON Map to GeoPosition in a lower layer.
    var geoPosition =
        GeoPosition.fromJson(element.features[Features.GEO_POSITION]);
    if (geoPosition?.latitude == null || geoPosition?.longitude == null) {
      return null;
    }

    return geoPosition;
  }

  LatLng _findDataPosition() {
    var geoPosition = data
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
      center = dataPosition;

      mapController.move(center, mapController.zoom);
    }
  }

  List<TileLayerOptions> createBaseLayers() {
    var layerOptions = <TileLayerOptions>[];

    _layers.asMap().forEach((index, layer) {
      if (visibleLayers[index] &&
          layer is GeoTileLayer &&
          layer.urlTemplate != null) {
        layerOptions.add(TileLayerOptions(
          urlTemplate: layer.urlTemplate,
          additionalOptions: layer.options,
          subdomains: layer.subdomains ?? [],
        ));
      }
    });

    return layerOptions;
  }

  List<Marker> createMarkers(FlutterApplicationService service,
      SubActionsController subActionsController) {
    var markers = <Marker>[];

    var layerVisibility = <String, bool>{};
    _layers.asMap().forEach((index, layer) {
      layerVisibility[layer.name] =
          layer is GeoMarkerLayer && visibleLayers[index];
    });

    var list = data;

    for (int i = 0; i < list.length; i++) {
      var element = list[i];

      var geoPosition = getElementGeoPositionByIndex(i);

      if (geoPosition == null) {
        continue;
      }

      var iconData = getIconData(service, element.features[Features.ICON]) ??
          MdiIcons.marker;
      var iconColor = string2color(element.features[Features.ICON_COLOR]) ??
          getPrimaryDarkerColor(uiContext.context);
      var iconWidth =
          (element.features[Features.ICON_WIDTH] as num)?.toDouble();
      var iconHeight =
          (element.features[Features.ICON_HEIGHT] as num)?.toDouble();
      var icon = Icon(iconData, color: iconColor, size: iconWidth);
      var label = element.valueLabel;

      var layerName = element.features[Features.GEO_LATER_NAME];

      if (layerVisibility[layerName]) {
        markers.add(
          Marker(
            width: iconWidth ?? markerWidth,
            height: iconHeight ?? markerHeight,
            point: LatLng(geoPosition.latitude, geoPosition.longitude),
            builder: (ctx) {
              return SubActionsWidget.forListElement(
                uiContext,
                service.spongeService,
                controller: subActionsController,
                element: element,
                index: i,
                menuIcon: icon,
                tooltip: label,
              );
            },
          ),
        );
      }
    }

    return markers;
  }
}

class GeoMapWidget extends StatefulWidget {
  GeoMapWidget({
    Key key,
    @required this.geoMapController,
    bool clusterMarkers = true,
  }) : super(key: key);

  final GeoMapController geoMapController;

  @override
  _GeoMapWidgetState createState() => _GeoMapWidgetState();
}

class _GeoMapWidgetState extends State<GeoMapWidget> {
  SubActionsController _subActionsController;

  UiContext get uiContext => widget.geoMapController.uiContext;

  bool get clusterMarkers => widget.geoMapController.enableClusterMarkers;

  @override
  Widget build(BuildContext context) {
    var service = ApplicationProvider.of(context).service;

    _subActionsController =
        SubActionsController.forList(uiContext, service.spongeService);

    var markers =
        widget.geoMapController.createMarkers(service, _subActionsController);
    var attribution = widget.geoMapController.attribution;

    return Stack(
      children: [
        FlutterMap(
          options: _createMapOptions(),
          layers: [
            ...widget.geoMapController.createBaseLayers(),
            if (!clusterMarkers) MarkerLayerOptions(markers: markers),
            if (clusterMarkers) _createMarkerClusterLayerOptions(markers),
            if (widget.geoMapController.enableCurrentLocation)
              _createUserLocationOptions(markers),
          ],
          mapController: widget.geoMapController.mapController,
        ),
        if (attribution != null) _buildAttributionWidget(attribution),
      ],
    );
  }

  MapOptions _createMapOptions() {
    return MapOptions(
      center: widget.geoMapController.center,
      zoom: widget.geoMapController.zoom,
      minZoom: widget.geoMapController.minZoom,
      maxZoom: widget.geoMapController.maxZoom,
      // The CRS is currently ignored.
      onPositionChanged: (MapPosition position, bool hasGesture) {
        widget.geoMapController.center = position.center;
        widget.geoMapController.zoom = position.zoom;
      },
      plugins: [
        if (clusterMarkers) MarkerClusterPlugin(),
        if (widget.geoMapController.enableCurrentLocation) UserLocationPlugin(),
      ],
    );
  }

  Widget _buildAttributionWidget(Object attribution) {
    return Container(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 5, bottom: 2),
        child: Opacity(
          opacity: 0.75,
          child: Text(
            attribution.toString(),
            style: TextStyle(
              color: Colors.black,
              backgroundColor: Colors.white,
              fontSize: Theme.of(context).textTheme.caption.fontSize,
            ),
          ),
        ),
      ),
    );
  }

  MarkerClusterLayerOptions _createMarkerClusterLayerOptions(
      List<Marker> markers) {
    return MarkerClusterLayerOptions(
      maxClusterRadius: 60,
      size: Size(40, 40),
      fitBoundsOptions: FitBoundsOptions(
        padding: EdgeInsets.all(50),
      ),
      markers: markers,
      polygonOptions: PolygonOptions(
        borderColor: Colors.blueAccent,
        color: Colors.black12,
        borderStrokeWidth: 2,
      ),
      builder: (context, markers) {
        return CircleAvatar(
          backgroundColor: getPrimaryColor(context),
          child: Text(markers.length.toString()),
        );
      },
    );
  }

  UserLocationOptions _createUserLocationOptions(List<Marker> markers) {
    return UserLocationOptions(
      context: context,
      mapController: widget.geoMapController.mapController,
      markers: markers,
      zoomToCurrentLocationOnLoad: false,
      updateMapLocationOnPositionChange:
          widget.geoMapController.followCurrentLocation,
      moveToCurrentLocationFloatingActionButton:
          _buildMoveToCurrentLocationFloatingActionButton(),
      fabBottom: widget.geoMapController.fabMargin,
      fabRight: widget.geoMapController.fabMargin,
      fabWidth: widget.geoMapController.fabSize,
      fabHeight: widget.geoMapController.fabSize,
    );
  }

  Widget _buildMoveToCurrentLocationFloatingActionButton() => Opacity(
      opacity: widget.geoMapController.fabOpacity,
      child: FloatingActionButton(
        heroTag: 'fabMoveToCurrentLocation',
        onPressed: null,
        child: Icon(Icons.my_location),
        backgroundColor: getFloatingButtonBackgroudColor(context),
      ));
}

class GeoMapPage extends StatefulWidget {
  GeoMapPage({
    Key key,
    @required this.title,
    @required this.geoMapController,
  }) : super(key: key);

  final String title;
  final GeoMapController geoMapController;

  @override
  _GeoMapPageState createState() => _GeoMapPageState();
}

class _GeoMapPageState extends State<GeoMapPage> {
  GeoMapController get _geoMapController => widget.geoMapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _geoMapController.fullScreen
          ? null
          : AppBar(
              title: Tooltip(
                message: widget.title,
                child: Text(widget.title),
              ),
              actions: <Widget>[
                _buildMenu(context),
              ],
            ),
      body: SafeArea(
        child: Stack(
          children: [
            GeoMapWidget(
              geoMapController: _geoMapController,
            ),
            if (_geoMapController.fullScreen)
              Container(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.only(
                    right: _geoMapController.fabMargin,
                    top: _geoMapController.fabMargin,
                  ),
                  child: _buildMenu(
                    context,
                    icon: _buildMenuIcon(context),
                    //),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuIcon(BuildContext context) => Opacity(
        opacity: _geoMapController.fabOpacity,
        child: SizedBox(
          child: FloatingActionButton(
            heroTag: 'fabMenu',
            onPressed: null,
            child: Icon(getPopupMenuIconData(context)),
            backgroundColor: getFloatingButtonBackgroudColor(context),
          ),
          width: _geoMapController.fabSize,
          height: _geoMapController.fabSize,
        ),
      );

  Widget _buildMenu(BuildContext context, {Widget icon}) {
    var layerItems = <CheckedPopupMenuItem<int>>[];
    _geoMapController.layers.asMap().forEach((index, layer) => layerItems.add(
          CheckedPopupMenuItem<int>(
            key: Key('map-menu-layer-$index'),
            value: index,
            child: Text(layer.label ?? layer.name ?? 'Layer ${index + 1}'),
            checked: _geoMapController.visibleLayers[index],
          ),
        ));

    return PopupMenuButton<Object>(
      key: Key('map-menu'),
      onSelected: (value) {
        setState(() {
          if (value == 'enableClusterMarkers') {
            _geoMapController.enableClusterMarkers =
                !_geoMapController.enableClusterMarkers;
          } else if (value == 'moveToData') {
            _geoMapController.moveToData();
          } else if (value == 'enableCurrentLocation') {
            _geoMapController.enableCurrentLocation =
                !_geoMapController.enableCurrentLocation;
          } else if (value == 'followCurrentLocation') {
            _geoMapController.followCurrentLocation =
                !_geoMapController.followCurrentLocation;
          } else if (value == 'fullScreen') {
            _geoMapController.fullScreen = !_geoMapController.fullScreen;
          } else if (value is int) {
            _geoMapController.visibleLayers[value] =
                !_geoMapController.visibleLayers[value];
          }
        });
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          key: Key('map-menu-enableClusterMarkers'),
          value: 'enableClusterMarkers',
          child: IconTextPopupMenuItemWidget(
            icon: MdiIcons.mapMarker,
            text: 'Cluster data markers',
            isOn: _geoMapController.enableClusterMarkers,
          ),
        ),
        PopupMenuItem<String>(
          key: Key('map-menu-moveToData'),
          value: 'moveToData',
          child: IconTextPopupMenuItemWidget(
            icon: Icons.list,
            text: 'Move to data',
          ),
        ),
        PopupMenuItem<String>(
          key: Key('map-menu-enableCurrentLocation'),
          value: 'enableCurrentLocation',
          child: IconTextPopupMenuItemWidget(
            icon: MdiIcons.crosshairsGps,
            text: 'Show current location',
            isOn: _geoMapController.enableCurrentLocation,
          ),
        ),
        PopupMenuItem<String>(
          key: Key('map-menu-followCurrentLocation'),
          value: 'followCurrentLocation',
          child: IconTextPopupMenuItemWidget(
            icon: MdiIcons.locationEnter,
            text: 'Follow current location',
            isOn: _geoMapController.followCurrentLocation,
          ),
          enabled: _geoMapController.enableCurrentLocation,
        ),
        PopupMenuItem<String>(
          key: Key('map-menu-fullScreen'),
          value: 'fullScreen',
          child: IconTextPopupMenuItemWidget(
            icon: Icons.fullscreen,
            text: 'Full screen',
            isOn: _geoMapController.fullScreen,
          ),
        ),
        if (layerItems.isNotEmpty) PopupMenuDivider(),
        ...layerItems,
      ],
      padding: EdgeInsets.zero,
      icon: icon,
    );
  }
}

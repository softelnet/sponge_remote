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
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong/latlong.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:sponge_client_dart/sponge_client_dart.dart';
import 'package:sponge_flutter_api/sponge_flutter_api.dart';
import 'package:user_location/user_location.dart';

typedef void OnMapCloseCallback(GeoMapController geoMapController);

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

    _markerLayerLookupMap = Map.fromIterable(
        _layers.whereType<GeoMarkerLayer>(),
        key: (layer) => layer.name,
        value: (layer) => layer);

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

  MapController _mapController;

  void bindMapController(MapController mapController) =>
      _mapController = mapController;

  List get data => (uiContext.value as List) ?? [];

  GeoLayer getTopVisibleBasemapLayer() {
    var result;

    _layers.asMap().forEach((index, layer) {
      if (layer is GeoTileLayer && visibleLayers[index]) {
        result = layer;
      }
    });

    return result;
  }

  String get attribution {
    var topBasemapLayer = getTopVisibleBasemapLayer();

    return (topBasemapLayer?.features != null
            ? topBasemapLayer?.features[Features.GEO_ATTRIBUTION]
            : null) ??
        _geoMap.features[Features.GEO_ATTRIBUTION];
  }

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

  List<TileLayerOptions> createBaseLayers() {
    var layerOptions = <TileLayerOptions>[];

    _layers.asMap().forEach((index, layer) {
      if (visibleLayers[index] &&
          layer is GeoTileLayer &&
          layer.urlTemplate != null) {
        layerOptions.add(
          TileLayerOptions(
            urlTemplate: layer.urlTemplate,
            additionalOptions: layer.options,
            subdomains: layer.subdomains ?? [],
            tms: Features.getBool(layer.features, Features.GEO_TMS,
                orElse: () => false),
            opacity: Features.getDouble(layer.features, Features.OPACITY,
                orElse: () => 1.0),
          ),
        );
      }
    });

    return layerOptions;
  }

  Map<String, bool> _getLayerVisibility() {
    var layerVisibility = <String, bool>{};
    _layers.asMap().forEach((index, layer) {
      layerVisibility[layer.name] =
          layer is GeoMarkerLayer && visibleLayers[index];
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
                controller: subActionsController,
                element: element,
                index: i,
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

    // Hide other layers in the same group if the layer has became visible.
    if (visibleLayers[index]) {
      var goup = _layers[index]?.features[Features.GROUP];
      if (goup != null) {
        layers.asMap().forEach((i, l) {
          if (i != index && _layers[i]?.features[Features.GROUP] == goup) {
            visibleLayers[i] = false;
          }
        });
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

        if (onRefresh != null) {
          onRefresh();
        }
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
        PopupMenuItem<String>(
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
        if (layerItems.isNotEmpty) PopupMenuDivider(),
        ...layerItems,
      ],
      padding: EdgeInsets.zero,
      icon: icon,
    );
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

  /// The map controller must be associated with the widget state.
  final _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    var service = ApplicationProvider.of(context).service;

    // Bind the map controller associated with the state for each GeoMapController instance.
    widget.geoMapController.bindMapController(_mapController);

    _subActionsController =
        SubActionsController.forList(uiContext, service.spongeService);

    var markers =
        widget.geoMapController.createMarkers(service, _subActionsController);
    var attribution = widget.geoMapController.attribution;

    return Stack(
      children: [
        Container(
          child: FlutterMap(
            options: _createMapOptions(),
            layers: [
              ...widget.geoMapController.createBaseLayers(),
              if (!clusterMarkers) MarkerLayerOptions(markers: markers),
              if (clusterMarkers) _createMarkerClusterLayerOptions(markers),
              if (widget.geoMapController.enableCurrentLocation)
                _createUserLocationOptions(markers),
            ],
            mapController: _mapController,
          ),
          color: widget.geoMapController.backgroundColor,
        ),
        if (attribution != null) _buildAttributionWidget(attribution),
      ],
    );
  }

  MapOptions _createMapOptions() {
    return MapOptions(
      center: widget.geoMapController.initialCenter,
      zoom: widget.geoMapController.initialZoom,
      minZoom: widget.geoMapController.minZoom,
      maxZoom: widget.geoMapController.maxZoom,
      // The CRS is currently ignored.
      plugins: [
        if (clusterMarkers) MarkerClusterPlugin(),
        if (widget.geoMapController.enableCurrentLocation) UserLocationPlugin(),
      ],
      onPositionChanged: (MapPosition position, bool hasGesture) {
        // Update the map position in the geo map controller.
        widget.geoMapController.center = position.center;
        widget.geoMapController.zoom = position.zoom;
      },
    );
  }

  Widget _buildAttributionWidget(Object attribution) {
    return Container(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: EdgeInsets.only(
            left: 5,
            bottom: 2,
            // Margin for the location FAB.
            right: widget.geoMapController.fabSize +
                widget.geoMapController.fabMargin * 2),
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
      mapController: _mapController,
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
      ));
}

class GeoMapContainer extends StatefulWidget {
  GeoMapContainer({
    @required this.geoMapController,
    this.onRefresh,
  });

  final GeoMapController geoMapController;
  final VoidCallback onRefresh;

  @override
  _GeoMapContainerState createState() => _GeoMapContainerState();
}

class _GeoMapContainerState extends State<GeoMapContainer> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GeoMapWidget(
          geoMapController: widget.geoMapController,
        ),
        // TODO Full screen map in the acton call page.
        //if (widget.geoMapController.fullScreen)
        Container(
          alignment: Alignment.topRight,
          child: Padding(
            padding: EdgeInsets.only(
              right: widget.geoMapController.fabMargin,
              top: widget.geoMapController.fabMargin,
            ),
            child: widget.geoMapController.buildMenu(
              context,
              widget.onRefresh != null
                  ? widget.onRefresh
                  : () => setState(() {}),
              icon: widget.geoMapController.buildMenuIcon(context),
              //),
            ),
          ),
        ),
      ],
    );

    // return GeoMapWidget(
    //   geoMapController: widget.geoMapController,
    // );
  }

  @override
  void deactivate() {
    if (widget.geoMapController.onMapClose != null) {
      widget.geoMapController.onMapClose(widget.geoMapController);
    }

    super.deactivate();
  }
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
              // actions: <Widget>[
              //   _geoMapController.buildMenu(
              //     context,
              //     () => setState(() {}),
              //   ),
              // ],
            ),
      body: SafeArea(
        child: GeoMapContainer(
          geoMapController: _geoMapController,
          onRefresh: () => setState(() {}),
        ),
      ),
    );
  }
}

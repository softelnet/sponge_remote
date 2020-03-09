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

  GeoMap get geoMap => widget.geoMapController.geoMap;

  UiContext get uiContext => widget.geoMapController.uiContext;

  bool get clusterMarkers => widget.geoMapController.clusterMarkers;

  @override
  Widget build(BuildContext context) {
    var service = ApplicationProvider.of(context).service;

    _subActionsController =
        SubActionsController.forList(uiContext, service.spongeService);

    var markers = _createMarkers();
    var attribution = geoMap.features[Features.GEO_ATTRIBUTION];

    return Stack(
      children: [
        FlutterMap(
          options: _createMapOptions(),
          layers: [
            ..._createBaseLayers(),
            if (!clusterMarkers) MarkerLayerOptions(markers: markers),
            if (clusterMarkers) _createMarkerClusterLayerOptions(markers),
            _createUserLocationOptions(markers),
          ],
          mapController: widget.geoMapController.mapController,
        ),
        if (attribution != null) _buildAttributionWidget(attribution),
      ],
    );
  }

  List<TileLayerOptions> _createBaseLayers() {
    var layerOptions = <TileLayerOptions>[];

    geoMap.layers?.asMap()?.forEach((index, layer) {
      if (widget.geoMapController.visibleLayers[index] &&
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

  MapOptions _createMapOptions() {
    return MapOptions(
      center: widget.geoMapController.center,
      zoom: geoMap.zoom ?? 13,
      minZoom: geoMap.minZoom,
      maxZoom: geoMap.maxZoom,
      // The CRS is currently ignored.
      //debug: true,
      plugins: [
        UserLocationPlugin(),
        if (clusterMarkers) MarkerClusterPlugin(),
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

  List<Marker> _createMarkers() {
    var markers = <Marker>[];

    var service = ApplicationProvider.of(context).service;
    var list = widget.geoMapController.data; //(uiContext.value as List) ?? [];

    for (int i = 0; i < list.length; i++) {
      var element = list[i];

      var geoPosition = widget.geoMapController.getElementGeoPositionByIndex(i);

      if (geoPosition == null) {
        continue;
      }

      var iconData = getIconData(service, element.features[Features.ICON]) ??
          MdiIcons.marker;
      var iconColor = string2color(element.features[Features.ICON_COLOR]);
      var iconWidth =
          (element.features[Features.ICON_WIDTH] as num)?.toDouble();
      var icon = Icon(iconData, color: iconColor, size: iconWidth);
      var label = element.valueLabel;

      markers.add(
        Marker(
          width: iconWidth ?? 30.0,
          height: (element.features[Features.ICON_HEIGHT] as num).toDouble() ??
              30.0,
          point: LatLng(geoPosition.latitude, geoPosition.longitude),
          builder: (ctx) {
            return SubActionsWidget.forListElement(
              uiContext,
              service.spongeService,
              controller: _subActionsController,
              element: element,
              index: i,
              menuIcon: icon,
              tooltip: label,
            );
          },
        ),
      );
    }

    return markers;
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
      updateMapLocationOnPositionChange: false,
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

class GeoMapController {
  GeoMapController({
    @required this.geoMap,
    @required this.uiContext,
    this.center,
    this.fabOpacity = 0.85,
    this.fabSize = 50,
    this.fabMargin = 10,
    List<bool> visibleLayers,
    this.visibleData = true,
    bool clusterMarkers = true,
  })  : assert(clusterMarkers != null),
        visibleLayers = visibleLayers ?? [],
        clusterMarkers = clusterMarkers;

  final GeoMap geoMap;
  final UiContext uiContext;

  LatLng center;
  double fabOpacity;
  double fabSize;
  double fabMargin;
  List<bool> visibleLayers;
  bool visibleData;
  bool clusterMarkers;

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

  void moveToData() {
    var geoPosition = data
        .map(getElementGeoPosition)
        .firstWhere((geoPosition) => geoPosition != null, orElse: () => null);
    if (geoPosition?.latitude != null && geoPosition?.longitude != null) {
      center = LatLng(geoPosition.latitude, geoPosition.longitude);

      mapController.move(center, mapController.zoom);
    }
  }
}

class GeoMapPage extends StatefulWidget {
  GeoMapPage({
    Key key,
    @required this.title,
    @required this.geoMap,
    @required this.uiContext,
  }) : super(key: key);

  final String title;
  final GeoMap geoMap;
  final UiContext uiContext;

  @override
  _GeoMapPageState createState() => _GeoMapPageState();
}

class _GeoMapPageState extends State<GeoMapPage> {
  GeoMapController _geoMapController;
  bool _fullScreen = false;

  @override
  void initState() {
    super.initState();

    _geoMapController = GeoMapController(
      geoMap: widget.geoMap,
      uiContext: widget.uiContext,
      center: widget.geoMap.center?.latitude != null &&
              widget.geoMap.center?.longitude != null
          ? LatLng(
              widget.geoMap.center.latitude, widget.geoMap.center.longitude)
          : null,
      visibleLayers:
          List.filled(widget.geoMap.layers.length, true, growable: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _fullScreen
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
            if (_fullScreen)
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
    widget.geoMap.layers.asMap().forEach((index, layer) => layerItems.add(
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
        if (value == 'fullScreen') {
          setState(() {
            _fullScreen = !_fullScreen;
          });
        } else if (value == 'goToData') {
          setState(() {
            _geoMapController.moveToData();
          });
        } else if (value is int) {
          setState(() {
            _geoMapController.visibleLayers[value] =
                !_geoMapController.visibleLayers[value];
          });
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          key: Key('map-menu-fullScreen'),
          value: 'fullScreen',
          child: IconTextPopupMenuItemWidget(
            icon: _fullScreen ? Icons.exit_to_app : Icons.fullscreen,
            text: _fullScreen ? 'Exit full screen' : 'Enter full screen',
          ),
          //checked: _fullScreen,
        ),
        PopupMenuItem<String>(
          key: Key('map-menu-goToData'),
          value: 'goToData',
          child: IconTextPopupMenuItemWidget(
            icon: Icons.list,
            text: 'Go to data',
          ),
          //checked: _fullScreen,
        ),
        if (layerItems.isNotEmpty) PopupMenuDivider(),
        ...layerItems,
      ],
      padding: EdgeInsets.zero,
      icon: icon,
    );
  }
}

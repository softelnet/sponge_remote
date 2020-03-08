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
    @required this.geoMap,
    @required this.configuration,
    @required this.uiContext,
    bool clusterMarkers = true,
  })  : assert(clusterMarkers != null),
        clusterMarkers = clusterMarkers,
        super(key: key);

  final GeoMap geoMap;
  final GeoMapConfiguration configuration;
  final UiContext uiContext;
  final bool clusterMarkers;

  @override
  _GeoMapWidgetState createState() => _GeoMapWidgetState();
}

class _GeoMapWidgetState extends State<GeoMapWidget> {
  final _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    var service = ApplicationProvider.of(context).service;

    List<TileLayerOptions> baseLayers = widget.geoMap.layers
            ?.where((layer) => layer.urlTemplate != null)
            ?.map((layer) => TileLayerOptions(
                  urlTemplate: layer.urlTemplate,
                  additionalOptions: layer.options,
                  subdomains: layer.subdomains ?? [],
                ))
            ?.toList() ??
        [];

    List<Marker> markers = (widget.uiContext.value as List)
            ?.whereType<AnnotatedValue>()
            ?.map((element) {
              // TODO Convert JSON Map to GeoPosition in a lower layer.
              var geoPosition =
                  GeoPosition.fromJson(element.features[Features.GEO_POSITION]);
              if (geoPosition?.latitude == null ||
                  geoPosition?.longitude == null) {
                return null;
              }

              var iconData =
                  getIconData(service, element.features[Features.ICON]) ??
                      MdiIcons.marker;
              var iconColor =
                  string2color(element.features[Features.ICON_COLOR]);
              var iconWidth =
                  (element.features[Features.ICON_WIDTH] as num)?.toDouble();
              var icon = Icon(iconData, color: iconColor, size: iconWidth);
              var label = element.valueLabel;

              return Marker(
                width: iconWidth ?? 30.0,
                height: (element.features[Features.ICON_HEIGHT] as num)
                        .toDouble() ??
                    30.0,
                point: LatLng(geoPosition.latitude, geoPosition.longitude),
                builder: (ctx) => label != null
                    ? Tooltip(
                        message: label,
                        child: Container(child: icon),
                      )
                    : icon,
              );
            })
            ?.where((marker) => marker != null)
            ?.toList() ??
        [];

    var attribution = widget.geoMap.features[Features.GEO_ATTRIBUTION];

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            center: widget.geoMap?.center != null
                ? LatLng(widget.geoMap.center.latitude,
                    widget.geoMap.center.longitude)
                : null,
            zoom: widget.geoMap?.zoom ?? 13,
            minZoom: widget.geoMap?.minZoom,
            maxZoom: widget.geoMap?.maxZoom,
            // The CRS is currently ignored.
            //debug: true,
            plugins: [
              UserLocationPlugin(),
              if (widget.clusterMarkers) MarkerClusterPlugin(),
            ],
          ),
          layers: [
            ...baseLayers,
            if (!widget.clusterMarkers)
              MarkerLayerOptions(
                markers: markers,
              ),
            if (widget.clusterMarkers)
              MarkerClusterLayerOptions(
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
              ),
            UserLocationOptions(
              context: context,
              mapController: _mapController,
              markers: markers,
              zoomToCurrentLocationOnLoad: false,
              updateMapLocationOnPositionChange: false,
              moveToCurrentLocationFloatingActionButton:
                  _buildMoveToCurrentLocationFloatingActionButton(),
              fabBottom: widget.configuration.fabMargin,
              fabRight: widget.configuration.fabMargin,
              fabWidth: widget.configuration.fabSize,
              fabHeight: widget.configuration.fabSize,
            ),
          ],
          mapController: _mapController,
        ),
        if (attribution != null)
          Container(
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
          ),
      ],
    );
  }

  Widget _buildMoveToCurrentLocationFloatingActionButton() => Opacity(
      opacity: widget.configuration.fabOpacity,
      child: FloatingActionButton(
        heroTag: 'fabMoveToCurrentLocation',
        onPressed: null,
        child: Icon(Icons.my_location),
        backgroundColor: getFloatingButtonBackgroudColor(context),
      ));
}

class GeoMapConfiguration {
  GeoMapConfiguration({
    this.fabOpacity = 0.85,
    this.fabSize = 50,
    this.fabMargin = 10,
  });

  final double fabOpacity;
  final double fabSize;
  final double fabMargin;
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
  final _configuration = GeoMapConfiguration();
  bool _fullScreen = false;

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
              geoMap: widget.geoMap,
              configuration: _configuration,
              uiContext: widget.uiContext,
            ),
            if (_fullScreen)
              Container(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.only(
                    right: _configuration.fabMargin,
                    top: _configuration.fabMargin,
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
        opacity: _configuration.fabOpacity,
        child: SizedBox(
          child: FloatingActionButton(
            heroTag: 'fabMenu',
            onPressed: null,
            child: Icon(getPopupMenuIconData(context)),
            backgroundColor: getFloatingButtonBackgroudColor(context),
          ),
          width: _configuration.fabSize,
          height: _configuration.fabSize,
        ),
      );

  Widget _buildMenu(BuildContext context, {Widget icon}) =>
      PopupMenuButton<String>(
        key: Key('map-menu'),
        onSelected: (value) {
          if (value == 'fullScreen') {
            setState(() {
              _fullScreen = !_fullScreen;
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
        ],
        padding: EdgeInsets.zero,
        icon: icon,
      );
}

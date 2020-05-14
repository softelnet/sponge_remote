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
import 'package:sponge_flutter_api/sponge_flutter_api.dart';
import 'package:sponge_remote_mobile/src/geo_map_controller.dart';
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

  UiContext get uiContext => widget.geoMapController.uiContext;

  bool get clusterMarkers => widget.geoMapController.enableClusterMarkers;

  /// The map controller must be associated with the widget state.
  MapController _mapController;

  @override
  void initState() {
    super.initState();

    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    var service = ApplicationProvider.of(context).service;

    // Bind the map controller associated with the state for each GeoMapController instance.
    widget.geoMapController.bindMapController(_mapController);

    try {
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
    } catch (e) {
      return Center(
        child: NotificationPanelWidget(
          notification: e,
          type: NotificationPanelType.error,
        ),
      );
    }
  }

  MapOptions _createMapOptions() {
    return MapOptions(
      center: widget.geoMapController.initialCenter,
      zoom: widget.geoMapController.initialZoom,
      minZoom: widget.geoMapController.minZoom,
      maxZoom: widget.geoMapController.maxZoom,
      crs: GeoMapController.createCrs(widget.geoMapController.crs) ??
          const Epsg3857(),
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
      size: const Size(40, 40),
      fitBoundsOptions: FitBoundsOptions(
        padding: const EdgeInsets.all(50),
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
              widget.onRefresh ?? () => setState(() {}),
              icon: widget.geoMapController.buildMenuIcon(context),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void deactivate() {
    if (widget.geoMapController.onMapClose != null) {
      widget.geoMapController.onMapClose(widget.geoMapController);
    }

    super.deactivate();
  }
}

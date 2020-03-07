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
import 'package:latlong/latlong.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:sponge_client_dart/sponge_client_dart.dart';
import 'package:sponge_flutter_api/sponge_flutter_api.dart';

class GeoMapWidget extends StatefulWidget {
  GeoMapWidget({
    Key key,
    @required this.geoMap,
    @required this.uiContext,
  }) : super(key: key);

  final GeoMap geoMap;
  final UiContext uiContext;

  @override
  _GeoMapWidgetState createState() => _GeoMapWidgetState();
}

class _GeoMapWidgetState extends State<GeoMapWidget> {
  @override
  Widget build(BuildContext context) {
    var service = ApplicationProvider.of(context).service;

    List<TileLayerOptions> baseLayers = widget.geoMap.layers
            ?.where((layer) => layer.urlTemplate != null)
            ?.map((layer) => TileLayerOptions(
                  urlTemplate: layer.urlTemplate,
                  additionalOptions: layer.options,
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
            debug: true,
          ),
          layers: [
            ...baseLayers,
            MarkerLayerOptions(
              markers: markers,
            ),
          ],
        ),
        if (attribution != null)
          Container(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Opacity(
                opacity: 0.75,
                child: Text(
                  attribution.toString(),
                  style: TextStyle(
                    color: Colors.black,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: GeoMapWidget(
        geoMap: widget.geoMap,
        uiContext: widget.uiContext,
      ),
    );
  }
}

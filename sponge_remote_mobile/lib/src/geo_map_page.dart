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
import 'package:sponge_remote_mobile/src/geo_map_controller.dart';
import 'package:sponge_remote_mobile/src/geo_map_widget.dart';

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

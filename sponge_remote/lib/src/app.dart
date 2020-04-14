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
//import 'package:fluro/fluro.dart';
import 'package:provider/provider.dart';
import 'package:sponge_flutter_api/sponge_flutter_api.dart';
import 'package:sponge_remote/src/application_constants.dart';

class SpongeRemoteApp extends StatelessWidget {
  SpongeRemoteApp({
    @required this.service,
    @required this.widgetsFactory,
  });

  final FlutterApplicationService service;
  final SpongeWidgetsFactory widgetsFactory;

  @override
  Widget build(BuildContext context) {
    //var router = Router();
    //configureRoutes(router);

    return FutureBuilder<FlutterApplicationService>(
      future: Future(() async {
        await service.init();
        return service;
      }),
      builder: (BuildContext context,
          AsyncSnapshot<FlutterApplicationService> snapshot) {
        if (snapshot.hasData) {
          var service = snapshot.data;

          return ApplicationProvider(
            service: service,
            child: Provider<SpongeWidgetsFactory>(
              create: (_) => widgetsFactory,
              child: Builder(
                builder: (BuildContext context) {
                  service.bindMainBuildContext(context);

                  return Consumer<ApplicationStateNotifier>(
                    builder: (BuildContext context,
                        ApplicationStateNotifier value, Widget child) {
                      return MaterialApp(
                        title: APPLICATION_NAME,
                        theme: ThemeData(
                          brightness: service.settings.isDarkMode
                              ? Brightness.dark
                              : Brightness.light,
                          primarySwatch: Colors.teal,
                          floatingActionButtonTheme:
                              FloatingActionButtonThemeData(
                            backgroundColor:
                                getFloatingButtonBackgroudColor(context),
                          ),
                        ),
                        initialRoute: DefaultRoutes.ACTIONS,
                        routes: widgetsFactory.createRoutes(),
                        //onGenerateRoute: router.generator,
                        debugShowCheckedModeBanner: false,
                      );
                    },
                  );
                },
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return _buildUninitializedApp(
            child: Center(
              child: NotificationPanelWidget(
                message: snapshot.error,
                type: NotificationPanelType.error,
              ),
            ),
          );
        }

        return _buildUninitializedApp(
          child: Container(color: Colors.teal),
        );
      },
    );
  }

  Widget _buildUninitializedApp({@required Widget child}) {
    return MaterialApp(
      title: APPLICATION_NAME,
      home: child,
      debugShowCheckedModeBanner: false,
    );
  }
}

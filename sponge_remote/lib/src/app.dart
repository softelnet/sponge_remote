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
import 'package:provider/provider.dart';
import 'package:sponge_flutter_api/sponge_flutter_api.dart';
import 'package:sponge_remote/src/application_constants.dart';

class SpongeRemoteApp extends StatelessWidget {
  SpongeRemoteApp({
    @required this.service,
    @required this.guiFactory,
  });

  final FlutterApplicationService service;
  final SpongeGuiFactory guiFactory;

  @override
  Widget build(BuildContext context) {
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
            child: Provider<SpongeGuiFactory>(
              create: (_) => guiFactory,
              child: Builder(
                builder: (BuildContext context) {
                  service.bindMainBuildContext(context);

                  return Consumer<ApplicationStateNotifier>(
                    builder: (BuildContext context,
                        ApplicationStateNotifier value, Widget child) {
                      return MaterialApp(
                        title: APPLICATION_NAME,
                        theme: ThemeData(
                          brightness:
                              service.settings.themeMode == ThemeMode.dark
                                  ? Brightness.dark
                                  : null,
                          primarySwatch: Colors.teal,
                          floatingActionButtonTheme:
                              FloatingActionButtonThemeData(
                            backgroundColor:
                                getFloatingButtonBackgroudColor(context),
                          ),
                        ),
                        darkTheme: ThemeData(
                          brightness: Brightness.dark,
                          primarySwatch: Colors.teal,
                          floatingActionButtonTheme:
                              FloatingActionButtonThemeData(
                            backgroundColor:
                                getFloatingButtonBackgroudColor(context),
                          ),
                        ),
                        themeMode: service.settings.themeMode,
                        initialRoute: DefaultRoutes.ACTIONS,
                        routes: guiFactory.createRoutes(),
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
                notification: snapshot.error,
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

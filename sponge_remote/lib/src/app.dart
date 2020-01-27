import 'package:flutter/material.dart';
//import 'package:fluro/fluro.dart';
import 'package:provider/provider.dart';
import 'package:sponge_flutter_api/sponge_flutter_api.dart';
import 'package:sponge_remote/src/application_constants.dart';

class SpongeFlutterApp extends StatelessWidget {
  SpongeFlutterApp({
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
          return _buildApp(Center(
              child: ErrorPanelWidget(
            error: snapshot.error,
          )));
        }

        return _buildApp(
          Container(
            color: Colors.teal,
          ),
        );
      },
    );
  }

  Widget _buildApp(Widget child) {
    return MaterialApp(
      title: APPLICATION_NAME,
      // theme: ThemeData(
      //   brightness:
      //       service.settings.isDarkMode ? Brightness.dark : Brightness.light,
      //   primarySwatch: Colors.teal,
      // ),
      //initialRoute: DefaultRoutes.ACTIONS,
      //routes: widgetsFactory.createRoutes(),
      //onGenerateRoute: router.generator,
      home: child,
      debugShowCheckedModeBanner: false,
    );
  }
}

// Copyright 2021 The Sponge authors.
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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:sponge_client_dart/sponge_client_dart.dart';
import 'package:sponge_flutter_api/sponge_flutter_api.dart';
import 'package:sponge_remote/src/application_constants.dart';

// TODO [Entrypoint] ActionCallApp. Is this entrypoint necessary?
class ActionCallApp extends StatelessWidget {
  ActionCallApp({
    @required this.service,
    @required this.actionName,
    Map<String, dynamic> args,
  }) : args = args ?? {};

  final FlutterApplicationService service;
  final String actionName;
  final Map<String, dynamic> args;

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
              create: (_) =>
                  SpongeGuiFactory(), // TODO Action call GUI factory.
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
                        home: ActionCallHome(),
                        debugShowCheckedModeBanner: false,
                        builder: (BuildContext context, Widget widget) {
                          ErrorWidget.builder =
                              _createErrorWidgetBuilder(widget);
                          return widget;
                        },
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

  ErrorWidgetBuilder _createErrorWidgetBuilder(Widget widget) {
    return (FlutterErrorDetails errorDetails) =>
        ErrorCircleWidget(error: errorDetails.exception);
  }
}

class ActionCallHomeViewModel extends BaseViewModel {}

abstract class ActionCallHomeView extends BaseView {}

class ActionCallHomePresenter
    extends BasePresenter<ActionCallHomeViewModel, ActionCallHomeView> {
  ActionCallHomePresenter(ApplicationService service, ActionCallHomeView view)
      : super(service, ActionCallHomeViewModel(), view);

  Future<List<ActionData>> getActions() async {
    List<ActionData> actionDataList = (await service.spongeService.getActions())
        .where((actionData) => actionData.isVisible)
        // Filter out actions with handled intents.
        .where((actionData) =>
            service.spongeService
                ?.isActionAllowedByIntent(actionData.actionMeta) ??
            true)
        // Filter out unsupported actions.
        .where((actionData) =>
            service.spongeService?.isActionSupported(actionData.actionMeta) ??
            true)
        .toList();

    // Sort actions.
    if (service.settings.actionsOrder == ActionsOrder.alphabetical) {
      actionDataList.sort((a1, a2) =>
          ModelUtils.getQualifiedActionDisplayLabel(a1.actionMeta).compareTo(
              ModelUtils.getQualifiedActionDisplayLabel(a2.actionMeta)));
    }
    return actionDataList;
  }
}

class ActionCallHome extends StatefulWidget {
  final String actionName;

  ActionCallHome({
    @required this.actionName,
  });
  @override
  _ActionCallHomeState createState() => _ActionCallHomeState();
}

class _ActionCallHomeState extends State<ActionCallHome>
    implements ActionCallHomeView {
  ActionCallHomePresenter _presenter;

  @override
  Widget build(BuildContext context) {
    var service = ApplicationProvider.of(context).service;
    _presenter ??= ActionCallHomePresenter(service, this);
    service.bindMainBuildContext(context);

    return BlocBuilder<ForwardingBloc<SpongeConnectionState>,
        SpongeConnectionState>(
      bloc: service.connectionBloc,
      builder: (BuildContext context, SpongeConnectionState state) {
        if (state is SpongeConnectionStateNotConnected) {
          return _buildScaffold(
            context,
            child: Center(
              child: _buildErrorWidget('Not connected'),
            ),
          );
        } else if (state is SpongeConnectionStateConnecting) {
          return _buildScaffold(
            context,
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (state is SpongeConnectionStateError) {
          return _buildScaffold(
            context,
            child: Center(
              child: _buildErrorWidget(state.error),
            ),
          );
        } else {
          return _buildMainWidget(context);
        }
      },
    );
  }

  Scaffold _buildScaffold(
    BuildContext context, {
    @required Widget child,
  }) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TODO Title'),
      ),
      body: SafeArea(
        child: ModalProgressHUD(
          child: child,
          inAsyncCall: false, // TODO _presenter.busy,
        ),
      ),
    );
  }

  Widget _buildMainWidget(BuildContext context) {
    return FutureBuilder<ActionData>(
      future: _presenter.service.spongeService.getAction(widget
          .actionName), //_busyNoConnection ? Future(() => []) : _getActionGroups(),
      builder: (context, snapshot) {
        return ActionCallPage(
          actionData: snapshot.data,
          bloc: _presenter.service.spongeService
              .getActionCallBloc(snapshot.data.actionMeta.name),
        );
      },
    );
  }

  Widget _buildErrorWidget(dynamic error) {
    // if (error is UsernamePasswordNotSetException /*||
    //     error is InvalidUsernamePasswordException*/) {
    //   return LoginRequiredWidget(connectionName: _presenter.connectionName);
    // } else {
    return NotificationPanelWidget(
      notification: error,
      type: NotificationPanelType.error,
    );
    // }
  }
}

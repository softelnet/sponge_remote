// Copyright 2018 The Sponge authors.
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

//import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

/// This integration tests require sponge-app-demo-service/DemoServiceMain
/// running on a host (10.0.2.2, see https://developer.android.com/studio/run/emulator-networking).
/// The tests should be run in an Android emulator on that host (verified on Pixel 3 API 29 emulator).
void main() {
  const String testHost = '10.0.2.2';
  const String TEST_SERVICE = 'My Sponge service';

  var startDelay = Duration(seconds: 2);

  group('app test', () {
    FlutterDriver driver;

    SerializableFinder findActionListElement(String actionName) =>
        find.byValueKey('action-$actionName');

    Future<SerializableFinder> openAction(
      String name, {
      String group = 'Basic',
      bool refresh = true,
      double dyScroll = -100,
    }) async {
      await driver.tap(find.byValueKey('connections'));
      await driver.tap(find.byValueKey('connection-$TEST_SERVICE'));

      await driver.waitFor(find.text('$TEST_SERVICE'));
      var refreshButton = find.byType('FloatingActionButton');
      await driver.waitFor(refreshButton);

      if (refresh) {
        await driver.tap(refreshButton);
        await driver.waitFor(refreshButton);
      }

      await driver.scrollUntilVisible(
          find.byType('TabBar'), find.byValueKey('group-$group'),
          dxScroll: 5);

      await driver.tap(find.byValueKey('group-$group'));

      var action = findActionListElement(name);
      if (dyScroll != 0) {
        await driver.scrollUntilVisible(find.byType('ListView'), action,
            dyScroll: dyScroll);
      }
      await driver.tap(action);

      return action;
    }

    SerializableFinder findByValueKeyAsType(String name) =>
        find.byValueKey('value-$name');

    SerializableFinder findTextWidget(
      SerializableFinder rootFinder, {
      SerializableFinder matching,
    }) =>
        find.descendant(
            of: rootFinder,
            matching: matching ?? find.byType('Text'),
            matchRoot: true);

    Future<SerializableFinder> chooseProvidedValueFromSet(
        String arg, String value) async {
      var argFinder = findByValueKeyAsType(arg);
      await driver.tap(argFinder);
      await driver.tap(find.text(value));

      return argFinder;
    }

    SerializableFinder findTextValueWidget(String arg) {
      return findTextWidget(findByValueKeyAsType(arg),
          matching: find.byValueKey('value'));
    }

    Future<SerializableFinder> findArg(String arg, {Duration timeout}) async {
      var parentFinder = find.byType('ListView');
      var argFinder = findByValueKeyAsType(arg);
      await driver.scrollUntilVisible(parentFinder, argFinder, dyScroll: -20);

      return argFinder;
    }

    Future<SerializableFinder> findWidget(SerializableFinder finder,
        {Duration timeout}) async {
      var parentFinder = find.byType('ListView');
      await driver.scrollUntilVisible(parentFinder, finder, dyScroll: -20);

      return finder;
    }

    Future<SerializableFinder> tapArg(String arg, {Duration timeout}) async {
      var argFinder = await findArg(arg, timeout: timeout);
      await driver.tap(argFinder, timeout: timeout);
      return argFinder;
    }

    Future<SerializableFinder> enterArgValue(String arg, String value,
        {Duration timeout}) async {
      var argFinder = await tapArg(arg, timeout: timeout);
      await driver.enterText(value, timeout: timeout);

      return argFinder;
    }

    SerializableFinder findListElement(String listName, int index) =>
        find.descendant(
            of: findByValueKeyAsType(listName),
            matching: find.byValueKey('list-element-$index'));

    Future<void> drawDoodle(String label) async {
      await driver.tap(find.text(label));
      var painterFinder = find.byType('PainterPanel');
      var bottomRight = await driver.getBottomRight(painterFinder);
      var topLeft = await driver.getTopLeft(painterFinder);

      var dx = bottomRight.dx - topLeft.dx;
      var dy = bottomRight.dy - topLeft.dy;

      await driver.tap(painterFinder);
      var duration = Duration(milliseconds: 500);
      await driver.scroll(painterFinder, -dx / 2, -dy / 2, duration);
      await driver.scroll(painterFinder, dx, 0, duration);
      await driver.scroll(painterFinder, 0, dy, duration);
      await driver.tap(find.pageBack());
    }

    Future<void> waitForResult(
      String label,
      String value, {
      Duration timeout,
    }) async {
      await driver.waitFor(find.text('$label: $value'), timeout: timeout);
    }

    Future<void> waitForAbsentResult(
      String label,
      String value, {
      Duration timeout,
    }) async {
      await driver.waitForAbsent(find.text('$label: $value'), timeout: timeout);
    }

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async => await driver?.close());

    group('Connections', () {
      test('create test connection', () async {
        await Future.delayed(startDelay);

        var activate = find.byValueKey('tapToActivateConnection');
        await driver.waitFor(activate);
        await driver.tap(activate);

        await driver.tap(find.byType('FloatingActionButton'));

        await driver.tap(find.byValueKey('name'));
        await driver.enterText(TEST_SERVICE);

        await driver.tap(find.byValueKey('address'));
        await driver.enterText('http://$testHost:8888');

        await driver.tap(find.byValueKey('anonymous'));

        await Future.delayed(startDelay);
        await driver.tap(find.byValueKey('username'));
        await driver.enterText('admin');
        await driver.tap(find.byValueKey('password'));
        await driver.enterText('password');

        await driver.tap(find.text('OK'));

        await driver.tap(find.text(TEST_SERVICE));
      });
    });

    group('Actions/Start', () {
      test('call Depending arguments (DependingArgumentsAction)', () async {
        await openAction('DependingArgumentsAction', group: 'Start');

        var continent = 'Africa';
        var country = 'Nigeria';
        var city = 'Lagos';
        var river = 'Niger';
        var weather = 'Sunny';

        await chooseProvidedValueFromSet('continent', continent);
        await chooseProvidedValueFromSet('country', country);
        await chooseProvidedValueFromSet('city', city);
        await chooseProvidedValueFromSet('river', river);
        await chooseProvidedValueFromSet('weather', weather);

        await driver.tap(find.text('RUN'));
        await waitForResult('Sentences',
            'There is a city $city in $country in $continent. The river $river flows in $continent. It\'s ${weather.toLowerCase()}.');
      });

      test(
          'call Depending arguments (DependingArgumentsAction) - change selection',
          () async {
        await openAction('DependingArgumentsAction', group: 'Start');

        var continent = 'Africa';
        var country = 'Nigeria';
        var city = 'Lagos';
        var river = 'Niger';
        var weather = 'Sunny';

        // The temporary selecttion.
        await chooseProvidedValueFromSet('continent', 'Europe');
        await chooseProvidedValueFromSet('country', 'Turkey');
        await chooseProvidedValueFromSet('city', 'Istanbul');
        await chooseProvidedValueFromSet('river', 'Danube');
        await chooseProvidedValueFromSet('weather', weather);

        // The actual selection.
        await chooseProvidedValueFromSet('continent', continent);
        await chooseProvidedValueFromSet('country', country);
        await chooseProvidedValueFromSet('city', city);
        await chooseProvidedValueFromSet('river', river);

        await driver.tap(find.text('RUN'));
        await waitForResult('Sentences',
            'There is a city $city in $country in $continent. The river $river flows in $continent. It\'s ${weather.toLowerCase()}.');
      });

      test('call Depending arguments (DependingArgumentsAction) - clear',
          () async {
        await openAction('DependingArgumentsAction', group: 'Start');

        var continent = 'Africa';
        var country = 'Nigeria';
        var city = 'Lagos';
        var river = 'Niger';
        var weather = 'Sunny';

        await chooseProvidedValueFromSet('continent', continent);
        await chooseProvidedValueFromSet('country', country);
        await chooseProvidedValueFromSet('city', city);
        await chooseProvidedValueFromSet('river', river);
        await chooseProvidedValueFromSet('weather', weather);

        await driver.waitFor(find.text(continent));
        await driver.waitFor(find.text(country));
        await driver.waitFor(find.text(city));
        await driver.waitFor(find.text(river));
        await driver.waitFor(find.text(weather));

        await driver.tap(find.text('CLEAR'));

        await driver.tap(find.text('CANCEL'));
      });

      test('call Draw a doodle (DrawDoodle) - clear', () async {
        await openAction('DrawDoodle', group: 'Start');
        await drawDoodle('DRAW DOODLE *');

        await driver.tap(find.text('CLEAR'));
        await driver.waitForAbsent(find.byType('Image'));

        await driver.tap(find.text('CANCEL'));
      });

      // TODO Hangs.
      // test('call Draw a doodle (DrawDoodle)', () async {
      //   await openAction('DrawDoodle', group: 'Start');
      //   await drawDoodle('DRAW DOODLE *');

      //   await driver.waitFor(find.byType('Image'));

      //   await driver.tap(find.text('OK'));
      //   // TODO Hangs.
      //   await waitForResult('Result', 'Success',
      //       timeout: Duration(seconds: 120));
      // });

      test('call Geo map (ActionWithGeoMap)', () async {
        await openAction('ActionWithGeoMap', group: 'Start');

        await driver.waitFor(find.byType('FlutterMap'));

        await driver.tap(find.byValueKey('map-menu'));
        await driver.tap(find.text('Cluster data markers'));

        await driver.tap(find.byValueKey('map-element-0'));
        await driver.tap(find.text('View the location'));

        await driver.tap(find.text('CLOSE'));

        await driver.tap(find.pageBack());
      });

      test('call Hello world (HelloWorldAction)', () async {
        await openAction('HelloWorldAction', group: 'Start');
        var name = 'Sponge user';
        await enterArgValue('name', name);

        await driver.tap(find.text('RUN'));
        await waitForResult('Greeting', 'Hello World! Hello $name!');
      });
    });

    group('Actions/Basic', () {
      test(
          'call Action returning a dynamic result (DynamicResultAction) - string arg',
          () async {
        await openAction('DynamicResultAction');

        await driver.tap(find.byType('ProvidedValueSetEditorWidget'));
        await driver.tap(find.text('string'));

        await driver.tap(find.text('RUN'));
        await waitForResult('Result', 'text');
      });
      test(
          'call Action returning a dynamic result (DynamicResultAction) - boolean arg',
          () async {
        await openAction('DynamicResultAction');

        await driver.tap(find.byType('ProvidedValueSetEditorWidget'));
        await driver.tap(find.text('boolean'));

        await driver.tap(find.text('RUN'));
        await waitForResult('Result', 'true');
      });

      test(
          'call Action returning a dynamic result (DynamicResultAction) - clear',
          () async {
        await openAction('DynamicResultAction');

        await driver.tap(find.byType('ProvidedValueSetEditorWidget'));
        await driver.tap(find.text('boolean'));

        await driver.tap(find.text('CLEAR'));
        await driver.tap(find.text('RUN'));

        // RUN unsuccessful.
        await driver.waitFor(find.text('RUN'));

        await driver.tap(find.text('CANCEL'));
      });

      test('call Action with a pageable list (ActionWithPageableList)',
          () async {
        var actionName = 'ActionWithPageableList';
        var selected = 5;

        await openAction(actionName);

        await driver.waitFor(find.descendant(
            of: find.byValueKey('list-element-$selected'),
            matching: find.byType('Icon')));

        // TODO Scroll to the last element.
        // var pageableListFinder = find.descendant(
        //     of: find.byType('ListBody'),
        //     matching: find.byType(
        //         'ListView')); //find.byValueKey('$TEST_SERVICE-$actionName-args-list-standard'));
        // for (int i = selected + 1; i < 25; i++) {
        //   print(i);
        //   await driver.scrollUntilVisible(
        //       pageableListFinder, find.byValueKey('list-element-$i'),
        //       dyScroll: -20);
        // }

        await driver.tap(find.pageBack());
      });

      test(
          'call Action with a provided, dynamic argument (DynamicProvidedArgAction)',
          () async {
        await openAction('DynamicProvidedArgAction');

        await driver.waitFor(find.text('Dynamic argument *'));
        await driver.waitFor(find.text('James'));
        await driver.waitFor(find.text('Joyce'));

        await driver.tap(find.text('RUN'));
        await waitForResult('Dynamic type', 'RECORD');
      });

      test(
          'call Action with active/inactive context actions (ContextActionsActiveInactive)',
          () async {
        await openAction('ContextActionsActiveInactive');

        // Activate.
        await tapArg('active');

        var subActionsFinder = find.byType('SubActionsWidget');

        // Context action 1 - enabled.
        await driver.tap(subActionsFinder);
        await driver.tap(find.text('Active/inactive context action'));

        await tapArg('active');

        // // Context action 1 - disabled.
        await driver.tap(subActionsFinder);
        try {
          await driver.tap(find.text('Active/inactive context action'),
              timeout: Duration(seconds: 5));
          fail('Exception expected');
        } catch (e) {
          // Ignore.
        }

        await driver.tap(find.text('Context action 2'));

        await driver.tap(find.pageBack());
      });

      test('call Action with an obscured text argument (ObscuredTextArgAction)',
          () async {
        await openAction('ObscuredTextArgAction');

        await enterArgValue('plainText', 'Abc');
        await enterArgValue('obscuredText', 'Abc');

        await driver.waitFor(find.text('Abc'));

        await driver.tap(find.text('RUN'));
        await waitForResult('Obscured text', '***');
      });

      test(
          'call Action with annotated arg with default (AnnotatedWithDefaultValue)',
          () async {
        await openAction('AnnotatedWithDefaultValue');
        await driver.tap(find.text('RUN'));
        await waitForResult('Result', 'Value');

        await openAction('AnnotatedWithDefaultValue');
        var arg1Value = 'NEW VALUE';
        await enterArgValue('annotated', arg1Value);
        await driver.tap(find.text('RUN'));

        await waitForResult('Result', arg1Value);
      });

      test('call Action with context actions (ActionWithContextActions)',
          () async {
        await openAction('ActionWithContextActions');

        var arg1 = 'A1';
        var arg2 = 'A2';

        await enterArgValue('arg1', arg1);
        await enterArgValue('arg2', arg2);

        var subActionsFinder = find.byType('SubActionsWidget');

        // Context action 1.
        await driver.tap(subActionsFinder);
        await driver.tap(find.text('Context action 1'));
        await waitForResult('Result', arg1);
        await driver.tap(find.text('CLOSE'));

        // Context action 2.
        await driver.tap(subActionsFinder);
        await driver.tap(find.text('Context action 2'));
        var additionalText2 = 'Additional 2';
        await enterArgValue('additionalText', additionalText2);
        await driver.tap(find.text('RUN'));
        await waitForResult('Result', '$arg2 $additionalText2');
        await driver.tap(find.text('CLOSE'));

        // Context action 3.
        await driver.tap(subActionsFinder);
        await driver.tap(find.text('Context action 3'));
        var arg31 = 'A3/1';
        var additionalText3 = 'Additional 3';
        await enterArgValue('arg1', arg31);
        await enterArgValue('additionalText', additionalText3);
        await driver.tap(find.text('RUN'));
        await waitForResult('Result', '$arg31 $arg2 $additionalText3');
        await driver.tap(find.text('CLOSE'));

        // Context action 4.
        await driver.tap(subActionsFinder);
        await driver.tap(find.text('Context action 4'));
        var arg42 = 'A4/2';
        await enterArgValue('arg2', arg42);
        await driver.tap(find.text('RUN'));
        await waitForResult('Result', '$arg1 $arg42');
        await driver.tap(find.text('CLOSE'));

        // Context action 5.
        await driver.tap(subActionsFinder);
        await driver.tap(find.text('Context action 5'));
        var additionalText5 = 'Additional 5';
        await enterArgValue('additionalText', additionalText5);
        await driver.tap(find.text('RUN'));
        await waitForResult('Result', '$arg1 $additionalText5');
        await driver.tap(find.text('CLOSE'));

        // Context action 6.
        await driver.tap(subActionsFinder);
        await driver.tap(find.text('Context action 6'));
        await driver.tap(find.text('RUN'));

        // Context action - Markdown text.
        await driver.tap(subActionsFinder);
        await driver.tap(find.text('Markdown text'));
        await driver.tap(find.text('CLOSE'));

        // Run the main action.
        await driver.tap(find.text('RUN'));
        await waitForResult('Result', 'Success');
      });

      test(
          'call Action with provided arguments (ProvideByAction) - arg3 is null',
          () async {
        await openAction('ProvideByAction');

        var arg1 = 'value2';
        await chooseProvidedValueFromSet('valueLimited', arg1);
        await driver.tap(find.byType('TextField'));
        var arg2 = 'Not limited value';
        await driver.enterText(arg2);

        await driver.tap(find.text('RUN'));
        await waitForResult('Values', '$arg1/$arg2/None');
      });
      test(
          'call Action with provided arguments (ProvideByAction) - arg3 is not null',
          () async {
        await openAction('ProvideByAction');

        var arg1 = 'value2';
        await chooseProvidedValueFromSet('valueLimited', arg1);
        await driver.tap(find.byType('TextField'));
        var arg2 = 'Not limited value';
        await driver.enterText(arg2);
        var arg3 = 'value3';
        await chooseProvidedValueFromSet('valueLimitedNullable', arg3);

        await driver.tap(find.text('RUN'));
        await waitForResult('Values', '$arg1/$arg2/$arg3');
      });

      test(
          'call Action with provided arguments (ProvideByAction) - arg2 is chosen',
          () async {
        await openAction('ProvideByAction');

        var arg1 = 'value1';
        await chooseProvidedValueFromSet('valueLimited', arg1);
        await driver.tap(find.byValueKey('popup-value-valueNotLimited'));
        var arg2 = 'value2';
        await driver.tap(find.text(arg2));

        await driver.tap(find.text('RUN'));
        await waitForResult('Values', '$arg1/$arg2/None');
      });

      test(
          'call Asynchronous provided argument (AsynchronousProvidedActionArg)',
          () async {
        await openAction('AsynchronousProvidedActionArg');

        await driver.waitFor(find.text('Asynchronous provided argument'));

        await driver.waitFor(find.text('Argument 1 *'));
        await driver.waitFor(find.text('Argument 2 *'));

        var arg1Finder = findTextValueWidget('arg1');
        await driver.waitFor(arg1Finder, timeout: Duration(seconds: 60));
        var arg1Value =
            await driver.getText(arg1Finder, timeout: Duration(seconds: 60));
        expect(arg1Value, startsWith('v'));

        var arg2Finder = findTextValueWidget('arg2');
        await driver.waitFor(arg2Finder, timeout: Duration(seconds: 60));
        var arg2Value = await driver.getText(arg2Finder);
        expect(arg2Value, equals('First arg is $arg1Value'));
        await driver.tap(find.text('CLOSE'));
      });

      test('call Choose a color (ChooseColor) - red', () async {
        await openAction('ChooseColor');

        await driver.tap(find.text('PICK COLOR'));
        var pickerFinder = find.byType('ColorPicker');

        var bottomRight = await driver.getBottomRight(pickerFinder);
        var topLeft = await driver.getTopLeft(pickerFinder);

        var dx = bottomRight.dx - topLeft.dx;
        var dy = bottomRight.dy - topLeft.dy;

        await driver.scroll(pickerFinder, dx, -dy, Duration(seconds: 1));
        await driver.tap(find.text('OK'));

        await driver.tap(find.text('RUN'));
        await waitForResult('Result', 'The chosen color is FF0000');
      });

      test('call Choose a color (ChooseColor) - none', () async {
        await openAction('ChooseColor');

        await driver.tap(find.text('PICK COLOR'));
        await driver.tap(find.byType('ColorPicker'));
        await driver.tap(find.text('OK'));

        await driver.tap(find.text('CLEAR'));

        await driver.tap(find.text('RUN'));
        await waitForResult('Result', 'No color chosen');
      });

      test('call Choose a fruit (FruitsWithColorsContextSetter_Choose)',
          () async {
        var actionName = 'FruitsWithColorsContextSetter_Choose';
        await openAction(actionName);

        await driver.tap(find.text('Kiwi'));
        await driver.tap(find.text('CHOOSE'));

        await driver.waitFor(find.descendant(
            of: findActionListElement(actionName),
            matching: find.text('Kiwi')));
        await driver.waitFor(find.descendant(
            of: findActionListElement(actionName),
            matching: find.text('green')));
      });

      test('call Console output (ConsoleOutput)', () async {
        var actionFinder = await openAction('ConsoleOutput');

        await driver.waitFor(find.descendant(
            of: actionFinder, matching: find.byType('MarkdownBody')));
      });

      test('call Convert to upper case (UpperCase)', () async {
        await openAction('UpperCase');

        await driver.tap(find.byType('TextFormField'));
        var text = 'To uppercase';
        await driver.enterText(text);

        await driver.waitFor(find.text(text));

        await driver.tap(find.text('RUN'));
        await waitForResult('Upper case text', text.toUpperCase());
      });
      test('call Convert to upper case (UpperCase) - clear/cancel', () async {
        await openAction('UpperCase');

        var text = 'To uppercase';

        await driver.tap(find.byType('TextFormField'));
        await driver.enterText(text);
        await driver.tap(find.text('CLEAR'));
        await driver.waitForAbsent(find.text(text));

        await driver.tap(find.byType('TextFormField'));
        await driver.enterText(text);
        await driver.tap(find.byValueKey('text-clear'));
        await driver.waitForAbsent(find.text(text));

        // RUN unsuccessful.
        await driver.waitFor(find.text('RUN'));

        await driver.tap(find.text('CANCEL'));

        await waitForAbsentResult('Upper case text', text.toUpperCase());
      });

      test('call Enable args action (EnableArgsAction)', () async {
        await openAction('EnableArgsAction');

        // A disabled text.
        try {
          await tapArg('dynamicallyDisabled', timeout: Duration(seconds: 2));
          fail('Exception expected');
        } catch (e) {
          // Ignoring.
        }
        await tapArg('enable');

        // An enabled text.
        await enterArgValue('dynamicallyDisabled', 'TEXT');

        var testContextAction = (String arg) async {
          await driver.tap(find.descendant(
              of: findListElement(arg, 1),
              matching: find.byValueKey('sub-actions')));
          var lowercase = 'lower case';
          await driver.tap(find.text('Convert to upper case'));
          await enterArgValue('text', lowercase);
          await driver.tap(find.text('RUN'));
          await driver.waitFor(
              find.text('Upper case text: ${lowercase.toUpperCase()}'));
          await driver.tap(find.text('CLOSE'));
        };

        // An enabled list.
        await testContextAction('list');

        // An enabled record.
        await driver.tap(find.descendant(
            of: await findArg('record'),
            matching: find.byValueKey('record-expand')));
        await enterArgValue('record.author', 'A');
        await enterArgValue('record.title', 'B');

        // An enabled list of records.
        await testContextAction('listOfRecords');

        // Test provided with current.
        var newValue = 'NEW TEXT';
        await enterArgValue('dynamicallyDisabled', newValue);

        await tapArg('enable');

        await driver.waitFor(find.text(newValue));

        await driver.tap(find.pageBack());
      });
      test(
          'call Fruits action with argument element value set (FruitsElementValueSetAction)',
          () async {
        await openAction('FruitsElementValueSetAction');

        await driver.tap(find.byValueKey('checkbox-Apple'));
        await driver.tap(find.byValueKey('checkbox-Lemon'));

        await driver.tap(find.text('RUN'));
        await waitForResult('Result', '2');
      });

      test(
          'call Fruits action with argument element value set (FruitsElementValueSetAction) - clear',
          () async {
        await openAction('FruitsElementValueSetAction');

        await driver.tap(find.byValueKey('checkbox-Apple'));
        await driver.tap(find.byValueKey('checkbox-Lemon'));

        await driver.tap(find.text('CLEAR'));

        await driver.waitFor(find.byValueKey('checkbox-Apple'));

        await driver.tap(find.text('RUN'));
        await waitForResult('Result', '0');
      });
      test(
          'call Fruits with colors - context setter (FruitsWithColorsContextSetter)',
          () async {
        await openAction('FruitsWithColorsContextSetter');

        await driver.waitFor(find.descendant(
            of: findListElement('fruits', 0), matching: find.text('Orange')));
        await driver.waitFor(find.descendant(
            of: findListElement('fruits', 1), matching: find.text('Lemon')));
        await driver.waitFor(find.descendant(
            of: findListElement('fruits', 2), matching: find.text('Apple')));

        // The 'Update a fruit' context action.
        await driver.tap(find.descendant(
            of: findListElement('fruits', 0),
            matching: find.byType('SubActionsWidget')));
        await driver.tap(find.text('Update a fruit'));
        await enterArgValue('fruit.name', 'Kiwi');
        await enterArgValue('fruit.color', 'green');
        await driver.tap(find.text('SAVE'));

        await driver.waitFor(find.descendant(
            of: findListElement('fruits', 0), matching: find.text('Kiwi')));
        await driver.waitFor(find.descendant(
            of: findListElement('fruits', 1), matching: find.text('Lemon')));
        await driver.waitFor(find.descendant(
            of: findListElement('fruits', 2), matching: find.text('Apple')));

        // The 'Choose a new fruit' context action.
        await driver.tap(find.descendant(
            of: findListElement('fruits', 0),
            matching: find.byType('SubActionsWidget')));
        await driver.tap(find.text('Choose a new fruit'));
        await driver.tap(find.descendant(
            of: await findArg('fruits'), matching: find.text('Banana')));
        await driver.tap(find.text('CHOOSE'));

        await driver.waitFor(find.descendant(
            of: findListElement('fruits', 0), matching: find.text('Banana')));
        await driver.waitFor(find.descendant(
            of: findListElement('fruits', 1), matching: find.text('Lemon')));
        await driver.waitFor(find.descendant(
            of: findListElement('fruits', 2), matching: find.text('Apple')));

        // The 'Get list index' context action.
        var index = 1;
        await driver.tap(find.descendant(
            of: findListElement('fruits', index),
            matching: find.byType('SubActionsWidget')));
        await driver.tap(find.text('Get list index'));
        await driver.waitFor(find.text('Index: $index'));
        await driver.tap(find.text('CLOSE'));

        // The 'Update a header' context action.
        var header = 'Header';
        await enterArgValue('header', header);
        await driver.tap(find.descendant(
            of: findListElement('fruits', index),
            matching: find.byType('SubActionsWidget')));
        await driver.tap(find.text('Update a header'));

        header += ' 2';
        await enterArgValue('header', header);
        await driver.tap(find.text('RUN'));

        await driver.waitFor(find.text(header));

        // The 'Action record' context action.
        await driver.tap(find.descendant(
            of: findListElement('fruits', index),
            matching: find.byType('SubActionsWidget')));
        await driver.tap(find.text('Action record'));

        header += ' 3';
        await enterArgValue('record.header', header);
        await driver.tap(await findWidget(find.text('RUN')));

        await driver.waitFor(find.text(header));

        // The 'Action record full' context action.
        await driver.tap(find.descendant(
            of: findListElement('fruits', index),
            matching: find.byType('SubActionsWidget')));
        await driver.tap(find.text('Action record full'));

        header += ' 4';
        await enterArgValue('header', header);
        await driver.tap(await findWidget(find.text('RUN')));

        await driver.waitFor(find.text(header), timeout: Duration(minutes: 1));

        // The 'Update a whole list' context action.
        await driver.tap(find.descendant(
            of: findListElement('fruits', index),
            matching: find.byType('SubActionsWidget')));
        await driver.tap(find.text('Update a whole list'));
        await driver.waitFor(find.descendant(
            of: findListElement('fruits', 3),
            matching: find.text('Strawberry')));

        await driver.tap(find.pageBack(), timeout: Duration(minutes: 1));
      });
// TODO Hangs.
      // test('call HTML file output (HtmlFileOutput)', () async {
      //   await openAction('HtmlFileOutput');

      //   //await driver.tap(find.byTooltip('Returns the HTML file.'), timeout: Duration(seconds: 120));
      // });

      test('call Hello with lower case (LowerCaseHello)', () async {
        await openAction('LowerCaseHello');
        var arg = 'Test';
        await enterArgValue('text', arg);

        await driver.tap(find.text('RUN'));
        await waitForResult(
            'Lower case text', 'Hello admin: ${arg.toLowerCase()}');
      });

      test('call Many arguments action (ManyArgumentsAction)', () async {
        await openAction('ManyArgumentsAction');

        for (int i = 1; i <= 30; i++) {
          await enterArgValue('a$i', 'Value $i');
        }

        await driver.tap(find.text('RUN'));
        await waitForResult('Result', 'Success');
      });
      test('call Markdown text (MarkdownText)', () async {
        await openAction('MarkdownText');
        await driver.tap(find.byType('ActionResultWidget'));
        await driver.tap(find.pageBack());
      });

      test(
          'call Numbers with filter in a context action (NumbersViewFilterInContextAction)',
          () async {
        await openAction('NumbersViewFilterInContextAction');

        await driver.waitFor(find.descendant(
            of: findListElement('numbers', 0), matching: find.text('1')));
        await driver.waitFor(find.descendant(
            of: findListElement('numbers', 3), matching: find.text('4')));

        // The 'filter' context action.
        await driver.tap(find.byType('SubActionsWidget'));
        await driver.tap(find.text('Filter'));
        await enterArgValue('filter.first', '5');
        await enterArgValue('filter.last', '6');
        await driver.tap(find.text('SAVE'));
        await driver.waitFor(find.descendant(
            of: findListElement('numbers', 0), matching: find.text('5')));
        await driver.waitFor(find.descendant(
            of: findListElement('numbers', 1), matching: find.text('6')));

        // The 'Substitution of this' context action.
        await driver.tap(find.byType('SubActionsWidget'));
        await driver.tap(find.text('Substitution of this'));
        await enterArgValue('record.filter.first', '2');
        await enterArgValue('record.filter.last', '4');
        await driver.tap(find.text('SAVE'));
        await driver.waitFor(find.descendant(
            of: findListElement('numbers', 0), matching: find.text('2')));
        await driver.waitFor(find.descendant(
            of: findListElement('numbers', 2), matching: find.text('4')));

        await driver.tap(find.pageBack());
      });

      test('call Numbers with inline filter (NumbersViewFilterInline)',
          () async {
        await openAction('NumbersViewFilterInline');

        await driver.waitFor(find.descendant(
            of: findListElement('numbers', 0), matching: find.text('1')));
        await driver.waitFor(find.descendant(
            of: findListElement('numbers', 3), matching: find.text('4')));

        await enterArgValue('filter.first', '5');
        await enterArgValue('filter.last', '6');

        await driver.tap(find.text('REFRESH'));

        await driver.waitFor(find.descendant(
            of: findListElement('numbers', 0), matching: find.text('5')));
        await driver.waitFor(find.descendant(
            of: findListElement('numbers', 1), matching: find.text('6')));

        await driver.tap(find.pageBack());
      });

      // TODO Hangs.
      // test('call PDF file output" (PdfFileOutput)', () async {
      //   await openAction('PdfFileOutput');
      //   await driver.tap(find.byType('ActionResultWidget'));
      //   await driver.tap(find.pageBack());
      // });

      test(
          'call Object type with companion type (ObjectTypeWithCompanionTypeAction)',
          () async {
        var actionName = 'ObjectTypeWithCompanionTypeAction';
        await openAction(actionName);

        var idArg = '5';
        var nameArg = 'Sponge';

        await driver.tap(find.byValueKey('record-expand'));
        await enterArgValue('customObject.id', idArg);
        await enterArgValue('customObject.name', nameArg);

        await driver.tap(find.text('RUN'));

        await driver.waitFor(find.descendant(
            of: findActionListElement(actionName), matching: find.text(idArg)));
        await driver.waitFor(find.descendant(
            of: findActionListElement(actionName),
            matching: find.text(nameArg.toUpperCase())));
      });

      test(
          'call Record argument with context actions (RecordWithContextActions)',
          () async {
        await openAction('RecordWithContextActions');

        var author = 'George Orwell';
        var title = 'Nineteen Eighty-Four';
        await enterArgValue('book.author', author);
        await enterArgValue('book.title', title);

        // The first context action.
        await driver.tap(find.byType('SubActionsWidget'));
        await driver.tap(find.text('Add author comment'));
        var authorComment =
            'An English novelist and essayist, journalist and critic.';
        await enterArgValue('comment', authorComment);
        await driver.tap(find.text('RUN'));
        await waitForResult(
            'Result', 'Added \'$authorComment\' comment to author \'$author\'');
        await driver.tap(find.text('CLOSE'));

        // The second context action.
        await driver.tap(find.byType('SubActionsWidget'));
        await driver.tap(find.text('Add title comment'));
        var titleComment =
            'A dystopian novel by English novelist George Orwell.';
        await enterArgValue('comment', titleComment);
        await driver.tap(find.text('RUN'));
        await waitForResult(
            'Result', 'Added \'$titleComment\' comment to title \'$title\'');
        await driver.tap(find.text('CLOSE'));

        await driver.tap(find.text('RUN'));
        await waitForResult('Result', 'Success');
      });

      test('call Submittable argument (SubmittableActionArg)', () async {
        await openAction('SubmittableActionArg');

        var arg1 = 'abc de';
        await enterArgValue('arg1', arg1);

        await driver.waitFor(find.text(arg1.toUpperCase()));

        expect(await driver.getText(findTextValueWidget('arg2')),
            equals(arg1.toUpperCase()));
        expect(await driver.getText(findTextValueWidget('arg3')),
            equals(arg1.toUpperCase()));
        expect(await driver.getText(findTextValueWidget('arg4')),
            equals(arg1.toUpperCase()));

        await driver.tap(find.text('CLOSE'));
      });
    }, timeout: Timeout(Duration(minutes: 1)));
    group('Actions/Forms', () {
      test('call Changed button labels form (ChangedButtonLabelsForm)',
          () async {
        await openAction('ChangedButtonLabelsForm', group: 'Forms');

        await driver.waitFor(find.text('Sponge version'));
        await driver.waitFor(find.text('CALL'));
        await driver.waitFor(find.text('RELOAD'));
        await driver.waitFor(find.text('RESET'));
        await driver.waitFor(find.text('CLOSE'));

        await driver.tap(find.text('RELOAD'));

        await driver.waitFor(find.text('Sponge version'));

        var text = 'Test text';
        await enterArgValue('text', text);
        await driver.tap(find.text('CALL'));
        await waitForResult('Upper case text', text.toUpperCase());
      });

      test(
          'call Default label for the call button form (DefaultCallButtonForm)',
          () async {
        await openAction('DefaultCallButtonForm', group: 'Forms');

        await driver.waitFor(find.text('Sponge version'));
        await driver.waitFor(find.text('RUN'));
        await driver.waitForAbsent(find.text('REFRESH'));
        await driver.waitForAbsent(find.text('CALL'));
        await driver.waitForAbsent(find.text('CLEAR'));
        await driver.waitForAbsent(find.text('CANCEL'));
        var text = 'Test text';
        await enterArgValue('text', text);
        await driver.tap(find.text('RUN'));
        await waitForResult('Upper case text', text.toUpperCase());
      });

      test('call Hidden buttons form (HiddenButtonsForm)', () async {
        await openAction('HiddenButtonsForm', group: 'Forms');

        await driver.waitFor(find.text('Sponge version'));
        await driver.waitFor(find.text('CALL'));
        await driver.waitForAbsent(find.text('REFRESH'));
        await driver.waitForAbsent(find.text('CLEAR'));
        await driver.waitForAbsent(find.text('CANCEL'));
        var text = 'Test text';
        await enterArgValue('text', text);
        await driver.tap(find.text('CALL'));
        await waitForResult('Upper case text', text.toUpperCase());
      });
      test(
          'call Library (books as records) (RecordLibraryForm) - Basic operations',
          () async {
        await openAction('RecordLibraryForm', group: 'Forms');

        await driver.waitFor(findByValueKeyAsType('search'));

        await driver.waitFor(findByValueKeyAsType('order'));
        await driver.waitFor(findTextWidget(findByValueKeyAsType('order'),
            matching: find.text('Author')));

        await driver.waitFor(findByValueKeyAsType('books'));
        var bookFinderEsisting = findTextWidget(findByValueKeyAsType('books'),
            matching: find.text('Alexandre Dumas - Count of Monte Cristo'));
        await driver.waitFor(bookFinderEsisting);
        await driver.waitFor(findTextWidget(findByValueKeyAsType('books'),
            matching: find
                .text('Arthur Conan Doyle - Adventures of Sherlock Holmes')));
        await driver.waitFor(findTextWidget(findByValueKeyAsType('books'),
            matching: find.text('Bram Stoker - Dracula')));

        // View a book.
        await driver.tap(bookFinderEsisting);
        await driver.waitFor(find.text('View the book'));
        await driver.waitFor(find.text('Author *'));
        await driver.waitFor(find.text('Alexandre Dumas'));
        await driver.waitFor(find.text('Title *'));
        await driver.waitFor(find.text('Count of Monte Cristo'));
        await driver.tap(find.text('CLOSE'));

        // Refresh the books list.
        await driver.tap(find.byValueKey('list-refresh'));

        await driver.tap(find.pageBack());
      });

      test(
          'call Library (books as records) (RecordLibraryForm) - Add a new book',
          () async {
        await openAction('RecordLibraryForm', group: 'Forms');

        var author = 'Alistair MacLean';
        var title = 'The Guns of Navarone';

        await driver.tap(find.byValueKey('list-create'));
        await driver.waitFor(find.text('Add a new book'));
        await driver.waitFor(find.text('Title *'));
        await driver.waitFor(find.text('SAVE'));
        await driver.waitFor(find.text('CANCEL'));

        await enterArgValue('book.author', author);
        await enterArgValue('book.title', title);

        await driver.tap(find.text('SAVE'));

        var bookFinderNew = findTextWidget(findByValueKeyAsType('books'),
            matching: find.text('$author - $title'));
        await driver.waitFor(bookFinderNew);

        await driver.tap(find.pageBack());
      });

      test(
          'call Library (books as records) (RecordLibraryForm) - Modify the book',
          () async {
        await openAction('RecordLibraryForm', group: 'Forms');

        var author = 'Alistair MacLean';
        var newTitle = 'Force 10 from Navarone';

        await driver.tap(find.descendant(
            of: findListElement('books', 1),
            matching: find.byValueKey('sub-actions')));
        await driver.tap(find.text('Modify the book'));

        await driver.waitFor(find.text('Modify the book'));
        await driver.waitFor(find.text(author));
        await driver.waitFor(find.text('Title *'));

        await enterArgValue('book.title', newTitle);

        await driver.tap(find.text('SAVE'));
        var bookFinderModified = findTextWidget(findByValueKeyAsType('books'),
            matching: find.text('$author - $newTitle'));
        await driver.waitFor(bookFinderModified);

        await driver.tap(find.pageBack());
      });

      test(
          'call Library (books as records) (RecordLibraryForm) - Remove the book',
          () async {
        await openAction('RecordLibraryForm', group: 'Forms');

        var author = 'Alistair MacLean';
        var newTitle = 'Force 10 from Navarone';

        // Remove the book - cancel.
        await driver.tap(find.descendant(
            of: findListElement('books', 1),
            matching: find.byValueKey('sub-actions')));
        await driver.tap(find.text('Remove the book'));

        await driver
            .waitFor(find.text('Do you want to remove $author - $newTitle?'));
        await driver.tap(find.text('NO'));

        // Remove the book.
        await driver.tap(find.descendant(
            of: findListElement('books', 1),
            matching: find.byValueKey('sub-actions')));
        await driver.tap(find.text('Remove the book'));

        await driver
            .waitFor(find.text('Do you want to remove $author - $newTitle?'));
        await driver.tap(find.text('YES'));

        await driver.waitForAbsent(findTextWidget(findByValueKeyAsType('books'),
            matching: find.text('$author - $newTitle')));

        await driver.tap(find.pageBack());
      });

      // TODO Hangs.
      // test(
      //     'call Library (books as records) (RecordLibraryForm) - Context action - Text sample as PDF',
      //     () async {
      //   await openAction('RecordLibraryForm', group: 'Forms');

      //   await driver.tap(find.descendant(
      //       of: findListElement('books', 0),
      //       matching: find.byValueKey('sub-actions')));
      //   await driver.tap(find.text('Text sample as PDF'));

      //   await driver.waitFor(find.text('Text sample as PDF'));
      //   await driver.waitFor(find.text('PDF'));

      //   await driver.tap(find.text('CLOSE'));
      //   await driver.tap(find.pageBack());
      // });

      test(
          'call Library (books as records) (RecordLibraryForm) - Context action - Return the book',
          () async {
        await openAction('RecordLibraryForm', group: 'Forms');

        await driver.tap(find.descendant(
            of: findListElement('books', 0),
            matching: find.byValueKey('sub-actions')));
        await driver.tap(find.text('Return the book'));

        // Closes automatically.

        await driver.waitFor(findTextWidget(findByValueKeyAsType('books'),
            matching: find.text('Alexandre Dumas - Count of Monte Cristo')));
        await driver.tap(find.pageBack());
      });

      test(
          'call Library (books as records) (RecordLibraryForm) - Context action - Add book comment',
          () async {
        await openAction('RecordLibraryForm', group: 'Forms');

        await driver.tap(find.descendant(
            of: findListElement('books', 0),
            matching: find.byValueKey('sub-actions')));
        await driver.tap(find.text('Add book comment'));

        await driver.waitFor(find.text('Add book comment'));
        await driver
            .waitFor(find.text('Alexandre Dumas - Count of Monte Cristo'));

        var comment = 'Some book comment';
        await enterArgValue('comment', comment);
        await driver.tap(find.text('RUN'));

        await driver.waitFor(find.text('Add book comment'));
        await waitForResult('Added comment', comment);
        await driver.tap(find.text('CLOSE'));

        await driver.tap(find.pageBack());
      });

      test('call Library (books as records) (RecordLibraryForm) - Search',
          () async {
        await openAction('RecordLibraryForm', group: 'Forms');

        await enterArgValue('search', 'Bradbury');
        await driver.waitFor(findTextWidget(findByValueKeyAsType('books'),
            matching: find.text('Ray Bradbury - Fahrenheit 451')));
        await driver.waitForAbsent(findTextWidget(findByValueKeyAsType('books'),
            matching: find
                .text('Arthur Conan Doyle - Adventures of Sherlock Holmes')));

        await enterArgValue('search', '');
        await driver.waitFor(findTextWidget(findByValueKeyAsType('books'),
            matching: find
                .text('Arthur Conan Doyle - Adventures of Sherlock Holmes')));

        await driver.tap(find.pageBack());
      });

      test('call Library (books as records) (RecordLibraryForm) - Order',
          () async {
        await openAction('RecordLibraryForm', group: 'Forms');

        expect(
            await driver.getText(find.descendant(
                of: findListElement('books', 0),
                matching: find.byType('Text'))),
            equals('Alexandre Dumas - Count of Monte Cristo'));

        await chooseProvidedValueFromSet('order', 'Title');
        expect(
            await driver.getText(find.descendant(
                of: findListElement('books', 0),
                matching: find.byType('Text'))),
            equals('Charles Dickens - A Christmas Carol'));

        await driver.tap(find.pageBack());
      });

      test('call Library (books as arguments) (ArgLibraryForm) - View the book',
          () async {
        await openAction('ArgLibraryForm', group: 'Forms');

        var bookFinderEsisting = findTextWidget(findByValueKeyAsType('books'),
            matching: find.text('Alexandre Dumas - Count of Monte Cristo'));
        await driver.waitFor(bookFinderEsisting);
        await driver.waitFor(findTextWidget(findByValueKeyAsType('books'),
            matching: find
                .text('Arthur Conan Doyle - Adventures of Sherlock Holmes')));
        await driver.waitFor(findTextWidget(findByValueKeyAsType('books'),
            matching: find.text('Bram Stoker - Dracula')));

        // View a book.
        await driver.tap(bookFinderEsisting);
        await driver.waitFor(find.text('View the book'));
        await driver.waitFor(find.text('Author *'));
        await driver.waitFor(find.text('Alexandre Dumas'));
        await driver.waitFor(find.text('Title *'));
        await driver.waitFor(find.text('Count of Monte Cristo'));
        await driver.tap(find.text('CLOSE'));

        await driver.tap(find.pageBack());
      });

      test('call Library (books as arguments) (ArgLibraryForm) - Order',
          () async {
        await openAction('ArgLibraryForm', group: 'Forms');

        await driver.waitFor(find.descendant(
            of: findListElement('books', 0),
            matching: find.text('Sample description (ID: 4)')));
        await driver.waitFor(find.descendant(
            of: findListElement('books', 1),
            matching: find.text('Sample description (ID: 2)')));

        await chooseProvidedValueFromSet('order', 'Title');

        await driver.waitFor(find.descendant(
            of: findListElement('books', 0),
            matching: find.text('Sample description (ID: 3)')));
        await driver.waitFor(find.descendant(
            of: findListElement('books', 1),
            matching: find.text('Sample description (ID: 2)')));

        await driver.tap(find.pageBack());
      });
      test('call Library (books as arguments) (ArgLibraryForm) - Search',
          () async {
        await openAction('ArgLibraryForm', group: 'Forms');

        await enterArgValue('search', 'Bradbury');

        await driver.waitFor(findTextWidget(findByValueKeyAsType('books'),
            matching: find.text('Ray Bradbury - Fahrenheit 451')));
        await driver.waitForAbsent(findTextWidget(findByValueKeyAsType('books'),
            matching: find
                .text('Arthur Conan Doyle - Adventures of Sherlock Holmes')));

        await enterArgValue('search', '');
        await driver.waitFor(findTextWidget(findByValueKeyAsType('books'),
            matching: find
                .text('Arthur Conan Doyle - Adventures of Sherlock Holmes')));

        await driver.tap(find.pageBack());
      });
      test(
          'call Library (books as arguments) (ArgLibraryForm) - Add a new book - cancel',
          () async {
        await openAction('ArgLibraryForm', group: 'Forms');

        var author = 'Alistair MacLean';
        var title = 'The Guns of Navarone';

        await driver.tap(find.byValueKey('list-create'));
        await driver.waitFor(find.text('Add a new book'));
        await driver.waitFor(find.text('Title *'));
        await driver.waitFor(find.text('SAVE'));
        await driver.waitFor(find.text('CANCEL'));

        await enterArgValue('author', author);
        await enterArgValue('title', title);

        await driver.tap(find.text('CANCEL'));

        await driver.tap(find.pageBack());
      });
    }, timeout: Timeout(Duration(minutes: 1)));

    group('Actions/Digits', () {
      // TODO Hangs.
      // test('call Recognize a digit (DigitsPredict)', () async {
      //   await openAction('DigitsPredict', group: 'Digits');

      //   await driver.tap(find.text('DRAW IMAGE OF A DIGIT *'));

      //   var painterFinder = find.byType('PainterPanel');
      //   var bottomRight = await driver.getBottomRight(painterFinder);
      //   var topLeft = await driver.getTopLeft(painterFinder);

      //   var dx = bottomRight.dx - topLeft.dx;
      //   var dy = bottomRight.dy - topLeft.dy;

      //   await driver.tap(painterFinder);
      //   var duration = Duration(milliseconds: 500);
      //   await driver.scroll(painterFinder, 0, dy / 3, duration);
      //   await driver.scroll(painterFinder, 0, -dy / 3, duration);

      //   await driver.tap(find.pageBack());

      //   await driver.tap(find.text('RUN'));

      //await waitForResult('Recognized digit', '1');
      // });
    });

    group('Actions/Events', () {
      test('call Counter (ViewCounter)', () async {
        await openAction('ViewCounter', group: 'Events');

        var counterFinder = findTextValueWidget('counter');
        await driver.waitFor(counterFinder);
        var counterValue = await driver.getText(counterFinder);
        var counter = int.parse(counterValue);

        // Wait for the counter + 2 because the counter + 1 could be skipped.
        await driver.waitFor(find.text('${counter + 2}'));
        await driver.waitFor(find.text('${counter + 3}'));

        await driver.tap(find.text('CLOSE'));
      });

      test('call Manage events subscription (GrpcApiManageSubscription) - memo',
          () async {
        // Subscribe.
        await openAction('GrpcApiManageSubscription', group: 'Events');
        await driver.tap(find.byValueKey('checkbox-Memo'));
        //await driver.tap(find.byValueKey('checkbox-Notification'));
        await driver.tap(await findArg('subscribe'));
        await driver.tap(find.text('SAVE'));

        // Send memo event.
        var message = 'Test message';
        var label = 'Test label';
        var description = 'Test description';
        await openAction('GrpcApiSendEvent', group: 'Events');
        await chooseProvidedValueFromSet('name', 'Memo');
        await enterArgValue('attributes.message', message);
        await enterArgValue('label', label);
        await enterArgValue('description', description);
        await driver.tap(find.text('SEND'));

        // TODO The test that uses a drawer doesn't work - hangs.
        // Check events list.
        // Open a drawer [https://github.com/flutter/flutter/issues/23007].
        //await driver.tap(find.byTooltip('Open navigation menu'));
        //await driver.tap(find.text('Events'));

        //await driver.waitFor(find.text('Events ($TEST_SERVICE)'));

        // await driver.tap(find.byValueKey('event-0'));
        // var messageFinder = findTextValueWidget('uppercaseMessage');
        // await driver.waitFor(messageFinder);
        // expect(
        //     await driver.getText(messageFinder), equals(message.toUpperCase()));
        // await driver.tap(find.text('CLOSE'));

        // await driver.tap(find.byValueKey('event-0'));
        // await driver.tap(find.text('DISMISS'));

        // await driver.waitForAbsent(find.byValueKey('event-0'));

        // Unsubscribe.
        await driver.tap(find.byTooltip('Open navigation menu'));
        await driver.tap(find.text('Actions'));

        await openAction('GrpcApiManageSubscription', group: 'Events');
        await driver.tap(find.byValueKey('checkbox-Memo'));
        await driver.tap(await findArg('subscribe'));
        await driver.tap(find.text('SAVE'));
      });
    });
  });
}

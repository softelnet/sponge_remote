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
import 'package:sponge_flutter_api/sponge_flutter_api.dart';
import 'package:sponge_remote/src/application_constants.dart';

Future<void> showAboutAppDialog(BuildContext context) async {
  final ThemeData themeData = Theme.of(context);
  final TextStyle headerTextStyle =
      themeData.textTheme.bodyText2.apply(fontWeightDelta: 2);
  final TextStyle aboutTextStyle = themeData.textTheme.bodyText2;
  final TextStyle linkStyle =
      themeData.textTheme.bodyText2.copyWith(color: themeData.accentColor);
  final TextStyle noteTextStyle =
      themeData.textTheme.bodyText2.apply(color: getSecondaryColor(context));

  await showDefaultAboutAppDialog(
    context,
    contents: RichText(
      textAlign: TextAlign.justify,
      text: TextSpan(
        children: <TextSpan>[
          TextSpan(
            style: headerTextStyle,
            text:
                '\n\n$APPLICATION_NAME is a generic GUI client to Sponge services that allows users to run remote Sponge actions. '
                'It is released under the open-source Apache 2.0 license.',
          ),
          TextSpan(
              style: noteTextStyle,
              text:
                  '\n\nThe current version is in alpha phase and supports only a limited set of Sponge features.'),
          TextSpan(
              style: aboutTextStyle,
              text:
                  '\n\nThe supported Sponge server versions are ${SpongeServiceConstants.SUPPORTED_SPONGE_VERSION_MAJOR_MINOR}.*.'),
          TextSpan(
            style: aboutTextStyle,
            text: '\n\nFor more information please visit the ',
          ),
          LinkTextSpan(
            style: linkStyle,
            url: 'https://sponge.openksavi.org/mobile',
            text: '$APPLICATION_NAME',
          ),
          TextSpan(
            style: aboutTextStyle,
            text: ' home page and the ',
          ),
          LinkTextSpan(
            style: linkStyle,
            url: 'https://sponge.openksavi.org',
            text: 'Sponge',
          ),
          TextSpan(
            style: aboutTextStyle,
            text: ' project home page.',
          ),
        ],
      ),
    ),
  );
}

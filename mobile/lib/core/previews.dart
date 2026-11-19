import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'theme.dart';
import 'ui.dart';

@Preview(name: 'Studio / light', size: Size(360, 640))
@Preview(
  name: 'Studio / narrow large text',
  size: Size(320, 640),
  textScaleFactor: 2,
)
Widget studioLightPreview() => _components(Brightness.light);

@Preview(name: 'Studio / dark', size: Size(360, 640))
Widget studioDarkPreview() => _components(Brightness.dark);

Widget _components(Brightness brightness) => MaterialApp(
  theme: buildTheme(brightness),
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(Space.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StudioHeader(
            kicker: 'Visual fixture',
            title: 'Make room for learning.',
          ),
          const StudioProgress(
            label: 'Learning progress',
            value: 50,
            detail: '1 of 2 assignments done · Mock data',
          ),
          StudioListItem(
            title: 'Explore a new idea',
            detail: 'A lesson and supporting resources',
            icon: Icons.menu_book_outlined,
            status: const StatusPill('Published', tone: Tone.success),
            onTap: () {},
          ),
        ],
      ),
    ),
  ),
);

import 'package:arbo_frontend/resources/previous_specific_data.dart';
import 'package:arbo_frontend/screens/root_screen.dart';
import 'package:arbo_frontend/screens/specific_post_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // https://stackoverflow.com/questions/74028226/space-bar-key-doesnt-work-on-textfields-flutter-web
      shortcuts: Map.of(WidgetsApp.defaultShortcuts)
        ..addAll({
          LogicalKeySet(LogicalKeyboardKey.space): const ActivateIntent(),
        }),
      initialRoute: '/',
      routes: {
        '/': (context) => const RootScreen(),
        SpecificPostScreen.routeName: (context) {
          final args = PreviousSpecificData.previousSpecific;
          return SpecificPostScreen.fromMap(args);
        },
      },
    );
  }
}

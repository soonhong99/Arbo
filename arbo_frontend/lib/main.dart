import 'package:arbo_frontend/resources/specific_data.dart';
import 'package:arbo_frontend/screens/create_post_screen.dart';
import 'package:arbo_frontend/screens/root_screen.dart';
import 'package:arbo_frontend/screens/specific_post_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
          final args = SpecificData.specificData;
          return SpecificPostScreen.fromMap(args);
        },
        CreatePostScreen.routeName: (context) => const CreatePostScreen(),
      },
    );
  }
}

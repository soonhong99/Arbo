import 'package:arbo_frontend/resources/specific_data.dart';
import 'package:arbo_frontend/screens/create_post_screen.dart';
import 'package:arbo_frontend/screens/root_screen.dart';
import 'package:arbo_frontend/screens/specific_post_screen.dart';
import 'package:arbo_frontend/screens/user_info_screen.dart';
import 'package:arbo_frontend/widgets/main_widgets/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // runApp(const App());
  runApp(ChangeNotifierProvider(
      create: (context) => UserData(), child: const App()));
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
      // initialRoute: '/',
      home: const RootScreen(),
      routes: {
        // '/': (context) => const RootScreen(),
        SpecificPostScreen.routeName: (context) {
          final args = SpecificData.specificData;
          return SpecificPostScreen.fromMap(args);
        },
        CreatePostScreen.routeName: (context) => const CreatePostScreen(),
      },
      //when you need to pass arguments to a route,
      //onGenerateRoute provides a more flexible solution.
      onGenerateRoute: (settings) {
        if (settings.name == UserInfoScreen.routeName) {
          final args = settings.arguments as UserInfoScreen;
          return MaterialPageRoute(
            builder: (context) {
              return UserInfoScreen(user: args.user);
            },
          );
        }
        assert(false, 'Need to implement ${settings.name}');
        return null;
      },
    );
  }
}

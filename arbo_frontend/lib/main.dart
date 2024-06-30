import 'package:arbo_frontend/data/user_data.dart';
import 'package:arbo_frontend/data/user_data_provider.dart';
import 'package:arbo_frontend/screens/create_post_screen.dart';
import 'package:arbo_frontend/roots/root_screen.dart';
import 'package:arbo_frontend/screens/specific_post_screen.dart';
import 'package:arbo_frontend/screens/user_info_screen.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'firebase/firebase_options.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await firebase_appcheck_instance.activate(
    // Set appleProvider to `AppleProvider.debug`
    appleProvider: AppleProvider.debug,
    androidProvider: AndroidProvider.debug,
    // debug 환경에서만 쓸 수있는 환경
    webProvider:
        ReCaptchaEnterpriseProvider('6LfsmAIqAAAAANCx1F7lQmzFF6_Yc68jRMz9nqg4'),
  );

  print('firebase app check: $firebase_appcheck_instance');
  firebase_appcheck_instance.setTokenAutoRefreshEnabled(true);
  firebase_appcheck_instance.onTokenChange.listen((token) {
    print('Received a new App Check token: $token');
  });

  runApp(
    ChangeNotifierProvider(
      create: (context) => UserDataProvider(),
      child: const App(),
    ),
  );
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
        // CategorizedScreen.routeName: (context) => const CategorizedScreen(),
        SpecificPostScreen.routeName: (context) => const SpecificPostScreen(),
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

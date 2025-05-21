import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_3/constants/constans.dart';
import 'package:flutter_application_3/data/notifier.dart';
import 'package:flutter_application_3/firebase_options.dart';
import 'package:flutter_application_3/screens/login_page.dart';
import 'package:flutter_application_3/screens/splash_screen.dart';
import 'package:flutter_application_3/widget/widget_tree.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  
  final prefs = await SharedPreferences.getInstance();
  final isLight = prefs.getBool(KConstansts.themeModeKey) ?? true;
  lightMode.value = isLight;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: lightMode,
      builder: (context, isLight, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(), 
          darkTheme: ThemeData.dark(), 
          themeMode: isLight ? ThemeMode.light : ThemeMode.dark, 
          home: SplashScreen(),
          routes: {
            '/home': (context) => LoginPage(),
            '/second': (context) => const WidgetTree(),
          },
        );
      },
    );
  }
}
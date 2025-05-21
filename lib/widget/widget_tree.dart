import 'package:flutter/material.dart';
import 'package:flutter_application_3/constants/constans.dart';
import 'package:flutter_application_3/data/notifier.dart';
import 'package:flutter_application_3/screens/events_screen.dart';
import 'package:flutter_application_3/screens/explore_screen.dart';
import 'package:flutter_application_3/screens/map_screen.dart';
import 'package:flutter_application_3/screens/profile_screen.dart';

import 'package:flutter_application_3/widget/navbar_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<Widget> pages = [
  ExploreScreen(),
  EventsScreen(),
  MapScreen(),
  ProfilePage()
];

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});
  final String title = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: () async {
              lightMode.value = !lightMode.value; //notifier
              final SharedPreferences prefs =
                  await SharedPreferences.getInstance();
              await prefs.setBool(KConstansts.themeModeKey, lightMode.value);
            },
            icon: ValueListenableBuilder(
              valueListenable: lightMode,
              builder: (BuildContext context, dynamic which, Widget? child) {
                return Icon(which ? Icons.light_mode : Icons.dark_mode);
              },
            ),
          )
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: selectedNotifier,
        builder: (BuildContext context, dynamic selectedPage, Widget? child) {
          return pages.elementAt(selectedPage);
        },
      ),
      bottomNavigationBar: NavbarWidget(),
    );
  }
}

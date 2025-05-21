import 'package:flutter/material.dart';
import 'package:flutter_application_3/data/notifier.dart';

class NavbarWidget extends StatelessWidget {
  const NavbarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: selectedNotifier,
      builder: (BuildContext context, int selectedPage, Widget? child) {
        return BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.explore,
                  label: 'Explore',
                  index: 0,
                  selectedPage: selectedPage,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.event,
                  label: 'Events',
                  index: 1,
                  selectedPage: selectedPage,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.map,
                  label: 'Map',
                  index: 2,
                  selectedPage: selectedPage,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.person,
                  label: 'Profile',
                  index: 3,
                  selectedPage: selectedPage,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
    required int selectedPage,
  }) {
    bool isSelected = selectedPage == index;
    return MaterialButton(
      onPressed: () {
        selectedNotifier.value = index;
      },
      minWidth: 40,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? Colors.black : Colors.grey),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

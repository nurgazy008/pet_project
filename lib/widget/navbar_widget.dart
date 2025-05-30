import 'package:flutter/material.dart';
import 'package:flutter_application_3/data/notifier.dart';
import 'package:flutter_application_3/services/firestore_service.dart';

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
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Explore Tab (Index 0)
                _buildNavItem(
                  context,
                  icon: Icons.explore,
                  label: 'Explore',
                  index: 0,
                  selectedPage: selectedPage,
                ),
                // Events Tab (Index 1)
                _buildNavItem(
                  context,
                  icon: Icons.event,
                  label: 'Events',
                  index: 1,
                  selectedPage: selectedPage,
                ),
                // Map Tab (Index 2) - Keep the map tab
                _buildNavItem(
                  context,
                  icon: Icons.map,
                  label: 'Map',
                  index: 2,
                  selectedPage: selectedPage,
                ),
                // Tickets Tab (Index 3) - NEW!
                _buildTicketsNavItem(
                  context,
                  selectedPage: selectedPage,
                ),
                // Profile Tab (Index 4) - Updated index
                _buildNavItem(
                  context,
                  icon: Icons.person,
                  label: 'Profile',
                  index: 4,
                  selectedPage: selectedPage,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Regular navigation item
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
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? Colors.black : Colors.grey),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.grey,
              fontSize: 11, // Slightly smaller to fit 5 tabs
            ),
          ),
        ],
      ),
    );
  }

  // Special tickets navigation item with badge
  Widget _buildTicketsNavItem(
    BuildContext context, {
    required int selectedPage,
  }) {
    bool isSelected = selectedPage == 3; // Index 3 for tickets
    final firestoreService = FirestoreService();

    return MaterialButton(
      onPressed: () {
        selectedNotifier.value = 3; // Set to tickets tab
      },
      minWidth: 40,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // StreamBuilder listens to real-time ticket count changes
          StreamBuilder<int>(
            stream: firestoreService.getTicketCount(),
            builder: (context, snapshot) {
              final ticketCount = snapshot.data ?? 0;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Ticket icon
                  Icon(
                    Icons.confirmation_number,
                    color: isSelected ? Colors.black : Colors.grey,
                  ),
                  // Red badge with ticket count (only shows if count > 0)
                  if (ticketCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          ticketCount > 99 ? '99+' : '$ticketCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            'Tickets',
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.grey,
              fontSize: 11, // Slightly smaller to fit 5 tabs
            ),
          ),
        ],
      ),
    );
  }
}

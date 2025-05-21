import 'package:flutter/material.dart';
import 'package:flutter_application_3/about/eventlistitem.dart';

/// Screen that displays the list of available events
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  // Controller for the search field
  final TextEditingController _searchController = TextEditingController();
  // Search query
  String _searchQuery = '';
  
  // List of all events as maps
  final List<Map<String, dynamic>> _allEvents = [
    {
      'title': 'Tutor\'s Day',
      'date': '07 May, 2025',
      'time': 'Tuesday, 19:00PM - 21:00PM',
      'venue': 'JIHC\nAct Hall',
      'imagePath': 'assets/DSC00297.JPG',
      'price': 1000,
    },
    {
      'title': 'Moral Night Girls',
      'date': '10 May, 2025',
      'time': 'Friday, 18:00PM - 20:00PM',
      'venue': 'JIHC\nAct Hall',
      'imagePath': 'assets/DSC03364.JPG',
      'price': 1000,
    },
    {
      'title': 'Welcome Party For Boys',
      'date': '12 May, 2025',
      'time': 'Sunday, 17:00PM - 19:00PM',
      'venue': 'JIHC\nAct Hall',
      'imagePath': 'assets/DSC00297.JPG',
      'price': 1000,
    },
    {
      'title': 'JIHC Voice - 2025',
      'date': '15 May, 2025',
      'time': 'Monday, 19:00PM - 21:00PM',
      'venue': 'JIHC\nAct Hall',
      'imagePath': 'assets/DSC03364.JPG',
      'price': 1000,
    },
    {
      'title': 'KVN - 2025',
      'date': '20 May, 2025',
      'time': 'Saturday, 18:00PM - 20:00PM',
      'venue': 'JIHC\nAct Hall',
      'imagePath': 'assets/DSC00297.JPG',
      'price': 750,
    },
  ];
  
  // Filtered events based on search
  List<Map<String, dynamic>> get _filteredEvents {
    if (_searchQuery.isEmpty) {
      return _allEvents;
    }
    
    return _allEvents.where((event) {
      return event['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
             event['date'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
             event['venue'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
             event['time'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Events',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 24),
              _buildEventsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: Colors.grey[600]),
          hintText: 'Search events',
          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          suffixIcon: _searchQuery.isNotEmpty 
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  });
                },
              )
            : null,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildEventsList() {
    if (_filteredEvents.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.event_busy,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No events found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different search terms',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Events',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_filteredEvents.length != _allEvents.length)
              Text(
                '${_filteredEvents.length} found',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          children: _filteredEvents.map((event) {
            return Column(
              children: [
                EventListItem(
                  title: event['title'],
                  date: event['date'],
                  time: event['time'],
                  venue: event['venue'],
                  imagePath: event['imagePath'],
                  price: event['price'],
                ),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
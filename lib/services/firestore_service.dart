import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_3/services/auth_service.dart';
import 'dart:math';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Check if user is authenticated
  bool get isUserAuthenticated => _authService.currentUser != null;
  
  // Get current user
  User? get currentUser => _authService.currentUser;

  // Generate random ticket ID
  String generateTicketId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        8, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  // ========== YOUR ORIGINAL METHODS (KEPT EXACTLY AS THEY WERE) ==========

  // Create ticket order (your original method)
  Future<String> createTicketOrder({
    required String eventTitle,
    required String eventDate,
    required String eventTime,
    required String eventVenue,
    required String eventImage,
    required double ticketPrice,
    required int ticketCount,
    required double fees,
  }) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('Please sign in to purchase tickets');
      }

      final ticketId = generateTicketId();
      final orderData = {
        'ticketId': ticketId,
        'userId': user.uid,
        'userEmail': user.email,
        'userName': user.displayName ?? 'Unknown User',
        'eventTitle': eventTitle,
        'eventDate': eventDate,
        'eventTime': eventTime,
        'eventVenue': eventVenue,
        'eventImage': eventImage,
        'ticketPrice': ticketPrice,
        'ticketCount': ticketCount,
        'fees': fees,
        'totalAmount': (ticketPrice * ticketCount) + fees,
        'orderDate': FieldValue.serverTimestamp(),
        'status': 'confirmed',
        'qrCode': ticketId,
        'hasRated': false,
      };

      // Create a batch write for atomic operation
      WriteBatch batch = _firestore.batch();

      // Add to main tickets collection
      DocumentReference ticketRef = _firestore
          .collection('tickets')
          .doc(ticketId);
      batch.set(ticketRef, orderData);

      // Add to user's tickets subcollection
      DocumentReference userTicketRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tickets')
          .doc(ticketId);
      batch.set(userTicketRef, orderData);

      // Add to event's tickets subcollection
      String eventId = eventTitle.replaceAll(' ', '_').toLowerCase();
      DocumentReference eventTicketRef = _firestore
          .collection('events')
          .doc(eventId)
          .collection('tickets')
          .doc(ticketId);
      batch.set(eventTicketRef, orderData);

      // Update user's profile with ticket purchase info
      await _authService.updateUserData({
        'email': user.email,
        'displayName': user.displayName ?? 'Unknown User',
        'lastActivity': FieldValue.serverTimestamp(),
        'totalTickets': FieldValue.increment(ticketCount),
        'totalSpent': FieldValue.increment((ticketPrice * ticketCount) + fees),
      });

      // Commit the batch
      await batch.commit();

      return ticketId;
    } catch (e) {
      throw Exception('Failed to create ticket order: $e');
    }
  }

  // Get user's tickets
  Stream<QuerySnapshot> getUserTickets() {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tickets')
        .orderBy('orderDate', descending: true)
        .snapshots();
  }

  // Get ticket count for navigation bar
  Stream<int> getTicketCount() {
    final user = _authService.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tickets')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get specific ticket details
  Future<DocumentSnapshot> getTicketDetails(String ticketId) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    return await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tickets')
        .doc(ticketId)
        .get();
  }

  // Validate ticket (for event organizers)
  Future<Map<String, dynamic>?> validateTicket(String ticketId) async {
    try {
      DocumentSnapshot ticketDoc = await _firestore
          .collection('tickets')
          .doc(ticketId)
          .get();

      if (ticketDoc.exists) {
        return ticketDoc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to validate ticket: $e');
    }
  }

  // Get all events
  Stream<QuerySnapshot> getAllEvents() {
    return _firestore
        .collection('events')
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    return await _authService.getUserData();
  }

  // Sign out user
  Future<void> signOut() async {
    await _authService.signOut();
  }

  // Check if user has tickets for a specific event
  Future<bool> hasTicketForEvent(String eventTitle) async {
    final user = _authService.currentUser;
    if (user == null) return false;

    try {
      QuerySnapshot tickets = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tickets')
          .where('eventTitle', isEqualTo: eventTitle)
          .limit(1)
          .get();

      return tickets.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get user's ticket for a specific event
  Future<DocumentSnapshot?> getUserTicketForEvent(String eventTitle) async {
    final user = _authService.currentUser;
    if (user == null) return null;

    try {
      QuerySnapshot tickets = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tickets')
          .where('eventTitle', isEqualTo: eventTitle)
          .limit(1)
          .get();

      if (tickets.docs.isNotEmpty) {
        return tickets.docs.first;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ========== NEW METHODS FOR ENHANCED FEATURES ==========

  // Rate an event
  Future<void> rateEvent({
    required String ticketId,
    required String eventId,
    required double rating,
  }) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create a batch write for atomic operation
      WriteBatch batch = _firestore.batch();

      // Update user's ticket with rating
      DocumentReference userTicketRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tickets')
          .doc(ticketId);
      batch.update(userTicketRef, {
        'rating': rating,
        'hasRated': true,
        'ratedAt': FieldValue.serverTimestamp(),
      });

      // Update main ticket with rating
      DocumentReference ticketRef = _firestore
          .collection('tickets')
          .doc(ticketId);
      batch.update(ticketRef, {
        'rating': rating,
        'hasRated': true,
        'ratedAt': FieldValue.serverTimestamp(),
      });

      // Update event's ticket with rating
      DocumentReference eventTicketRef = _firestore
          .collection('events')
          .doc(eventId)
          .collection('tickets')
          .doc(ticketId);
      batch.update(eventTicketRef, {
        'rating': rating,
        'hasRated': true,
        'ratedAt': FieldValue.serverTimestamp(),
      });

      // Update event's average rating
      DocumentReference eventRef = _firestore
          .collection('events')
          .doc(eventId);
      
      // Get current event data
      DocumentSnapshot eventDoc = await eventRef.get();
      if (eventDoc.exists) {
        Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;
        
        int totalRatings = eventData['totalRatings'] ?? 0;
        double currentAvgRating = eventData['averageRating'] ?? 0.0;
        
        // Calculate new average rating
        double newAvgRating;
        if (totalRatings == 0) {
          newAvgRating = rating;
        } else {
          double totalRatingSum = currentAvgRating * totalRatings;
          newAvgRating = (totalRatingSum + rating) / (totalRatings + 1);
        }
        
        batch.update(eventRef, {
          'totalRatings': FieldValue.increment(1),
          'averageRating': newAvgRating,
          'lastRated': FieldValue.serverTimestamp(),
        });
      }

      // Commit the batch
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to rate event: $e');
    }
  }

  // Get popular events (CORRECTED - no problematic query)
  Stream<QuerySnapshot> getPopularEvents() {
    return _firestore
        .collection('events')
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  // Get event capacity info
  Future<Map<String, dynamic>> getEventCapacity(String eventId) async {
    try {
      DocumentSnapshot eventDoc = await _firestore
          .collection('events')
          .doc(eventId)
          .get();
      
      if (!eventDoc.exists) {
        return {
          'capacity': 100,
          'soldTickets': 0,
          'availableTickets': 100,
          'isSoldOut': false,
        };
      }
      
      Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;
      int capacity = eventData['capacity'] ?? 100;
      int soldTickets = eventData['soldTickets'] ?? 0;
      int availableTickets = capacity - soldTickets;
      
      return {
        'capacity': capacity,
        'soldTickets': soldTickets,
        'availableTickets': availableTickets,
        'isSoldOut': availableTickets <= 0,
      };
    } catch (e) {
      return {
        'capacity': 100,
        'soldTickets': 0,
        'availableTickets': 100,
        'isSoldOut': false,
      };
    }
  }

  // Create ticket order with seat selection (for future seat feature)
  Future<String> createTicketOrderWithSeats({
    required String eventTitle,
    required String eventDate,
    required String eventTime,
    required String eventVenue,
    required String eventImage,
    required double ticketPrice,
    required int ticketCount,
    required double fees,
    required List<String> selectedSeats,
    required List<Map<String, dynamic>> seatDetails,
  }) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('Please sign in to purchase tickets');
      }

      final ticketId = generateTicketId();
      final orderData = {
        'ticketId': ticketId,
        'userId': user.uid,
        'userEmail': user.email,
        'userName': user.displayName ?? 'Unknown User',
        'eventTitle': eventTitle,
        'eventDate': eventDate,
        'eventTime': eventTime,
        'eventVenue': eventVenue,
        'eventImage': eventImage,
        'ticketPrice': ticketPrice,
        'ticketCount': ticketCount,
        'fees': fees,
        'totalAmount': ticketPrice + fees,
        'selectedSeats': selectedSeats,
        'seatDetails': seatDetails,
        'orderDate': FieldValue.serverTimestamp(),
        'status': 'confirmed',
        'qrCode': ticketId,
        'hasRated': false,
      };

      // Create a batch write for atomic operation
      WriteBatch batch = _firestore.batch();

      // Add to main tickets collection
      DocumentReference ticketRef = _firestore
          .collection('tickets')
          .doc(ticketId);
      batch.set(ticketRef, orderData);

      // Add to user's tickets subcollection
      DocumentReference userTicketRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tickets')
          .doc(ticketId);
      batch.set(userTicketRef, orderData);

      // Add to event's tickets subcollection
      String eventId = eventTitle.replaceAll(' ', '_').toLowerCase();
      DocumentReference eventTicketRef = _firestore
          .collection('events')
          .doc(eventId)
          .collection('tickets')
          .doc(ticketId);
      batch.set(eventTicketRef, orderData);

      // Update user's profile
      await _authService.updateUserData({
        'email': user.email,
        'displayName': user.displayName ?? 'Unknown User',
        'lastActivity': FieldValue.serverTimestamp(),
        'totalTickets': FieldValue.increment(ticketCount),
        'totalSpent': FieldValue.increment(ticketPrice + fees),
      });

      // Commit the batch
      await batch.commit();

      return ticketId;
    } catch (e) {
      throw Exception('Failed to create ticket order: $e');
    }
  }
}
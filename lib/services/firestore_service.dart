import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_3/services/auth_service.dart';
import 'dart:math';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  bool get isUserAuthenticated => _authService.currentUser != null;
  
  User? get currentUser => _authService.currentUser;

  String generateTicketId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        8, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }


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

      WriteBatch batch = _firestore.batch();

      DocumentReference ticketRef = _firestore
          .collection('tickets')
          .doc(ticketId);
      batch.set(ticketRef, orderData);

      DocumentReference userTicketRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tickets')
          .doc(ticketId);
      batch.set(userTicketRef, orderData);

      String eventId = eventTitle.replaceAll(' ', '_').toLowerCase();
      DocumentReference eventTicketRef = _firestore
          .collection('events')
          .doc(eventId)
          .collection('tickets')
          .doc(ticketId);
      batch.set(eventTicketRef, orderData);

      await _authService.updateUserData({
        'email': user.email,
        'displayName': user.displayName ?? 'Unknown User',
        'lastActivity': FieldValue.serverTimestamp(),
        'totalTickets': FieldValue.increment(ticketCount),
        'totalSpent': FieldValue.increment((ticketPrice * ticketCount) + fees),
      });

      await batch.commit();

      return ticketId;
    } catch (e) {
      throw Exception('Failed to create ticket order: $e');
    }
  }

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

  Stream<QuerySnapshot> getAllEvents() {
    return _firestore
        .collection('events')
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    return await _authService.getUserData();
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

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

      DocumentReference eventRef = _firestore
          .collection('events')
          .doc(eventId);
      
      DocumentSnapshot eventDoc = await eventRef.get();
      if (eventDoc.exists) {
        Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;
        
        int totalRatings = eventData['totalRatings'] ?? 0;
        double currentAvgRating = eventData['averageRating'] ?? 0.0;
        
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

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to rate event: $e');
    }
  }

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

  
      WriteBatch batch = _firestore.batch();

      DocumentReference ticketRef = _firestore
          .collection('tickets')
          .doc(ticketId);
      batch.set(ticketRef, orderData);

      DocumentReference userTicketRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tickets')
          .doc(ticketId);
      batch.set(userTicketRef, orderData);

      String eventId = eventTitle.replaceAll(' ', '_').toLowerCase();
      DocumentReference eventTicketRef = _firestore
          .collection('events')
          .doc(eventId)
          .collection('tickets')
          .doc(ticketId);
      batch.set(eventTicketRef, orderData);

      await _authService.updateUserData({
        'email': user.email,
        'displayName': user.displayName ?? 'Unknown User',
        'lastActivity': FieldValue.serverTimestamp(),
        'totalTickets': FieldValue.increment(ticketCount),
        'totalSpent': FieldValue.increment(ticketPrice + fees),
      });

      await batch.commit();

      return ticketId;
    } catch (e) {
      throw Exception('Failed to create ticket order: $e');
    }
  }
}
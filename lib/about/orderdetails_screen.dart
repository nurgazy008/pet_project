import 'package:flutter/material.dart';

/// Screen that displays order details for event ticket purchases
/// and allows users to complete their order.
class OrderDetailsScreen extends StatelessWidget {
  final String eventTitle;
  final String eventDate;
  final String eventTime;
  final String eventVenue;
  final String eventImage;
  final double ticketPrice;
  final int ticketCount;
  final double fees;
  
  const OrderDetailsScreen({
    super.key,
    required this.eventTitle,
    required this.eventDate,
    required this.eventTime,
    required this.eventVenue,
    required this.eventImage,
    required this.ticketPrice,
    required this.ticketCount,
    required this.fees,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate totals
    final double subtotal = ticketPrice * ticketCount;
    final double total = subtotal + fees; // Fixed: total should be subtotal + fees
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        title: const Text(
          'Order Details',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEventCard(),
              const SizedBox(height: 20),
              _buildOrderSummary(subtotal, total),
              const SizedBox(height: 20),
              _buildPaymentMethod(),
              const SizedBox(height: 30),
              _buildCheckoutButton(total),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard() {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                eventImage,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$eventDate • $eventTime",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    eventTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        eventVenue,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.bookmark_border),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(double subtotal, double total) {
    // Format currency to match the image (e.g., "2000KZT")
    String formatCurrency(double amount) {
      return "${amount.toInt()}KZT";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Summary',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${ticketCount}x Ticket Price',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              formatCurrency(ticketPrice * ticketCount),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Subtotal',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              formatCurrency(subtotal),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Fees',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              formatCurrency(fees),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              formatCurrency(total),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethod() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildPaymentOption(
          icon: Image.asset(
            'assets/mastercard.png',
            width: 32,
            height: 32,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                ),
                child: const Center(
                  child: Text('MC', style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
              );
            },
          ),
          label: 'Credit /Debit Card',
          isSelected: false,
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          icon: Image.asset(
            'assets/paypal.png',
            width: 32,
            height: 32,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent,
                ),
                child: const Center(
                  child: Text('PP', style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
              );
            },
          ),
          label: 'Paypal',
          isSelected: true,
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          icon: Image.asset(
            'assets/googlepay.png',
            width: 32,
            height: 32,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.green, Colors.yellow, Colors.red],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Text('G', style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
              );
            },
          ),
          label: 'Google pay',
          isSelected: false,
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required Widget icon,
    required String label,
    required bool isSelected,
  }) {
    return Row(
      children: [
        icon,
        const SizedBox(width: 16),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
        const Spacer(),
        if (isSelected)
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue[600],
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            ),
          ),
      ],
    );
  }

  Widget _buildCheckoutButton(double total) {
    // Format currency to match the image (e.g., "1500KZT")
    String formatCurrency(double amount) {
      return "${amount.toInt()}KZT";
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Price',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  formatCurrency(total),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text(
                    'Place order',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: 60,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}
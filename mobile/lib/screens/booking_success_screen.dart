import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BookingSuccessScreen extends StatelessWidget {
  final Map<String, dynamic>? bookingDetails;

  const BookingSuccessScreen({super.key, this.bookingDetails});

  @override
  Widget build(BuildContext context) {
    // Attempt to get bookingDetails from GoRouter state if not passed directly (e.g. deep linking)
    final details =
        bookingDetails ??
        (GoRouterState.of(context).extra as Map<String, dynamic>?);

    if (details == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Error')),
        body: const Center(
          child: Text('Booking details not found. Please contact support.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Successful!'),
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 100,
              ),
              const SizedBox(height: 20),
              Text(
                'Thank You For Your Booking!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Your room has been booked successfully.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              if (details['bookingConfirmationCode'] != null)
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Your Booking Confirmation Code:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          details['bookingConfirmationCode'].toString(),
                          style: Theme.of(
                            context,
                          ).textTheme.headlineMedium?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text('Check-in: ${details['checkInDate'] ?? 'N/A'}'),
                        Text('Check-out: ${details['checkOutDate'] ?? 'N/A'}'),
                        Text('Guest: ${details['guestFullName'] ?? 'N/A'}'),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  context.go('/'); // Navigate to home screen
                },
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mobile/utils/api_functions.dart' as api;
// Potentially import a widget to display booking details if creating a shared one

class FindBookingScreen extends StatefulWidget {
  const FindBookingScreen({super.key});

  @override
  State<FindBookingScreen> createState() => _FindBookingScreenState();
}

class _FindBookingScreenState extends State<FindBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _confirmationCodeController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _bookingDetails;
  String? _errorMessage;

  Future<void> _findBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
      _bookingDetails = null; // Clear previous results
      _errorMessage = null;
    });

    try {
      final details = await api.getBookingByConfirmationCode(
        _confirmationCodeController.text,
      );
      if (mounted) {
        setState(() {
          _bookingDetails = details;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.toString().replaceFirst(
            "Exception: ",
            "",
          ); // Clean up common exception prefix
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _confirmationCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find My Booking')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Enter your booking confirmation code to find your reservation.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _confirmationCodeController,
                decoration: const InputDecoration(
                  labelText: 'Confirmation Code',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your confirmation code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _findBooking,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Find Booking'),
                ),
              const SizedBox(height: 30),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              if (_bookingDetails != null)
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking Details:',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Divider(),
                        Text(
                          'Confirmation Code: ${_bookingDetails!['bookingConfirmationCode'] ?? 'N/A'}',
                        ),
                        Text(
                          'Room ID: ${_bookingDetails!['room']['id'] ?? 'N/A'}',
                        ), // Assuming room details are nested
                        Text(
                          'Room Type: ${_bookingDetails!['room']['roomType'] ?? 'N/A'}',
                        ),
                        Text(
                          'Check-in Date: ${_bookingDetails!['checkInDate'] ?? 'N/A'}',
                        ),
                        Text(
                          'Check-out Date: ${_bookingDetails!['checkOutDate'] ?? 'N/A'}',
                        ),
                        Text(
                          'Guest Name: ${_bookingDetails!['guestFullName'] ?? 'N/A'}',
                        ),
                        Text(
                          'Guest Email: ${_bookingDetails!['guestEmail'] ?? 'N/A'}',
                        ),
                        // Add more details as needed
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

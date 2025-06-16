import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:mobile/utils/api_functions.dart' as api;
import 'package:provider/provider.dart';
import 'package:mobile/providers/auth_provider.dart';

class CheckoutScreen extends StatefulWidget {
  final String roomId;
  const CheckoutScreen({super.key, required this.roomId});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  final _guestFullNameController = TextEditingController();
  final _guestEmailController = TextEditingController();
  // final _numberOfAdultsController = TextEditingController(text: "1"); // Default to 1
  // final _numberOfChildrenController = TextEditingController(text: "0"); // Default to 0

  bool _isLoading = false;
  Map<String, dynamic>? _roomDetails;

  @override
  void initState() {
    super.initState();
    _fetchRoomDetails();
    // Pre-fill email if user is logged in
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn && authProvider.userId != null) {
      // Assuming we can fetch user email via getUserProfile or it's stored in AuthProvider
      // For now, let's assume it might be part of a user object in AuthProvider
      // _guestEmailController.text = authProvider.userEmail ?? '';
    }
  }

  Future<void> _fetchRoomDetails() async {
    setState(() => _isLoading = true);
    try {
      final room = await api.getRoomById(widget.roomId);
      if (mounted) {
        setState(() {
          _roomDetails = room;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load room details: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isCheckIn ? _checkInDate : _checkOutDate) ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
          // If check-out date is before check-in date, reset check-out date
          if (_checkOutDate != null && _checkOutDate!.isBefore(_checkInDate!)) {
            _checkOutDate = null;
          }
        } else {
          _checkOutDate = picked;
        }
      });
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_checkInDate == null || _checkOutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select check-in and check-out dates.'),
        ),
      );
      return;
    }
    if (_checkOutDate!.isBefore(_checkInDate!) ||
        _checkOutDate!.isAtSameMomentAs(_checkInDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-out date must be after check-in date.'),
        ),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    final bookingData = {
      "checkInDate": DateFormat('yyyy-MM-dd').format(_checkInDate!),
      "checkOutDate": DateFormat('yyyy-MM-dd').format(_checkOutDate!),
      "guestFullName": _guestFullNameController.text,
      "guestEmail": _guestEmailController.text,
      // "numOfAdults": _numberOfAdultsController.text,
      // "numOfChildren": _numberOfChildrenController.text,
    };

    try {
      final response = await api.bookRoom(widget.roomId, bookingData);
      if (mounted) {
        if (response != null &&
            response.containsKey('bookingConfirmationCode')) {
          // Navigate to booking success screen
          context.go('/booking-success', extra: response);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response?['message']?.toString() ??
                    'Failed to book room. Please try again.',
              ),
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: ${error.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _guestFullNameController.dispose();
    _guestEmailController.dispose();
    // _numberOfAdultsController.dispose();
    // _numberOfChildrenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Pre-fill email if user is logged in and email controller is empty
    if (authProvider.isLoggedIn && _guestEmailController.text.isEmpty) {
      // This is a simplistic way. A better approach would be to fetch user profile
      // and get the email from there, or have it available in AuthProvider.
      // For now, if we had a user object in AuthProvider:
      // _guestEmailController.text = authProvider.user?.email ?? '';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _roomDetails != null
              ? 'Book Room: ${_roomDetails!['roomType']}'
              : 'Book Room',
        ),
      ),
      body:
          _isLoading && _roomDetails == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (_roomDetails != null) ...[
                        Text(
                          'Room Type: ${_roomDetails!['roomType']}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          'Price: \$${_roomDetails!['roomPrice']}/night',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _guestFullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                        ),
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Please enter your full name'
                                    : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _guestEmailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              !value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _checkInDate == null
                                  ? 'Select Check-in Date'
                                  : 'Check-in: ${DateFormat.yMd().format(_checkInDate!)}',
                            ),
                          ),
                          TextButton(
                            onPressed: () => _selectDate(context, true),
                            child: const Text('Select'),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _checkOutDate == null
                                  ? 'Select Check-out Date'
                                  : 'Check-out: ${DateFormat.yMd().format(_checkOutDate!)}',
                            ),
                          ),
                          TextButton(
                            onPressed: () => _selectDate(context, false),
                            child: const Text('Select'),
                          ),
                        ],
                      ),
                      // Add fields for number of adults and children if needed
                      const SizedBox(height: 30),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        ElevatedButton(
                          onPressed: _submitBooking,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Confirm Booking'),
                        ),
                    ],
                  ),
                ),
              ),
    );
  }
}

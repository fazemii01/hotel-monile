import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/utils/api_functions.dart'
    as api; // For fetching profile details

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _userBookings = [];
  bool _isLoadingProfile = true;
  bool _isLoadingBookings = true;
  String? _profileErrorMessage;
  String? _bookingsErrorMessage;

  Future<void> _fetchUserProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn && authProvider.userId != null) {
      try {
        final profile = await api.getUserProfile(authProvider.userId!);
        if (mounted) {
          setState(() {
            _userProfile = profile;
            _isLoadingProfile = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _profileErrorMessage = "Failed to load profile: ${e.toString()}";
            _isLoadingProfile = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _profileErrorMessage = "User not logged in or user ID is missing.";
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _fetchUserBookings() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn && authProvider.userId != null) {
      try {
        final bookings = await api.getBookingsByUserId(authProvider.userId!);
        if (mounted) {
          setState(() {
            _userBookings = bookings;
            _isLoadingBookings = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _bookingsErrorMessage = "Failed to load bookings: ${e.toString()}";
            _isLoadingBookings = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _bookingsErrorMessage =
              "User not logged in or user ID is missing to fetch bookings.";
          _isLoadingBookings = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchUserBookings(); // Fetch bookings when screen initializes
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              context.go('/');
            },
          ),
        ],
      ),
      body:
          _isLoadingProfile || _isLoadingBookings
              ? const Center(child: CircularProgressIndicator())
              : _profileErrorMessage != null
              ? Center(
                child: Text(
                  _profileErrorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
              : _userProfile != null
              ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Name: ${_userProfile!['firstName'] ?? ''} ${_userProfile!['lastName'] ?? ''}',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Email: ${_userProfile!['email'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'User ID: ${authProvider.userId ?? "N/A"}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    // Add more profile details here as needed
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to edit profile or other actions
                      },
                      child: const Text('Edit Profile (Not Implemented)'),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'My Bookings:',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    _isLoadingBookings
                        ? const Center(child: CircularProgressIndicator())
                        : _bookingsErrorMessage != null
                        ? Text(
                          _bookingsErrorMessage!,
                          style: const TextStyle(color: Colors.red),
                        )
                        : _userBookings.isEmpty
                        ? const Text('You have no bookings yet.')
                        : Expanded(
                          // Use Expanded if Column is inside another Column/flex widget
                          child: ListView.builder(
                            shrinkWrap:
                                true, // Important if ListView is in a Column
                            itemCount: _userBookings.length,
                            itemBuilder: (context, index) {
                              final booking = _userBookings[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: ListTile(
                                  title: Text(
                                    'Room Type: ${booking['room']?['roomType'] ?? 'N/A'}',
                                  ),
                                  subtitle: Text(
                                    'Confirmation: ${booking['bookingConfirmationCode']}\n'
                                    'Check-in: ${booking['checkInDate']} - Check-out: ${booking['checkOutDate']}',
                                  ),
                                  // Add a button to cancel booking if needed
                                  // trailing: IconButton(
                                  //   icon: Icon(Icons.cancel, color: Colors.red),
                                  //   onPressed: () async {
                                  //     // Implement cancel booking
                                  //   },
                                  // ),
                                ),
                              );
                            },
                          ),
                        ),
                  ],
                ),
              )
              : const Center(child: Text('No profile data found.')),
    );
  }
}

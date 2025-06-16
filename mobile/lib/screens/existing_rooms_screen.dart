import 'package:flutter/material.dart';
import 'package:mobile/utils/api_functions.dart' as api;
import 'package:provider/provider.dart';
import 'package:mobile/providers/auth_provider.dart'; // To ensure user is logged in
// import 'package:go_router/go_router.dart'; // For navigation to edit room, etc.

class ExistingRoomsScreen extends StatefulWidget {
  const ExistingRoomsScreen({super.key});

  @override
  State<ExistingRoomsScreen> createState() => _ExistingRoomsScreenState();
}

class _ExistingRoomsScreenState extends State<ExistingRoomsScreen> {
  List<Map<String, dynamic>> _rooms = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchExistingRooms();
  }

  Future<void> _fetchExistingRooms() async {
    // Assuming this is a protected route, check login status
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      if (mounted) {
        setState(() {
          _errorMessage = "Please login to view existing rooms.";
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final rooms = await api.getAllRooms();
      if (mounted) {
        setState(() {
          _rooms = rooms;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load rooms: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteRoom(String roomId) async {
    setState(() => _isLoading = true);
    try {
      await api.deleteRoom(roomId);
      // Refresh the list of rooms
      _fetchExistingRooms();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Room deleted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete room: ${e.toString()}')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Rooms')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Rooms')),
        body: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    if (_rooms.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Rooms')),
        body: const Center(
          child: Text('No rooms found.', style: TextStyle(fontSize: 18)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Rooms')),
      body: ListView.builder(
        itemCount: _rooms.length,
        itemBuilder: (context, index) {
          final room = _rooms[index];
          final String photoUrl =
              room['photo'] != null
                  ? '${api.baseUrl}/rooms/room/photo/${room['id']}'
                  : ''; // Construct direct URL if backend serves it this way or handle base64

          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (photoUrl.isNotEmpty)
                    Image.network(
                      photoUrl, // This assumes your backend serves images directly via URL.
                      // If photo is base64, use Image.memory(base64Decode(room['photo']))
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox(
                          height: 150,
                          child: Center(child: Text('Image not available')),
                        );
                      },
                    )
                  else
                    const SizedBox(
                      height: 150,
                      child: Center(child: Text('No Image')),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Room Type: ${room['roomType'] ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Price: \$${room['roomPrice']?.toString() ?? 'N/A'} per night',
                    style: const TextStyle(fontSize: 14),
                  ),
                  // Add more details as needed
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          // Navigate to EditRoomScreen
                          // context.go('/edit-room/${room['id']}');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Edit functionality not yet implemented.',
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteRoom(room['id'].toString()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

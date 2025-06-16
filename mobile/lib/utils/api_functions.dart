import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io'; // For File type if handling actual file objects for photo

const String baseUrl = "http://localhost:9192";

Future<Map<String, String>> getHeaders() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token != null && token.isNotEmpty) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }
  return {'Content-Type': 'application/json'};
}

Future<Map<String, String>> getHeadersWithFormData() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token != null && token.isNotEmpty) {
    return {
      'Authorization': 'Bearer $token',
      // Content-Type for multipart/form-data is set by http.MultipartRequest
    };
  }
  return {};
}

// This function login a registered user
Future<Map<String, dynamic>?> loginUser(String email, String password) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await getHeaders(),
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      // Assuming the token is in a field named 'token' or 'jwt' in the response
      // Adjust 'tokenFieldName' based on your actual backend response
      String tokenFieldName = 'token';
      if (data.containsKey('jwt')) {
        tokenFieldName = 'jwt';
      } else if (data.containsKey('accessToken')) {
        tokenFieldName = 'accessToken';
      }

      if (data.containsKey(tokenFieldName)) {
        await prefs.setString('token', data[tokenFieldName]);
      }
      if (data.containsKey('userId')) {
        await prefs.setString('userId', data['userId'].toString());
      }
      return data;
    } else {
      print('Login failed: ${response.statusCode} ${response.body}');
      return null;
    }
  } catch (e) {
    print('Error during login: $e');
    return null;
  }
}

// This function adds a new room to the database
// For 'photo', you'll typically pass the path to the image file in Flutter
// or the bytes of the image. Here, we assume 'photoPath' is a String.
Future<bool> addRoom(
  String photoPath,
  String roomType,
  double roomPrice,
) async {
  try {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/rooms/add/new-room'),
    );
    request.headers.addAll(await getHeadersWithFormData());

    request.fields['roomType'] = roomType;
    request.fields['roomPrice'] = roomPrice.toString();

    if (photoPath.isNotEmpty) {
      // If photoPath is a local file path
      File imageFile = File(photoPath);
      if (await imageFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath('photo', imageFile.path),
        );
      } else {
        print("Photo file does not exist at path: $photoPath");
        // Optionally handle this case, e.g., by not sending the photo or returning false
      }
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      return true;
    } else {
      print('Failed to add room: ${response.statusCode} ${responseBody}');
      return false;
    }
  } catch (e) {
    print('Error adding room: $e');
    return false;
  }
}

// This function gets all room types from the database
Future<List<String>> getRoomTypes() async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/rooms/room/types'));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((type) => type.toString()).toList();
    } else {
      print(
        'Error fetching room types: ${response.statusCode} ${response.body}',
      );
      throw Exception("Error fetching room types");
    }
  } catch (e) {
    print('Error fetching room types: $e');
    throw Exception("Error fetching room types: $e");
  }
}

// This function gets all rooms from the database
Future<List<Map<String, dynamic>>> getAllRooms() async {
  try {
    final result = await http.get(Uri.parse('$baseUrl/rooms/all-rooms'));
    if (result.statusCode == 200) {
      List<dynamic> data = jsonDecode(result.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      print('Error fetching rooms: ${result.statusCode} ${result.body}');
      throw Exception("Error fetching rooms");
    }
  } catch (error) {
    print('Error fetching rooms: $error');
    throw Exception("Error fetching rooms: $error");
  }
}

// This function deletes a room by the Id
Future<String> deleteRoom(String roomId) async {
  try {
    final result = await http.delete(
      Uri.parse('$baseUrl/rooms/delete/room/$roomId'),
      headers: await getHeaders(),
    );
    if (result.statusCode == 200 || result.statusCode == 204) {
      // 204 No Content is also a success
      // Assuming the backend returns a confirmation message or just success status
      return result.body.isNotEmpty ? result.body : "Room deleted successfully";
    } else {
      print('Error deleting room: ${result.statusCode} ${result.body}');
      throw Exception('Error deleting room ${result.body}');
    }
  } catch (error) {
    print('Error deleting room: $error');
    throw Exception('Error deleting room: $error');
  }
}

// This function updates a room
// roomData should be a Map<String, dynamic> containing roomType, roomPrice, and photoPath (optional)
Future<Map<String, dynamic>?> updateRoom(
  String roomId,
  Map<String, dynamic> roomData,
) async {
  try {
    var request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/rooms/update/$roomId'),
    );
    request.headers.addAll(await getHeadersWithFormData());

    if (roomData.containsKey('roomType')) {
      request.fields['roomType'] = roomData['roomType'] as String;
    }
    if (roomData.containsKey('roomPrice')) {
      request.fields['roomPrice'] = roomData['roomPrice'].toString();
    }

    if (roomData.containsKey('photoPath') &&
        (roomData['photoPath'] as String).isNotEmpty) {
      String photoPath = roomData['photoPath'] as String;
      File imageFile = File(photoPath);
      if (await imageFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath('photo', imageFile.path),
        );
      } else {
        print("Photo file for update does not exist at path: $photoPath");
      }
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(responseBody);
    } else {
      print('Failed to update room: ${response.statusCode} $responseBody');
      return null;
    }
  } catch (e) {
    print('Error updating room: $e');
    return null;
  }
}

// This function gets a room by the id
Future<Map<String, dynamic>?> getRoomById(String roomId) async {
  try {
    final result = await http.get(Uri.parse('$baseUrl/rooms/room/$roomId'));
    if (result.statusCode == 200) {
      return jsonDecode(result.body);
    } else {
      print('Error fetching room by ID: ${result.statusCode} ${result.body}');
      throw Exception('Error fetching room ${result.body}');
    }
  } catch (error) {
    print('Error fetching room by ID: $error');
    throw Exception('Error fetching room: $error');
  }
}

// This function saves a new booking to the database
// 'booking' should be a Map<String, dynamic> representing the booking details
// e.g., {'checkInDate': 'YYYY-MM-DD', 'checkOutDate': 'YYYY-MM-DD', 'guestFullName': 'John Doe', ...}
Future<Map<String, dynamic>?> bookRoom(
  String roomId,
  Map<String, dynamic> booking,
) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/bookings/room/$roomId/booking'),
      headers:
          await getHeaders(), // Assuming booking doesn't require JWT for now, adjust if needed
      body: jsonEncode(booking),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      print('Error booking room: ${response.statusCode} ${response.body}');
      throw Exception(
        jsonDecode(response.body)['message'] ?? 'Error booking room',
      );
    }
  } catch (error) {
    print('Error booking room: $error');
    throw Exception('Error booking room: $error');
  }
}

// This function gets all bookings from the database
Future<List<Map<String, dynamic>>> getAllBookings() async {
  try {
    final result = await http.get(
      Uri.parse('$baseUrl/bookings/all-bookings'),
      headers: await getHeaders(),
    );
    if (result.statusCode == 200) {
      List<dynamic> data = jsonDecode(result.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      print('Error fetching bookings: ${result.statusCode} ${result.body}');
      throw Exception('Error fetching bookings');
    }
  } catch (error) {
    print('Error fetching bookings: $error');
    throw Exception('Error fetching bookings: $error');
  }
}

// This function gets booking by the confirmation code
Future<Map<String, dynamic>?> getBookingByConfirmationCode(
  String confirmationCode,
) async {
  try {
    final result = await http.get(
      Uri.parse('$baseUrl/bookings/confirmation/$confirmationCode'),
    );
    if (result.statusCode == 200) {
      return jsonDecode(result.body);
    } else {
      print('Error finding booking: ${result.statusCode} ${result.body}');
      throw Exception(
        jsonDecode(result.body)['message'] ?? 'Error finding booking',
      );
    }
  } catch (error) {
    print('Error finding booking: $error');
    throw Exception('Error finding booking: $error');
  }
}

// This function cancels a user booking
Future<String> cancelBooking(String bookingId) async {
  try {
    final result = await http.delete(
      Uri.parse('$baseUrl/bookings/booking/$bookingId/delete'),
      headers: await getHeaders(), // Assuming cancellation requires auth
    );
    if (result.statusCode == 200 || result.statusCode == 204) {
      return result.body.isNotEmpty
          ? result.body
          : "Booking cancelled successfully";
    } else {
      print('Error cancelling booking: ${result.statusCode} ${result.body}');
      throw Exception('Error cancelling booking: ${result.body}');
    }
  } catch (error) {
    print('Error cancelling booking: $error');
    throw Exception('Error cancelling booking: $error');
  }
}

// This function gets all available rooms from the database with a given date and a room type
Future<List<Map<String, dynamic>>> getAvailableRooms(
  String checkInDate,
  String checkOutDate,
  String roomType,
) async {
  try {
    final result = await http.get(
      Uri.parse(
        '$baseUrl/rooms/available-rooms?checkInDate=$checkInDate&checkOutDate=$checkOutDate&roomType=$roomType',
      ),
    );
    if (result.statusCode == 200) {
      List<dynamic> data = jsonDecode(result.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      print(
        'Error fetching available rooms: ${result.statusCode} ${result.body}',
      );
      throw Exception("Error fetching available rooms");
    }
  } catch (error) {
    print('Error fetching available rooms: $error');
    throw Exception("Error fetching available rooms: $error");
  }
}

// This function registers a new user
// 'registration' should be a Map<String, dynamic> e.g., {'firstName': 'Test', 'lastName': 'User', 'email': 'test@example.com', 'password': 'password'}
Future<Map<String, dynamic>?> registerUser(
  Map<String, dynamic> registration,
) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register-user'),
      headers:
          await getHeaders(), // Content-Type is application/json by default from getHeaders
      body: jsonEncode(registration),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      print('User registration error: ${response.statusCode} ${response.body}');
      throw Exception(
        jsonDecode(response.body)['message'] ?? 'User registration error',
      );
    }
  } catch (error) {
    print('User registration error: $error');
    throw Exception('User registration error: $error');
  }
}

// This function gets the user profile
Future<Map<String, dynamic>?> getUserProfile(String userId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/users/profile/$userId'),
      headers: await getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print(
        'Error fetching user profile: ${response.statusCode} ${response.body}',
      );
      throw Exception('Error fetching user profile');
    }
  } catch (error) {
    print('Error fetching user profile: $error');
    throw error; // Rethrow to allow UI to handle
  }
}

// This function deletes a user
Future<String> deleteUser(String userId) async {
  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/delete/$userId'),
      headers: await getHeaders(),
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      return response.body.isNotEmpty
          ? response.body
          : "User deleted successfully";
    } else {
      print('Error deleting user: ${response.statusCode} ${response.body}');
      throw Exception(response.body);
    }
  } catch (error) {
    print('Error deleting user: $error');
    throw Exception('Error deleting user: $error');
  }
}

// This function gets a single user
Future<Map<String, dynamic>?> getUser(String userId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId'),
      headers: await getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Error fetching user: ${response.statusCode} ${response.body}');
      throw Exception('Error fetching user');
    }
  } catch (error) {
    print('Error fetching user: $error');
    throw error; // Rethrow
  }
}

// This function gets user bookings by the user id
Future<List<Map<String, dynamic>>> getBookingsByUserId(String userId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/bookings/user/$userId/bookings'),
      headers: await getHeaders(),
    );
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      print(
        'Error fetching user bookings: ${response.statusCode} ${response.body}',
      );
      throw Exception('Failed to fetch bookings');
    }
  } catch (error) {
    print('Error fetching user bookings: $error');
    throw Exception('Failed to fetch bookings: $error');
  }
}

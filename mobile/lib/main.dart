import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/screens/home_screen.dart';
import 'package:mobile/screens/login_screen.dart';
import 'package:mobile/screens/registration_screen.dart';
import 'package:mobile/screens/profile_screen.dart';
import 'package:mobile/screens/add_room_screen.dart';
import 'package:mobile/screens/existing_rooms_screen.dart';
import 'package:mobile/screens/room_listing_screen.dart';
import 'package:mobile/screens/checkout_screen.dart';
import 'package:mobile/screens/booking_success_screen.dart';
import 'package:mobile/screens/find_booking_screen.dart'; // Import FindBookingScreen

// GoRouter configuration
final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'login',
          builder: (BuildContext context, GoRouterState state) {
            return const LoginScreen();
          },
        ),
        GoRoute(
          path: 'register',
          builder: (BuildContext context, GoRouterState state) {
            return const RegistrationScreen();
          },
        ),
        GoRoute(
          path: 'profile',
          builder: (BuildContext context, GoRouterState state) {
            return const ProfileScreen(); // Placeholder
          },
          redirect: (BuildContext context, GoRouterState state) {
            final authProvider = Provider.of<AuthProvider>(
              context,
              listen: false,
            );
            if (!authProvider.isLoggedIn) {
              return '/login'; // Redirect to login if not authenticated
            }
            return null; // No redirect if authenticated
          },
        ),
        GoRoute(
          path: 'add-room',
          builder: (BuildContext context, GoRouterState state) {
            return const AddRoomScreen();
          },
          redirect: (BuildContext context, GoRouterState state) {
            final authProvider = Provider.of<AuthProvider>(
              context,
              listen: false,
            );
            if (!authProvider.isLoggedIn) {
              return '/login'; // Redirect to login if not authenticated
            }
            return null; // No redirect if authenticated
          },
        ),
        GoRoute(
          path: 'existing-rooms',
          builder: (BuildContext context, GoRouterState state) {
            return const ExistingRoomsScreen();
          },
          redirect: (BuildContext context, GoRouterState state) {
            final authProvider = Provider.of<AuthProvider>(
              context,
              listen: false,
            );
            if (!authProvider.isLoggedIn) {
              return '/login'; // Redirect to login if not authenticated
            }
            return null; // No redirect if authenticated
          },
        ),
        GoRoute(
          path: 'browse-all-rooms', // Publicly accessible
          builder: (BuildContext context, GoRouterState state) {
            return const RoomListingScreen();
          },
        ),
        GoRoute(
          path: 'book-room/:roomId',
          builder: (BuildContext context, GoRouterState state) {
            final roomId = state.pathParameters['roomId']!;
            return CheckoutScreen(roomId: roomId);
          },
          redirect: (BuildContext context, GoRouterState state) {
            final authProvider = Provider.of<AuthProvider>(
              context,
              listen: false,
            );
            if (!authProvider.isLoggedIn) {
              return '/login'; // Redirect to login if not authenticated
            }
            return null; // No redirect if authenticated
          },
        ),
        GoRoute(
          path: 'booking-success',
          builder: (BuildContext context, GoRouterState state) {
            // The 'extra' parameter from the previous route (CheckoutScreen)
            // will be available in state.extra
            return BookingSuccessScreen(
              bookingDetails: state.extra as Map<String, dynamic>?,
            );
          },
          // This route is typically navigated to after a successful booking,
          // so direct access might not need auth check if booking process itself is protected.
          // However, if sensitive info is displayed, consider adding redirect.
        ),
        GoRoute(
          path: 'find-booking', // Publicly accessible
          builder: (BuildContext context, GoRouterState state) {
            return const FindBookingScreen();
          },
        ),
        // Add other routes here later
      ],
    ),
  ],
  // Optional: Error page
  // errorBuilder: (context, state) => ErrorScreen(state.error),
);

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Hotel App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routerConfig: _router,
    );
  }
}

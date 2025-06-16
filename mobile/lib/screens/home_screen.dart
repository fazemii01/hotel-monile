import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to the Hotel App!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Login'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => context.go('/register'),
              child: const Text('Register'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => context.go('/browse-all-rooms'),
              child: const Text('Browse All Rooms'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => context.go('/find-booking'),
              child: const Text('Find My Booking'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).isLoggedIn) {
                  context.go('/profile');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please login to view profile.'),
                    ),
                  );
                  context.go('/login');
                }
              },
              child: const Text('View Profile (Protected)'),
            ),
            const SizedBox(height: 10),
            Consumer<AuthProvider>(
              // Use Consumer to react to login state changes
              builder: (context, auth, child) {
                if (auth.isLoggedIn) {
                  return ElevatedButton(
                    onPressed: () => context.go('/add-room'),
                    child: const Text('Add New Room'),
                  );
                }
                return const SizedBox.shrink(); // Return empty if not logged in
              },
            ),
            const SizedBox(height: 10),
            Consumer<AuthProvider>(
              builder: (context, auth, child) {
                if (auth.isLoggedIn) {
                  return ElevatedButton(
                    onPressed: () => context.go('/existing-rooms'),
                    child: const Text('Manage Existing Rooms'),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Empty state widget shown when there's no active navigation
class NavigationEmptyState extends StatelessWidget {
  final VoidCallback onBackToMap;

  const NavigationEmptyState({super.key, required this.onBackToMap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navigation')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.navigation_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No active navigation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start a route from the map page',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onBackToMap,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Map'),
            ),
          ],
        ),
      ),
    );
  }
}

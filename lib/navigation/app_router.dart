import 'package:flutter/material.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => const _PlaceholderScreen(title: 'Home Placeholder'),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const _PlaceholderScreen(title: '404 - Not Found'),
        );
    }
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: Text('Replace with real screen')), 
    );
  }
}



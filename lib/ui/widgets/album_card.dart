import 'package:flutter/material.dart';

class AlbumCard extends StatelessWidget {
  final String title;
  const AlbumCard({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(title),
      ),
    );
  }
}



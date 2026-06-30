import 'package:flutter/material.dart';

/// Small pill shown next to a track's title when it was released recently.
/// Centralized here so every song list (library, artist page, playlist,
/// home cards) renders "new" consistently instead of each screen rolling
/// its own badge.
class NewBadge extends StatelessWidget {
  final DateTime releaseDate;
  final int withinDays;

  const NewBadge({Key? key, required this.releaseDate, this.withinDays = 14}) : super(key: key);

  bool get isNew => DateTime.now().difference(releaseDate).inDays <= withinDays;

  @override
  Widget build(BuildContext context) {
    if (!isNew) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF3B30), Color(0xFFFF6B5B)]),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'NEW',
        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.4),
      ),
    );
  }
}

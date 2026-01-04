import 'package:flutter/material.dart';

class PlaybackControls extends StatelessWidget {
  const PlaybackControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.skip_previous),
        SizedBox(width: 16),
        Icon(Icons.play_arrow),
        SizedBox(width: 16),
        Icon(Icons.skip_next),
      ],
    );
  }
}



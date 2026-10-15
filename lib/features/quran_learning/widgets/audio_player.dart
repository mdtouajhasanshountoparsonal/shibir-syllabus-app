import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AudioPlayerWidget extends StatelessWidget {
  const AudioPlayerWidget({super.key, required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.accent, size: 42),
        ),
        const Expanded(
          child: Text('অডিও শোনো', style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }
}

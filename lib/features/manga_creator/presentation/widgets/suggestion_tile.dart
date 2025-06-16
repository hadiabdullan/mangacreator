import 'package:flutter/material.dart';

class SuggestionTile extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const SuggestionTile({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // <--- This is the build method
    return GestureDetector(
      // Using GestureDetector instead of InkWell for simpler example
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1), // Light background for the tile
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: color, width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Wrap content horizontally
          children: [
            Icon(icon, size: 18, color: color), // Small icon
            const SizedBox(width: 8.0),
            Flexible(
              // Allow text to wrap if it's too long
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  color: color,
                  fontWeight: FontWeight.w500, // Slightly bolder
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

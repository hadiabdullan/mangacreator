import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';

import '../../../../core/constants/app_constants.dart';

class EmptyStateView extends StatefulWidget {
  const EmptyStateView({super.key});

  @override
  State<EmptyStateView> createState() => _EmptyStateViewState();
}

class _EmptyStateViewState extends State<EmptyStateView> {
  Uint8List? _placeholderImageBytes;

  @override
  void initState() {
    super.initState();
    _loadPlaceholderImage();
  }

  // Asynchronously loads the placeholder image from the 'assets' folder.
  Future<void> _loadPlaceholderImage() async {
    try {
      final ByteData data = await rootBundle.load(
        AppConstants.placeholderMangaPanelPath,
      );
      if (mounted) {
        setState(() {
          _placeholderImageBytes = data.buffer.asUint8List();
        });
      }
      debugPrint('Placeholder image loaded successfully.');
    } catch (e) {
      debugPrint('Error loading placeholder image in EmptyStateView: $e');
      // Note: We don't show a dialog here, as it's a UI component.
      // Any error handling (like a snackbar) should be done in the parent screen.
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🌟 Welcome to AI Manga Studio! 🌟\n\n'
                'Type a concept below to generate your first manga panel. '
                'AI will then provide dynamic suggestions to continue your story!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 30),
              if (_placeholderImageBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Image.memory(
                    _placeholderImageBytes!,
                    fit: BoxFit.contain,
                    height: 250,
                    width: 250,
                  ),
                )
              else
                const SizedBox.shrink(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

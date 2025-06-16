import 'dart:typed_data';

class MangaPanel {
  final Uint8List? imageBytes;
  final String prompt;
  final String aiDescription;
  final List<String> nextSceneIdeas;
  final List<String> dialogueSuggestions;
  final String soundEffect;

  // Constructor to initialize a MangaPanel object.
  MangaPanel({
    required this.imageBytes,
    required this.prompt,
    required this.aiDescription,
    this.nextSceneIdeas = const [],
    this.dialogueSuggestions = const [],
    this.soundEffect = 'N/A',
  });
}

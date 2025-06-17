import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/models/manga_panel.dart';

class AiService {
  late final GenerativeModel _geminiFlashModel;
  late final ImagenModel _imagenModel;

  AiService() {
    _geminiFlashModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash-preview-05-20',
    );
    _imagenModel = FirebaseAI.googleAI().imagenModel(
      model: 'imagen-3.0-generate-002',
    );
  }

  Future<MangaPanel> generateMangaPanel({
    required String prompt,
    required ValueChanged<String> onProgressUpdate,
  }) async {
    if (prompt.isEmpty) {
      throw Exception('Prompt cannot be empty.');
    }

    onProgressUpdate('Generating manga panel image...');

    final imagenPrompt =
        "black and white manga panel, highly detailed, comic art style, dynamic lines, action lines, screentones, ink drawing, Japanese manga style, $prompt";

    final imageGenerationResponse = await _imagenModel.generateImages(
      imagenPrompt,
    );

    if (imageGenerationResponse.images.isEmpty) {
      throw Exception(
        'Imagen failed to generate an image. Response was empty.',
      );
    }

    final generatedImageBytes =
        imageGenerationResponse.images[0].bytesBase64Encoded;

    onProgressUpdate(
      'Manga panel image generated! Now getting AI analysis and suggestions...',
    );

    final imagePart = InlineDataPart('image/png', generatedImageBytes);

    final multimodalPromptContent = Content.multi([
      TextPart('''
        You are an AI assistant collaborating to create a manga story.
        The current black and white manga panel's central concept is: "$prompt".
        Describe this imagined manga panel in detail, focusing on elements derived from the user's prompt.
        Based on this scene, suggest 3 concise, distinct ideas for the next panel's setting or action, to powerfully continue the story.
        Suggest 2 lines of dialogue or character thoughts that are highly relevant to this specific panel.
        Suggest one appropriate manga sound effect (e.g., "POW!", "SWOOSH!").
        Provide all this information in a strictly valid JSON format with the following keys:
        "description" (string), "next_scene_ideas" (list of strings), "dialogue_suggestions" (list of strings), "sound_effect" (string).
        Example JSON response:
        {"description": "...", "next_scene_ideas": ["...", "...", "..."], "dialogue_suggestions": ["...", "..."], "sound_effect": "..."}
        Ensure there are no leading/trailing characters or additional text outside the JSON object.
      '''),
      imagePart,
    ]);

    final aiResponse = await _geminiFlashModel.generateContent([
      multimodalPromptContent,
    ]);
    String aiSuggestionsRaw =
        aiResponse.text ?? 'AI did not return specific suggestions.';

    String cleanAiSuggestions = aiSuggestionsRaw.trim();
    if (cleanAiSuggestions.startsWith('```json')) {
      cleanAiSuggestions = cleanAiSuggestions.substring('```json'.length);
    }
    if (cleanAiSuggestions.endsWith('```')) {
      cleanAiSuggestions = cleanAiSuggestions.substring(
        0,
        cleanAiSuggestions.length - '```'.length,
      );
    }
    cleanAiSuggestions = cleanAiSuggestions.trim();

    try {
      final parsedJson = jsonDecode(cleanAiSuggestions);
      if (parsedJson is Map<String, dynamic>) {
        final description = parsedJson['description'] ?? 'N/A';
        final nextScenes =
            (parsedJson['next_scene_ideas'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final dialogues =
            (parsedJson['dialogue_suggestions'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final sfx = parsedJson['sound_effect'] ?? 'N/A';

        return MangaPanel(
          imageBytes: generatedImageBytes,
          prompt: prompt,
          aiDescription: description,
          nextSceneIdeas: nextScenes,
          dialogueSuggestions: dialogues,
          soundEffect: sfx,
        );
      } else {
        return MangaPanel(
          imageBytes: generatedImageBytes,
          prompt: prompt,
          aiDescription: aiSuggestionsRaw,
        );
      }
    } catch (e) {
      // Return a panel with raw description if JSON parsing fails
      return MangaPanel(
        imageBytes: generatedImageBytes,
        prompt: prompt,
        aiDescription: aiSuggestionsRaw,
      );
    }
  }
}

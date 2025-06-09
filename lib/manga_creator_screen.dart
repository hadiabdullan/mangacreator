import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data'; // Essential for Uint8List

import 'package:firebase_ai/firebase_ai.dart'; // Core Firebase AI SDK
import 'package:flutter/material.dart'; // Needed for MaterialApp, Scaffold, etc.
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts for local use if needed, but primarily themed via main.dart

// Ensure firebase_options.dart is in the same directory or correctly imported
import 'firebase_options.dart';

// The MangaCreatorScreen widget.
class MangaCreatorScreen extends StatefulWidget {
  const MangaCreatorScreen({super.key});

  @override
  State<MangaCreatorScreen> createState() => _MangaCreatorScreenState();
}

// The State class for MangaCreatorScreen, holding all dynamic data and logic.
class _MangaCreatorScreenState extends State<MangaCreatorScreen> {
  // Controller for the text input field where the user types prompts for new panels.
  final TextEditingController _panelPromptController = TextEditingController();

  // A list to store each generated manga panel (conceptually).
  final List<MangaPanel> _mangaPanels = [];

  // A boolean to control the overall loading state of the UI (e.g., showing a progress indicator
  // during image generation and AI analysis).
  bool _isLoading = false;

  // AI Model instance for ALL multimodal input (text + image) and text/JSON output.
  // This model will analyze the generated image and provide structured suggestions.
  late final GenerativeModel _geminiFlashModel;

  // AI Model instance specifically for generating images using Imagen.
  late final ImagenModel _imagenModel;

  // Stores the bytes of our static placeholder image loaded from assets (used for initial display/fallback).
  Uint8List? _placeholderImageBytes;

  // Stores the bytes of the *currently generated* manga panel image by Imagen,
  // which is then passed to Gemini Flash for analysis and displayed.
  Uint8List? _currentGeneratedPanelBytes;

  // Stores any error messages related to panel generation or AI processing.
  String? _panelGenerationError;

  // NEW: State variables for reader mode
  bool _isReadingMode =
      false; // Flag to switch between creation and reading mode
  late PageController _pageController; // Controller for PageView
  int _currentPageIndex = 0; // Current index in PageView

  @override
  void initState() {
    super.initState();
    // Initialize the Gemini Flash model for all multimodal interactions.
    _geminiFlashModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash-preview-05-20',
    );
    // Initialize the Imagen model for text-to-image generation.
    _imagenModel = FirebaseAI.googleAI().imagenModel(
      model: 'imagen-3.0-generate-002',
    );
    // Load the placeholder image asynchronously when the screen is created.
    _loadPlaceholderImage();

    _pageController = PageController(); // Initialize PageController
  }

  @override
  void dispose() {
    // Clean up the TextEditingController when the widget is removed to prevent memory leaks.
    _panelPromptController.dispose();
    _pageController.dispose(); // Dispose PageController
    super.dispose();
  }

  // Asynchronously loads the placeholder image from the 'assets' folder.
  // This is used for initial display or as a fallback if no image is generated yet.
  Future<void> _loadPlaceholderImage() async {
    try {
      final ByteData data = await rootBundle.load(
        'images/placeholder_manga_panel.png', // Ensure this path is correct in your pubspec.yaml
      );
      setState(() {
        _placeholderImageBytes = data.buffer.asUint8List();
      });
      debugPrint('Placeholder image loaded successfully.');
    } catch (e) {
      debugPrint('Error loading placeholder image: $e');
      _showSnackBar(
        'Error loading placeholder image. Please check assets/placeholder_manga_panel.png in pubspec.yaml',
      );
    }
  }

  // Function to trigger the entire manga panel generation and AI analysis process.
  Future<void> _generateMangaPanel() async {
    final prompt = _panelPromptController.text.trim();
    if (prompt.isEmpty) {
      _showSnackBar('Please enter a prompt to start your manga panel concept!');
      return;
    }

    // Reset states for a new generation attempt.
    setState(() {
      _isLoading = true;
      _currentGeneratedPanelBytes = null; // Clear previous generated image
      _panelGenerationError = null; // Clear previous error message
    });

    // Initial message for UI feedback; actual suggestions will be parsed later.
    String aiSuggestionsRaw = 'Generating AI suggestions...';

    try {
      _showSnackBar('Generating manga panel image with Imagen...');

      // Add specific instructions to guide Imagen to generate a black and white manga-style image.
      // You can experiment with these keywords to fine-tune the style.
      final imagenPrompt =
          'black and white manga panel, highly detailed, comic art style, dynamic lines, action lines, screentones, ink drawing, Japanese manga style, ' +
          prompt;

      // --- STEP 1: GENERATE IMAGE USING IMAGEN (imagen-3.0-generate-002) ---
      // Use the enhanced prompt for image generation
      final imageGenerationResponse = await _imagenModel.generateImages(
        imagenPrompt,
      );

      if (imageGenerationResponse.images.isEmpty) {
        throw Exception(
          'Imagen failed to generate an image. Response was empty.',
        );
      }

      // Store the newly generated image bytes. This will be displayed and passed to Gemini Flash.
      // Accessing the bytes using the 'bytesBase64Encoded' property.
      _currentGeneratedPanelBytes =
          imageGenerationResponse.images[0].bytesBase64Encoded;

      _showSnackBar(
        'Manga panel image generated! Now getting AI analysis and suggestions with Gemini Flash...',
      );

      // --- STEP 2: GET AI SUGGESTIONS USING GEMINI FLASH (gemini-2.5-flash-preview-05-20) ---
      // Prepare the image part for the multimodal AI request using the *newly generated* image.
      final imagePart = InlineDataPart(
        'image/png', // Use 'image/png' if that's the format returned by Imagen (or 'image/jpeg')
        _currentGeneratedPanelBytes!,
      );

      // Construct the multimodal content for Gemini Flash.
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
        imagePart, // Attach the newly generated image data for analysis
      ]);

      // Call the Gemini Flash model to generate content (analysis and suggestions).
      final aiResponse = await _geminiFlashModel.generateContent([
        multimodalPromptContent,
      ]);
      aiSuggestionsRaw =
          aiResponse.text ?? 'AI did not return specific suggestions.';

      // --- Clean the AI's response string before parsing JSON ---
      String cleanAiSuggestions = aiSuggestionsRaw
          .trim(); // Remove leading/trailing whitespace

      // Check and remove markdown code block delimiters
      if (cleanAiSuggestions.startsWith('```json')) {
        cleanAiSuggestions = cleanAiSuggestions.substring('```json'.length);
      }
      if (cleanAiSuggestions.endsWith('```')) {
        cleanAiSuggestions = cleanAiSuggestions.substring(
          0,
          cleanAiSuggestions.length - '```'.length,
        );
      }
      cleanAiSuggestions = cleanAiSuggestions
          .trim(); // Trim again after removing delimiters

      // Attempt to parse the AI's response as JSON for structured display.
      try {
        final parsedJson = jsonDecode(cleanAiSuggestions);
        if (parsedJson is Map<String, dynamic>) {
          // Extract individual components
          final description = parsedJson['description'] ?? 'N/A';
          final nextScenes =
              (parsedJson['next_scene_ideas'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
          // Corrected key to 'dialogue_suggestions' as per the prompt instructions
          final dialogues =
              (parsedJson['dialogue_suggestions'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
          final sfx = parsedJson['sound_effect'] ?? 'N/A';

          // Update _mangaPanels.add() to use the new fields
          setState(() {
            _mangaPanels.add(
              MangaPanel(
                imageBytes: _currentGeneratedPanelBytes,
                prompt: prompt,
                aiDescription: description,
                nextSceneIdeas: nextScenes,
                dialogueSuggestions: dialogues,
                soundEffect: sfx,
              ),
            );
            _panelPromptController.clear();
          });

          _showSnackBar('Panel concept processed and AI suggestions received!');
        } else {
          // Fallback if parsedJson is not a Map, just use raw text for aiDescription
          debugPrint('Parsed JSON was not a Map: $parsedJson');
          setState(() {
            _mangaPanels.add(
              MangaPanel(
                imageBytes: _currentGeneratedPanelBytes,
                prompt: prompt,
                aiDescription:
                    aiSuggestionsRaw, // Use raw text if parsing failed
              ),
            );
            _panelPromptController.clear();
          });
          _showSnackBar(
            'AI response not perfectly formatted JSON. Displaying raw text.',
          );
        }
      } catch (e) {
        debugPrint(
          'Failed to parse AI suggestions JSON: $e\nRaw AI response: $cleanAiSuggestions',
        );
        _showSnackBar(
          'AI response not perfectly formatted JSON. Displaying raw text.',
        );
        // If parsing fails, store the raw `aiSuggestionsRaw` string in aiDescription.
        setState(() {
          _mangaPanels.add(
            MangaPanel(
              imageBytes: _currentGeneratedPanelBytes,
              prompt: prompt,
              aiDescription: aiSuggestionsRaw, // Fallback to raw text
            ),
          );
          _panelPromptController.clear();
        });
      }
    } catch (e) {
      debugPrint(
        'Error during AI processing: $e',
      ); // Log the full error for debugging
      _showSnackBar('An error occurred: ${e.toString()}');
      setState(() {
        _panelGenerationError =
            'Failed to generate or analyze panel: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading =
            false; // Hide loading indicator regardless of success or failure
      });
    }
  }

  // Helper function to display a temporary message at the bottom of the screen (SnackBar).
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Helper function to build a consistent suggestion tile
  Widget _buildSuggestionTile({
    required BuildContext context,
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
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

  // NEW: Function to switch to reader mode
  void _startReadingMode() {
    if (_mangaPanels.isNotEmpty) {
      setState(() {
        _isReadingMode = true;
        _currentPageIndex = 0;
        // Do NOT call jumpToPage here directly.
      });

      // Schedule jumpToPage after the next frame, ensuring PageView is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          // Check if controller is attached
          _pageController.jumpToPage(0);
        }
      });
    } else {
      _showSnackBar('Generate at least one panel to start reading!');
    }
  }

  // NEW: Function to exit reader mode
  void _exitReadingMode() {
    setState(() {
      _isReadingMode = false;
    });
  }

  // NEW: Function to navigate to the previous panel
  void _goToPreviousPanel() {
    if (_currentPageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // NEW: Function to navigate to the next panel
  void _goToNextPanel() {
    if (_currentPageIndex < _mangaPanels.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Collaborative Manga Storyteller'),
        // AppBar styling is now handled by ThemeData in main.dart
        centerTitle: true,
        // Add a back button for reader mode
        leading: _isReadingMode
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _exitReadingMode,
              )
            : null,
        actions: [
          // "Read Story" button to switch modes
          if (!_isReadingMode && _mangaPanels.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton.icon(
                onPressed: _startReadingMode,
                icon: const Icon(Icons.menu_book),
                label: const Text('Read Story'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondary, // Use accent color
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  elevation: 3,
                  textStyle: GoogleFonts.zillaSlab(fontSize: 14),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Expanded widget to make the list of panels take available space
          Expanded(
            child: _isReadingMode
                ? _buildMangaReaderView() // NEW: Reader mode view
                : (_mangaPanels.isEmpty
                      ? _buildEmptyState() // Existing: Empty state view
                      : _buildCreationListView()), // Existing: Creation mode list view
          ),
          // Input field and button always visible in creation mode, hidden in reading mode
          if (!_isReadingMode) // Only show input in creation mode
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _panelPromptController,
                      // InputDecoration is now primarily handled by ThemeData in main.dart
                      decoration: InputDecoration(
                        labelText: 'Describe your next manga panel concept...',
                        hintText: 'e.g., "The warrior draws a gleaming sword."',
                        suffixIcon: _isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : null,
                      ),
                      maxLines: null,
                      minLines: 1,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : _generateMangaPanel, // Disable button while loading
                    // ElevatedButton styling is now handled by ThemeData in main.dart
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Generate',
                            // Text style is now handled by ThemeData in main.dart
                          ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- NEW WIDGETS FOR DIFFERENT VIEWS ---

  // Builds the empty state UI when no panels are generated.
  Widget _buildEmptyState() {
    return Center(
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
                borderRadius: BorderRadius.circular(
                  16.0,
                ), // Larger border radius
                child: Image.memory(
                  _placeholderImageBytes!,
                  fit: BoxFit.contain,
                  height: 250, // Slightly larger
                  width: 250,
                ),
              )
            else
              const SizedBox.shrink(), // Or a simple text if placeholder not loaded
            const SizedBox(height: 30),
            // Show loading indicator on empty state too
            _isLoading
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.deepPurple,
                    ), // Use theme color
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  // Builds the creation mode list view of panels with all details and suggestions.
  Widget _buildCreationListView() {
    return ListView.builder(
      // Builds a scrollable list of manga panels
      padding: const EdgeInsets.all(16.0),
      itemCount: _mangaPanels.length,
      itemBuilder: (context, index) {
        final panel = _mangaPanels[index];
        return Card(
          // Card styling is now handled by ThemeData in main.dart
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Panel Concept Section
                Text(
                  'Panel ${index + 1} Concept:',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  '\"${panel.prompt}\"',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16.0),

                // Generated Image Section
                if (panel.imageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.memory(
                      panel.imageBytes!,
                      fit: BoxFit.fitWidth, // Ensures image fits width
                      width:
                          double.infinity, // Image takes full available width
                      // height is removed, letting the image's aspect ratio dictate it
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                            child: Text('Error loading generated image.'),
                          ),
                    ),
                  )
                else
                  Container(
                    // Fallback if generated image bytes are null
                    height: 280, // Keep placeholder height for consistency
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Colors.grey, width: 1.5),
                    ),
                    child: const Text(
                      'No Image Generated for this Panel',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                const SizedBox(height: 20.0), // Increased spacing
                // AI Vision Section
                Text(
                  'AI\'s Analysis:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  panel
                      .aiDescription, // Removed "Description:" prefix for cleaner display
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16.0),

                // Divider for visual separation
                const Divider(thickness: 1, height: 20, color: Colors.grey),
                const SizedBox(height: 10.0),

                // Next Scene Ideas Section
                if (panel.nextSceneIdeas.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Scene Ideas (Tap to Draft):', // More action-oriented label
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      ...panel.nextSceneIdeas.map(
                        (idea) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: 8.0,
                          ), // Consistent spacing
                          child: _buildSuggestionTile(
                            context: context,
                            text: idea,
                            icon: Icons.lightbulb_outline, // Suggestive icon
                            color: Colors.blue.shade700,
                            onTap: () {
                              _panelPromptController.text = idea;
                              FocusScope.of(context).unfocus();
                              _showSnackBar('Prompt updated: "$idea"');
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10.0),
                    ],
                  ),
                // Dialogue Suggestions Section
                if (panel.dialogueSuggestions.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dialogue Suggestions (Tap to Add):',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      ...panel.dialogueSuggestions.map(
                        (dialogue) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _buildSuggestionTile(
                            context: context,
                            text: dialogue,
                            icon: Icons.chat_bubble_outline, // Chat icon
                            color: Colors.green.shade700,
                            onTap: () {
                              // Append dialogue to current prompt
                              _panelPromptController.text +=
                                  (_panelPromptController.text.isEmpty
                                      ? ''
                                      : ' ') +
                                  '\"$dialogue\" ';
                              FocusScope.of(context).unfocus();
                              _showSnackBar('Dialogue added: \"$dialogue\"');
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10.0),
                    ],
                  ),
                // Sound Effect Section
                if (panel.soundEffect != 'N/A')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sound Effect (Tap to Add):',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      _buildSuggestionTile(
                        context: context,
                        text: panel.soundEffect,
                        icon: Icons.volume_up_outlined, // Sound icon
                        color: Colors.redAccent.shade700,
                        onTap: () {
                          // Append sound effect to current prompt
                          _panelPromptController.text +=
                              (_panelPromptController.text.isEmpty ? '' : ' ') +
                              '(${panel.soundEffect})'; // Commonly (SFX) format
                          FocusScope.of(context).unfocus();
                          _showSnackBar(
                            'Sound effect added: \"${panel.soundEffect}\"',
                          );
                        },
                      ),
                      const SizedBox(height: 10.0),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // NEW: Builds the manga reader view using PageView
  Widget _buildMangaReaderView() {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: _mangaPanels.length,
          onPageChanged: (index) {
            setState(() {
              _currentPageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final panel = _mangaPanels[index];
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Panel ${index + 1}: ${panel.prompt}', // Show concept
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // The image should now take all available height while maintaining aspect ratio
                  if (panel.imageBytes != null)
                    Expanded(
                      // Allow image to take available space
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.0),
                        child: Image.memory(
                          panel.imageBytes!,
                          fit: BoxFit
                              .contain, // Ensure entire image is visible within its bounds
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                child: Text('Error loading manga panel image.'),
                              ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: Colors.grey, width: 1.5),
                        ),
                        child: const Text(
                          'Image not available for this panel.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  // Optional: Display AI Description or other details in reader mode, but concise.
                  // For a pure manga reading experience, you might omit this.
                  // Text(
                  //   panel.aiDescription,
                  //   textAlign: TextAlign.center,
                  //   style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  //     color: Colors.grey.shade700,
                  //     fontStyle: FontStyle.italic,
                  //   ),
                  // ),
                ],
              ),
            );
          },
        ),
        // Left Arrow
        if (_currentPageIndex > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ),
                onPressed: _goToPreviousPanel,
              ),
            ),
          ),
        // Right Arrow
        if (_currentPageIndex < _mangaPanels.length - 1)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_forward_ios,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ),
                onPressed: _goToNextPanel,
              ),
            ),
          ),
      ],
    );
  }
}

// Data model for a single manga panel.
class MangaPanel {
  final Uint8List? imageBytes; // Stores the raw bytes of the GENERATED image
  final String prompt; // The user's text concept for this panel
  final String aiDescription; // The AI's description of this panel
  final List<String> nextSceneIdeas; // Store next scene ideas as a list
  final List<String>
  dialogueSuggestions; // Store dialogue suggestions as a list
  final String soundEffect; // Store sound effect

  // Constructor to initialize a MangaPanel object.
  MangaPanel({
    required this.imageBytes,
    required this.prompt,
    required this.aiDescription,
    this.nextSceneIdeas = const [], // Default to empty list
    this.dialogueSuggestions = const [], // Default to empty list
    this.soundEffect = 'N/A', // Default value
  });
}

import 'package:flutter/material.dart';

import '../../../../core/models/manga_panel.dart';
import 'suggestion_tile.dart';

class CreationListView extends StatelessWidget {
  final List<MangaPanel> panels;
  final TextEditingController promptController;

  const CreationListView({
    super.key,
    required this.panels,
    required this.promptController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: panels.length,
      itemBuilder: (context, index) {
        final panel = panels[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 24.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                if (panel.imageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.memory(
                      panel.imageBytes!,
                      fit: BoxFit.fitWidth,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                            child: Text('Error loading generated image.'),
                          ),
                    ),
                  )
                else
                  Container(
                    height: 280,
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
                const SizedBox(height: 20.0),
                Text(
                  'AI\'s Analysis:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  panel.aiDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16.0),

                const Divider(thickness: 1, height: 20, color: Colors.grey),
                const SizedBox(height: 10.0),

                if (panel.nextSceneIdeas.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Scene Ideas (Tap to Draft):',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      ...panel.nextSceneIdeas
                          .map(
                            (idea) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: SuggestionTile(
                                text: idea,
                                icon: Icons.lightbulb_outline,
                                color: Colors.blue.shade700,
                                onTap: () {
                                  promptController.text = idea;
                                  FocusScope.of(context).unfocus();
                                },
                              ),
                            ),
                          )
                          .toList(), // ADDED .toList()
                      const SizedBox(height: 10.0),
                    ],
                  ),
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
                      ...panel.dialogueSuggestions
                          .map(
                            (dialogue) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: SuggestionTile(
                                text: dialogue,
                                icon: Icons.chat_bubble_outline,
                                color: Colors.green.shade700,
                                onTap: () {
                                  promptController.text +=
                                      (promptController.text.isEmpty
                                          ? ''
                                          : ' ') +
                                      '\"$dialogue\" ';
                                  FocusScope.of(context).unfocus();
                                },
                              ),
                            ),
                          )
                          .toList(), // ADDED .toList()
                      const SizedBox(height: 10.0),
                    ],
                  ),
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
                      SuggestionTile(
                        text: panel.soundEffect,
                        icon: Icons.volume_up_outlined,
                        color: Colors.redAccent.shade700,
                        onTap: () {
                          promptController.text +=
                              (promptController.text.isEmpty ? '' : ' ') +
                              '(${panel.soundEffect})';
                          FocusScope.of(context).unfocus();
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
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/manga_panel.dart';
import '../../../core/utils/dialogue_utils.dart';
import 'bloc/manga_creator_cubit.dart';
import 'bloc/manga_creator_state.dart';
import 'widgets/creation_list_view.dart';
import 'widgets/empty_state_view.dart';
import 'widgets/manga_reader_view.dart';

class MangaCreatorScreen extends StatefulWidget {
  const MangaCreatorScreen({super.key});

  @override
  State<MangaCreatorScreen> createState() => _MangaCreatorScreenState();
}

class _MangaCreatorScreenState extends State<MangaCreatorScreen> {
  final TextEditingController _panelPromptController = TextEditingController();

  @override
  void dispose() {
    _panelPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('AI Collaborative Manga Storyteller'),
        centerTitle: true,
        leading: BlocBuilder<MangaCreatorCubit, MangaCreatorState>(
          builder: (context, state) {
            if (state is MangaCreatorLoaded && state.isReadingMode) {
              return IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    context.read<MangaCreatorCubit>().toggleReadingMode(),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        actions: [
          BlocBuilder<MangaCreatorCubit, MangaCreatorState>(
            builder: (context, state) {
              final panels = state is MangaCreatorLoaded ? state.panels : [];
              final isReadingMode = state is MangaCreatorLoaded
                  ? state.isReadingMode
                  : false;

              if (!isReadingMode && panels.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        context.read<MangaCreatorCubit>().toggleReadingMode(),
                    icon: const Icon(Icons.menu_book),
                    label: const Text('Read Story'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onSecondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      elevation: 3,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<MangaCreatorCubit, MangaCreatorState>(
        listener: (context, state) {
          if (state is MangaCreatorError) {
            DialogUtils.hideLoadingDialog();
            DialogUtils.showErrorDialog(state.message);
          }
          // The loading dialog is managed by DialogUtils directly called from the Cubit
        },
        builder: (context, state) {
          final List<MangaPanel> panels = (state is MangaCreatorLoaded)
              ? state.panels
              : context.read<MangaCreatorCubit>().currentPanels;
          final bool isReadingMode = (state is MangaCreatorLoaded)
              ? state.isReadingMode
              : false;
          final int currentPageIndex = (state is MangaCreatorLoaded)
              ? state.currentPageIndex
              : 0;
          final bool isLoading = state is MangaCreatorLoading;

          return Column(
            children: [
              Expanded(
                child: isReadingMode
                    ? MangaReaderView(
                        panels: panels,
                        initialPageIndex: currentPageIndex,
                      )
                    : (panels.isEmpty
                          ? const EmptyStateView() // Now a dedicated widget
                          : CreationListView(
                              // Now a dedicated widget
                              panels: panels,
                              promptController: _panelPromptController,
                            )),
              ),
              if (!isReadingMode)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _panelPromptController,
                          decoration: const InputDecoration(
                            labelText:
                                'Describe your next manga panel concept...',
                            hintText:
                                'e.g., "The warrior draws a gleaming sword."',
                          ),
                          maxLines: null,
                          minLines: 1,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () => context
                                  .read<MangaCreatorCubit>()
                                  .generatePanel(_panelPromptController.text),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Generate'),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

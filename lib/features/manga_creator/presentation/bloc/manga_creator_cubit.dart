import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/models/manga_panel.dart';
import '../../../../core/utils/dialogue_utils.dart';
import '../../data/services/ai_service.dart';
import 'manga_creator_state.dart';

class MangaCreatorCubit extends Cubit<MangaCreatorState> {
  final AiService _aiService;

  MangaCreatorCubit(this._aiService) : super(MangaCreatorInitial());

  // Internal list to manage panels before emitting state
  final List<MangaPanel> _panels = [];

  List<MangaPanel> get currentPanels => _panels; // Getter for external access

  Future<void> generatePanel(String prompt) async {
    if (prompt.isEmpty) {
      emit(
        const MangaCreatorError(
          'Please enter a prompt to start your manga panel concept!',
        ),
      );
      return;
    }

    emit(
      const MangaCreatorLoading('Preparing to generate your manga panel...'),
    ); // Initial loading state

    try {
      // Use AiService to generate the panel, passing a progress callback
      final newPanel = await _aiService.generateMangaPanel(
        prompt: prompt,
        onProgressUpdate: (message) {
          // Emit a loading state with updated message, keeping current panels if available
          if (state is MangaCreatorLoaded) {
            emit(
              (state as MangaCreatorLoaded).copyWith(
                panels:
                    _panels, // Ensure panels are preserved during internal loading
                isReadingMode:
                    false, // Ensure not in reading mode during creation
              ),
            );
          }
          // The DialogUtils handles showing the actual dialog overlay
          DialogUtils.showLoadingDialog(message);
        },
      );

      _panels.add(newPanel); // Add the new panel to our internal list
      DialogUtils.hideLoadingDialog(); // Hide loading dialog on success

      emit(
        MangaCreatorLoaded(panels: List.from(_panels)),
      ); // Emit loaded state with all panels
    } catch (e) {
      debugPrint('Error generating panel in Cubit: $e');
      DialogUtils.hideLoadingDialog(); // Ensure dialog is hidden on error
      emit(
        MangaCreatorError('Failed to generate panel: ${e.toString()}'),
      ); // Emit error state
    }
  }

  void toggleReadingMode() {
    if (_panels.isEmpty) {
      emit(
        const MangaCreatorError(
          'Generate at least one panel to start reading!',
        ),
      );
      return;
    }

    final currentState = state;
    if (currentState is MangaCreatorLoaded) {
      emit(currentState.copyWith(isReadingMode: !currentState.isReadingMode));
    } else {
      // If we are in initial or error state, transition to loaded and then toggle
      emit(MangaCreatorLoaded(panels: List.from(_panels), isReadingMode: true));
    }
  }

  void goToPreviousPanel() {
    final currentState = state;
    if (currentState is MangaCreatorLoaded &&
        currentState.currentPageIndex > 0) {
      emit(
        currentState.copyWith(
          currentPageIndex: currentState.currentPageIndex - 1,
        ),
      );
    }
  }

  void goToNextPanel() {
    final currentState = state;
    if (currentState is MangaCreatorLoaded &&
        currentState.currentPageIndex < _panels.length - 1) {
      emit(
        currentState.copyWith(
          currentPageIndex: currentState.currentPageIndex + 1,
        ),
      );
    }
  }

  void setPageIndex(int index) {
    final currentState = state;
    if (currentState is MangaCreatorLoaded) {
      emit(currentState.copyWith(currentPageIndex: index));
    }
  }

  // Clear all panels (e.g., for a "start new story" feature)
  void clearPanels() {
    _panels.clear();
    emit(MangaCreatorInitial());
  }
}

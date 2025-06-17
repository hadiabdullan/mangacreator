import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/manga_panel.dart';
import '../../../../core/utils/dialogue_utils.dart';
import '../../data/services/ai_service.dart';
import 'manga_creator_state.dart';

class MangaCreatorCubit extends Cubit<MangaCreatorState> {
  final AiService _aiService;

  MangaCreatorCubit(this._aiService) : super(MangaCreatorInitial());

  final List<MangaPanel> _panels = [];

  List<MangaPanel> get currentPanels => _panels;

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
    );

    try {
      final newPanel = await _aiService.generateMangaPanel(
        prompt: prompt,
        onProgressUpdate: (message) {
          if (state is MangaCreatorLoaded) {
            emit(
              (state as MangaCreatorLoaded).copyWith(
                panels: _panels,
                isReadingMode: false,
              ),
            );
          }
          DialogUtils.showLoadingDialog(message);
        },
      );

      _panels.add(newPanel);
      DialogUtils.hideLoadingDialog();

      emit(MangaCreatorLoaded(panels: List.from(_panels)));
    } catch (e) {
      DialogUtils.hideLoadingDialog();
      emit(MangaCreatorError('Failed to generate panel: ${e.toString()}'));
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

  void clearPanels() {
    _panels.clear();
    emit(MangaCreatorInitial());
  }
}

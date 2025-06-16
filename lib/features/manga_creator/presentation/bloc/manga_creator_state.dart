import 'package:equatable/equatable.dart';

import '../../../../core/models/manga_panel.dart'; // Ensure correct import

// Base class for all MangaCreator states
abstract class MangaCreatorState extends Equatable {
  const MangaCreatorState();

  @override
  List<Object?> get props => [];
}

// Initial state, before any action is taken
class MangaCreatorInitial extends MangaCreatorState {}

// State when an operation (like generating a panel) is in progress
class MangaCreatorLoading extends MangaCreatorState {
  final String message;
  const MangaCreatorLoading(this.message);

  @override
  List<Object?> get props => [message];
}

// State when a panel has been successfully loaded/generated
class MangaCreatorLoaded extends MangaCreatorState {
  final List<MangaPanel> panels;
  final bool isReadingMode;
  final int currentPageIndex; // Keep track for reader mode

  const MangaCreatorLoaded({
    required this.panels,
    this.isReadingMode = false,
    this.currentPageIndex = 0,
  });

  // Helper method to create a new state with modified values
  MangaCreatorLoaded copyWith({
    List<MangaPanel>? panels,
    bool? isReadingMode,
    int? currentPageIndex,
  }) {
    return MangaCreatorLoaded(
      panels: panels ?? this.panels,
      isReadingMode: isReadingMode ?? this.isReadingMode,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
    );
  }

  @override
  List<Object?> get props => [panels, isReadingMode, currentPageIndex];
}

// State when an error occurs
class MangaCreatorError extends MangaCreatorState {
  final String message;
  const MangaCreatorError(this.message);

  @override
  List<Object?> get props => [message];
}

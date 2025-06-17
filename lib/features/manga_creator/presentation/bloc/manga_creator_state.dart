import 'package:equatable/equatable.dart';

import '../../../../core/models/manga_panel.dart';

abstract class MangaCreatorState extends Equatable {
  const MangaCreatorState();

  @override
  List<Object?> get props => [];
}

class MangaCreatorInitial extends MangaCreatorState {}

class MangaCreatorLoading extends MangaCreatorState {
  final String message;
  const MangaCreatorLoading(this.message);

  @override
  List<Object?> get props => [message];
}

class MangaCreatorLoaded extends MangaCreatorState {
  final List<MangaPanel> panels;
  final bool isReadingMode;
  final int currentPageIndex;

  const MangaCreatorLoaded({
    required this.panels,
    this.isReadingMode = false,
    this.currentPageIndex = 0,
  });

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

class MangaCreatorError extends MangaCreatorState {
  final String message;
  const MangaCreatorError(this.message);

  @override
  List<Object?> get props => [message];
}

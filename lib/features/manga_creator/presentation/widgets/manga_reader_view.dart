import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mangacreator/core/models/manga_panel.dart';

import '../bloc/manga_creator_cubit.dart';
import '../bloc/manga_creator_state.dart';

class MangaReaderView extends StatefulWidget {
  final List<MangaPanel> panels;
  final int initialPageIndex;

  const MangaReaderView({
    super.key,
    required this.panels,
    required this.initialPageIndex,
  });

  @override
  State<MangaReaderView> createState() => _MangaReaderViewState();
}

class _MangaReaderViewState extends State<MangaReaderView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPageIndex);
  }

  @override
  void didUpdateWidget(covariant MangaReaderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the initial page index changes from parent (e.g., exiting reader mode and re-entering)
    if (widget.initialPageIndex != oldWidget.initialPageIndex) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(widget.initialPageIndex);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the Cubit's state to potentially update the PageController
    return BlocListener<MangaCreatorCubit, MangaCreatorState>(
      listener: (context, state) {
        if (state is MangaCreatorLoaded && _pageController.hasClients) {
          // Animate to the page index managed by the Cubit
          if (_pageController.page?.round() != state.currentPageIndex) {
            _pageController.animateToPage(
              state.currentPageIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        }
      },
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.panels.length,
            onPageChanged: (index) {
              // Inform the Cubit of the page change
              context.read<MangaCreatorCubit>().setPageIndex(index);
            },
            itemBuilder: (context, index) {
              final panel = widget.panels[index];
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Panel ${index + 1}: ${panel.prompt}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 20),
                    if (panel.imageBytes != null)
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.0),
                          child: Image.memory(
                            panel.imageBytes!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                                  child: Text(
                                    'Error loading manga panel image.',
                                  ),
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
                  ],
                ),
              );
            },
          ),
          // Navigation buttons need to respond to the Cubit's currentPageIndex
          BlocBuilder<MangaCreatorCubit, MangaCreatorState>(
            builder: (context, state) {
              final int currentPageIndex = (state is MangaCreatorLoaded)
                  ? state.currentPageIndex
                  : 0;
              final int totalPanels = widget.panels.length;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Arrow
                  if (currentPageIndex > 0)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios,
                          size: 40,
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.7),
                        ),
                        onPressed: () => context
                            .read<MangaCreatorCubit>()
                            .goToPreviousPanel(),
                      ),
                    )
                  else
                    const SizedBox(width: 56), // Placeholder to keep alignment
                  // Right Arrow
                  if (currentPageIndex < totalPanels - 1)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                        icon: Icon(Icons.arrow_forward_ios),
                        onPressed: () =>
                            context.read<MangaCreatorCubit>().goToNextPanel(),
                      ),
                    )
                  else
                    const SizedBox(width: 56), // Placeholder to keep alignment
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../ui/app_error_state.dart';

/// Full-screen failure panel for the catalogue surfaces.
///
/// A thin, movie-flavoured wrapper over [AppErrorState]: the shared panel owns
/// the layout, the type scale, and the colours; this keeps the copy the
/// catalogue screens have always shown.
class ErrorView extends StatelessWidget {
  final String? error;
  final VoidCallback onRetry;

  const ErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppErrorState(
        title: 'Could not load movies',
        message: error ?? 'Unknown error',
        onRetry: onRetry,
      ),
    );
  }
}

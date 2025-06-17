import 'package:flutter/material.dart';

import '../../main.dart';

class DialogUtils {
  static bool _isDialogShowing = false;

  static void showLoadingDialog(String message) {
    if (navigatorKey.currentContext == null) return; // Use currentContext

    if (_isDialogShowing) {
      hideLoadingDialog();
    }

    _isDialogShowing = true;

    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: Theme.of(dialogContext).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(dialogContext).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      _isDialogShowing = false;
    });
  }

  static void hideLoadingDialog() {
    if (navigatorKey.currentContext != null &&
        Navigator.of(navigatorKey.currentContext!).canPop()) {
      Navigator.of(navigatorKey.currentContext!).pop();
    }
  }

  static void showErrorDialog(String message) {
    if (navigatorKey.currentContext == null) return;

    hideLoadingDialog();

    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(dialogContext).colorScheme.errorContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Error',
            style: TextStyle(
              color: Theme.of(dialogContext).colorScheme.onErrorContainer,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              color: Theme.of(dialogContext).colorScheme.onErrorContainer,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'OK',
                style: TextStyle(
                  color: Theme.of(dialogContext).colorScheme.onErrorContainer,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

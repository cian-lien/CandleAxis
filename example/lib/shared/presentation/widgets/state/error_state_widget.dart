import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';

class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({super.key, this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (message != null) Text(message!),
      TextButton(onPressed: onRetry, child: Text(S.of(context).retry)),
    ],
  );
}

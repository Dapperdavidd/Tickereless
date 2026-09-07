import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tickerless/core/error/failures.dart';
import 'package:tickerless/features/wallet/domain/usecases/reveal_private_key.dart';

/// Reveals the account's private key, behind a warning the user has to accept.
///
/// This does not go through a bloc: the key is shown once, in a dialog, and is
/// deliberately never held in any state object.
Future<void> revealPrivateKey(
  BuildContext context, {
  required RevealPrivateKeyUseCase revealUseCase,
  required String userId,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Never share your private key'),
      content: const Text(
        'Anyone with this key can control your wallet and its assets. '
        'Tickerless support will never ask for it.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('I understand'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final String privateKey;
  try {
    privateKey = await revealUseCase(userId);
  } on Failure catch (failure) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
    return;
  }
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Private key'),
      content: SelectableText(privateKey),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: privateKey));
            if (dialogContext.mounted) Navigator.pop(dialogContext);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Private key copied')),
              );
            }
          },
          child: const Text('Copy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Done'),
        ),
      ],
    ),
  );
}

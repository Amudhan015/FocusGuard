import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class BlockNoteDialog extends StatefulWidget {
  const BlockNoteDialog({super.key, required this.appName, this.initialNote});

  final String appName;
  final String? initialNote;

  static Future<String?> show(
    BuildContext context, {
    required String appName,
    String? initialNote,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => BlockNoteDialog(appName: appName, initialNote: initialNote),
    );
  }

  @override
  State<BlockNoteDialog> createState() => _BlockNoteDialogState();
}

class _BlockNoteDialogState extends State<BlockNoteDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Why block ${widget.appName}?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Optional - shown to you on the block screen, so it feels like your own decision, not a rule.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _controller,
            maxLength: 120,
            maxLines: 2,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g. "This is where my revision time goes"',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).pop(_controller.text.trim());
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

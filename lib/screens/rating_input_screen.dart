import 'package:flutter/material.dart';
import 'package:focusguard/models/enums.dart';
import 'package:focusguard/theme/app_theme.dart';

/// Screen for inputting session rating and optional note at end of session.
/// Provides 1-5 scale via Poor/Okay/Good/Great options and an optional note field.
class RatingInputScreen extends StatefulWidget {
  const RatingInputScreen({
    super.key,
    required this.onRatingSubmitted,
    this.initialRating,
    this.initialNote,
  });

  /// Callback when rating and note are submitted.
  final Function(SelfRating rating, String? note) onRatingSubmitted;

  /// Optional initial rating for editing.
  final SelfRating? initialRating;

  /// Optional initial note for editing.
  final String? initialNote;

  @override
  State<RatingInputScreen> createState() => _RatingInputScreenState();
}

class _RatingInputScreenState extends State<RatingInputScreen> {
  late SelfRating _selectedRating;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.initialRating ?? SelfRating.okay;
    _noteController.text = widget.initialNote ?? '';
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _submitRating() {
    final note = _noteController.text.trim();
    widget.onRatingSubmitted(
      _selectedRating,
      note.isEmpty ? null : note,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Session Rating'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Rating options
              Text(
                'How productive was this session?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: SelfRating.values.map((rating) => _buildRatingOption(
                  context,
                  rating,
                  rating == _selectedRating,
                )).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Note field
              Text(
                'Optional reflection note',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _noteController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'What went well? What could be improved?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Submit button
              ElevatedButton(
                onPressed: _submitRating,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                ),
                child: const Text('Submit Rating'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingOption(
      BuildContext context,
      SelfRating rating,
      bool isSelected,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return ChoiceChip(
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rating.label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${rating.score}/5',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
      selected: isSelected,
      selectedColor: colorScheme.primary.withValues(alpha: 0.15),
      backgroundColor: colorScheme.surface,
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.primary : colorScheme.onSurface,
      ),
      labelPadding: const EdgeInsets.all(AppSpacing.xs),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShape.radiusSmall),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outline,
          width: isSelected ? 2 : 1,
        ),
      ),
      onSelected: (_) {
        setState(() => _selectedRating = rating);
      },
    );
  }
}
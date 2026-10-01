import 'dart:io';

import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/focus_session.dart';
import '../providers/session_proof_controller.dart';
import '../services/database_service.dart';
import '../screens/proof_flow_screen.dart';
import '../screens/rating_input_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_app_bar.dart';

/// Screen for viewing and editing session proof details.
/// Displays full-size photo, rating, and note, with ability to edit.
class SessionDetailScreen extends StatelessWidget {
  const SessionDetailScreen({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Session Proof',
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: _SessionDetailContent(sessionId: sessionId),
    );
  }
}

class _SessionDetailContent extends StatefulWidget {
  const _SessionDetailContent({
    required this.sessionId,
  });

  final String sessionId;

  @override
  State<_SessionDetailContent> createState() => _SessionDetailContentState();
}

// Was a StatelessWidget wrapped in Consumer<SessionProvider> - that
// provider has nothing to do with viewing a past session's details, and
// only notifies listeners while some OTHER session is actively ticking.
// That meant this screen only ever picked up an edited rating/note or a
// re-captured photo by accident, when a live timer happened to be
// running elsewhere at the same time - normally (no session currently
// active) a save here was invisible until you left and came back. A
// plain State + setState() after each save is what was actually needed,
// and it also stops rebuilding this screen every second for no reason.
class _SessionDetailContentState extends State<_SessionDetailContent> {
  Future<void> _editRatingAndNote(BuildContext context) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>?>(
      MaterialPageRoute(
        builder: (context) => RatingInputScreen(
          onRatingSubmitted: (rating, note) {
            Navigator.of(context).pop(<String, dynamic>{
              'rating': rating,
              'note': note,
            });
          },
        ),
      ),
    );

    if (result != null) {
      final rating = result['rating'] as SelfRating?;
      final note = result['note'] as String?;
      final session = DatabaseService.instance.getSession(widget.sessionId);
      if (session != null) {
        session.selfRating = rating;
        session.reflectionNote = note;
        await DatabaseService.instance.saveSession(session);
      }
      if (mounted) setState(() {});
    }
  }

  Future<void> _reproofSession(BuildContext context) async {
    final proofController = SessionProofController.instance;
    await proofController.startProofFlow(widget.sessionId);
    if (context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProofFlowScreen(sessionId: widget.sessionId),
        ),
      );
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = DatabaseService.instance.getSession(widget.sessionId);
    if (session == null) {
      return const Center(child: Text('Session not found'));
    }

    return _SessionDetailBody(
      session: session,
      onEditRatingAndNote: _editRatingAndNote,
      onReproofSession: _reproofSession,
    );
  }
}

class _SessionDetailBody extends StatelessWidget {
  const _SessionDetailBody({
    required this.session,
    required this.onEditRatingAndNote,
    required this.onReproofSession,
  });

  final FocusSession session;
  final Future<void> Function(BuildContext) onEditRatingAndNote;
  final Future<void> Function(BuildContext) onReproofSession;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Photo display
          if (session.photoPath != null)
            ClipRRect(
              borderRadius: AppShape.borderRadius,
              child: Image.file(
                File(session.photoPath!),
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.05),
                borderRadius: AppShape.borderRadius,
              ),
              child: const Icon(
                Icons.image_not_supported,
                size: 48,
                color: Colors.grey,
              ),
            ),
          const SizedBox(height: AppSpacing.lg),

          // Photo info badges
          if (session.photoPath != null) ...[
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                if (session.isGalleryFallbackPhoto)
                  Chip(
                    label: const Text('Gallery Fallback'),
                    backgroundColor: colorScheme.tertiary.withValues(alpha: 0.1),
                    labelStyle: TextStyle(
                      color: colorScheme.tertiary,
                      fontSize: 12,
                    ),
                  ),
                if (session.isDuplicatePhoto)
                  Chip(
                    label: const Text('Duplicate Photo'),
                    backgroundColor: colorScheme.error.withValues(alpha: 0.1),
                    labelStyle: TextStyle(
                      color: colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Rating display
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Rating',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (session.selfRating != null)
            Chip(
              label: Text('${session.selfRating!.label} (${session.selfRating!.score}/5)'),
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              labelStyle: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            const Text(
              'Not rated',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          const SizedBox(height: AppSpacing.lg),

          // Note display
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Reflection Note',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (session.reflectionNote != null && session.reflectionNote!.isNotEmpty)
            Text(
              session.reflectionNote!,
              style: Theme.of(context).textTheme.bodyLarge,
            )
          else
            const Text(
              'No note added',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          const SizedBox(height: AppSpacing.lg),

          // Action buttons
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Rating & Note'),
                  onPressed: () => onEditRatingAndNote(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Re-capture Proof'),
                  onPressed: () => onReproofSession(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
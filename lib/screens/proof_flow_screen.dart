import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusguard/models/enums.dart';
import 'package:focusguard/providers/session_proof_controller.dart';
import 'package:focusguard/screens/camera_capture_screen.dart';
import 'package:focusguard/screens/rating_input_screen.dart';
import 'package:focusguard/theme/app_theme.dart';

/// Screen that orchestrates the end-of-session proof submission flow.
/// Shows camera capture, then rating input, and handles saving proof to session.
class ProofFlowScreen extends StatelessWidget {
  const ProofFlowScreen({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChangeNotifierProvider.value(
        value: SessionProofController.instance,
        child: Consumer<SessionProofController>(
          builder: (context, proofController, _) {
            // Start the proof flow when the screen is first shown for this
            // session. SessionProofController is a singleton reused across
            // every session's proof flow, so checking `state == active`
            // here was wrong: after session A's flow finished, `state`
            // was left at `closed` (not reset), so opening this screen for
            // a brand new session B never called startProofFlow at all -
            // the switch below just fell straight into the `closed` case
            // and showed "Proof saved successfully!" for a session that
            // was never actually captured. Compare on sessionId instead,
            // which correctly detects "this is a different session".
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (proofController.sessionId != sessionId) {
                proofController.startProofFlow(sessionId);
              }
            });

            return _ProofFlowBody(
              key: key,
              proofController: proofController,
              onFlowCompleted: () => Navigator.of(context).pop(),
            );
          },
        ),
      ),
    );
  }
}

class _ProofFlowBody extends StatelessWidget {
  const _ProofFlowBody({
    super.key,
    required this.proofController,
    required this.onFlowCompleted,
  });

  final SessionProofController proofController;
  final VoidCallback onFlowCompleted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Session Proof'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onFlowCompleted,
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (proofController.state) {
      case SessionStatus.pendingClosure:
        // Check if we have an error to show
        if (proofController.error != null) {
          return _buildErrorView(context);
        }

        // Check if we have captured an image and are ready for rating
        if (proofController.isReadyForRating) {
          return RatingInputScreen(
            onRatingSubmitted: (rating, note) {
              proofController.submitProof(
                rating: rating,
                note: note,
              );
            },
          );
        }

        // Otherwise, show the camera capture screen
        return CameraCaptureScreen(
          onImageCaptured: (filePath, isGalleryFallback) {
            // When image is captured, we set it in the controller via the public method.
            proofController.setImagePath(filePath, isGalleryFallback);
          },
          sessionId: proofController.sessionId,
          maxRetries: 3,
        );

      case SessionStatus.closed:
        // Proof submitted successfully, show success and then exit.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Show a brief success message then pop.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Proof saved successfully!')),
          );
          Future.delayed(const Duration(seconds: 1), onFlowCompleted);
        });
        return const Center(child: CircularProgressIndicator());

      default:
        return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildErrorView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              proofController.error ?? 'An error occurred',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: () {
                proofController.reset();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:focusguard/theme/app_theme.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

/// Screen for capturing proof photo at end of session.
/// Shows live camera preview, capture button, permission handling,
/// and retry mechanism for camera failures.
class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({
    super.key,
    required this.onImageCaptured,
    this.sessionId,
    this.maxRetries = 3,
  });

  /// Callback when an image is successfully captured.
  /// Returns the image file path and whether it was from gallery fallback.
  final Function(String filePath, bool isGalleryFallback) onImageCaptured;

  /// Optional session ID for logging or debugging.
  final String? sessionId;

  /// Maximum number of camera retries before showing gallery fallback.
  final int maxRetries;

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  late CameraController _controller;
  bool _isInitialized = false;
  bool _isPermissionGranted = false;
  bool _isCaptureInProgress = false;
  String? _error;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndInitializeCamera();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _requestPermissionsAndInitializeCamera() async {
    try {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        setState(() => _isPermissionGranted = true);
        await _initializeCamera();
      } else {
        setState(() {
          _error = 'Camera permission is required to capture proof photo.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to request camera permission: $e';
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _error = 'No camera found on device.';
        });
        return;
      }

      // Prefer back camera, fall back to first available.
      // LensDirection.back has index 1.
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection.index == 1, // LensDirection.back
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller.initialize();
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _error = null;
      });
    } on CameraException catch (e) {
      setState(() {
        _error = 'Camera initialization failed: ${e.description}';
      });
    } catch (e) {
      setState(() {
        _error = 'Unexpected error initializing camera: $e';
      });
    }
  }

  Future<void> _captureImage() async {
    if (!_isInitialized || !_controller.value.isInitialized) {
      setState(() => _error = 'Camera not initialized');
      return;
    }

    setState(() => _isCaptureInProgress = true);
    _error = null;

    try {
      final XFile file = await _controller.takePicture();
      final String path = file.path;

      // Notify parent with captured image path.
      widget.onImageCaptured(path, false); // false = not gallery fallback
    } on CameraException catch (e) {
      setState(() {
        _error = 'Image capture failed: ${e.description}';
        _isCaptureInProgress = false;
        _retryCount++;
      });
    } catch (e) {
      setState(() {
        _error = 'Unexpected error capturing image: $e';
        _isCaptureInProgress = false;
        _retryCount++;
      });
    }
  }

  Future<void> _retryCamera() async {
    setState(() {
      _error = null;
      _isCaptureInProgress = false;
    });
    await _initializeCamera();
  }

  Future<void> _openGalleryFallback() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        widget.onImageCaptured(image.path, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to pick image from gallery: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Capture Proof'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: _isPermissionGranted
          ? _isInitialized
              ? _buildCameraView(context)
              : const Center(child: CircularProgressIndicator())
          : _buildPermissionDeniedView(),
    );
  }

  Widget _buildCameraView(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        // Camera preview
        CameraPreview(_controller),
        // Overlay UI
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Capture button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: FloatingActionButton(
                onPressed: _isCaptureInProgress ? null : _captureImage,
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                child: _isCaptureInProgress
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.camera_alt),
              ),
            ),
            // Error message
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                child: Text(
                  _error!,
                  style: TextStyle(color: colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_error != null)
              if (_retryCount < widget.maxRetries)
                // Retry button
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: ElevatedButton(
                    onPressed: _retryCamera,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.secondary,
                    ),
                    child: const Text('Retry'),
                  ),
                )
              else
                // Gallery fallback button
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: ElevatedButton(
                    onPressed: _openGalleryFallback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.secondary,
                    ),
                    child: const Text('Gallery Fallback'),
                  ),
                ),
          ],
        ),
      ],
    );
  }

  Widget _buildPermissionDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _error ??
                  'Camera permission is required to capture proof photo.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: _requestPermissionsAndInitializeCamera,
              icon: const Icon(Icons.perm_device_information),
              label: const Text('Grant Permission'),
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
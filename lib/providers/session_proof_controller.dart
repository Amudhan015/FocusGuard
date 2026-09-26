import 'dart:io';
import 'package:focusguard/models/enums.dart';
import 'package:focusguard/services/database_service.dart';
import 'package:focusguard/services/duplicate_detector.dart';
import 'package:flutter/foundation.dart';

/// Controller managing the end-of-session proof submission process.
/// Handles camera capture, gallery fallback, duplicate detection,
/// rating input, and saving proof to session.
class SessionProofController extends ChangeNotifier {
  SessionProofController._();
  static final SessionProofController instance = SessionProofController._();

  // --- State ---
  SessionStatus _state = SessionStatus.active; // Reusing SessionStatus for simplicity
  String? _error;
  String? _capturedImagePath;
  bool _isGalleryFallback = false;
  bool _isDuplicatePhoto = false;
  SelfRating? _selectedRating;
  String? _reflectionNote;
  String? _sessionId; // The session we are collecting proof for

  // --- Getters ---
  SessionStatus get state => _state;
  String? get error => _error;
  String? get capturedImagePath => _capturedImagePath;
  bool get isGalleryFallback => _isGalleryFallback;
  bool get isDuplicatePhoto => _isDuplicatePhoto;
  SelfRating? get selectedRating => _selectedRating;
  String? get reflectionNote => _reflectionNote;
  String? get sessionId => _sessionId;
  bool get isReadyForRating => _capturedImagePath != null && _state == SessionStatus.pendingClosure;
  bool get isProofComplete =>
      _capturedImagePath != null &&
      _selectedRating != null &&
      _state == SessionStatus.closed;

  // --- Constants ---

  // --- Private fields ---

  // --- Public Methods ---

  /// Starts the proof submission flow for the given session.
  /// Assumes the session is already in pendingClosure status.
  Future<void> startProofFlow(String sessionId) async {
    _resetState();
    _sessionId = sessionId;
    _state = SessionStatus.pendingClosure;
    notifyListeners();
    // The UI should now present the image capture screen (e.g., camera_capture_screen)
    // which will call setImagePath when an image is available.
  }

  /// Resets the controller to initial state.
  void _resetState() {
    _error = null;
    _capturedImagePath = null;
    _isGalleryFallback = false;
    _isDuplicatePhoto = false;
    _selectedRating = null;
    _reflectionNote = null;
    _sessionId = null;
  }

  /// Sets the captured image path and whether it was from the gallery,
  /// then processes the image (duplicate detection).
  void setImagePath(String path, bool isGalleryFallback) {
    _capturedImagePath = path;
    _isGalleryFallback = isGalleryFallback;
    _processCapturedImage();
  }

  /// Processes a captured image: runs duplicate detection and moves to rating.
  Future<void> _processCapturedImage() async {
    if (_capturedImagePath == null) return;

    _state = SessionStatus.pendingClosure; // Checking duplicate
    notifyListeners();

    try {
      final File imageFile = File(_capturedImagePath!);
      final bool isDuplicate =
          await DuplicateDetectorService.instance.isDuplicate(imageFile);
      _isDuplicatePhoto = isDuplicate;

      // Move to rating input
      _state = SessionStatus.pendingClosure; // Ready for rating
      notifyListeners();
    } catch (e) {
      _error = 'Error processing image: $e';
      // Still allow proceeding to rating
      _state = SessionStatus.pendingClosure;
      notifyListeners();
    }
  }

  // --- Rating Handling ---

  /// Submits the rating and note, then saves the proof to the session.
  Future<void> submitProof({
    required SelfRating rating,
    String? note,
  }) async {
    if (_capturedImagePath == null) {
      _error = 'No image captured';
      notifyListeners();
      return;
    }

    _selectedRating = rating;
    _reflectionNote = note;

    _state = SessionStatus.pendingClosure; // Saving
    notifyListeners();

    try {
      await _saveProofToSession();
      _state = SessionStatus.closed;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to save proof: $e';
      _state = SessionStatus.pendingClosure; // Allow retry
      notifyListeners();
    }
  }

  /// Saves the collected proof to the session record.
  Future<void> _saveProofToSession() async {
    if (_sessionId == null) throw Exception('No session ID');
    if (_capturedImagePath == null) throw Exception('No captured image');

    final session = DatabaseService.instance.getSession(_sessionId!);
    if (session == null) throw Exception('Session not found');

    session.photoPath = _capturedImagePath;
    session.selfRating = _selectedRating;
    session.reflectionNote = _reflectionNote;
    session.isGalleryFallbackPhoto = _isGalleryFallback;
    session.isDuplicatePhoto = _isDuplicatePhoto;
    session.status = SessionStatus.closed;

    await DatabaseService.instance.saveSession(session);
  }

  // --- Retry and Reset ---

  /// Resets the controller and returns to idle state.
  void reset() {
    _resetState();
    _state = SessionStatus.active;
    notifyListeners();
  }
}
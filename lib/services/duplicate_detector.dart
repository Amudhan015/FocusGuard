import 'dart:io';
import 'package:image/image.dart' as img;
import '../services/database_service.dart';

/// Service for detecting duplicate photos using perceptual hash (average hash).
class DuplicateDetectorService {
  DuplicateDetectorService._();
  static final DuplicateDetectorService instance = DuplicateDetectorService._();

  /// Size of the hash grid (8x8 = 64 bits).
  static const int _hashSize = 8;

  /// Threshold for considering two images as duplicates (Hamming distance).
  /// Lower means stricter. 0-64 range. 5 means up to 5 bits different.
  static const int _duplicateThreshold = 5;

  /// Computes the average hash of an image file.
  Future<List<bool>> _computeAverageHash(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize to hashSize x hashSize and grayscale.
      final smaller = img.copyResize(
        image,
        width: _hashSize,
        height: _hashSize,
      );
      final grayscale = img.grayscale(smaller);

      // Calculate average pixel value.
      int total = 0;
      for (int y = 0; y < _hashSize; y++) {
        for (int x = 0; x < _hashSize; x++) {
          final pixel = grayscale.getPixel(x, y);
          // Extract red component (grayscale: R=G=B)
          final int red = pixel.r.toInt();
          total += red;
        }
      }
      final double avg = total / (_hashSize * _hashSize);

      // Build hash bits: true if pixel value > average.
      final List<bool> hash = [];
      for (int y = 0; y < _hashSize; y++) {
        for (int x = 0; x < _hashSize; x++) {
          final pixel = grayscale.getPixel(x, y);
          // Extract red component (grayscale: R=G=B)
          final int red = pixel.r.toInt();
          final bool bit = red > avg;
          hash.add(bit);
        }
      }
      return hash;
    } catch (e) {
      throw Exception('Error computing image hash: $e');
    }
  }

  /// Computes Hamming distance between two hash bit lists.
  int _hammingDistance(List<bool> a, List<bool> b) {
    if (a.length != b.length) {
      throw ArgumentError('Hashes must be of equal length');
    }
    int distance = 0;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) distance++;
    }
    return distance;
  }

  /// Checks if the given image is a duplicate of any existing proof photo.
  /// Returns true if duplicate found, false otherwise.
  Future<bool> isDuplicate(File imageFile) async {
    try {
      final newHash = await _computeAverageHash(imageFile);

      // Get all sessions that have a photo path.
      final allSessions = DatabaseService.instance.getAllSessions();
      final sessionsWithPhotos = allSessions.where((s) => s.photoPath != null).toList();

      for (final session in sessionsWithPhotos) {
        final File existingFile = File(session.photoPath!);
        if (!await existingFile.exists()) continue;

        try {
          final existingHash = await _computeAverageHash(existingFile);
          final distance = _hammingDistance(newHash, existingHash);
          if (distance <= _duplicateThreshold) {
            return true; // Duplicate found
          }
        } catch (e) {
          // Skip unreadable existing photos.
          continue;
        }
      }
      return false; // No duplicates found
    } catch (e) {
      // If we cannot compute hash, assume not duplicate to avoid blocking.
      return false;
    }
  }
}
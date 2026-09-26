// Templates repository for FocusGuard
// Handles saving and retrieving session templates

import '../../models/session_template.dart';
import '../../services/database_service.dart';

/// Repository for managing session templates
class TemplatesRepository {
  TemplatesRepository._internal();
  static final TemplatesRepository _instance = TemplatesRepository._internal();
  factory TemplatesRepository() => _instance;

  /// Initialize the repository (ensures database is initialized)
  Future<void> init() async {
    await DatabaseService.instance.init();
  }

  /// Save a new template or update an existing one
  Future<void> saveTemplate(SessionTemplate template) async {
    await DatabaseService.instance.saveTemplate(template);
  }

  /// Get all templates, sorted by creation date (newest first)
  List<SessionTemplate> getAllTemplates() {
    return DatabaseService.instance.getAllTemplates();
  }

  /// Get a template by its ID
  SessionTemplate? getTemplateById(String id) {
    // Since HiveBox doesn't have a direct get by id in the service, we'll use getAll and find
    // Alternatively, we can add a method to DatabaseService, but to keep it simple, we'll do:
    final templates = DatabaseService.instance.getAllTemplates();
    return templates.where((t) => t.id == id).firstOrNull;
  }

  /// Delete a template by its ID
  Future<void> deleteTemplate(String id) async {
    await DatabaseService.instance.deleteTemplate(id);
  }

  /// Get the seeded default templates (if any)
  /// Note: The database service already seeds templates on first launch.
  /// This method is for retrieving those seeded templates if needed separately.
  List<SessionTemplate> getDefaultTemplates() {
    // We could return a hardcoded list, but since they are already in the database,
    // we'll just return all templates that match the seed IDs.
    final seedIds = [
      'seed-homework-45',
      'seed-revision-90',
      'seed-quick-focus-25',
    ];
    final all = getAllTemplates();
    return all.where((t) => seedIds.contains(t.id)).toList();
  }

  /// Check if a template with the given name already exists (case-insensitive)
  bool templateNameExists(String name, {String? excludeId}) {
    final templates = getAllTemplates();
    return templates.any((t) =>
        t.name.toLowerCase() == name.toLowerCase() && t.id != excludeId);
  }
}
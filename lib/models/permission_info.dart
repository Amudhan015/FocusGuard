import 'package:flutter/widgets.dart';

class PermissionInfo {
  PermissionInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isCritical,
    required this.checkGranted,
    required this.requestGrant,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isCritical;
  final Future<bool> Function() checkGranted;
  final Future<void> Function() requestGrant;
}

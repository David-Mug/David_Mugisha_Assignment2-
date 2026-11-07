import 'package:flutter/material.dart';

/// The kinds of problem a student can report.
///
/// Stored in Firestore by [name] (e.g. `"water"`), so labels and icons can be
/// changed freely without migrating data.
enum IncidentCategory {
  facilities('Facilities', Icons.apartment_rounded),
  water('Water', Icons.water_drop_outlined),
  electricity('Electricity', Icons.bolt_rounded),
  safety('Safety', Icons.shield_outlined),
  sanitation('Sanitation', Icons.delete_outline_rounded),
  furniture('Furniture', Icons.chair_outlined),
  internet('Internet', Icons.wifi_rounded),
  other('Other', Icons.more_horiz_rounded);

  const IncidentCategory(this.label, this.icon);

  final String label;
  final IconData icon;

  /// Converts a Firestore value back to the enum, falling back to [other]
  /// so an unexpected value never crashes the app.
  static IncidentCategory fromName(String? value) => IncidentCategory.values
      .firstWhere((c) => c.name == value, orElse: () => IncidentCategory.other);
}

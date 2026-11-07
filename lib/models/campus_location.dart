import 'package:flutter/material.dart';

/// Campus areas a student can pick when reporting an incident.
///
/// Combined with a free-text "details" field (e.g. "Block B — Room 204"),
/// this keeps data consistent for filtering while still being precise.
enum CampusLocation {
  classroom('Classroom', Icons.class_outlined),
  lectureHall('Lecture Hall', Icons.co_present_outlined),
  library('Library', Icons.local_library_outlined),
  residence('Student Residence', Icons.bed_outlined),
  cafeteria('Cafeteria', Icons.restaurant_outlined),
  washroom('Washroom', Icons.wc_outlined),
  sportsArea('Sports Area', Icons.sports_soccer_outlined),
  adminBlock('Administrative Block', Icons.business_outlined),
  other('Other', Icons.place_outlined);

  const CampusLocation(this.label, this.icon);

  final String label;
  final IconData icon;

  static CampusLocation fromName(String? value) => CampusLocation.values
      .firstWhere((l) => l.name == value, orElse: () => CampusLocation.other);
}

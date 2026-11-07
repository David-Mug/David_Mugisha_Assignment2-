/// Lifecycle of an incident: Submitted → In Progress → Resolved.
///
/// Stored in Firestore by [name]. The same transition table is enforced in
/// `firestore.rules`, so the client check below is only for a good UX — the
/// server is the real authority.
enum IncidentStatus {
  submitted('Submitted'),
  inProgress('In Progress'),
  resolved('Resolved');

  const IncidentStatus(this.label);

  final String label;

  /// Position in the timeline (0, 1, 2).
  int get step => index;

  /// Statuses staff may move to from this one.
  ///
  /// Staff can advance one step or step back one (e.g. re-open a report that
  /// was resolved too early). Jumping straight from Submitted to Resolved is
  /// allowed too, because some issues are fixed immediately.
  Set<IncidentStatus> get allowedNext => switch (this) {
    submitted => {inProgress, resolved},
    inProgress => {submitted, resolved},
    resolved => {inProgress},
  };

  bool canTransitionTo(IncidentStatus next) => allowedNext.contains(next);

  static IncidentStatus fromName(String? value) =>
      IncidentStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => IncidentStatus.submitted,
      );
}

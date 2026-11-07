import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../theme/app_colors.dart';

/// Circular profile picture, falling back to the user's initials.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.radius = 20});

  final AppUser? user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final photo = user?.photoUrl;
    final initials = Text(
      user?.initials ?? '',
      style: TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
        fontSize: radius * 0.7,
      ),
    );
    return Semantics(
      label: 'Profile picture',
      image: true,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primarySoft,
        foregroundImage: photo == null || photo.isEmpty
            ? null
            : NetworkImage(photo),
        // Shown while the photo loads, or if there is none / it fails.
        child: initials,
      ),
    );
  }
}

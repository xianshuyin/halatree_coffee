import 'package:coffee/controllers/profile_controller.dart';
import 'package:coffee/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  String _initials(String? first, String? email) {
    final a = (first != null && first.isNotEmpty) ? first[0] : '';
    //final b = (last != null && last.isNotEmpty) ? last[0] : '';
    if (a.isNotEmpty) {
      return ('$a').toUpperCase();
    }
    final e = email ?? '';
    if (e.isNotEmpty) return e[0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.roboto(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Obx(() {
          final u = controller.user.value;
          if (u == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No profile data.',
                  style: GoogleFonts.roboto(fontSize: 16, color: colorOnSurface),
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              Material(
                color: colorSurface,
                elevation: 0,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorOutline.withValues(alpha: 0.6)),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: colorPrimary.withValues(alpha: 0.35),
                        child: Text(
                          _initials(u.user_name, u.email),
                          style: GoogleFonts.roboto(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: colorOnBackground,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${u.user_name ?? ''} '.trim().isEmpty
                            ? 'Member'
                            : '${u.user_name ?? ''}'.trim(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: colorOnBackground,
                        ),
                      ),
                      if ((u.email ?? '').isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          u.email!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(fontSize: 14, color: colorOnSurface),
                        ),
                      ],
                      if ((u.total_points ?? '').isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: colorPrimary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FaIcon(FontAwesomeIcons.star, size: 18, color: colorPrimaryDark),
                              const SizedBox(width: 10),
                              Text(
                                '${u.total_points} points',
                                style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.w600,
                                  color: colorOnBackground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _InfoCard(
                children: [
                  _ProfileTile(
                    icon: Icons.mail_outline_rounded,
                    label: 'Email',
                    value: u.email ?? '—',
                  ),
                  const Divider(height: 1),
                  _ProfileTile(
                    icon: Icons.badge_outlined,
                    label: 'User name',
                    value: u.user_name ?? '—',
                  ),
                  // const Divider(height: 1),
                  // _ProfileTile(
                  //   icon: Icons.person_outline_rounded,
                  //   label: 'Last name',
                  //   value: u.last_name ?? '—',
                  // ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: controller.onEditProfilePressed,
                icon: const Icon(Icons.edit_outlined, size: 20),
                label: Text('Edit profile', style: GoogleFonts.roboto(fontWeight: FontWeight.w600)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: colorPrimaryDark,
                  foregroundColor: colorOnPrimary,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: controller.onUpdatePasswordPressed,
                icon: const Icon(Icons.lock_outline_rounded, size: 20),
                label: Text('Update password', style: GoogleFonts.roboto(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: colorPrimaryDark,
                  side: BorderSide(color: colorPrimaryDark),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorSurface,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorOutline.withValues(alpha: 0.6)),
        ),
        child: Column(children: children),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: colorPrimaryDark),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorOnSurface.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorOnBackground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

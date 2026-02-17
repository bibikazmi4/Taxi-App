import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/profile_provider.dart';
import '../screens/app_shell.dart';

class AppDrawer extends StatelessWidget {
  final int currentIndex;

  const AppDrawer({super.key, required this.currentIndex});

  void _go(BuildContext context, int index) {
    Navigator.pop(context);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => AppShell(initialIndex: index)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundImage: AssetImage("assets/images/user_avatar.png"),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile?.name ?? "User",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(profile?.phone ?? "", style: Theme.of(context).textTheme.labelMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              selected: currentIndex == 0,
              leading: const Icon(Icons.map_outlined),
              title: const Text("Home"),
              onTap: () => _go(context, 0),
            ),
            ListTile(
              selected: currentIndex == 1,
              leading: const Icon(Icons.history_outlined),
              title: const Text("History"),
              onTap: () => _go(context, 1),
            ),
            ListTile(
              selected: currentIndex == 2,
              leading: const Icon(Icons.person_outline),
              title: const Text("Profile"),
              onTap: () => _go(context, 2),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text("SwiftRide", style: Theme.of(context).textTheme.labelLarge),
            )
          ],
        ),
      ),
    );
  }
}

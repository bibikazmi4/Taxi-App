import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/profile_model.dart';
import '../providers/profile_provider.dart';
import '../utils/constants.dart';
import '../widgets/app_drawer.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool editing = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _fill(ProfileModel p) {
    _nameCtrl.text = p.name;
    _phoneCtrl.text = p.phone;
    _emailCtrl.text = p.email;
  }

  Future<void> _saveProfile(BuildContext context) async {
    final pp = context.read<ProfileProvider>();

    if (_nameCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final updated = ProfileModel(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
    );

    try {
      await pp.save(updated);

      if (mounted) {
        setState(() => editing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile saved successfully!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save: ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pp = context.watch<ProfileProvider>();
    final profile = pp.profile;

    if (profile == null && pp.isLoading) {
      return Scaffold(
        drawer: const AppDrawer(currentIndex: 2),
        appBar: AppBar(title: const Text("Profile")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentProfile = profile ??
        const ProfileModel(
          name: "User",
          phone: "+92 300 0000000",
          email: "user@example.com",
        );

    if (!editing && _nameCtrl.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fill(currentProfile);
        }
      });
    }

    return Scaffold(
      drawer: const AppDrawer(currentIndex: 2),
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(
            tooltip: editing ? "Cancel" : "Edit",
            icon: Icon(editing ? Icons.close : Icons.edit_outlined),
            onPressed: () {
              setState(() {
                editing = !editing;
                if (!editing) _fill(currentProfile);
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Constants.defaultPadding),
          child: ListView(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: cs.primaryContainer,
                    child: const Icon(
                      Icons.person,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(currentProfile.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 2),
                        Text(currentProfile.phone,
                            style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 2),
                        Text(currentProfile.email,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Details",
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameCtrl,
                        enabled: editing && !pp.isLoading,
                        decoration: const InputDecoration(labelText: "Name"),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _phoneCtrl,
                        enabled: editing && !pp.isLoading,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: "Phone"),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _emailCtrl,
                        enabled: editing && !pp.isLoading,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: "Email"),
                      ),
                      if (editing) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: pp.isLoading
                                ? null
                                : () => _saveProfile(context),
                            icon: pp.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator())
                                : const Icon(Icons.save_outlined),
                            label: pp.isLoading
                                ? const Text("Saving...")
                                : const Text("Save changes"),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.security_outlined, color: cs.primary),
                      title: const Text("Account"),
                      subtitle: const Text(
                          "Your information is stored locally on your device."),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.info_outline, color: cs.primary),
                      title: const Text("About"),
                      subtitle:
                          const Text("SwiftRide • Taxi & Courier booking"),
                    ),
                  ],
                ),
              ),
              if (pp.error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: cs.error),
                      const SizedBox(width: 8),
                      Expanded(child: Text(pp.error!)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

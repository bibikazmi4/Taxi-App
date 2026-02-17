import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/constants.dart';

class CallScreen extends StatefulWidget {
  final String driverName;
  final String phoneNumber;
  final String driverPhoto;

  const CallScreen({
    super.key,
    required this.driverName,
    required this.phoneNumber,
    required this.driverPhoto,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  Timer? _callTimer;
  Duration _callDuration = Duration.zero;
  bool _isCallConnected = false;
  bool _isMuted = false;
  bool _isOnSpeaker = false;

  @override
  void initState() {
    super.initState();
    _startCallSimulation();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    super.dispose();
  }

  void _startCallSimulation() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isCallConnected = true);
        _startCallTimer();
      }
    });
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _callDuration += const Duration(seconds: 1));
      }
    });
  }

  Future<void> _makeRealCall() async {
    final url = Uri.parse('tel:${widget.phoneNumber}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot make call')),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Status bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_callDuration),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const Icon(Icons.signal_cellular_alt,
                      color: Colors.white, size: 16),
                ],
              ),
            ),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Driver Photo
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[800],
                    backgroundImage:
                        const AssetImage("assets/images/driver_avatar.png"),
                  ),
                  const SizedBox(height: 20),

                  // Driver Name
                  Text(
                    widget.driverName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Call Status
                  Text(
                    _isCallConnected ? 'Connected' : 'Calling...',
                    style: TextStyle(
                      color: _isCallConnected ? Colors.green : Colors.yellow,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Phone Number
                  Text(
                    widget.phoneNumber,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),

            // Call Controls
            Padding(
              padding: const EdgeInsets.all(Constants.defaultPadding),
              child: Column(
                children: [
                  // Mute & Speaker Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _CallControlButton(
                        icon: _isMuted ? Icons.mic_off : Icons.mic,
                        label: _isMuted ? 'Unmute' : 'Mute',
                        isActive: _isMuted,
                        onPressed: () => setState(() => _isMuted = !_isMuted),
                      ),
                      _CallControlButton(
                        icon:
                            _isOnSpeaker ? Icons.volume_up : Icons.volume_down,
                        label: _isOnSpeaker ? 'Speaker On' : 'Speaker',
                        isActive: _isOnSpeaker,
                        onPressed: () =>
                            setState(() => _isOnSpeaker = !_isOnSpeaker),
                      ),
                      _CallControlButton(
                        icon: Icons.pause,
                        label: 'Hold',
                        onPressed: () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Call & End Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Make Real Call Button
                      InkWell(
                        onTap: _makeRealCall,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call,
                              color: Colors.white, size: 30),
                        ),
                      ),

                      // End Call Button
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call_end,
                              color: Colors.white, size: 30),
                        ),
                      ),

                      // Dialpad Button
                      InkWell(
                        onTap: () {
                          // Show dialpad
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.dialpad,
                              color: Colors.white, size: 30),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Additional Options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _CallOptionButton(
                        icon: Icons.message,
                        label: 'Message',
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      _CallOptionButton(
                        icon: Icons.person_add,
                        label: 'Add Contact',
                        onPressed: () {},
                      ),
                      _CallOptionButton(
                        icon: Icons.record_voice_over,
                        label: 'Record',
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isActive;

  const _CallControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.grey[800],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}

class _CallOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _CallOptionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white, size: 24),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}

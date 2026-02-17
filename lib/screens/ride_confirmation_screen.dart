import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/ride_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/platform_support.dart';
import '../widgets/primary_button.dart';
import '../widgets/driver_card.dart';
import 'ride_tracking_screen.dart';
import 'driver_chat_screen.dart';
import 'call_screen.dart'; // ADD THIS IMPORT

class RideConfirmationScreen extends StatefulWidget {
  const RideConfirmationScreen({super.key});

  @override
  State<RideConfirmationScreen> createState() => _RideConfirmationScreenState();
}

class _RideConfirmationScreenState extends State<RideConfirmationScreen> {
  Timer? _timer;
  int _etaMinutes = 6;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      setState(() => _etaMinutes = (_etaMinutes - 1).clamp(1, 99));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideProvider>().activeRide;

    if (ride == null) {
      return const Scaffold(
        body: Center(child: Text("No active ride.")),
      );
    }

    final pickup = LatLng(ride.pickup.position.lat, ride.pickup.position.lng);
    final driverPos = _fakeDriverNear(pickup);

    return Scaffold(
      appBar: AppBar(title: const Text("Ride confirmed")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Constants.defaultPadding),
          child: Column(
            children: [
              DriverCard(driver: ride.driver),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Summary",
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text("Pickup: ${ride.pickup.label}"),
                      Text("Drop-off: ${ride.dropoff.label}"),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                              child: Text(
                                  "${ride.distanceKm.toStringAsFixed(1)} km")),
                          Expanded(
                              child: Text(
                                  "${ride.durationMin.toStringAsFixed(0)} min")),
                          Expanded(
                              child: Text(Formatters.money(ride.fare),
                                  textAlign: TextAlign.end)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: PlatformSupport.isDesktopUnsupportedForGoogleMaps
                        ? const Center(
                            child: Text(
                                "Mini-map is available on Android/iOS/Web."))
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: GoogleMap(
                              initialCameraPosition:
                                  CameraPosition(target: pickup, zoom: 14),
                              markers: {
                                Marker(
                                    markerId: const MarkerId("pickup"),
                                    position: pickup),
                                Marker(
                                  markerId: const MarkerId("driver"),
                                  position: driverPos,
                                  infoWindow: const InfoWindow(title: "Driver"),
                                ),
                              },
                              polylines: const {},
                              zoomControlsEnabled: false,
                              myLocationEnabled: false,
                              myLocationButtonEnabled: false,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Driver arriving in",
                                style: Theme.of(context).textTheme.labelLarge),
                            Text("$_etaMinutes min",
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      // UPDATED CALL BUTTON
                      IconButton(
                        tooltip: "Call",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CallScreen(
                                driverName: ride.driver.name,
                                phoneNumber: ride.driver.phone,
                                driverPhoto: ride.driver.avatarAsset,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.call_outlined),
                      ),
                      IconButton(
                        tooltip: "Message",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DriverChatScreen(
                                threadId: ride.id,
                                driverName: ride.driver.name,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline),
                      ),
                      IconButton(
                        tooltip: "Cancel",
                        onPressed: () async {
                          await context.read<RideProvider>().cancelActiveRide();
                          if (!context.mounted) return;
                          Navigator.popUntil(context, (r) => r.isFirst);
                          _toast(context, "Ride cancelled.");
                        },
                        icon: const Icon(Icons.cancel_outlined),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                label: "Start tracking",
                icon: Icons.navigation_outlined,
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RideTrackingScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  LatLng _fakeDriverNear(LatLng pickup) {
    return LatLng(pickup.latitude + 0.004, pickup.longitude - 0.003);
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../models/app_latlng.dart';
import '../models/ride_model.dart';
import '../providers/ride_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/platform_support.dart';
import '../widgets/primary_button.dart';
import 'rate_driver_screen.dart';

class RideTrackingScreen extends StatefulWidget {
  const RideTrackingScreen({super.key});

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  Timer? _timer;
  int _index = 0;

  LatLng? _driverPos;
  double _etaMin = 12;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<AppLatLng> _expandedRoute(List<AppLatLng> route) {
    if (route.length >= 10) return route;
    if (route.length < 2) return route;

    // Create more points by interpolation for smoother animation.
    final out = <AppLatLng>[];
    for (int i = 0; i < route.length - 1; i++) {
      final a = route[i];
      final b = route[i + 1];
      out.add(a);
      for (int s = 1; s <= 6; s++) {
        final t = s / 7.0;
        out.add(AppLatLng(
          a.lat + (b.lat - a.lat) * t,
          a.lng + (b.lng - a.lng) * t,
        ));
      }
    }
    out.add(route.last);
    return out;
  }

  void _tick() async {
    final rp = context.read<RideProvider>();
    final ride = rp.activeRide;
    if (ride == null) return;

    final route = _expandedRoute(ride.route);
    if (route.isEmpty) return;

    setState(() {
      _index = min(_index + 1, route.length - 1);
      _driverPos = LatLng(route[_index].lat, route[_index].lng);
      _etaMin = max(1, _etaMin - 0.4);
    });

    // update ride status progression
    if (_index < route.length * 0.25) {
      await rp.updateActiveRideStatus(RideStatus.arriving);
    } else if (_index < route.length * 0.85) {
      await rp.updateActiveRideStatus(RideStatus.inTrip);
    } else if (_index == route.length - 1) {
      await rp.completeActiveRide();
      if (!mounted) return;
      _timer?.cancel();
      _showCompleteSheet();
    }
  }

  void _showCompleteSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Constants.defaultPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Trip completed!",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                const Text("Thanks for riding with SwiftRide."),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: "Rate driver",
                  icon: Icons.star_outline,
                  onPressed: () {
                    final rideId = context.read<RideProvider>().activeRide?.id;
                    if (rideId == null) return;
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RateDriverScreen(rideId: rideId)),
                    );
                  },
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: "Back to home",
                  icon: Icons.home_outlined,
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.popUntil(context, (r) => r.isFirst);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<RideProvider>();
    final ride = rp.activeRide;

    if (ride == null) {
      return const Scaffold(body: Center(child: Text("No active ride.")));
    }

    final route = _expandedRoute(ride.route);
    final start = LatLng(ride.pickup.position.lat, ride.pickup.position.lng);
    final end = LatLng(ride.dropoff.position.lat, ride.dropoff.position.lng);
    final driver = _driverPos ?? start;

    final polyline = Polyline(
      polylineId: const PolylineId("route"),
      points: route.map((p) => LatLng(p.lat, p.lng)).toList(),
      width: 6,
    );

    final status = ride.status;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tracking"),
        actions: [
          IconButton(
            tooltip: "Cancel ride",
            onPressed: () async {
              await context.read<RideProvider>().cancelActiveRide();
              if (!context.mounted) return;
              Navigator.popUntil(context, (r) => r.isFirst);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ride cancelled.")));
            },
            icon: const Icon(Icons.cancel_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PlatformSupport.isDesktopUnsupportedForGoogleMaps
                  ? const Center(child: Text("Tracking map available on Android/iOS/Web."))
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(target: start, zoom: 14),
                      markers: {
                        Marker(markerId: const MarkerId("pickup"), position: start),
                        Marker(markerId: const MarkerId("dropoff"), position: end),
                        Marker(
                          markerId: const MarkerId("driver"),
                          position: driver,
                          infoWindow: const InfoWindow(title: "Driver"),
                        ),
                      },
                      polylines: {polyline},
                      zoomControlsEnabled: false,
                      myLocationEnabled: false,
                      myLocationButtonEnabled: false,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(Constants.defaultPadding),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          status.label,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text("${_etaMin.toStringAsFixed(0)} min ETA",
                          style: Theme.of(context).textTheme.labelLarge),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: status.progress),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Trip details",
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Text("Pickup: ${ride.pickup.label}"),
                          Text("Drop-off: ${ride.dropoff.label}"),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: Text("${ride.distanceKm.toStringAsFixed(1)} km")),
                              Expanded(child: Text(Formatters.money(ride.fare), textAlign: TextAlign.end)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (status == RideStatus.inTrip)
                    PrimaryButton(
                      label: "Navigate",
                      icon: Icons.directions,
                      onPressed: () => ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text("Open navigation."))),
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
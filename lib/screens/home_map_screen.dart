import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../models/app_latlng.dart';
import '../models/location_model.dart';
import '../providers/location_provider.dart';
import '../providers/ride_provider.dart';
import '../utils/constants.dart';
import '../utils/platform_support.dart';
import '../widgets/primary_button.dart';
import 'ride_options_screen.dart';
import '../widgets/app_drawer.dart';

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  final _pickupCtrl = TextEditingController();
  final _dropCtrl = TextEditingController();

  GoogleMapController? _mapController;
  Completer<GoogleMapController> _controller = Completer();

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    // Future initialization if needed
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _dropCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // MANUAL LOCATION INPUT METHOD
  Future<void> _showManualLocationInput(
      BuildContext context, bool isPickup) async {
    final locProvider = context.read<LocationProvider>();
    final TextEditingController searchCtrl = TextEditingController();
    List<LocationModel> searchResults = [];

    final result = await showModalBottomSheet<LocationModel>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(Constants.defaultPadding),
                    child: Column(
                      children: [
                        Text(
                          isPickup
                              ? "Enter pickup address"
                              : "Enter destination",
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: searchCtrl,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText:
                                "Type address (e.g., Gulshan, Clifton)...",
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchCtrl.clear();
                                setState(() => searchResults = []);
                              },
                            ),
                          ),
                          onChanged: (value) {
                            if (value.trim().isNotEmpty) {
                              // Filter preset locations based on search
                              final filtered = locProvider.presetLocations
                                  .where((loc) => loc.label
                                      .toLowerCase()
                                      .contains(value.toLowerCase()))
                                  .toList();
                              setState(() => searchResults = filtered);
                            } else {
                              setState(() => searchResults = []);
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  // Search Results
                  if (searchResults.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(
                            bottom: Constants.defaultPadding),
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final location = searchResults[index];
                          return ListTile(
                            leading: Icon(isPickup
                                ? Icons.my_location_outlined
                                : Icons.place_outlined),
                            title: Text(location.label),
                            subtitle: Text(
                                "${location.position.lat.toStringAsFixed(5)}, ${location.position.lng.toStringAsFixed(5)}"),
                            onTap: () => Navigator.pop(context, location),
                          );
                        },
                      ),
                    ),

                  // Recent/Preset Locations (when no search)
                  if (searchResults.isEmpty)
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(
                            bottom: Constants.defaultPadding),
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: Constants.defaultPadding),
                            child: Text("Popular locations in Karachi:",
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(height: 8),
                          ...locProvider.presetLocations.map((location) {
                            return ListTile(
                              leading: const Icon(Icons.location_on),
                              title: Text(location.label),
                              subtitle: Text(
                                  "${location.position.lat.toStringAsFixed(5)}, ${location.position.lng.toStringAsFixed(5)}"),
                              onTap: () => Navigator.pop(context, location),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      if (isPickup) {
        locProvider.setPickup(result);
        _pickupCtrl.text = result.label;
      } else {
        locProvider.setDropoff(result);
        _dropCtrl.text = result.label;
      }
      await _animateTo(result.position);
    }
  }

  Future<void> _selectLocation({
    required bool isPickup,
    required List<LocationModel> options,
  }) async {
    final choice = await showModalBottomSheet<LocationModel>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: Constants.defaultPadding,
                  left: Constants.defaultPadding,
                  right: Constants.defaultPadding,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isPickup ? "Select pickup" : "Select drop-off",
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(Icons.keyboard),
                      onPressed: () {
                        Navigator.pop(context); // Close this sheet
                        _showManualLocationInput(
                            context, isPickup); // Open manual input
                      },
                      tooltip: "Type address",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(
                    left: Constants.defaultPadding,
                    right: Constants.defaultPadding,
                    bottom: Constants.defaultPadding,
                  ),
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final location = options[index];
                    return ListTile(
                      leading: Icon(isPickup
                          ? Icons.my_location_outlined
                          : Icons.place_outlined),
                      title: Text(location.label),
                      subtitle: Text(
                          "${location.position.lat.toStringAsFixed(5)}, ${location.position.lng.toStringAsFixed(5)}"),
                      onTap: () => Navigator.pop(context, location),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    if (choice == null) return;

    final locProvider = context.read<LocationProvider>();
    if (isPickup) {
      locProvider.setPickup(choice);
      _pickupCtrl.text = choice.label;
    } else {
      locProvider.setDropoff(choice);
      _dropCtrl.text = choice.label;
    }

    await _animateTo(choice.position);
    _updateMapMarkers();
  }

  Future<void> _animateTo(AppLatLng p) async {
    final ctrl = _mapController;
    if (ctrl == null) return;
    await ctrl.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(p.lat, p.lng),
        14,
      ),
    );
  }

  void _updateMapMarkers() {
    final loc = context.read<LocationProvider>();
    _markers.clear();

    if (loc.pickup != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId("pickup"),
          position: LatLng(loc.pickup!.position.lat, loc.pickup!.position.lng),
          infoWindow: InfoWindow(
            title: "Pickup",
            snippet: loc.pickup!.label,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    if (loc.dropoff != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId("dropoff"),
          position:
              LatLng(loc.dropoff!.position.lat, loc.dropoff!.position.lng),
          infoWindow: InfoWindow(
            title: "Drop-off",
            snippet: loc.dropoff!.label,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _updatePolylines() {
    final ride = context.read<RideProvider>();
    _polylines.clear();

    if (ride.routePoints.isNotEmpty) {
      final pts = ride.routePoints
          .map((p) => LatLng(p.lat, p.lng))
          .toList(growable: false);

      _polylines.add(
        Polyline(
          polylineId: const PolylineId("route"),
          points: pts,
          color: const Color(Constants.accentBlue),
          width: 5,
        ),
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocationProvider>();
    final ride = context.watch<RideProvider>();

    // Update text controllers
    if (loc.pickup != null && _pickupCtrl.text != loc.pickup!.label) {
      _pickupCtrl.text = loc.pickup!.label;
    }
    if (loc.dropoff != null && _dropCtrl.text != loc.dropoff!.label) {
      _dropCtrl.text = loc.dropoff!.label;
    }

    // Update markers and polylines
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMapMarkers();
      _updatePolylines();
    });

    final canChooseRide =
        loc.pickup != null && loc.dropoff != null && !ride.isLoading;

    final initialPosition = loc.currentPosition == null
        ? const LatLng(24.8607, 67.0011)
        : LatLng(loc.currentPosition!.latitude, loc.currentPosition!.longitude);

    return Scaffold(
      drawer: const AppDrawer(currentIndex: 0),
      appBar: AppBar(
        title: const Text("SwiftRide"),
        actions: [
          IconButton(
            tooltip: "Refresh location",
            onPressed: loc.isLoading ? null : () => loc.loadCurrentLocation(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Location Selection Card
            Padding(
              padding: const EdgeInsets.all(Constants.defaultPadding),
              child: Column(
                children: [
                  // Pickup Field with Keyboard Icon
                  Row(
                    children: [
                      Expanded(
                        child: _LocationField(
                          controller: _pickupCtrl,
                          hint: "Pickup location",
                          icon: Icons.my_location_outlined,
                          onTap: () async {
                            final options = <LocationModel>[
                              if (loc.currentPosition != null)
                                LocationModel(
                                  label: "Current location",
                                  position: AppLatLng(
                                    loc.currentPosition!.latitude,
                                    loc.currentPosition!.longitude,
                                  ),
                                ),
                              ...loc.presetLocations,
                            ];
                            await _selectLocation(
                              isPickup: true,
                              options: options,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.keyboard),
                        onPressed: () =>
                            _showManualLocationInput(context, true),
                        tooltip: "Type pickup address",
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Dropoff Field with Keyboard Icon
                  Row(
                    children: [
                      Expanded(
                        child: _LocationField(
                          controller: _dropCtrl,
                          hint: "Drop-off location",
                          icon: Icons.place_outlined,
                          onTap: () async {
                            await _selectLocation(
                              isPickup: false,
                              options: loc.presetLocations,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.keyboard),
                        onPressed: () =>
                            _showManualLocationInput(context, false),
                        tooltip: "Type destination",
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: "Swap locations",
                        onPressed: (loc.pickup != null || loc.dropoff != null)
                            ? () {
                                loc.swap();
                                final temp = _pickupCtrl.text;
                                _pickupCtrl.text = _dropCtrl.text;
                                _dropCtrl.text = temp;
                              }
                            : null,
                        icon: const Icon(Icons.swap_vert),
                      ),
                    ],
                  ),

                  if (loc.errorMessage != null) ...[
                    const SizedBox(height: 10),
                    _InlineError(text: loc.errorMessage!),
                  ],
                  if (ride.errorMessage != null) ...[
                    const SizedBox(height: 10),
                    _InlineError(text: ride.errorMessage!),
                  ],
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: ride.isLoading ? "Loading route..." : "Choose Ride",
                    icon: Icons.local_taxi,
                    onPressed: canChooseRide
                        ? () async => _buildRouteAndGo(context)
                        : null,
                  ),
                ],
              ),
            ),

            // Map Section
            Expanded(
              child: PlatformSupport.isDesktopUnsupportedForGoogleMaps
                  ? const _DesktopNotSupportedCard()
                  : Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: initialPosition,
                            zoom: 13,
                          ),
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          markers: _markers,
                          polylines: _polylines,
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                            _controller.complete(controller);
                          },
                          zoomControlsEnabled: false,
                          mapType: MapType.normal,
                          compassEnabled: true,
                          rotateGesturesEnabled: true,
                          scrollGesturesEnabled: true,
                          zoomGesturesEnabled: true,
                          tiltGesturesEnabled: true,
                        ),
                        if (ride.isLoading)
                          const Positioned(
                            left: 0,
                            right: 0,
                            top: 10,
                            child: _LoadingPill(),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _buildRouteAndGo(BuildContext context) async {
    final loc = context.read<LocationProvider>();
    final ride = context.read<RideProvider>();
    final pickup = loc.pickup!;
    final dropoff = loc.dropoff!;

    await ride.buildRoute(pickup: pickup, dropoff: dropoff);
    if (!mounted) return;

    if (ride.lastRoute != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RideOptionsScreen(pickup: pickup, dropoff: dropoff),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Could not load route. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _LoadingPill extends StatelessWidget {
  const _LoadingPill();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        borderRadius: BorderRadius.circular(999),
        elevation: 4,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Fetching route...",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String text;
  const _InlineError({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 20, color: cs.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: cs.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final VoidCallback onTap;

  const _LocationField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: hint,
      button: true,
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: onTap,
        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          prefixIcon: Icon(icon),
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopNotSupportedCard extends StatelessWidget {
  const _DesktopNotSupportedCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Constants.defaultPadding),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(Constants.defaultPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  "Google Maps on Desktop",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "For full map functionality, run on Android/iOS or use Chrome (web).",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Open in browser option
                  },
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text("Open in Chrome"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
